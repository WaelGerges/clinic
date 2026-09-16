import '../domain/scheduling.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../domain/models.dart';
import '../domain/clinic_time.dart';
import 'database.dart';
import 'gateway.dart';
import 'patient_sync_review.dart';

class SyncSummary {
  const SyncSummary(this.pending, this.conflicts, this.failed);
  final int pending, conflicts, failed;
  bool get clean => pending + conflicts + failed == 0;
}

class ClinicRepository {
  ClinicRepository({
    required this.db,
    required this.session,
    this.gateway,
    this.deviceId,
    this.onAccessRevoked,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final ClinicDatabase db;
  final ClinicSession session;
  final ClinicGateway? gateway;
  final String? deviceId;
  final void Function()? onAccessRevoked;
  ClinicAdministration get administration {
    final remote = gateway;
    if (!session.isAdmin || remote is! ClinicAdministration) {
      throw const ClinicFailure(
        'forbidden',
        'Online clinic administrator access is required.',
      );
    }
    return remote as ClinicAdministration;
  }

  ClinicAuditGateway get auditGateway {
    final remote = gateway;
    if (!session.isDoctor ||
        !session.isAdmin ||
        session.isDemo ||
        remote is! ClinicAuditGateway) {
      throw const ClinicFailure(
        'forbidden',
        'Online doctor administrator access is required to review audit history.',
      );
    }
    return remote as ClinicAuditGateway;
  }

  ClinicDocumentGateway get documentGateway {
    final remote = gateway;
    if (remote is! ClinicDocumentGateway) {
      throw const ClinicFailure(
        'offline',
        'Connect to the clinic document service. Local files are retained.',
      );
    }
    return remote as ClinicDocumentGateway;
  }

  Future<DoctorDeliveryState> deliveryState({String? appointmentId}) async {
    if (session.isDemo && session.isDoctor) {
      final now = clock().toUtc();
      return DoctorDeliveryState(
        serverNow: now,
        doctorOnline: true,
        serviceAvailable: false,
        presenceExpiresAt: now.add(const Duration(minutes: 1)),
        acknowledgedAt: appointmentId == null ? null : now,
      );
    }
    final remote = gateway;
    if (remote is! ClinicDeliveryGateway) {
      return DoctorDeliveryState.unavailable(clock());
    }
    return (remote as ClinicDeliveryGateway).doctorDeliveryState(
      session.clinicId,
      session.doctorId,
      appointmentId: appointmentId,
    );
  }

  Future<void> renewDoctorPresence() async {
    if (!session.isDoctor || session.isDemo) return;
    final remote = gateway, currentDevice = deviceId;
    if (remote is! ClinicDeliveryGateway || currentDevice == null) {
      throw const ClinicFailure(
        'offline',
        'Doctor device presence requires an online protected device identity.',
      );
    }
    await (remote as ClinicDeliveryGateway).doctorHeartbeat(
      session.clinicId,
      currentDevice,
    );
  }

  Future<void> acknowledgeAppointment(Appointment appointment) async {
    _requireDoctor();
    _checkClinic(appointment.clinicId);
    if (appointment.doctorId != session.userId ||
        appointment.status != AppointmentStatus.withDoctor) {
      throw const ClinicFailure(
        'assignment_changed',
        'This patient is no longer assigned to this doctor.',
      );
    }
    final remote = gateway, currentDevice = deviceId;
    if (remote is! ClinicDeliveryGateway || currentDevice == null) {
      throw const ClinicFailure(
        'offline',
        'Connect this Doctor device before acknowledging the patient.',
      );
    }
    await renewDoctorPresence();
    await (remote as ClinicDeliveryGateway).acknowledgeAppointment(
      session.clinicId,
      appointment.id,
      currentDevice,
      _uuid.v4(),
      appointment.version,
    );
    _emit();
  }

  final DateTime Function() clock;
  final _changes = StreamController<void>.broadcast();
  final _uuid = const Uuid();
  Future<void>? _sync;
  StreamSubscription<void>? _remoteSubscription;
  Timer? _retry;
  int _failures = 0;
  bool _closed = false;
  bool _criticalInProgress = false;
  bool _resolutionInProgress = false;
  String? connectionWarning;
  final _watchedHistory = <String, int>{};
  void watchPatientHistory(String id) =>
      _watchedHistory.update(id, (n) => n + 1, ifAbsent: () => 1);
  void unwatchPatientHistory(String id) {
    final count = (_watchedHistory[id] ?? 1) - 1;
    if (count <= 0) {
      _watchedHistory.remove(id);
    } else {
      _watchedHistory[id] = count;
    }
  }

  void reportConnectionFailure() {
    connectionWarning =
        'Connection unavailable. Showing saved local data; synchronization is pending.';
    _emit();
  }

  Stream<void> get changes => _changes.stream;
  void _emit() {
    if (!_closed) _changes.add(null);
  }

  void _checkClinic(String id) {
    if (id != session.clinicId) {
      throw const ClinicFailure(
        'forbidden',
        'This record belongs to another clinic.',
      );
    }
  }

  void _requireDoctor() {
    if (!session.isDoctor) {
      throw const ClinicFailure(
        'forbidden',
        'Only a doctor can change clinical records.',
      );
    }
  }

  Future<void> startSync() async {
    if (gateway == null) return;
    _remoteSubscription ??= gateway!
        .changes(session.clinicId)
        .listen(
          (_) {
            // Reconciliation is serialized and dirty records are never overwritten.
            unawaited(
              refresh().catchError((Object _) {
                connectionWarning =
                    'Connection interrupted. Showing saved local data.';
                _emit();
              }),
            );
          },
          onError: (Object _) {
            _scheduleRetry();
          },
        );
    await db.customStatement(
      "UPDATE outbox SET state='pending' WHERE state='sending'",
    );
    await db.customStatement(
      "UPDATE document_blobs SET transfer_state='pending' WHERE transfer_state='uploading'",
    );
    await synchronize();
  }

  Future<List<Patient>> patients({
    String search = '',
    bool archived = false,
    int offset = 0,
    int limit = 50,
  }) async {
    final term = search
        .trim()
        .toLowerCase()
        .replaceAll('\\', '\\\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final digits = normalizePhone(search);
    final rows = await db
        .customSelect(
          "SELECT * FROM cached_patients WHERE clinic_id=? AND archived=? AND "
          "(LOWER(full_name) LIKE ? ESCAPE '\\' OR LOWER(patient_number) LIKE ? ESCAPE '\\' "
          "OR id=? OR (? <> '' AND (mobile_digits LIKE ? OR secondary_mobile LIKE ?))) ORDER BY full_name COLLATE NOCASE,id LIMIT ? OFFSET ?",
          variables: [
            Variable(session.clinicId),
            Variable(archived ? 1 : 0),
            Variable('%$term%'),
            Variable('%$term%'),
            Variable(search.trim()),
            Variable(digits),
            Variable('%$digits%'),
            Variable('%$digits%'),
            Variable(limit.clamp(1, 100)),
            Variable(offset < 0 ? 0 : offset),
          ],
        )
        .get();
    return rows
        .map(
          (r) =>
              Patient.fromMap({...r.data, 'archived': r.data['archived'] == 1}),
        )
        .toList();
  }

  Future<Patient?> patient(String id) async {
    final rows = await db
        .customSelect(
          'SELECT * FROM cached_patients WHERE clinic_id=? AND id=?',
          variables: [Variable(session.clinicId), Variable(id)],
        )
        .get();
    if (rows.isEmpty) return null;
    return Patient.fromMap({
      ...rows.first.data,
      'archived': rows.first.data['archived'] == 1,
    });
  }

  /// Reads a patient, falling back to the server when it is not cached.
  ///
  /// Screens that resolve a patient by id held in server-side state (the
  /// scheduling waitlist) must not render "unavailable" merely because the
  /// record sits outside the cached pages.
  Future<Patient?> patientOrFetch(String id) async {
    final local = await patient(id);
    if (local != null) return local;
    final remote = gateway;
    if (remote == null) return null;
    final values = await remote.patientsByIds(session.clinicId, [id]);
    if (values.isEmpty) return null;
    _checkClinic(values.single.clinicId);
    await _cachePatients(values);
    return values.single;
  }

  Future<List<Appointment>> appointments({DateTime? day}) async {
    final date = day ?? ClinicTime.local(clock());
    final bounds = ClinicTime.dayBounds(date);
    final from = bounds.from, to = bounds.to;
    final rows = await db
        .customSelect(
          'SELECT * FROM cached_appointments WHERE clinic_id=? AND starts_at>=? AND starts_at<? ORDER BY starts_at,id',
          variables: [
            Variable(session.clinicId),
            Variable(from.toIso8601String()),
            Variable(to.toIso8601String()),
          ],
        )
        .get();
    return rows.map((r) => Appointment.fromMap(r.data)).toList();
  }

  Future<Appointment?> appointment(String id) async {
    final rows = await db
        .customSelect(
          'SELECT * FROM cached_appointments WHERE clinic_id=? AND id=?',
          variables: [Variable(session.clinicId), Variable(id)],
        )
        .get();
    return rows.isEmpty ? null : Appointment.fromMap(rows.first.data);
  }

  Future<Appointment?> activeAppointment() async {
    final rows = await db
        .customSelect(
          "SELECT * FROM cached_appointments WHERE clinic_id=? AND doctor_id=? AND status='withDoctor' ORDER BY starts_at LIMIT 1",
          variables: [Variable(session.clinicId), Variable(session.doctorId)],
        )
        .get();
    return rows.isEmpty ? null : Appointment.fromMap(rows.first.data);
  }

  Future<Visit> visitForPrinting(String patientId, String visitId) async {
    if (!session.clinicalRead) {
      throw const ClinicFailure('forbidden', 'Clinical access restricted');
    }
    final remote = gateway;
    if (!session.isDemo) {
      if (remote is! ClinicVisitExportGateway) {
        throw const ClinicFailure(
          'offline',
          'Connect to refresh the saved visit before printing.',
        );
      }
      await remote!.verifySession(session);
      return (remote as ClinicVisitExportGateway).printableVisit(
        session.clinicId,
        patientId,
        visitId,
      );
    }
    for (var offset = 0; ; offset += 50) {
      final rows = await visits(patientId, offset: offset);
      final found = rows.where((v) => v.id == visitId).firstOrNull;
      if (found != null) return found;
      if (rows.length < 50) {
        throw const ClinicFailure(
          'not_found',
          'The saved visit is unavailable.',
        );
      }
    }
  }

  Future<List<Visit>> visits(String patientId, {int offset = 0}) async {
    if (!session.clinicalRead) {
      throw const ClinicFailure(
        'forbidden',
        'Clinical access has not been granted by the doctor.',
      );
    }
    final rows = await db
        .customSelect(
          'SELECT * FROM cached_visits WHERE clinic_id=? AND patient_id=? ORDER BY created_at DESC,id LIMIT 50 OFFSET ?',
          variables: [
            Variable(session.clinicId),
            Variable(patientId),
            Variable(offset),
          ],
        )
        .get();
    final result = <Visit>[];
    for (final row in rows) {
      final diagnoses = await db
          .customSelect(
            'SELECT description FROM cached_diagnoses WHERE visit_id=? ORDER BY position',
            variables: [Variable(row.data['id'] as String)],
          )
          .get();
      final medicines = await db
          .customSelect(
            'SELECT * FROM cached_medications WHERE visit_id=? ORDER BY position',
            variables: [Variable(row.data['id'] as String)],
          )
          .get();
      result.add(
        Visit.fromMap({
          ...row.data,
          'completed': row.data['completed'] == 1,
          'diagnoses': diagnoses.map((d) => d.data['description']).toList(),
          'medications': medicines.map((d) => d.data).toList(),
        }),
      );
    }
    return result;
  }

  Future<List<ClinicDocument>> documents(
    String patientId, {
    String? visitId,
    bool archived = false,
    int offset = 0,
  }) async {
    final patientValue = await patient(patientId);
    if (patientValue == null) {
      throw const ClinicFailure('not_found', 'The patient is not available.');
    }
    _checkClinic(patientValue.clinicId);
    if (visitId != null && !session.clinicalRead) {
      throw const ClinicFailure(
        'forbidden',
        'Clinical access has not been granted by the doctor.',
      );
    }
    final whereVisit = visitId == null ? '' : ' AND visit_id=?';
    final rows = await db
        .customSelect(
          "SELECT * FROM cached_documents WHERE clinic_id=? AND patient_id=?$whereVisit AND state${archived ? '=' : '<>'}'archived' ORDER BY created_at DESC,id LIMIT 50 OFFSET ?",
          variables: [
            Variable(session.clinicId),
            Variable(patientId),
            if (visitId != null) Variable(visitId),
            Variable(offset < 0 ? 0 : offset),
          ],
        )
        .get();
    return rows.map((row) => ClinicDocument.fromMap(row.data)).toList();
  }

  Future<ClinicDocument?> document(String id) async {
    final rows = await db
        .customSelect(
          'SELECT * FROM cached_documents WHERE clinic_id=? AND id=?',
          variables: [Variable(session.clinicId), Variable(id)],
        )
        .get();
    return rows.isEmpty ? null : ClinicDocument.fromMap(rows.first.data);
  }

  Future<ClinicDocument> stageDocument({
    required String patientId,
    required String fileName,
    required String contentType,
    required ClinicDocumentCategory category,
    required Uint8List data,
    String? visitId,
    String notes = '',
    bool clinical = true,
  }) async {
    if (_closed) {
      throw const ClinicFailure('closed', 'Clinic access is closed.');
    }
    final patientValue = await patient(patientId);
    if (patientValue == null || patientValue.archived) {
      throw const ClinicFailure(
        'invalid_patient',
        'Documents cannot be added to an unavailable or archived patient.',
      );
    }
    _checkClinic(patientValue.clinicId);
    if (clinical && !session.clinicalRead) {
      throw const ClinicFailure(
        'forbidden',
        'Clinical document access has not been granted by the doctor.',
      );
    }
    if (visitId != null) {
      if (!clinical || !session.clinicalRead) {
        throw const ClinicFailure(
          'forbidden',
          'Visit documents must be clinical records.',
        );
      }
      final visit = await db
          .customSelect(
            'SELECT 1 FROM cached_visits WHERE clinic_id=? AND id=? AND patient_id=? LIMIT 1',
            variables: [
              Variable(session.clinicId),
              Variable(visitId),
              Variable(patientId),
            ],
          )
          .get();
      if (visit.isEmpty) {
        throw const ClinicFailure(
          'invalid_visit',
          'Save this visit before attaching a document.',
        );
      }
    }
    final detected = ClinicDocument.detectContentType(data);
    if (detected == null || detected != contentType) {
      throw const ClinicFailure(
        'invalid_document',
        'The file contents do not match a supported image or PDF format.',
      );
    }
    final id = _uuid.v4();
    final digest = sha256.convert(data).toString();
    final now = clock().toUtc();
    final value = ClinicDocument(
      id: id,
      clinicId: session.clinicId,
      patientId: patientId,
      visitId: visitId,
      fileName: fileName.trim(),
      contentType: contentType,
      category: category,
      notes: notes.trim(),
      objectPath: '${session.clinicId}/$patientId/$id',
      bytes: data.length,
      sha256Hex: digest,
      clinical: clinical,
      state: 'pending',
      uploadedBy: session.userId,
      createdAt: now,
      updatedAt: now,
    );
    value.validate();
    await db.transaction(() async {
      await _writeDocument(value);
      await db.customStatement(
        'INSERT INTO document_blobs(attachment_id,clinic_id,user_id,data,sha256_hex,transfer_state,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?)',
        [
          id,
          session.clinicId,
          session.userId,
          data,
          digest,
          'pending',
          now.toIso8601String(),
          now.toIso8601String(),
        ],
      );
    });
    _changed();
    return value;
  }

  Future<void> refreshDocuments(String patientId, {int offset = 0}) async {
    final remote = documentGateway;
    await _verifySession();
    if (session.clinicalRead) await refreshVisits(patientId);
    final values = await remote.documents(
      session.clinicId,
      patientId,
      offset: offset,
    );
    await db.transaction(() async {
      for (final value in values) {
        _checkClinic(value.clinicId);
        if (value.patientId != patientId) {
          throw const ClinicFailure(
            'protocol',
            'The document service returned a mismatched patient record.',
          );
        }
        value.validate();
        await _writeDocument(value);
      }
    });
    _emit();
  }

  Future<void> retryDocument(String id) async {
    final value = await document(id);
    if (value == null || value.uploadedBy != session.userId) {
      throw const ClinicFailure(
        'forbidden',
        'This document cannot be retried.',
      );
    }
    final changed = await db.customUpdate(
      "UPDATE document_blobs SET transfer_state='pending',error=NULL,updated_at=? WHERE attachment_id=? AND clinic_id=? AND user_id=? AND transfer_state='failed'",
      variables: [
        Variable(clock().toUtc().toIso8601String()),
        Variable(id),
        Variable(session.clinicId),
        Variable(session.userId),
      ],
    );
    if (changed != 1) {
      throw const ClinicFailure(
        'invalid_document_state',
        'This document is not waiting for a retry.',
      );
    }
    _changed();
  }

  Future<ClinicDocumentContent> documentContent(
    String id, {
    String purpose = 'preview',
  }) async {
    if (!{'preview', 'download', 'share'}.contains(purpose)) {
      throw const ClinicFailure('invalid_document', 'Invalid document action.');
    }
    final value = await document(id);
    if (value == null || value.isArchived) {
      throw const ClinicFailure('not_found', 'The document is not available.');
    }
    if (value.clinical && !session.clinicalRead) {
      throw const ClinicFailure(
        'forbidden',
        'Clinical document access has not been granted by the doctor.',
      );
    }
    final local = await db
        .customSelect(
          'SELECT data,sha256_hex,transfer_state FROM document_blobs WHERE attachment_id=? AND clinic_id=? AND user_id=?',
          variables: [
            Variable(id),
            Variable(session.clinicId),
            Variable(session.userId),
          ],
        )
        .get();
    Uint8List? bytes = local.isEmpty
        ? null
        : local.first.data['data'] as Uint8List;
    final localValid =
        bytes != null &&
        bytes.length == value.bytes &&
        sha256.convert(bytes).toString() == value.sha256Hex;
    if (!localValid && bytes != null) {
      await db.customStatement(
        'DELETE FROM document_blobs WHERE attachment_id=?',
        [id],
      );
      bytes = null;
      if (!value.isReady) {
        throw const ClinicFailure(
          'integrity',
          'The protected local document failed its integrity check.',
        );
      }
    }
    if (!value.isReady) {
      if (purpose == 'share') {
        throw const ClinicFailure(
          'upload_pending',
          'Wait for the document upload to be confirmed before sharing.',
        );
      }
      if (bytes == null || value.uploadedBy != session.userId) {
        throw const ClinicFailure(
          'upload_pending',
          'This document is still waiting to upload.',
        );
      }
      return ClinicDocumentContent(value, bytes);
    }
    await _verifySession();
    final remote = documentGateway;
    final lease = await remote.authorizeDocument(id, purpose);
    if (lease['attachment_id'] != id ||
        lease['object_path'] != value.objectPath ||
        (lease['bytes'] as num?)?.toInt() != value.bytes ||
        lease['sha256_hex'] != value.sha256Hex) {
      throw const ClinicFailure(
        'protocol',
        'The document access response failed validation.',
      );
    }
    bytes ??= await remote.downloadDocument(value.objectPath);
    if (bytes.length != value.bytes ||
        sha256.convert(bytes).toString() != value.sha256Hex) {
      throw const ClinicFailure(
        'integrity',
        'The downloaded document failed its integrity check and was not opened.',
      );
    }
    await _storeDocumentBlob(value, bytes, 'ready');
    return ClinicDocumentContent(value, bytes);
  }

  Future<ClinicDocument> setDocumentArchived(
    ClinicDocument value,
    bool archived,
  ) async {
    _checkClinic(value.clinicId);
    await _verifySession();
    final remote = await documentGateway.setDocumentArchived(
      value.id,
      archived,
    );
    _checkClinic(remote.clinicId);
    if (remote.id != value.id || remote.patientId != value.patientId) {
      throw const ClinicFailure(
        'protocol',
        'The document archive response failed validation.',
      );
    }
    await _writeDocument(remote);
    _emit();
    return remote;
  }

  Future<SyncSummary> syncSummary() async {
    final rows = await db
        .customSelect(
          'SELECT state,COUNT(*) AS n FROM outbox WHERE clinic_id=? GROUP BY state',
          variables: [Variable(session.clinicId)],
        )
        .get();
    final counts = {for (final r in rows) r.data['state']: r.data['n'] as int};
    final documentRows = await db
        .customSelect(
          'SELECT transfer_state,COUNT(*) AS n FROM document_blobs WHERE clinic_id=? AND user_id=? GROUP BY transfer_state',
          variables: [Variable(session.clinicId), Variable(session.userId)],
        )
        .get();
    final documents = {
      for (final r in documentRows)
        r.data['transfer_state']: r.data['n'] as int,
    };
    return SyncSummary(
      (counts['pending'] ?? 0) +
          (counts['sending'] ?? 0) +
          (documents['pending'] ?? 0) +
          (documents['uploading'] ?? 0),
      counts['conflict'] ?? 0,
      (counts['failed'] ?? 0) + (documents['failed'] ?? 0),
    );
  }

  Future<List<Map<String, dynamic>>> pendingOperations() async =>
      (await db
              .customSelect(
                'SELECT * FROM outbox WHERE clinic_id=? ORDER BY sequence',
                variables: [Variable(session.clinicId)],
              )
              .get())
          .map((e) => e.data)
          .toList();

  /// Discards a request the server definitively rejected.
  ///
  /// Only the `failed` state is eligible: it is reached solely after a
  /// non-transient server rejection, so the request was never applied. A
  /// `pending`/`sending` request may already have reached the server and is
  /// never discarded here. Without this, one rejected request blocks every
  /// later operation, document upload and shared action indefinitely.
  ///
  /// The local record still holds the version the server refused, so it is
  /// restored from the server before the queue resumes.
  Future<void> discardRejectedOperation(String operationId) async {
    if (_closed || _criticalInProgress || _resolutionInProgress) {
      throw const ClinicFailure(
        'busy',
        'Wait for the current action to finish.',
      );
    }
    await _verifySession();
    final rows = await pendingOperations();
    final row = rows.where((r) => r['operation_id'] == operationId).firstOrNull;
    if (row == null || row['state'] != 'failed') {
      throw const ClinicFailure(
        'review_changed',
        'This request is no longer waiting for review. Refresh synchronization.',
      );
    }
    final type = row['entity_type'] as String,
        id = row['entity_id'] as String,
        sequence = row['sequence'] as int;
    // Later queued work for the same record would be left expecting a version
    // this request was going to create, so it must be reviewed first.
    if (rows.any(
      (r) =>
          r['entity_type'] == type &&
          r['entity_id'] == id &&
          (r['sequence'] as int) > sequence,
    )) {
      throw const ClinicFailure(
        'review_changed',
        'A newer queued change for this record must be reviewed first.',
      );
    }
    await db.customStatement(
      "DELETE FROM outbox WHERE operation_id=? AND state='failed'",
      [operationId],
    );
    await _restoreRejectedEntity(type, id);
    _changed();
  }

  /// Replaces the locally cached record with the server's copy after a
  /// rejected request, so the next save sends the version the server holds.
  Future<void> _restoreRejectedEntity(String type, String id) async {
    final remote = gateway;
    if (remote == null) return;
    switch (type) {
      case 'patient':
        final values = await remote.patientsByIds(session.clinicId, [id]);
        if (values.isEmpty) {
          await _forgetRejectedPatient(id);
        } else {
          _checkClinic(values.single.clinicId);
          await _writePatient(values.single);
        }
      case 'appointment':
        final values = await remote.appointmentsByIds(session.clinicId, [id]);
        if (values.isNotEmpty) {
          _checkClinic(values.single.clinicId);
          await _writeAppointment(values.single);
        } else {
          await db.customStatement(
            'DELETE FROM cached_appointments WHERE clinic_id=? AND id=? AND NOT EXISTS'
            '(SELECT 1 FROM cached_visits WHERE appointment_id=?)',
            [session.clinicId, id, id],
          );
        }
      case 'visit':
        final rows = await db
            .customSelect(
              'SELECT patient_id FROM cached_visits WHERE clinic_id=? AND id=?',
              variables: [Variable(session.clinicId), Variable(id)],
            )
            .get();
        if (rows.isNotEmpty) {
          await refreshVisits(rows.first.data['patient_id'] as String);
        }
    }
  }

  /// Removes a patient the server never accepted, provided nothing local
  /// depends on it. Anything still referencing it is kept for review.
  Future<void> _forgetRejectedPatient(String id) async {
    final referenced = await db
        .customSelect(
          'SELECT 1 FROM cached_appointments WHERE patient_id=? '
          'UNION ALL SELECT 1 FROM cached_documents WHERE patient_id=? LIMIT 1',
          variables: [Variable(id), Variable(id)],
        )
        .get();
    if (referenced.isEmpty) {
      await db.customStatement(
        'DELETE FROM cached_patients WHERE clinic_id=? AND id=?',
        [session.clinicId, id],
      );
    }
  }

  Future<void> _verifySession() async {
    if (_closed || gateway == null) {
      throw const ClinicFailure(
        'offline',
        'Connect to the clinic before reviewing server changes.',
      );
    }
    try {
      await gateway!.verifySession(session);
    } on ClinicFailure catch (e) {
      if (e.code == 'access_changed') onAccessRevoked?.call();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _patientConflictRows(String id) async {
    final operations = await pendingOperations();
    final first = operations.where((r) => r['operation_id'] == id).firstOrNull;
    if (first == null ||
        first['entity_type'] != 'patient' ||
        first['action'] != 'save' ||
        first['state'] != 'conflict') {
      throw const ClinicFailure(
        'review_changed',
        'This patient conflict is no longer available. Refresh synchronization.',
      );
    }
    final rows = operations
        .where(
          (r) =>
              r['entity_type'] == 'patient' &&
              r['entity_id'] == first['entity_id'],
        )
        .toList();
    if (rows.first['operation_id'] != id ||
        rows
            .skip(1)
            .any(
              (r) =>
                  r['action'] != 'save' ||
                  r['state'] != 'pending' ||
                  r['attempts'] != 0,
            )) {
      throw const ClinicFailure(
        'confirmation_pending',
        'A request may already have reached the server. Retry its exact request before resolving.',
      );
    }
    return rows;
  }

  Future<Patient> _remotePatient(String id) async {
    final values = await gateway!.patientsByIds(session.clinicId, [id]);
    if (values.length != 1 ||
        values.single.id != id ||
        values.single.version < 1) {
      throw const ClinicFailure(
        'review_unavailable',
        'The server patient is unavailable. Local changes are retained.',
      );
    }
    _checkClinic(values.single.clinicId);
    return values.single;
  }

  Future<PatientSyncReview> reviewPatientConflict(String operationId) async {
    await _verifySession();
    final rows = await _patientConflictRows(operationId);
    final local = await patient(rows.first['entity_id'] as String);
    if (local == null) {
      throw const ClinicFailure(
        'review_unavailable',
        'The local patient is unavailable. Queued changes are retained.',
      );
    }
    final remote = await _remotePatient(local.id);
    return PatientSyncReview(
      operationId: operationId,
      local: local,
      remote: remote,
      operationsSnapshot: jsonEncode(rows),
      operationCount: rows.length,
    );
  }

  /// Empty localFields accepts the server record; otherwise submit a reviewed
  /// merge as a NEW request. Never edit a request that was already sent.
  Future<void> resolvePatientConflict(
    PatientSyncReview review, {
    required Set<String> localFields,
  }) async {
    if (_resolutionInProgress || _criticalInProgress) {
      throw const ClinicFailure(
        'busy',
        'Wait for the current action to finish.',
      );
    }
    _checkClinic(review.local.clinicId);
    _checkClinic(review.remote.clinicId);
    if (localFields.any((f) => !patientMergeFields.containsKey(f)) ||
        (!session.isDoctor && localFields.contains('alerts'))) {
      throw const ClinicFailure(
        'forbidden',
        'Only permitted patient fields can be merged. Medical alerts require a doctor.',
      );
    }
    _resolutionInProgress = true;
    _retry?.cancel();
    try {
      await _sync;
      await _verifySession();
      final remote = await _remotePatient(review.remote.id);
      if (jsonEncode(remote.toMap()) != jsonEncode(review.remote.toMap())) {
        throw const ClinicFailure(
          'review_changed',
          'The server patient changed during review. Reload and compare the latest versions.',
        );
      }
      if (_closed) {
        throw const ClinicFailure('access_changed', 'Clinic access is closed.');
      }
      await db.transaction(() async {
        final rows = await _patientConflictRows(review.operationId);
        final local = await patient(rows.first['entity_id'] as String);
        if (local == null ||
            local.id != remote.id ||
            jsonEncode(rows) != review.operationsSnapshot ||
            jsonEncode(local.toMap()) != jsonEncode(review.local.toMap())) {
          throw const ClinicFailure(
            'review_changed',
            'Local changes were added during review. Reload before resolving; all changes are retained.',
          );
        }
        final values = remote.toMap(), localValues = local.toMap();
        for (final field in localFields) {
          values[field] = localValues[field];
        }
        var resolved = Patient.fromMap(values);
        String? replacement;
        if (localFields.isNotEmpty) {
          resolved.validate(clock());
          if (resolved.archived && !remote.archived) {
            final active = await db
                .customSelect(
                  "SELECT 1 FROM cached_appointments WHERE clinic_id=? AND patient_id=? AND status IN ('waiting','withDoctor') LIMIT 1",
                  variables: [Variable(session.clinicId), Variable(local.id)],
                )
                .get();
            if (active.isNotEmpty) {
              throw const ClinicFailure(
                'active_patient',
                'Finish or remove the active queue entry before archiving this patient.',
              );
            }
          }
          resolved = resolved.copyWith(
            version: remote.version + 1,
            updatedAt: clock(),
          );
        }
        // All superseded requests and both versions are retained atomically.
        for (final row in rows) {
          await db.customStatement('DELETE FROM outbox WHERE operation_id=?', [
            row['operation_id'],
          ]);
        }
        if (localFields.isNotEmpty) {
          replacement = await _enqueue(
            'patient',
            local.id,
            'save',
            resolved.toMap(),
            remote.version,
          );
          // Preserve dependency order: appointments must not overtake this save.
          await db.customStatement(
            'UPDATE outbox SET sequence=? WHERE operation_id=?',
            [rows.first['sequence'], replacement],
          );
        }
        await _writePatient(resolved);
        await db.customStatement(
          'INSERT INTO sync_resolutions(id,clinic_id,user_id,entity_id,resolved_at,choice,original_operations,local_value,remote_value,resolved_value,replacement_operation_id) VALUES(?,?,?,?,?,?,?,?,?,?,?)',
          [
            _uuid.v4(),
            session.clinicId,
            session.userId,
            local.id,
            clock().toUtc().toIso8601String(),
            localFields.isEmpty ? 'server' : 'merge',
            jsonEncode(rows),
            jsonEncode(local.toMap()),
            jsonEncode(remote.toMap()),
            jsonEncode(resolved.toMap()),
            replacement,
          ],
        );
      });
    } finally {
      _resolutionInProgress = false;
      if (!_closed) _changed();
    }
  }

  Future<List<PatientSyncResolution>> patientRecoveryHistory({
    int offset = 0,
  }) async {
    final rows = await db
        .customSelect(
          'SELECT * FROM sync_resolutions WHERE clinic_id=? AND user_id=? ORDER BY resolved_at DESC,id LIMIT 50 OFFSET ?',
          variables: [
            Variable(session.clinicId),
            Variable(session.userId),
            Variable(offset < 0 ? 0 : offset),
          ],
        )
        .get();
    return rows.map((row) {
      final r = row.data;
      Patient decode(String key) =>
          Patient.fromMap(jsonDecode(r[key] as String) as Map<String, dynamic>);
      return PatientSyncResolution(
        id: r['id'] as String,
        resolvedAt: DateTime.parse(r['resolved_at'] as String),
        choice: r['choice'] as String,
        local: decode('local_value'),
        remote: decode('remote_value'),
        resolved: decode('resolved_value'),
        operationCount:
            (jsonDecode(r['original_operations'] as String) as List).length,
      );
    }).toList();
  }

  Future<Patient> savePatient(Patient value) async {
    if (_closed || _resolutionInProgress) {
      throw const ClinicFailure(
        'busy',
        'Wait for conflict review to finish. Your form is retained.',
      );
    }
    _checkClinic(value.clinicId);
    value.validate(clock());
    final previous = await patient(value.id);
    if (!session.isDoctor && value.alerts != (previous?.alerts ?? '')) {
      throw const ClinicFailure(
        'forbidden',
        'Only a doctor may change medical alerts.',
      );
    }
    if (previous != null && previous.version != value.version) {
      throw const ClinicFailure(
        'conflict',
        'This patient changed while the form was open. Reopen it to review.',
      );
    }
    final next = value.copyWith(updatedAt: clock(), version: value.version + 1);
    await db.transaction(() async {
      await _writePatient(next);
      await _enqueue('patient', value.id, 'save', next.toMap(), value.version);
    });
    _changed();
    return next;
  }

  Future<void> archivePatient(Patient value, bool archive) async {
    _checkClinic(value.clinicId);
    final rows = await db
        .customSelect(
          "SELECT id FROM cached_appointments WHERE patient_id=? AND clinic_id=? AND status IN ('waiting','withDoctor') LIMIT 1",
          variables: [Variable(value.id), Variable(session.clinicId)],
        )
        .get();
    if (archive && rows.isNotEmpty) {
      throw const ClinicFailure(
        'active_patient',
        'Remove the patient from the queue or finish the consultation before archiving.',
      );
    }
    await savePatient(value.copyWith(archived: archive));
  }

  ScheduleSettings _scheduleSettings = const ScheduleSettings();
  final List<Map<String, dynamic>> _demoWaitlist = [];
  Future<Map<String, dynamic>> scheduleAction(
    String action, [
    Map<String, dynamic> payload = const {},
  ]) async {
    if (session.isDemo) {
      if (action == 'settings') {
        if ((payload['periods'] as List? ?? const []).isEmpty) {
          throw const ClinicFailure(
            'EMPTY_SCHEDULE',
            'Add at least one working period, or clear the working hours so any time can be booked.',
          );
        }
        _scheduleSettings = ScheduleSettings.fromMap({
          ...payload,
          'configured': true,
        });
      }
      if (action == 'settings_clear') {
        _scheduleSettings = const ScheduleSettings();
      }
      if (action == 'waitlist_add') {
        _demoWaitlist.removeWhere(
          (v) => v['patient_id'] == payload['patient_id'],
        );
        _demoWaitlist.add({...payload, 'id': payload['patient_id']});
      }
      if (action == 'waitlist_remove') {
        _demoWaitlist.removeWhere((v) => v['id'] == payload['id']);
      }
      return {'settings': _scheduleSettings.toMap(), 'waitlist': _demoWaitlist};
    }
    final remote = gateway;
    if (remote is! ClinicSchedulingGateway) {
      throw const ClinicFailure(
        'offline',
        'Connect to load shared scheduling settings.',
      );
    }
    await remote!.verifySession(session);
    return (remote as ClinicSchedulingGateway).schedule(
      session.clinicId,
      session.doctorId,
      action,
      payload,
    );
  }

  Future<ScheduleSettings> schedulingSettings() async {
    final data = await scheduleAction('read');
    return ScheduleSettings.fromMap(
      Map<String, dynamic>.from(data['settings'] as Map),
    );
  }

  Future<void> saveAppointment(Appointment value) async {
    _checkClinic(value.clinicId);
    await _requireNoPendingCritical('appointment', value.id);
    final p = await patient(value.patientId);
    if (p == null || p.archived) {
      throw const ClinicFailure(
        'validation',
        'Choose an active patient in this clinic.',
      );
    }
    final previous = await appointment(value.id);
    if (previous != null &&
        (previous.status.terminal ||
            previous.status == AppointmentStatus.withDoctor ||
            previous.status == AppointmentStatus.waiting ||
            previous.version != value.version)) {
      throw const ClinicFailure(
        'conflict',
        'This appointment cannot be rescheduled in its current state.',
      );
    }
    if (value.status != (previous?.status ?? AppointmentStatus.scheduled)) {
      throw const ClinicFailure(
        'invalid_transition',
        'Use the appointment status actions.',
      );
    }
    if (value.durationMinutes < 5 || value.durationMinutes > 240) {
      throw const ClinicFailure(
        'validation',
        'Choose a duration between 5 and 240 minutes.',
      );
    }
    final next = value.copyWith(version: value.version + 1);
    await db.transaction(() async {
      if (appointmentOverlaps(
        value,
        await appointments(day: ClinicTime.local(value.startsAt)),
      )) {
        throw const ClinicFailure(
          'conflict',
          'This time overlaps another appointment. Choose an available slot.',
        );
      }
      await _writeAppointment(next);
      await _enqueue(
        'appointment',
        value.id,
        'save',
        next.toMap(),
        value.version,
      );
    });
    _changed();
  }

  Future<void> changeStatus(Appointment value, AppointmentStatus next) async {
    _checkClinic(value.clinicId);
    requireTransition(value.status, next);
    // Entering the doctor and completing stay on their dedicated paths.
    // Leaving the doctor for the queue or a cancellation is an ordinary
    // status change, so a stranded patient can always be released.
    if (next == AppointmentStatus.completed ||
        next == AppointmentStatus.withDoctor) {
      throw const ClinicFailure(
        'protected_transition',
        'Use the consultation handoff or completion action.',
      );
    }
    // Queue state is shared; do not claim changes without a server receipt.
    await _onlineCommand('appointment', value.id, 'status', {
      'status': next.name,
    }, value.version);
  }

  Future<void> sendToDoctor(Appointment value) async {
    _checkClinic(value.clinicId);
    if (value.status != AppointmentStatus.waiting) {
      throw const ClinicFailure(
        'not_waiting',
        'Only a waiting appointment can be sent to the doctor.',
      );
    }
    await _onlineCommand('appointment', value.id, 'send', {}, value.version);
  }

  Future<Visit> saveVisit(Visit value) async {
    _checkClinic(value.clinicId);
    _requireDoctor();
    await _requireNoPendingCritical('visit', value.id);
    if (value.doctorId != session.userId || value.completed) {
      throw const ClinicFailure(
        'immutable_record',
        'Completed visits require an amendment, never an overwrite.',
      );
    }
    final a = await appointment(value.appointmentId);
    if (a == null ||
        a.patientId != value.patientId ||
        a.doctorId != session.userId ||
        a.status != AppointmentStatus.withDoctor) {
      throw const ClinicFailure(
        'assignment_changed',
        'This patient is no longer assigned to you. Your form remains available.',
      );
    }
    final existing = (await visits(
      value.patientId,
    )).where((v) => v.id == value.id).firstOrNull;
    if (existing != null &&
        (existing.completed || existing.version != value.version)) {
      throw const ClinicFailure(
        'conflict',
        'This visit changed while it was open. Keep your draft and review the saved record.',
      );
    }
    final next = value.copyWith(version: value.version + 1, updatedAt: clock());
    await db.transaction(() async {
      await _writeVisit(next);
      await _enqueue('visit', value.id, 'save', next.toMap(), value.version);
    });
    _changed();
    return next;
  }

  Future<void> completeVisit(Visit value) async {
    _requireDoctor();
    _checkClinic(value.clinicId);
    value.validateForCompletion();
    await _onlineCommand('visit', value.id, 'complete', {}, value.version);
  }

  Future<Visit> amendVisit(Visit value, String reason) async {
    _requireDoctor();
    _checkClinic(value.clinicId);
    value.validateAmendment(reason);
    await _requireNoPendingCritical('visit', value.id);
    final saved = (await visits(
      value.patientId,
    )).where((item) => item.id == value.id).firstOrNull;
    if (saved == null || !saved.completed || saved.version != value.version) {
      throw const ClinicFailure(
        'conflict',
        'This completed visit changed while it was open. Refresh it before amending.',
      );
    }
    await _onlineCommand('visit', value.id, 'amend', {
      ...value.toMap(),
      'amendment_reason': reason.trim(),
    }, value.version);
    final updated = (await visits(
      value.patientId,
    )).where((item) => item.id == value.id).firstOrNull;
    if (updated == null || updated.version <= value.version) {
      throw const ClinicFailure(
        'protocol',
        'The amendment was confirmed but the updated visit is not available yet.',
      );
    }
    return updated;
  }

  Future<void> _onlineCommand(
    String type,
    String id,
    String action,
    Map<String, dynamic> payload,
    int expected,
  ) async {
    if (gateway == null) {
      throw const ClinicFailure(
        'offline',
        'Connection required. No shared queue or completion state was changed.',
      );
    }
    if (_criticalInProgress) {
      throw const ClinicFailure(
        'busy',
        'Wait for the current action to be confirmed.',
      );
    }
    _criticalInProgress = true;
    try {
      await synchronize();
      if (!(await syncSummary()).clean) {
        throw const ClinicFailure(
          'sync_pending',
          'Sync pending changes and resolve conflicts before this action.',
        );
      }
      // Persist the exact request before network I/O. Retries reuse this ID.
      // Unaccepted critical intent expires; acknowledged intent can still replay.
      final operationId = await _enqueue(type, id, action, {
        ...payload,
        '_expires_at': clock()
            .toUtc()
            .add(const Duration(minutes: 1))
            .toIso8601String(),
      }, expected);
      _emit();
      await synchronize();
      final remaining = (await pendingOperations())
          .where((r) => r['operation_id'] == operationId)
          .firstOrNull;
      if (remaining != null) {
        throw ClinicFailure(
          'confirmation_pending',
          remaining['state'] == 'pending' || remaining['state'] == 'sending'
              ? 'Server confirmation is pending. The request is retained and will retry; do not repeat the handoff manually.'
              : remaining['error'] as String? ??
                    'This action needs review in synchronization.',
        );
      }
      // Failure to refresh after an acknowledged commit is not a failed action.
      try {
        await refresh();
      } catch (_) {
        connectionWarning =
            'Action confirmed. Refresh is pending; saved records are retained.';
        _emit();
      }
    } finally {
      _criticalInProgress = false;
    }
  }

  Future<void> _requireNoPendingCritical(String type, String id) async {
    final rows = await db
        .customSelect(
          "SELECT 1 FROM outbox WHERE entity_type=? AND entity_id=? AND action<>'save' LIMIT 1",
          variables: [Variable(type), Variable(id)],
        )
        .get();
    if (rows.isNotEmpty) {
      throw const ClinicFailure(
        'confirmation_pending',
        'A shared action for this record is awaiting confirmation. Your form is retained.',
      );
    }
  }

  void _changed() {
    _emit();
    if (gateway != null) unawaited(synchronize());
  }

  Future<String> _enqueue(
    String type,
    String id,
    String action,
    Map<String, Object?> payload,
    int expected,
  ) async {
    final operationId = _uuid.v4();
    await db.customStatement(
      'INSERT INTO outbox(operation_id,clinic_id,entity_type,entity_id,action,payload,expected_version,created_at) VALUES(?,?,?,?,?,?,?,?)',
      [
        operationId,
        session.clinicId,
        type,
        id,
        action,
        jsonEncode(payload),
        expected,
        clock().toUtc().toIso8601String(),
      ],
    );
    return operationId;
  }

  Future<void> synchronize() {
    if (_resolutionInProgress) return Future.value();
    if (_sync != null) return _sync!;
    final task = _flush();
    _sync = task;
    return task.whenComplete(() {
      _sync = null;
    });
  }

  Future<void> _flush() async {
    if (gateway == null || _closed) return;
    final rows = await pendingOperations();
    for (final row in rows) {
      if (row['state'] != 'pending') continue;
      // A conflict blocks following operations, including dependent records.
      final blockers = await db
          .customSelect(
            "SELECT sequence FROM outbox WHERE sequence<? AND state IN ('conflict','failed') LIMIT 1",
            variables: [Variable(row['sequence'] as int)],
          )
          .get();
      if (blockers.isNotEmpty) break;
      final id = row['operation_id'] as String;
      await db.customStatement(
        "UPDATE outbox SET state='sending', attempts=attempts+1 WHERE operation_id=?",
        [id],
      );
      try {
        final receipt = await gateway!.apply(
          PendingCommand(
            operationId: id,
            clinicId: session.clinicId,
            entityType: row['entity_type'] as String,
            entityId: row['entity_id'] as String,
            action: row['action'] as String,
            payload:
                jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            expectedVersion: row['expected_version'] as int,
          ),
        );
        await db.transaction(() async {
          await db.customStatement('DELETE FROM outbox WHERE operation_id=?', [
            id,
          ]);
          final newer = await db
              .customSelect(
                'SELECT operation_id FROM outbox WHERE entity_type=? AND entity_id=? LIMIT 1',
                variables: [
                  Variable(row['entity_type'] as String),
                  Variable(row['entity_id'] as String),
                ],
              )
              .get();
          if (newer.isEmpty) {
            await _writeReceipt(row['entity_type'] as String, receipt);
          }
        });
        _failures = 0;
      } on SyncConflict catch (e) {
        await db.customStatement(
          "UPDATE outbox SET state='conflict',error=?,remote_value=? WHERE operation_id=?",
          [e.message, jsonEncode(e.remote), id],
        );
        break;
      } on ClinicFailure catch (e) {
        final transient = e.code == 'offline' || e.code == 'unavailable';
        await db.customStatement(
          'UPDATE outbox SET state=?,error=? WHERE operation_id=?',
          [transient ? 'pending' : 'failed', e.message, id],
        );
        if (transient) _scheduleRetry();
        break;
      } catch (_) {
        await db.customStatement(
          "UPDATE outbox SET state='pending',error=? WHERE operation_id=?",
          ['Connection interrupted. Your local changes are retained.', id],
        );
        _scheduleRetry();
        break;
      }
    }
    final documentBlockers = await db
        .customSelect(
          "SELECT 1 FROM outbox WHERE clinic_id=? AND state IN ('pending','sending','conflict','failed') LIMIT 1",
          variables: [Variable(session.clinicId)],
        )
        .get();
    if (documentBlockers.isEmpty) await _flushDocuments();
    _emit();
    final remaining = await syncSummary();
    if (!_closed &&
        _failures == 0 &&
        remaining.pending > 0 &&
        remaining.conflicts == 0 &&
        remaining.failed == 0) {
      _retry?.cancel();
      _retry = Timer(const Duration(milliseconds: 50), () {
        unawaited(synchronize());
      });
    }
  }

  Future<void> _flushDocuments() async {
    if (gateway is! ClinicDocumentGateway || _closed) return;
    try {
      await _verifySession();
    } on ClinicFailure catch (error) {
      if (error.code == 'offline' || error.code == 'unavailable') {
        _scheduleRetry();
      }
      return;
    }
    final rows = await db
        .customSelect(
          "SELECT d.*,b.data,b.transfer_state,b.attempts FROM cached_documents d JOIN document_blobs b ON b.attachment_id=d.id WHERE b.clinic_id=? AND b.user_id=? AND b.transfer_state='pending' ORDER BY b.created_at,b.attachment_id",
          variables: [Variable(session.clinicId), Variable(session.userId)],
        )
        .get();
    final remote = documentGateway;
    for (final row in rows) {
      if (_closed) return;
      final value = ClinicDocument.fromMap(row.data);
      final bytes = row.data['data'] as Uint8List;
      if (bytes.length != value.bytes ||
          sha256.convert(bytes).toString() != value.sha256Hex) {
        await db.customStatement(
          "UPDATE document_blobs SET transfer_state='failed',error=?,updated_at=? WHERE attachment_id=?",
          [
            'The protected local document failed its integrity check.',
            clock().toUtc().toIso8601String(),
            value.id,
          ],
        );
        continue;
      }
      await db.customStatement(
        "UPDATE document_blobs SET transfer_state='uploading',attempts=attempts+1,error=NULL,updated_at=? WHERE attachment_id=?",
        [clock().toUtc().toIso8601String(), value.id],
      );
      try {
        final begun = await remote.beginDocument(value);
        _validateRemoteDocument(value, begun, allowPending: true);
        ClinicDocument ready;
        try {
          ready = await remote.finalizeDocument(value.id);
        } on ClinicFailure catch (error) {
          if (error.code != 'object_missing') rethrow;
          try {
            await remote.uploadDocument(
              value.objectPath,
              bytes,
              value.contentType,
            );
          } on ClinicFailure catch (uploadError) {
            if (uploadError.code != 'already_exists') rethrow;
          }
          ready = await remote.finalizeDocument(value.id);
        }
        _validateRemoteDocument(value, ready);
        await db.transaction(() async {
          await _writeDocument(ready);
          await db.customStatement(
            "UPDATE document_blobs SET transfer_state='ready',error=NULL,updated_at=? WHERE attachment_id=?",
            [clock().toUtc().toIso8601String(), value.id],
          );
        });
        _failures = 0;
      } on ClinicFailure catch (error) {
        final transient = {
          'offline',
          'unavailable',
          'object_missing',
        }.contains(error.code);
        await db.customStatement(
          'UPDATE document_blobs SET transfer_state=?,error=?,updated_at=? WHERE attachment_id=?',
          [
            transient ? 'pending' : 'failed',
            error.message,
            clock().toUtc().toIso8601String(),
            value.id,
          ],
        );
        if (transient) _scheduleRetry();
        break;
      } catch (_) {
        await db.customStatement(
          "UPDATE document_blobs SET transfer_state='pending',error=?,updated_at=? WHERE attachment_id=?",
          [
            'Connection interrupted. The local document is retained.',
            clock().toUtc().toIso8601String(),
            value.id,
          ],
        );
        _scheduleRetry();
        break;
      }
    }
  }

  void _validateRemoteDocument(
    ClinicDocument local,
    ClinicDocument remote, {
    bool allowPending = false,
  }) {
    if (remote.id != local.id ||
        remote.clinicId != local.clinicId ||
        remote.patientId != local.patientId ||
        remote.visitId != local.visitId ||
        remote.objectPath != local.objectPath ||
        remote.fileName != local.fileName ||
        remote.contentType != local.contentType ||
        remote.category != local.category ||
        remote.notes != local.notes ||
        remote.bytes != local.bytes ||
        remote.sha256Hex != local.sha256Hex ||
        remote.clinical != local.clinical ||
        remote.uploadedBy != local.uploadedBy ||
        (!allowPending && !remote.isReady) ||
        (allowPending &&
            !{'pending', 'ready', 'failed'}.contains(remote.state))) {
      throw const ClinicFailure(
        'protocol',
        'The document service returned mismatched metadata. The local file is retained.',
      );
    }
  }

  void _scheduleRetry() {
    if (_closed || gateway == null) return;
    _retry?.cancel();
    _failures = (_failures + 1).clamp(1, 6);
    _retry = Timer(Duration(seconds: 1 << _failures), () {
      unawaited(synchronize());
    });
  }

  /// Server page size for patient reads, and the cap on how many pages one
  /// reconciliation walks so a large clinic cannot stall the app.
  static const patientPageSize = 50;
  static const maxReconcilePages = 40;
  static const reconcileInterval = Duration(minutes: 5);
  DateTime? _lastReconcile;

  Future<void> _cachePatients(List<Patient> values) async {
    await db.transaction(() async {
      for (final p in values) {
        _checkClinic(p.clinicId);
        if (await _dirty('patient', p.id)) continue;
        final existing = await patient(p.id);
        if (existing == null || existing.version < p.version) {
          await _writePatient(p);
        }
      }
    });
  }

  /// Pages through active *and* archived patients.
  ///
  /// Reading only the first active page left records beyond it permanently
  /// stale, and an archive performed on another device was never observed at
  /// all, because the archived record no longer appears in the active page.
  /// The server exposes no patient delete, so re-reading both states is
  /// sufficient and no tombstone protocol is needed here.
  Future<void> reconcilePatients() async {
    if (gateway == null || _closed) return;
    for (final archived in const [false, true]) {
      for (var page = 0; page < maxReconcilePages; page++) {
        if (_closed) return;
        final remote = await gateway!.patients(
          clinicId: session.clinicId,
          offset: page * patientPageSize,
          archived: archived,
        );
        if (remote.isEmpty) break;
        await _cachePatients(remote);
        if (remote.length < patientPageSize) break;
      }
    }
    _lastReconcile = clock().toUtc();
  }

  Future<void> refresh({
    String search = '',
    int offset = 0,
    bool archived = false,
    bool full = false,
  }) async {
    if (gateway == null) return;
    await _verifySession();
    final last = _lastReconcile;
    final due =
        full ||
        last == null ||
        clock().toUtc().difference(last) >= reconcileInterval;
    if (due && search.isEmpty && offset == 0 && !archived) {
      await reconcilePatients();
    } else {
      await _cachePatients(
        await gateway!.patients(
          clinicId: session.clinicId,
          search: search,
          offset: offset,
          archived: archived,
        ),
      );
    }
    await refreshAppointments();
    for (final id in _watchedHistory.keys.toList()) {
      await refreshVisits(id);
    }
    connectionWarning = null;
    _emit();
  }

  Future<void> refreshAppointments({DateTime? day}) async {
    if (gateway == null) return;
    final today = day ?? ClinicTime.local(clock());
    final bounds = ClinicTime.dayBounds(today);
    final appointments = await gateway!.appointments(
      session.clinicId,
      bounds.from,
      bounds.to,
    );
    final active = await gateway!.activeAppointment(
      session.clinicId,
      session.doctorId,
    );
    final previous = await activeAppointment();
    // Also re-read the old active row so completion outside this date clears it.
    final former = previous == null || previous.id == active?.id
        ? <Appointment>[]
        : await gateway!.appointmentsByIds(session.clinicId, [previous.id]);
    await _cacheAppointments([...appointments, ?active, ...former]);
    if (session.clinicalRead && active != null) {
      await refreshVisits(active.patientId);
    }
    _emit();
  }

  Future<void> _cacheAppointments(List<Appointment> values) async {
    final missing = <String>{};
    for (final a in values) {
      _checkClinic(a.clinicId);
      if (await patient(a.patientId) == null) missing.add(a.patientId);
    }
    final people = missing.isEmpty
        ? <Patient>[]
        : await gateway!.patientsByIds(session.clinicId, missing.toList());
    await db.transaction(() async {
      for (final p in people) {
        _checkClinic(p.clinicId);
        if (!await _dirty('patient', p.id)) await _writePatient(p);
      }
      for (final a in values) {
        if (await patient(a.patientId) == null) {
          throw const ClinicFailure(
            'incomplete_sync',
            'An appointment’s patient is not available. Retry synchronization.',
          );
        }
        final old = await appointment(a.id);
        if (!await _dirty('appointment', a.id) &&
            (old == null || old.version <= a.version)) {
          await _writeAppointment(a);
        }
      }
    });
  }

  Future<void> refreshVisits(String id, {int offset = 0}) async {
    if (!session.clinicalRead || gateway == null) return;
    final data = await gateway!.visits(session.clinicId, id, offset: offset);
    final appointments = await gateway!.appointmentsByIds(
      session.clinicId,
      data.map((v) => v.appointmentId).toSet().toList(),
    );
    await _cacheAppointments(appointments);
    await db.transaction(() async {
      for (final visit in data) {
        _checkClinic(visit.clinicId);
        if (visit.patientId != id ||
            await appointment(visit.appointmentId) == null) {
          throw const ClinicFailure(
            'incomplete_sync',
            'A historical visit’s appointment is not available. Retry synchronization.',
          );
        }
        if (!await _dirty('visit', visit.id)) await _writeVisit(visit);
      }
    });
    _emit();
  }

  Future<bool> _dirty(String type, String id) async =>
      (await db
              .customSelect(
                'SELECT 1 FROM outbox WHERE entity_type=? AND entity_id=? LIMIT 1',
                variables: [Variable(type), Variable(id)],
              )
              .get())
          .isNotEmpty;

  Future<void> _writeReceipt(String type, CommandReceipt receipt) async {
    _checkClinic(receipt.entity['clinic_id'] as String);
    if (receipt.appointment != null) {
      final related = Appointment.fromMap(receipt.appointment!);
      _checkClinic(related.clinicId);
      await _writeAppointment(related);
    }
    switch (type) {
      case 'patient':
        await _writePatient(Patient.fromMap(receipt.entity));
      case 'appointment':
        await _writeAppointment(Appointment.fromMap(receipt.entity));
      case 'visit':
        await _writeVisit(Visit.fromMap(receipt.entity));
      default:
        throw const ClinicFailure(
          'protocol',
          'Unrecognized sync response; local work is retained.',
        );
    }
  }

  Future<void> _writeDocument(ClinicDocument value) async {
    _checkClinic(value.clinicId);
    final row = value.toMap();
    row['clinical'] = value.clinical ? 1 : 0;
    await _upsert('cached_documents', row);
  }

  Future<void> _storeDocumentBlob(
    ClinicDocument value,
    Uint8List bytes,
    String state,
  ) async {
    final now = clock().toUtc().toIso8601String();
    await db.customStatement(
      'INSERT INTO document_blobs(attachment_id,clinic_id,user_id,data,sha256_hex,transfer_state,error,attempts,created_at,updated_at) VALUES(?,?,?,?,?,?,NULL,0,?,?) '
      'ON CONFLICT(attachment_id) DO UPDATE SET clinic_id=excluded.clinic_id,user_id=excluded.user_id,data=excluded.data,sha256_hex=excluded.sha256_hex,transfer_state=excluded.transfer_state,error=NULL,updated_at=excluded.updated_at',
      [
        value.id,
        session.clinicId,
        session.userId,
        bytes,
        value.sha256Hex,
        state,
        now,
        now,
      ],
    );
  }

  Future<void> _writePatient(Patient value) async {
    final row = value.toMap();
    row['archived'] = value.archived ? 1 : 0;
    row['mobile_digits'] = normalizePhone(value.mobile);
    await _upsert('cached_patients', row);
  }

  Future<void> _writeAppointment(Appointment value) =>
      _upsert('cached_appointments', value.toMap());
  Future<void> _writeVisit(Visit value) async {
    final row = value.toMap()
      ..remove('diagnoses')
      ..remove('medications');
    row['completed'] = value.completed ? 1 : 0;
    await _upsert('cached_visits', row);
    await db.customStatement('DELETE FROM cached_diagnoses WHERE visit_id=?', [
      value.id,
    ]);
    await db.customStatement(
      'DELETE FROM cached_medications WHERE visit_id=?',
      [value.id],
    );
    for (var i = 0; i < value.diagnoses.length; i++) {
      await db.customStatement('INSERT INTO cached_diagnoses VALUES(?,?,?)', [
        value.id,
        i,
        value.diagnoses[i],
      ]);
    }
    for (var i = 0; i < value.medications.length; i++) {
      await _upsert('cached_medications', {
        ...value.medications[i].toMap(),
        'visit_id': value.id,
        'position': i,
      });
    }
  }

  Future<void> _upsert(
    String table,
    Map<String, Object?> row,
  ) => db.customStatement(
    'INSERT INTO $table (${row.keys.join(',')}) VALUES (${List.filled(row.length, '?').join(',')}) '
    'ON CONFLICT(id) DO UPDATE SET ${row.keys.where((k) => k != 'id').map((k) => '$k=excluded.$k').join(',')}',
    row.values.toList(),
  );

  /// Seeds only a clearly marked in-memory fictional workspace used in tests/previews.
  Future<void> seedDemo(
    List<Patient> patients,
    List<Appointment> appointments,
    List<Visit> visits,
  ) async {
    if (!session.isDemo) {
      throw StateError('Demo seeding is forbidden for real clinic sessions.');
    }
    await db.transaction(() async {
      for (final p in patients) {
        _checkClinic(p.clinicId);
        await _writePatient(p);
      }
      for (final a in appointments) {
        _checkClinic(a.clinicId);
        await _writeAppointment(a);
      }
      for (final v in visits) {
        _checkClinic(v.clinicId);
        await _writeVisit(v);
      }
    });
    _emit();
  }

  Future<void> close() async {
    _closed = true;
    _retry?.cancel();
    await _remoteSubscription?.cancel();
    await _sync;
    await _changes.close();
    await db.close();
  }
}
