import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_core/src/data/database.dart';
import 'package:clinic_core/src/data/repository.dart';
import 'package:clinic_core/src/data/gateway.dart';
import 'package:clinic_core/src/domain/models.dart';

class FakeGateway implements ClinicGateway {
  @override
  Future<void> verifySession(ClinicSession session) async {
    if (revoked) throw const ClinicFailure('access_changed', 'Access changed');
    if (offline) throw const ClinicFailure('offline', 'Offline');
  }

  final seen = <PendingCommand>[];
  bool conflict = false, offline = false;
  bool revoked = false;
  Future<CommandReceipt> Function(PendingCommand)? handler;
  List<Patient> people = [];
  List<Appointment> bookings = [];
  List<Visit> history = [];
  @override
  Future<CommandReceipt> apply(PendingCommand command) async {
    seen.add(command);
    if (handler != null) return handler!(command);
    if (offline) throw const ClinicFailure('offline', 'Offline');
    if (conflict) {
      throw const SyncConflict({'notes': 'Remote text', 'version': 9});
    }
    return CommandReceipt({
      ...command.payload,
      'version': command.expectedVersion + 1,
      'patient_number': 'P-1',
    }, command.expectedVersion + 1);
  }

  @override
  Stream<void> changes(String id) => const Stream.empty();
  @override
  Future<List<Patient>> patients({
    required String clinicId,
    String search = '',
    int offset = 0,
    bool archived = false,
  }) async => [];
  @override
  Future<List<Appointment>> appointments(
    String id,
    DateTime from,
    DateTime to,
  ) async => bookings
      .where((a) => !a.startsAt.isBefore(from) && a.startsAt.isBefore(to))
      .toList();
  @override
  Future<List<Patient>> patientsByIds(
    String clinicId,
    List<String> ids,
  ) async => people.where((p) => ids.contains(p.id)).toList();
  @override
  Future<List<Appointment>> appointmentsByIds(
    String clinicId,
    List<String> ids,
  ) async => bookings.where((a) => ids.contains(a.id)).toList();
  @override
  Future<Appointment?> activeAppointment(
    String clinicId,
    String doctorId,
  ) async => bookings
      .where(
        (a) =>
            a.doctorId == doctorId && a.status == AppointmentStatus.withDoctor,
      )
      .firstOrNull;
  @override
  Future<List<Visit>> visits(
    String id,
    String patientId, {
    int offset = 0,
  }) async => history
      .where((v) => v.patientId == patientId)
      .skip(offset)
      .take(50)
      .toList();
}

class FakeDocumentGateway extends FakeGateway implements ClinicDocumentGateway {
  final metadata = <String, ClinicDocument>{};
  final objects = <String, Uint8List>{};
  final accessLog = <String>[];
  bool loseNextUploadResponse = false;
  int uploadCalls = 0, downloadCalls = 0;

  void requireOnline() {
    if (offline) throw const ClinicFailure('offline', 'Offline');
  }

  @override
  Future<ClinicDocument> beginDocument(ClinicDocument document) async {
    requireOnline();
    final existing = metadata[document.id];
    if (existing != null) {
      if (existing.objectPath != document.objectPath ||
          existing.sha256Hex != document.sha256Hex ||
          existing.bytes != document.bytes) {
        throw const ClinicFailure('rejected', 'Identifier reused');
      }
      return existing;
    }
    final created = document.copyWith(version: 1);
    metadata[document.id] = created;
    return created;
  }

  @override
  Future<ClinicDocument> finalizeDocument(String id) async {
    requireOnline();
    final value = metadata[id]!;
    final bytes = objects[value.objectPath];
    if (bytes == null) {
      throw const ClinicFailure('object_missing', 'Object missing');
    }
    if (bytes.length != value.bytes) {
      throw const ClinicFailure('integrity', 'Size mismatch');
    }
    final ready = value.copyWith(state: 'ready', version: value.version + 1);
    metadata[id] = ready;
    return ready;
  }

