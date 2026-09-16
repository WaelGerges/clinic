import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models.dart';
import 'gateway.dart';

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this.projectRef);
  final String projectRef;
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  String get _key => 'clinic_auth_$projectRef';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);
  @override
  Future<String?> accessToken() => _storage.read(key: _key);
  @override
  Future<void> persistSession(String value) =>
      _storage.write(key: _key, value: value);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}

class SupabaseClinicGateway
    implements
        ClinicGateway,
        ClinicAdministration,
        ClinicAuditGateway,
        ClinicDeliveryGateway,
        ClinicDocumentGateway,
        ClinicSchedulingGateway,
        ClinicVisitExportGateway {
  SupabaseClinicGateway(this.client, {this.onSessionVerified});
  final SupabaseClient client;
  final Future<void> Function(ClinicSession session)? onSessionVerified;
  @override
  Future<Visit> printableVisit(
    String clinicId,
    String patientId,
    String visitId,
  ) async {
    final row = await client
        .from('visit_details')
        .select()
        .eq('clinic_id', clinicId)
        .eq('patient_id', patientId)
        .eq('id', visitId)
        .single();
    return Visit.fromMap(row);
  }

  @override
  Future<Map<String, dynamic>> schedule(
    String clinicId,
    String doctorId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    try {
      final value = await client.rpc(
        'clinic_schedule',
        params: {
          'p_clinic_id': clinicId,
          'p_doctor_id': doctorId,
          'p_action': action,
          'p_payload': payload,
        },
      );
      return Map<String, dynamic>.from(value as Map);
    } on PostgrestException catch (e) {
      throw ClinicFailure(e.message, schedulingError(e.message));
    }
  }

  @override
  Future<void> verifySession(ClinicSession session) async {
    final row = await client
        .from('clinic_memberships')
        .select('active,role,is_admin,clinical_read')
        .eq('clinic_id', session.clinicId)
        .eq('user_id', session.userId)
        .maybeSingle();
    if (row == null ||
        row['active'] != true ||
        row['role'] != session.role.name ||
        row['is_admin'] != session.isAdmin ||
        row['clinical_read'] != session.canReadClinical) {
      throw const ClinicFailure(
        'access_changed',
        'Clinic access changed. Sign in again to verify your permissions. Local work is retained.',
      );
    }
    try {
      await onSessionVerified?.call(session);
    } catch (_) {
      // Online authorization remains usable if secure lease persistence fails.
      // The existing lease is not extended, so offline access still fails closed.
    }
  }

  @override
  Future<Map<String, dynamic>> inviteAssistant(
    String clinicId,
    String email,
    bool clinicalRead,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'clinic_invite_assistant',
          params: {
            'p_clinic_id': clinicId,
            'p_email': email,
            'p_clinical_read': clinicalRead,
          },
        )
        as Map,
  );
  @override
  Future<List<Map<String, dynamic>>> staff(String clinicId) async =>
      (await client.rpc('clinic_staff', params: {'p_clinic_id': clinicId})
              as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
  @override
  Future<void> setStaffAccess(
    String clinicId,
    String userId,
    bool active,
    bool clinicalRead,
  ) async {
    await client.rpc(
      'clinic_set_staff_access',
      params: {
        'p_clinic_id': clinicId,
        'p_user_id': userId,
        'p_active': active,
        'p_clinical_read': clinicalRead,
      },
    );
  }

  @override
  Future<List<ClinicAuditEvent>> auditEvents(
    String clinicId, {
    int offset = 0,
    int limit = 25,
  }) async {
    if (offset < 0 || limit < 1 || limit > 50) {
      throw const ClinicFailure(
        'invalid_request',
        'The audit history page request is invalid.',
      );
    }
    try {
      final rows = await client
          .from('audit_events')
          .select(clinicAuditSafeColumns)
          .eq('clinic_id', clinicId)
          .order('occurred_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + limit - 1);
      try {
        return rows.map(ClinicAuditEvent.fromMap).toList(growable: false);
      } on FormatException {
        throw const ClinicFailure(
          'invalid_response',
          'The audit service returned an invalid event. No audit details were displayed.',
        );
      }
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw const ClinicFailure(
          'forbidden',
          'Doctor administrator access is required to review audit history.',
        );
      }
      if (error.code == 'PGRST205') {
        throw const ClinicFailure(
          'backend_pending',
          'The audit history service is unavailable or incompatible.',
        );
      }
      throw const ClinicFailure(
        'unavailable',
        'Audit history could not be loaded. Check the connection and try again.',
      );
    } on AuthException {
      throw const ClinicFailure(
        'session_expired',
        'Your session expired. Sign in again before reviewing audit history.',
      );
    }
  }

  Never _deliveryPostgrest(PostgrestException error) {
    if (error.code == '42501') {
      throw const ClinicFailure(
        'forbidden',
        'Current clinic access does not allow this delivery action.',
      );
    }
    const messages = {
      'DOCTOR_OFFLINE':
          'The Doctor app is not currently online. Do not send the patient until device presence is confirmed.',
      'DOCTOR_DEVICE_OFFLINE':
          'This Doctor device is not currently registered as online. Reconnect and try again.',
      'ASSIGNMENT_CHANGED':
          'The patient assignment changed before receipt was acknowledged.',
      'INVALID_DOCTOR': 'The assigned doctor is no longer active.',
      'NOT_FOUND': 'The appointment is unavailable.',
      'OPERATION_ID_REUSED':
          'The receipt identifier was already used for another appointment.',
    };
    throw ClinicFailure(
      error.code == 'PGRST202' ? 'backend_pending' : 'unavailable',
      messages[error.message] ??
          (error.code == 'PGRST202'
              ? 'The doctor delivery service is unavailable or incompatible.'
              : 'Doctor delivery status could not be confirmed. Try again.'),
    );
  }

  DoctorDeliveryState _deliveryState(Object? value) {
    try {
      return DoctorDeliveryState.fromMap(
        Map<String, dynamic>.from(value as Map),
      );
    } catch (_) {
      throw const ClinicFailure(
        'invalid_response',
        'The doctor delivery service returned an invalid response.',
      );
    }
  }

  @override
  Future<DoctorDeliveryState> doctorHeartbeat(
    String clinicId,
    String deviceId,
  ) async {
    try {
      return _deliveryState(
        await client.rpc(
          'clinic_doctor_heartbeat',
          params: {'p_clinic_id': clinicId, 'p_device_id': deviceId},
        ),
      );
    } on PostgrestException catch (error) {
      _deliveryPostgrest(error);
    }
  }

  @override
  Future<DoctorDeliveryState> doctorDeliveryState(
    String clinicId,
    String doctorId, {
    String? appointmentId,
  }) async {
    try {
      return _deliveryState(
        await client.rpc(
          'clinic_doctor_delivery_state',
          params: {
            'p_clinic_id': clinicId,
            'p_doctor_id': doctorId,
            'p_appointment_id': appointmentId,
          },
        ),
      );
    } on PostgrestException catch (error) {
      _deliveryPostgrest(error);
    }
  }

  @override
  Future<DoctorDeliveryState> acknowledgeAppointment(
    String clinicId,
    String appointmentId,
    String deviceId,
    String operationId,
    int expectedVersion,
  ) async {
    try {
      return _deliveryState(
        await client.rpc(
          'clinic_acknowledge_appointment',
          params: {
            'p_clinic_id': clinicId,
            'p_appointment_id': appointmentId,
            'p_device_id': deviceId,
            'p_operation_id': operationId,
            'p_expected_version': expectedVersion,
          },
        ),
      );
    } on PostgrestException catch (error) {
      _deliveryPostgrest(error);
    }
  }

  Never _documentPostgrest(PostgrestException error) {
    if (error.code == '42501') {
      throw const ClinicFailure(
        'forbidden',
        'Your current permissions do not allow access to this document.',
      );
    }
    const codes = {
      'ATTACHMENT_OBJECT_MISSING': 'object_missing',
      'ATTACHMENT_SIZE_MISMATCH': 'integrity',
      'ATTACHMENT_ID_REUSED': 'rejected',
      'INVALID_ATTACHMENT': 'rejected',
      'INVALID_ATTACHMENT_STATE': 'rejected',
      'INVALID_PATIENT': 'rejected',
      'INVALID_VISIT': 'forbidden',
    };
    throw ClinicFailure(codes[error.message] ?? 'unavailable', switch (error
        .message) {
      'ATTACHMENT_OBJECT_MISSING' =>
        'The uploaded object is not available yet.',
      'ATTACHMENT_SIZE_MISMATCH' =>
        'The uploaded document failed its size integrity check.',
      'ATTACHMENT_ID_REUSED' =>
        'This document identifier was already used for different content.',
      'INVALID_ATTACHMENT' => 'The server rejected this document format.',
      'INVALID_ATTACHMENT_STATE' =>
        'The document changed on another device. Refresh and try again.',
      'INVALID_PATIENT' => 'The patient is unavailable or archived.',
      'INVALID_VISIT' =>
        'The visit does not match this patient or your clinical access changed.',
      _ => 'The document service is temporarily unavailable.',
    });
  }

  @override
  Future<ClinicDocument> beginDocument(ClinicDocument document) async {
    try {
      final value = await client.rpc(
        'clinic_begin_attachment',
        params: {
          'p_id': document.id,
          'p_clinic_id': document.clinicId,
          'p_patient_id': document.patientId,
          'p_visit_id': document.visitId,
          'p_file_name': document.fileName,
          'p_content_type': document.contentType,
          'p_category': document.category.label,
          'p_notes': document.notes,
          'p_bytes': document.bytes,
          'p_clinical': document.clinical,
          'p_sha256_hex': document.sha256Hex,
        },
      );
      return ClinicDocument.fromMap(Map<String, dynamic>.from(value as Map));
    } on PostgrestException catch (error) {
      _documentPostgrest(error);
    }
  }

  @override
  Future<ClinicDocument> finalizeDocument(String id) async {
    try {
      final value = await client.rpc(
        'clinic_finalize_attachment',
        params: {'p_id': id},
      );
      return ClinicDocument.fromMap(Map<String, dynamic>.from(value as Map));
    } on PostgrestException catch (error) {
      _documentPostgrest(error);
    }
  }

  @override
  Future<void> failDocument(String id) async {
    try {
      await client.rpc('clinic_fail_attachment', params: {'p_id': id});
    } on PostgrestException catch (error) {
      _documentPostgrest(error);
    }
  }

  @override
  Future<List<ClinicDocument>> documents(
    String clinicId,
    String patientId, {
    int offset = 0,
  }) async {
    try {
      final rows = await client
          .from('attachments')
          .select()
          .eq('clinic_id', clinicId)
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .range(offset, offset + 49);
      return rows.map(ClinicDocument.fromMap).toList();
    } on PostgrestException catch (error) {
      _documentPostgrest(error);
    }
  }

  @override
  Future<Map<String, dynamic>> authorizeDocument(
    String id,
    String purpose,
  ) async {
    try {
      return Map<String, dynamic>.from(
        await client.rpc(
              'clinic_authorize_attachment_access',
              params: {'p_id': id, 'p_purpose': purpose},
            )
            as Map,
      );
    } on PostgrestException catch (error) {
      _documentPostgrest(error);
    }
  }

  @override
  Future<void> uploadDocument(
    String objectPath,
    Uint8List bytes,
    String contentType,
  ) async {
    try {
      await client.storage
          .from('clinic-documents')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
    } on StorageException catch (error) {
      final status = error.statusCode;
      if (status == '409' ||
          error.message.toLowerCase().contains('already exists') ||
          error.message.toLowerCase().contains('duplicate')) {
        throw const ClinicFailure(
          'already_exists',
          'The document object already exists.',
        );
      }
      if (status == '401' || status == '403') {
        throw const ClinicFailure(
          'forbidden',
          'Your current permissions do not allow this upload.',
        );
      }
      throw const ClinicFailure(
        'unavailable',
        'The document upload was interrupted. It will retry safely.',
      );
    }
  }

  @override
  Future<Uint8List> downloadDocument(String objectPath) async {
    try {
      return await client.storage.from('clinic-documents').download(objectPath);
    } on StorageException catch (error) {
      if (error.statusCode == '401' || error.statusCode == '403') {
        throw const ClinicFailure(
          'forbidden',
          'Document access expired or your permissions changed.',
        );
      }
      throw const ClinicFailure(
        'unavailable',
        'The document download was interrupted. Try again.',
      );
    }
  }

  @override
  Future<ClinicDocument> setDocumentArchived(String id, bool archived) async {
    try {
      final value = await client.rpc(
        'clinic_set_attachment_archived',
        params: {'p_id': id, 'p_archived': archived},
      );
      return ClinicDocument.fromMap(Map<String, dynamic>.from(value as Map));
    } on PostgrestException catch (error) {
      _documentPostgrest(error);
    }
  }

  @override
  Future<CommandReceipt> apply(PendingCommand command) async {
    try {
      final raw = await client.rpc(
        'clinic_apply_command',
        params: {
          'p_clinic_id': command.clinicId,
          'p_operation_id': command.operationId,
          'p_entity_type': command.entityType,
          'p_entity_id': command.entityId,
          'p_action': command.action,
          'p_payload': command.payload,
          'p_expected_version': command.expectedVersion,
        },
      );
      final value = Map<String, dynamic>.from(raw as Map);
      return CommandReceipt(
        Map<String, dynamic>.from(value['entity'] as Map),
        (value['version'] as num).toInt(),
        appointment: value['appointment'] == null
            ? null
            : Map<String, dynamic>.from(value['appointment'] as Map),
      );
    } on PostgrestException catch (e) {
      if ([
        'SLOT_UNAVAILABLE',
        'OUTSIDE_WORKING_HOURS',
        'INVALID_DURATION',
        'PAST_APPOINTMENT',
      ].contains(e.message)) {
        throw ClinicFailure(e.message, schedulingError(e.message));
      }
      if (e.message == 'VERSION_CONFLICT') {
        Map<String, dynamic> remote = {};
        try {
          remote = jsonDecode(e.details as String) as Map<String, dynamic>;
        } catch (_) {}
        throw SyncConflict(remote);
      }
      if (e.code == '42501') {
        throw const ClinicFailure(
          'forbidden',
          'Your current permissions do not allow this action.',
        );
      }
      if (e.code == 'PGRST202' || e.code == 'PGRST205') {
        throw const ClinicFailure(
          'backend_pending',
          'The clinic command service is unavailable or incompatible. Your local work is retained.',
        );
      }
      const messages = {
        'DOCTOR_BUSY':
            'Another patient is with the doctor. Finish that consultation first.',
        'DOCTOR_OFFLINE':
            'The Doctor app is not currently online. Confirm device presence before sending the patient.',
        'PATIENT_ACTIVE':
            'The patient is still in the queue or with the doctor.',
        'PATIENT_ARCHIVED':
            'This patient has been archived. Refresh the record.',
        'INVALID_TRANSITION':
            'The appointment status has changed. Refresh before continuing.',
        'ASSIGNMENT_CHANGED':
            'The patient assignment changed. Your draft is retained.',
        'NOT_TODAYS_APPOINTMENT':
            'Only today’s appointments can enter the queue.',
        'COMPLETED_VISIT_IMMUTABLE':
            'Completed records cannot be overwritten. An amendment is required.',
        'VISIT_NOT_COMPLETED':
            'Only a completed visit can receive an amendment.',
        'AMENDMENT_NOT_ASSIGNED_DOCTOR':
            'Only the doctor who recorded this visit can amend it.',
        'AMENDMENT_REASON_REQUIRED':
            'Explain the amendment in 10 to 1000 characters.',
        'INVALID_AMENDMENT':
            'The amendment contains invalid or excessive clinical data.',
        'DIAGNOSIS_REQUIRED': 'Add a diagnosis before completing the visit.',
        'COMMAND_EXPIRED':
            'This action expired before the server accepted it. Refresh and confirm the action again.',
        'INVALID_DOCTOR': 'This doctor is no longer available in the clinic.',
        'VISIT_IDENTITY_REQUIRED':
            'The visit’s patient and appointment must be specified. Your draft is retained.',
        'VISIT_IDENTITY_CHANGED':
            'The visit does not match this patient and appointment. Review your draft before retrying.',
      };
      throw ClinicFailure(
        'rejected',
        e.code == '23505'
            ? 'This would create a duplicate queue entry or active assignment.'
            : messages[e.message] ??
                  'The server rejected this change. Review the record and your permissions.',
      );
    } on AuthException {
      throw const ClinicFailure(
        'session_expired',
        'Your session expired. Sign in again; local work is retained.',
      );
    }
  }

  @override
  Future<List<Patient>> patients({
    required String clinicId,
    String search = '',
    int offset = 0,
    bool archived = false,
  }) async {
    final rows = await client.rpc(
      'clinic_search_patients',
      params: {
        'p_clinic_id': clinicId,
        'p_search': search,
        'p_offset': offset,
        'p_limit': 50,
        'p_archived': archived,
      },
    );
    return (rows as List)
        .map((e) => Patient.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<Patient>> patientsByIds(String clinicId, List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await client
        .from('patients')
        .select()
        .eq('clinic_id', clinicId)
        .inFilter('id', ids)
        .limit(ids.length);
    return rows.map(Patient.fromMap).toList();
  }

  @override
  Future<List<Appointment>> appointmentsByIds(
    String clinicId,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await client
        .from('appointments')
        .select()
        .eq('clinic_id', clinicId)
        .inFilter('id', ids)
        .limit(ids.length);
    return rows.map(Appointment.fromMap).toList();
  }

  @override
  Future<Appointment?> activeAppointment(
    String clinicId,
    String doctorId,
  ) async {
    final row = await client
        .from('appointments')
        .select()
        .eq('clinic_id', clinicId)
        .eq('doctor_id', doctorId)
        .eq('status', 'withDoctor')
        .maybeSingle();
    return row == null ? null : Appointment.fromMap(row);
  }

  @override
  Future<List<Appointment>> appointments(
    String clinicId,
    DateTime from,
    DateTime to,
  ) async {
    final rows = await client
        .from('appointments')
        .select()
        .eq('clinic_id', clinicId)
        .gte('starts_at', from.toUtc().toIso8601String())
        .lt('starts_at', to.toUtc().toIso8601String())
        .order('starts_at')
        .limit(500);
    return rows.map(Appointment.fromMap).toList();
  }

  @override
  Future<List<Visit>> visits(
    String clinicId,
    String patientId, {
    int offset = 0,
  }) async {
    final rows = await client
        .from('visit_details')
        .select()
        .eq('clinic_id', clinicId)
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .range(offset, offset + 49);
    return rows.map(Visit.fromMap).toList();
  }

  @override
  Stream<void> changes(String clinicId) {
    late StreamController<void> controller;
    RealtimeChannel? channel;
    Timer? polling;
    controller = StreamController<void>(
      onListen: () {
        channel = client.channel('clinic:$clinicId');
        for (final table in ['patients', 'appointments', 'visits']) {
          channel!.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'clinic_id',
              value: clinicId,
            ),
            callback: (_) {
              if (!controller.isClosed) controller.add(null);
            },
          );
        }
        channel!.subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed &&
              !controller.isClosed) {
            controller.add(null);
          }
        });
        polling = Timer.periodic(const Duration(seconds: 30), (_) {
          if (!controller.isClosed) controller.add(null);
        });
      },
      onCancel: () async {
        polling?.cancel();
        if (channel != null) await client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }
}

String schedulingError(String code) => switch (code) {
  'SLOT_UNAVAILABLE' =>
    'This time overlaps another appointment. Choose an available slot.',
  'OUTSIDE_WORKING_HOURS' =>
    'Choose a time within the doctor’s working hours and outside breaks.',
  'INVALID_DURATION' => 'Choose a duration between 5 and 240 minutes.',
  'PAST_APPOINTMENT' => 'Choose a future appointment time.',
  'FORBIDDEN' => 'You do not have permission to change this schedule.',
  'INVALID_SCHEDULE' =>
    'Check working hours and breaks. Periods must not overlap.',
  'EMPTY_SCHEDULE' =>
    'Add at least one working period, or clear the working hours so any time can be booked.',
  _ => 'Scheduling could not be updated. Refresh and try again.',
};
