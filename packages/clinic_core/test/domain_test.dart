import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_core/src/data/access_lease.dart';
import 'package:clinic_core/src/data/device_presence.dart';
import 'package:clinic_core/src/data/gateway.dart';
import 'package:clinic_core/src/domain/models.dart';
import 'package:clinic_core/src/domain/clinic_time.dart';

Patient example({DateTime? birthDate}) => Patient(
  id: 'p1',
  clinicId: 'c1',
  name: 'Test Patient',
  gender: 'Female',
  birthDate: birthDate ?? DateTime.utc(2000, 8, 29),
  mobile: '01000000000',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class MemorySecureValueStore implements ClinicSecureValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

ClinicSession assistantSession() => const ClinicSession(
  userId: 'user-1',
  clinicId: 'clinic-1',
  clinicName: 'Fictional Clinic',
  role: ClinicRole.assistant,
  doctorId: 'doctor-1',
  canReadClinical: true,
);

void main() {
  test('doctor device identity is protected, canonical, and stable', () async {
    final storage = MemorySecureValueStore();
    final store = DoctorDeviceIdentityStore(
      projectRef: 'test-project',
      storage: storage,
    );
    final first = await store.readOrCreate();
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(await store.readOrCreate(), first);
    storage.values[storage.values.keys.single] = 'not-a-device-id';
    expect(await store.readOrCreate(), isNot(first));
  });

  test('doctor delivery state validates server time and receipt fields', () {
    final state = DoctorDeliveryState.fromMap({
      'server_now': '2026-08-29T12:00:00Z',
      'doctor_online': true,
      'presence_expires_at': '2026-08-29T12:01:00Z',
      'acknowledged_at': '2026-08-29T12:00:10Z',
      'appointment_version': 4,
    });
    expect(state.acknowledged, isTrue);
    expect(state.appointmentVersion, 4);
    expect(
      () => DoctorDeliveryState.fromMap({
        'server_now': 'invalid',
        'doctor_online': true,
      }),
      throwsFormatException,
    );
  });

  test(
    'audit parsing ignores clinical payloads and identifiers are compact',
    () {
      final event = ClinicAuditEvent.fromMap({
        'id': 42,
        'clinic_id': '00000000-0000-0000-0000-000000000001',
        'actor_id': '00000000-0000-0000-0000-000000000002',
        'actor_role': 'doctor',
        'action': 'visit.amend',
        'object_type': 'visit',
        'object_id': '00000000-0000-0000-0000-000000000003',
        'occurred_at': '2026-08-29T12:00:00Z',
        'previous_value': {'diagnosis': 'SENSITIVE-PREVIOUS'},
        'new_value': {'diagnosis': 'SENSITIVE-NEW'},
      });
      expect(event.action, 'visit.amend');
      expect(compactAuditIdentifier(event.actorId), '00000000…0002');
      expect(clinicAuditSafeColumns, isNot(contains('previous_value')));
      expect(clinicAuditSafeColumns, isNot(contains('new_value')));
    },
  );

  test('offline access lease expires and rejects clock rollback', () async {
    var now = DateTime.utc(2026, 8, 29, 8);
    final storage = MemorySecureValueStore();
    final store = ClinicAccessLeaseStore(
      projectRef: 'test-project',
      kind: AppKind.assistant,
      storage: storage,
      clock: () => now,
    );
    final issued = await store.issue(assistantSession());
    expect(issued.expiresAt, DateTime.utc(2026, 8, 29, 16));
    now = DateTime.utc(2026, 8, 29, 9);
    expect((await store.readValid('user-1'))?.session.clinicId, 'clinic-1');

    now = DateTime.utc(2026, 8, 29, 8, 50);
    expect(await store.readValid('user-1'), isNull);
    expect(storage.values, isEmpty);
  });

  test('offline access lease fails closed on expiry and tampering', () async {
    var now = DateTime.utc(2026, 8, 29, 8);
    final storage = MemorySecureValueStore();
    final store = ClinicAccessLeaseStore(
      projectRef: 'test-project',
      kind: AppKind.assistant,
      storage: storage,
      clock: () => now,
    );
    await store.issue(assistantSession());
    now = DateTime.utc(2026, 8, 29, 16);
    expect(await store.readValid('user-1'), isNull);

    now = DateTime.utc(2026, 8, 29, 8);
    await store.issue(assistantSession());
    final key = storage.values.keys.single;
    final payload = jsonDecode(storage.values[key]!) as Map<String, dynamic>;
    payload['expires_at'] = DateTime.utc(2026, 8, 30).toIso8601String();
    storage.values[key] = jsonEncode(payload);
    expect(await store.readValid('user-1'), isNull);
    await expectLater(
      ClinicAccessLeaseStore(
        projectRef: 'test-project',
        kind: AppKind.doctor,
        storage: storage,
        clock: () => now,
      ).issue(assistantSession()),
      throwsA(isA<ClinicFailure>()),
    );
  });

  test(
    'Cairo appointment conversion uses clinic DST independently of the device zone',
    () {
      expect(
        ClinicTime.at(DateTime.utc(2026, 1, 1), 9, 0),
        DateTime.utc(2026, 1, 1, 7),
      );
      expect(
        ClinicTime.at(DateTime.utc(2026, 7, 1), 9, 0),
        DateTime.utc(2026, 7, 1, 6),
      );
      expect(ClinicTime.local(DateTime.utc(2026, 7, 1, 22)).day, 2);
      expect(
        () => ClinicTime.at(DateTime.utc(2026, 4, 24), 0, 30),
        throwsA(isA<ClinicFailure>()),
      );
    },
  );
  test('age uses calendar birthday, not an approximate duration', () {
    expect(example().ageAt(DateTime(2026, 8, 28)), 25);
    expect(example().ageAt(DateTime(2026, 8, 29)), 26);
    expect(
      example(
        birthDate: DateTime.utc(2024, 2, 29),
      ).ageAt(DateTime(2025, 2, 28)),
      0,
    );
  });
  test('birth dates reject normalization of impossible dates', () {
    expect(parseBirthDate('2026-02-31'), isNull);
    expect(parseBirthDate('2024-02-29'), DateTime.utc(2024, 2, 29));
    expect(parseBirthDate('2026-2-03'), isNull);
  });
  test('phone normalization supports Arabic and Persian digits', () {
    expect(normalizePhone('+20 ١٠-۱۲۳۴۵۶۷۸'), '201012345678');
  });
  test('future birth dates are rejected', () {
    expect(
      () => example(
        birthDate: DateTime.utc(2030),
      ).validate(DateTime(2026, 8, 28)),
      throwsA(isA<ClinicFailure>()),
    );
  });
  test(
    'appointment workflow rejects reopening terminal states and skipping queue',
    () {
      requireTransition(AppointmentStatus.arrived, AppointmentStatus.waiting);
      expect(
        () => requireTransition(
          AppointmentStatus.scheduled,
          AppointmentStatus.withDoctor,
        ),
        throwsA(isA<ClinicFailure>()),
      );
      expect(
        () => requireTransition(
          AppointmentStatus.completed,
          AppointmentStatus.waiting,
        ),
        throwsA(isA<ClinicFailure>()),
      );
    },
  );
  test('visit keeps immutable medication and diagnosis collections', () {
    final input = ['Test'];
    final visit = Visit(
      id: 'v',
      clinicId: 'c',
      patientId: 'p',
      appointmentId: 'a',
      doctorId: 'd',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      diagnoses: input,
    );
    input.clear();
    expect(visit.diagnoses, ['Test']);
    expect(() => visit.diagnoses.add('Changed'), throwsUnsupportedError);
    visit.validateForCompletion();
    expect(
      () => visit.copyWith(diagnoses: []).validateForCompletion(),
      throwsA(isA<ClinicFailure>()),
    );
    final completed = visit.copyWith(
      completed: true,
      version: 3,
      currentRevision: 2,
    );
    completed.validateAmendment('Correct a fictional transcription error.');
    expect(completed.toMap()['current_revision'], 2);
    expect(
      () => completed.validateAmendment('short'),
      throwsA(isA<ClinicFailure>()),
    );
    expect(
      () => visit.validateAmendment('Correct a fictional transcription error.'),
      throwsA(isA<ClinicFailure>()),
    );
  });
}