  @override
  Future<void> failDocument(String id) async {
    requireOnline();
    final value = metadata[id];
    if (value != null && objects[value.objectPath] == null) {
      metadata[id] = value.copyWith(state: 'failed');
    }
  }

  @override
  Future<List<ClinicDocument>> documents(
    String clinicId,
    String patientId, {
    int offset = 0,
  }) async {
    requireOnline();
    return metadata.values
        .where((d) => d.clinicId == clinicId && d.patientId == patientId)
        .skip(offset)
        .take(50)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> authorizeDocument(
    String id,
    String purpose,
  ) async {
    requireOnline();
    final value = metadata[id];
    if (value == null || !value.isReady) {
      throw const ClinicFailure('forbidden', 'Unavailable');
    }
    accessLog.add('$id:$purpose');
    return {
      'attachment_id': id,
      'object_path': value.objectPath,
      'bytes': value.bytes,
      'sha256_hex': value.sha256Hex,
    };
  }

  @override
  Future<void> uploadDocument(
    String objectPath,
    Uint8List bytes,
    String contentType,
  ) async {
    requireOnline();
    uploadCalls++;
    if (objects.containsKey(objectPath)) {
      throw const ClinicFailure('already_exists', 'Exists');
    }
    objects[objectPath] = Uint8List.fromList(bytes);
    if (loseNextUploadResponse) {
      loseNextUploadResponse = false;
      throw const ClinicFailure('unavailable', 'Response lost');
    }
  }

  @override
  Future<Uint8List> downloadDocument(String objectPath) async {
    requireOnline();
    downloadCalls++;
    return Uint8List.fromList(objects[objectPath]!);
  }

  @override
  Future<ClinicDocument> setDocumentArchived(String id, bool archived) async {
    requireOnline();
    final value = metadata[id]!;
    final next = value.copyWith(
      state: archived ? 'archived' : 'ready',
      version: value.version + 1,
    );
    metadata[id] = next;
    return next;
  }
}

class FakeDeliveryGateway extends FakeGateway implements ClinicDeliveryGateway {
  int heartbeats = 0, acknowledgements = 0;
  final operations = <String>[];
  DoctorDeliveryState state = DoctorDeliveryState(
    serverNow: DateTime.utc(2026, 8, 29, 12),
    doctorOnline: true,
    serviceAvailable: true,
    presenceExpiresAt: DateTime.utc(2026, 8, 29, 12, 1),
  );

  @override
  Future<DoctorDeliveryState> doctorHeartbeat(
    String clinicId,
    String deviceId,
  ) async {
    heartbeats++;
    return state;
  }

  @override
  Future<DoctorDeliveryState> doctorDeliveryState(
    String clinicId,
    String doctorId, {
    String? appointmentId,
  }) async => state;

  @override
  Future<DoctorDeliveryState> acknowledgeAppointment(
    String clinicId,
    String appointmentId,
    String deviceId,
    String operationId,
    int expectedVersion,
  ) async {
    acknowledgements++;
    operations.add(operationId);
    state = DoctorDeliveryState(
      serverNow: state.serverNow,
      doctorOnline: true,
      serviceAvailable: true,
      presenceExpiresAt: state.presenceExpiresAt,
      acknowledgedAt: DateTime.utc(2026, 8, 29, 12, 0, 10),
      appointmentVersion: expectedVersion,
    );
    return state;
  }
}

ClinicSession session({bool doctor = false}) => ClinicSession(
  userId: doctor ? 'doctor' : 'assistant',
  clinicId: 'clinic',
  clinicName: 'Test',
  role: doctor ? ClinicRole.doctor : ClinicRole.assistant,
  doctorId: 'doctor',
  isDemo: true,
);
Patient patient() => Patient(
  id: 'patient',
  clinicId: 'clinic',
  name: 'Test Patient',
  gender: 'Female',
  birthDate: DateTime.utc(2000, 1, 1),
  mobile: '01000000000',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Future<({ClinicRepository repo, FakeGateway gateway})> patientConflict({
  bool doctor = false,
}) async {
  final gateway = FakeGateway()..conflict = true;
  final repo = ClinicRepository(
    db: ClinicDatabase.memory(),
    session: session(doctor: doctor),
    gateway: gateway,
  );
  final original = patient().copyWith(version: 1);
  gateway.people = [
    original.copyWith(
      version: 9,
      notes: 'Server notes',
      alerts: 'Doctor alert',
      number: '42',
    ),
  ];
  await repo.seedDemo([original], [], []);
  await repo.savePatient(original.copyWith(notes: 'Local notes'));
  await repo.synchronize();
  return (repo: repo, gateway: gateway);
}

void main() {
  test(
    'only the assigned protected Doctor device can acknowledge receipt',
    () async {
      final gateway = FakeDeliveryGateway();
      final repository = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: const ClinicSession(
          userId: 'doctor',
          clinicId: 'clinic',
          clinicName: 'Fictional Clinic',
          role: ClinicRole.doctor,
          doctorId: 'doctor',
        ),
        gateway: gateway,
        deviceId: '00000000-0000-4000-8000-000000000001',
      );
      addTearDown(repository.close);
      final appointment = Appointment(
        id: 'appointment',
        clinicId: 'clinic',
        patientId: 'patient',
        doctorId: 'doctor',
        startsAt: DateTime.utc(2026, 8, 29, 12),
        status: AppointmentStatus.withDoctor,
        version: 4,
      );
      await repository.renewDoctorPresence();
      await repository.acknowledgeAppointment(appointment);
      expect(gateway.heartbeats, 2);
      expect(gateway.acknowledgements, 1);
      expect(gateway.operations.single, isNotEmpty);
      expect(
        (await repository.deliveryState(
          appointmentId: appointment.id,
        )).acknowledged,
        isTrue,
      );

      final assistant = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: const ClinicSession(
          userId: 'assistant',
          clinicId: 'clinic',
          clinicName: 'Fictional Clinic',
          role: ClinicRole.assistant,
          doctorId: 'doctor',
        ),
        gateway: gateway,
      );
      addTearDown(assistant.close);
      await expectLater(
        assistant.acknowledgeAppointment(appointment),
        throwsA(
          isA<ClinicFailure>().having(
            (failure) => failure.code,
            'code',
            'forbidden',
          ),
        ),
      );
    },
  );

  test(
    'document upload survives a lost response without duplicate bytes and verifies every read',
    () async {
      final gateway = FakeDocumentGateway()..offline = true;
      final db = ClinicDatabase.memory();
      final repo = ClinicRepository(
        db: db,
        session: session(doctor: true),
        gateway: gateway,
      );
      addTearDown(repo.close);
      await repo.seedDemo([patient()], [], []);
      final original = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31]);
      final staged = await repo.stageDocument(
        patientId: 'patient',
        fileName: 'fictional-report.pdf',
        contentType: 'application/pdf',
        category: ClinicDocumentCategory.lab,
        data: original,
        clinical: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((await repo.syncSummary()).pending, 1);
      expect(
        (await repo.documentContent(staged.id)).data,
        orderedEquals(original),
      );
      await expectLater(
        repo.documentContent(staged.id, purpose: 'share'),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'upload_pending'),
        ),
      );

      gateway
        ..offline = false
        ..loseNextUploadResponse = true;
      await repo.synchronize();
      expect(gateway.uploadCalls, 1);
      expect((await repo.syncSummary()).pending, 1);
      await repo.synchronize();
      expect(
        gateway.uploadCalls,
        1,
        reason: 'retry must finalize the existing object',
      );
      expect((await repo.syncSummary()).clean, isTrue);
      final ready = (await repo.documents('patient')).single;
      expect(ready.state, 'ready');

      final cached = await repo.documentContent(ready.id, purpose: 'preview');
      expect(cached.data, orderedEquals(original));
      expect(gateway.accessLog, contains('${ready.id}:preview'));
      await db.customStatement(
        'UPDATE document_blobs SET data=? WHERE attachment_id=?',
        [
          Uint8List.fromList([9, 9, 9, 9, 9, 9]),
          ready.id,
        ],
      );
      final recovered = await repo.documentContent(ready.id);
      expect(recovered.data, orderedEquals(original));
      expect(gateway.downloadCalls, 1);

      await db.customStatement(
        'UPDATE document_blobs SET data=? WHERE attachment_id=?',
        [
          Uint8List.fromList([8, 8, 8, 8, 8, 8]),
          ready.id,
        ],
      );
      gateway.objects[ready.objectPath] = Uint8List.fromList([
        7,
        7,
        7,
        7,
        7,
        7,
      ]);
      await expectLater(
        repo.documentContent(ready.id),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'integrity'),
        ),
      );
    },
  );

  test(
    'document staging rejects unsafe formats and unauthorized clinical data',
    () async {
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(),
      );
      addTearDown(repo.close);
      await repo.seedDemo([patient()], [], []);
      await expectLater(
        repo.stageDocument(
          patientId: 'patient',
          fileName: 'escape/record.pdf',
          contentType: 'application/pdf',
          category: ClinicDocumentCategory.other,
          data: Uint8List.fromList([1]),
          clinical: false,
        ),
        throwsA(
          isA<ClinicFailure>().having(
            (e) => e.code,
            'code',
            'invalid_document',
          ),
        ),
      );
      await expectLater(
        repo.stageDocument(
          patientId: 'patient',
          fileName: 'clinical.pdf',
          contentType: 'application/pdf',
          category: ClinicDocumentCategory.other,
          data: Uint8List.fromList([1]),
          clinical: true,
        ),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'forbidden'),
        ),
      );
    },
  );

  test(
    'lost handoff response retains request and replays the same operation without optimistic assignment',
    () async {
      final gateway = FakeGateway();
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(),
        gateway: gateway,
      );
      addTearDown(repo.close);
      final p = patient(),
          a = Appointment(
            id: 'appointment',
            clinicId: 'clinic',
            patientId: 'patient',
            doctorId: 'doctor',
            startsAt: DateTime.now(),
            status: AppointmentStatus.waiting,
            version: 1,
          );
      await repo.seedDemo([p], [a], []);
      var first = true;
      gateway.handler = (command) async {
        if (first) {
          first = false;
          throw const ClinicFailure('offline', 'Response lost after commit');
        }
        return CommandReceipt(
          a.copyWith(status: AppointmentStatus.withDoctor, version: 2).toMap(),
          2,
        );
      };
      await expectLater(repo.sendToDoctor(a), throwsA(isA<ClinicFailure>()));
      expect((await repo.appointment(a.id))!.status, AppointmentStatus.waiting);
      final pending = (await repo.pendingOperations()).single;
      expect(
        jsonDecode(pending['payload'] as String)['_expires_at'],
        isNotNull,
      );
      await repo.synchronize();
      expect(gateway.seen.map((c) => c.operationId).toSet(), {
        pending['operation_id'],
      });
      expect(
        (await repo.appointment(a.id))!.status,
        AppointmentStatus.withDoctor,
      );
      expect((await repo.syncSummary()).clean, isTrue);
    },
  );
  test(
    'schedule and historical visits hydrate patient and appointment dependencies',
    () async {
      final gateway = FakeGateway(), p = patient();
      final a = Appointment(
        id: 'appointment',
        clinicId: 'clinic',
        patientId: p.id,
        doctorId: 'doctor',
        startsAt: DateTime(2020),
        status: AppointmentStatus.completed,
        version: 3,
      );
      final visit = Visit(
        id: 'visit',
        clinicId: 'clinic',
        patientId: p.id,
        appointmentId: a.id,
        doctorId: 'doctor',
        createdAt: DateTime(2020),
        updatedAt: DateTime(2020),
        diagnoses: ['Fictional diagnosis'],
        completed: true,
        version: 2,
      );
      gateway.people = [p];
      gateway.bookings = [a];
      gateway.history = [visit];
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(doctor: true),
        gateway: gateway,
      );
      addTearDown(repo.close);
      await repo.refreshVisits(p.id);
      expect((await repo.patient(p.id))!.name, p.name);
      expect(
        (await repo.appointment(a.id))!.status,
        AppointmentStatus.completed,
      );
      expect((await repo.visits(p.id)).single.diagnoses, [
        'Fictional diagnosis',
      ]);
    },
  );
  test(
    'completed visit amendment is confirmed online and appends the returned revision',
    () async {
      final gateway = FakeGateway();
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(doctor: true),
        gateway: gateway,
      );
      addTearDown(repo.close);
      final p = patient();
      final appointment = Appointment(
        id: 'appointment',
        clinicId: 'clinic',
        patientId: p.id,
        doctorId: 'doctor',
        startsAt: DateTime.utc(2026),
        status: AppointmentStatus.completed,
        version: 4,
      );
      final completed = Visit(
        id: 'visit',
        clinicId: 'clinic',
        patientId: p.id,
        appointmentId: appointment.id,
        doctorId: 'doctor',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        diagnoses: const ['Fictional diagnosis'],
        notes: 'Original fictional note',
        completed: true,
        version: 3,
        currentRevision: 2,
      );
      await repo.seedDemo([p], [appointment], [completed]);
      gateway.handler = (command) async {
        expect(command.action, 'amend');
        expect(command.expectedVersion, 3);
        expect(
          command.payload['amendment_reason'],
          'Correct a fictional transcription error.',
        );
        final value = completed.copyWith(
          notes: command.payload['notes'] as String,
          amendmentReason: command.payload['amendment_reason'] as String,
          version: 4,
          currentRevision: 3,
          updatedAt: DateTime.utc(2026, 1, 2),
        );
        return CommandReceipt(value.toMap(), 4);
      };
      await expectLater(
        repo.amendVisit(completed, 'short'),
        throwsA(
          isA<ClinicFailure>().having(
            (error) => error.code,
            'code',
            'validation',
          ),
        ),
      );
      final amended = await repo.amendVisit(
        completed.copyWith(notes: 'Corrected fictional note'),
        'Correct a fictional transcription error.',
      );
      expect(amended.completed, isTrue);
      expect(amended.notes, 'Corrected fictional note');
      expect(amended.currentRevision, 3);
      expect(amended.version, 4);
      expect(
        amended.amendmentReason,
        'Correct a fictional transcription error.',
      );
      expect(await repo.pendingOperations(), isEmpty);
    },
  );
  test(
    'encrypted v1 cache upgrades without losing pending work and retains recovery history after reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinic-cache-test-',
      );
      final file = File('${directory.path}/cache.sqlite');
      final key = List.filled(64, 'a').join();
      final first = ClinicRepository(
        db: ClinicDatabase.encrypted(file, key),
        session: session(),
      );
      await first.savePatient(patient());
      final operationId =
          (await first.pendingOperations()).single['operation_id'];
      // Model the exact schema this project shipped before recovery history.
      await first.db.customStatement('DROP TABLE sync_resolutions');
      await first.db.customStatement(
        'ALTER TABLE cached_visits DROP COLUMN current_revision',
      );
      await first.db.customStatement('PRAGMA user_version=1');
      await first.close();
      final bytes = await file.readAsBytes();
      expect(
        utf8.decode(bytes.take(16).toList(), allowMalformed: true),
        isNot(startsWith('SQLite format')),
      );
      final reopened = ClinicRepository(
        db: ClinicDatabase.encrypted(file, key),
        session: session(),
        gateway: FakeGateway()
          ..conflict = true
          ..people = [patient().copyWith(version: 9)],
      );
      expect((await reopened.patient('patient'))!.name, 'Test Patient');
      expect(
        (await reopened.pendingOperations()).single['operation_id'],
        operationId,
      );
      expect(await reopened.patientRecoveryHistory(), isEmpty);
      await reopened.synchronize();
      final review = await reopened.reviewPatientConflict(
        operationId as String,
      );
      await reopened.resolvePatientConflict(review, localFields: {});
      await reopened.close();
      final restored = ClinicRepository(
        db: ClinicDatabase.encrypted(file, key),
        session: session(),
      );
      expect(
        (await restored.patientRecoveryHistory()).single.local.name,
        'Test Patient',
      );
      expect(await restored.pendingOperations(), isEmpty);
      await restored.close();
      final wrongKey = ClinicDatabase.encrypted(
        file,
        List.filled(64, 'b').join(),
      );
      await expectLater(
        wrongKey.customSelect('SELECT * FROM cached_patients').get(),
        throwsA(anything),
      );
      await wrongKey.close();
      // Only remove this test's own, explicitly created files.
      for (final entry in await directory.list().toList()) {
        if (entry is File) await entry.delete();
      }
      await directory.delete();
    },
  );
  test(
    'patient and outbox commit together and literal partial search works',
    () async {
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(),
      );
      addTearDown(repo.close);
      await repo.savePatient(patient());
      expect((await repo.patient('patient'))!.version, 1);
      expect((await repo.pendingOperations()).single['expected_version'], 0);
      expect((await repo.patients(search: 't Pa')).single.id, 'patient');
      expect((await repo.patients(search: '0000')).single.id, 'patient');
      expect((await repo.patients(search: '%')), isEmpty);
      expect((await repo.syncSummary()).pending, 1);
    },
  );
  test(
    'cross-clinic writes and assistant alert changes are rejected before persistence',
    () async {
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(),
      );
      addTearDown(repo.close);
      await expectLater(
        repo.savePatient(patient().copyWith(alerts: 'Clinical alert')),
        throwsA(isA<ClinicFailure>()),
      );
      expect(await repo.pendingOperations(), isEmpty);
      final other = Patient.fromMap({
        ...patient().toMap(),
        'clinic_id': 'other',
      });
      await expectLater(repo.savePatient(other), throwsA(isA<ClinicFailure>()));
    },
  );
  test('offline handoff makes no appointment status change', () async {
    final repo = ClinicRepository(
      db: ClinicDatabase.memory(),
      session: session(),
    );
    addTearDown(repo.close);
    final p = patient(),
        a = Appointment(
          id: 'appointment',
          clinicId: 'clinic',
          patientId: p.id,
          doctorId: 'doctor',
          startsAt: DateTime.now(),
          status: AppointmentStatus.waiting,
          version: 1,
        );
    await repo.seedDemo([p], [a], []);
    await expectLater(repo.sendToDoctor(a), throwsA(isA<ClinicFailure>()));
    expect((await repo.appointment(a.id))!.status, AppointmentStatus.waiting);
  });
  test('sync conflict retains both local content and remote values', () async {
    final db = ClinicDatabase.memory();
    final offline = ClinicRepository(db: db, session: session());
    await offline.savePatient(patient());
    final gateway = FakeGateway()..conflict = true;
    final repo = ClinicRepository(db: db, session: session(), gateway: gateway);
    addTearDown(repo.close);
    await repo.synchronize();
    expect((await repo.patient('patient'))!.name, 'Test Patient');
    final pending = (await repo.pendingOperations()).single;
    expect(pending['state'], 'conflict');
    expect(pending['remote_value'], contains('Remote text'));
    expect((await repo.syncSummary()).conflicts, 1);
  });
  test(
    'reviewed merge retains every local save and preserves dependent queue order with a new operation ID',
    () async {
      final fixture = await patientConflict(),
          repo = fixture.repo,
          gateway = fixture.gateway;
      addTearDown(repo.close);
      final old = (await repo.pendingOperations()).single;
      final appointment = Appointment(
        id: 'later-appointment',
        clinicId: 'clinic',
        patientId: 'patient',
        doctorId: 'doctor',
        startsAt: DateTime.now(),
      );
      await repo.saveAppointment(appointment);
      await repo.savePatient(
        (await repo.patient('patient'))!.copyWith(name: 'Later local name'),
      );
      await repo.synchronize();
      final review = await repo.reviewPatientConflict(
        old['operation_id'] as String,
      );
      expect(review.operationCount, 2);
      expect(review.local.name, 'Later local name');
      // Keep the replacement queued so its ordering and immutable request are inspectable.
      gateway.handler = (_) async =>
          throw const ClinicFailure('unavailable', 'Simulated connection loss');
      await repo.resolvePatientConflict(
        review,
        localFields: {'full_name', 'notes'},
      );
      await repo.synchronize();
      final queued = await repo.pendingOperations();
      expect(queued.length, 2);
      expect(queued.first['entity_type'], 'patient');
      expect(queued.last['entity_type'], 'appointment');
      expect(queued.first['sequence'], old['sequence']);
      expect(queued.first['operation_id'], isNot(old['operation_id']));
      expect(queued.first['expected_version'], 9);
      final payload = jsonDecode(queued.first['payload'] as String) as Map;
      expect(payload['full_name'], 'Later local name');
      expect(payload['notes'], 'Local notes');
      expect(payload['alerts'], 'Doctor alert');
      expect(payload['patient_number'], '42');
      final recovery = (await repo.patientRecoveryHistory()).single;
      expect(recovery.operationCount, 2);
      expect(recovery.remote.notes, 'Server notes');
      expect(recovery.local.notes, 'Local notes');
      final archived =
          (await repo.db
                  .customSelect(
                    'SELECT original_operations FROM sync_resolutions',
                  )
                  .get())
              .single;
      expect(
        archived.data['original_operations'],
        contains(old['operation_id']),
      );
    },
  );
  test(
    'keeping server version archives local edits without sending an overwrite',
    () async {
      final fixture = await patientConflict(), repo = fixture.repo;
      addTearDown(repo.close);
      final id =
          (await repo.pendingOperations()).single['operation_id'] as String;
      final review = await repo.reviewPatientConflict(id);
      await repo.resolvePatientConflict(review, localFields: {});
      await repo.synchronize();
      expect(await repo.pendingOperations(), isEmpty);
      expect(fixture.gateway.seen.length, 1);
      expect((await repo.patient('patient'))!.notes, 'Server notes');
      expect(
        (await repo.patientRecoveryHistory()).single.local.notes,
        'Local notes',
      );
    },
  );
  test(
    'new server or local changes invalidate an open review without losing any request',
    () async {
      final fixture = await patientConflict(),
          repo = fixture.repo,
          gateway = fixture.gateway;
      addTearDown(repo.close);
      final id =
          (await repo.pendingOperations()).single['operation_id'] as String;
      final review = await repo.reviewPatientConflict(id);
      gateway.people = [
        gateway.people.single.copyWith(version: 10, notes: 'New server edit'),
      ];
      await expectLater(
        repo.resolvePatientConflict(review, localFields: {'notes'}),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'review_changed'),
        ),
      );
      expect(await repo.patientRecoveryHistory(), isEmpty);
      final latest = await repo.reviewPatientConflict(id);
      await repo.savePatient(
        (await repo.patient('patient'))!.copyWith(notes: 'New local edit'),
      );
      await expectLater(
        repo.resolvePatientConflict(latest, localFields: {}),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'review_changed'),
        ),
      );
      expect((await repo.pendingOperations()).length, 2);
      expect((await repo.patient('patient'))!.notes, 'New local edit');
      expect(await repo.patientRecoveryHistory(), isEmpty);
    },
  );
  test(
    'revoked access, cross-clinic responses and assistant alert merges are rejected',
    () async {
      final fixture = await patientConflict(),
          repo = fixture.repo,
          gateway = fixture.gateway;
      addTearDown(repo.close);
      final id =
          (await repo.pendingOperations()).single['operation_id'] as String;
      final review = await repo.reviewPatientConflict(id);
      await expectLater(
        repo.resolvePatientConflict(review, localFields: {'alerts'}),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'forbidden'),
        ),
      );
      await expectLater(
        repo.resolvePatientConflict(review, localFields: {'clinic_id'}),
        throwsA(isA<ClinicFailure>()),
      );
      gateway.revoked = true;
      await expectLater(
        repo.resolvePatientConflict(review, localFields: {}),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'access_changed'),
        ),
      );
      gateway.revoked = false;
      gateway.people = [
        Patient.fromMap({...review.remote.toMap(), 'clinic_id': 'other'}),
      ];
      await expectLater(
        repo.reviewPatientConflict(id),
        throwsA(isA<ClinicFailure>()),
      );
      expect((await repo.pendingOperations()).single['operation_id'], id);
      expect(await repo.patientRecoveryHistory(), isEmpty);
    },
  );
  test(
    'doctor may explicitly select local medical alerts for a reviewed merge',
    () async {
      final fixture = await patientConflict(doctor: true), repo = fixture.repo;
      addTearDown(repo.close);
      await repo.savePatient(
        (await repo.patient(
          'patient',
        ))!.copyWith(alerts: 'Reviewed doctor alert'),
      );
      await repo.synchronize();
      final review = await repo.reviewPatientConflict(
        (await repo.pendingOperations()).first['operation_id'] as String,
      );
      fixture.gateway.handler = (_) async =>
          throw const ClinicFailure('unavailable', 'Connection lost');
      await repo.resolvePatientConflict(review, localFields: {'alerts'});
      await repo.synchronize();
      expect((await repo.patient('patient'))!.alerts, 'Reviewed doctor alert');
      expect((await repo.patient('patient'))!.notes, 'Server notes');
    },
  );
  test(
    'history write failure rolls back resolution and leaves both versions and original request intact',
    () async {
      final fixture = await patientConflict(), repo = fixture.repo;
      addTearDown(repo.close);
      final original = await repo.pendingOperations();
      final review = await repo.reviewPatientConflict(
        original.single['operation_id'] as String,
      );
      await repo.db.customStatement(
        "CREATE TRIGGER simulate_full_disk BEFORE INSERT ON sync_resolutions BEGIN SELECT RAISE(ABORT, 'simulated storage failure'); END",
      );
      await expectLater(
        repo.resolvePatientConflict(review, localFields: {'notes'}),
        throwsA(anything),
      );
      await repo.synchronize();
      expect(await repo.pendingOperations(), original);
      expect((await repo.patient('patient'))!.notes, 'Local notes');
      expect(await repo.patientRecoveryHistory(), isEmpty);
    },
  );
  test(
    'an uncertain request cannot be discarded or rewritten through conflict review',
    () async {
      final gateway = FakeGateway()..offline = true;
      final repo = ClinicRepository(
        db: ClinicDatabase.memory(),
        session: session(),
        gateway: gateway,
      );
      addTearDown(repo.close);
      await repo.savePatient(patient());
      await repo.synchronize();
      final operation = (await repo.pendingOperations()).single;
      gateway.offline = false;
      await expectLater(
        repo.reviewPatientConflict(operation['operation_id'] as String),
        throwsA(
          isA<ClinicFailure>().having((e) => e.code, 'code', 'review_changed'),
        ),
      );
      expect((await repo.pendingOperations()).single, operation);
    },
  );
  test(
    'successful sync applies server identity and removes only acknowledged operation',
    () async {
      final db = ClinicDatabase.memory(), gateway = FakeGateway();
      final offline = ClinicRepository(db: db, session: session());
      await offline.savePatient(patient());
      final repo = ClinicRepository(
        db: db,
        session: session(),
        gateway: gateway,
      );
      addTearDown(repo.close);
      final operation = (await repo.pendingOperations()).single['operation_id'];
      await repo.synchronize();
      expect(gateway.seen.single.operationId, operation);
      expect((await repo.patient('patient'))!.number, 'P-1');
      expect((await repo.syncSummary()).clean, isTrue);
    },
  );
}
