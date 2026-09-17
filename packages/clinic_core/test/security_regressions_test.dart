// Regression tests from the 2026-09-17 security and reliability assessment
// (docs/reviews/2026-09-17-security-assessment.md).
//
//  BUG-001  An appointment or visit conflict blocked the outbox forever.
//  BUG-002  Transient server errors were recorded as permanent rejections.
//  SEC-001  Client-side bounds that mirror the new server constraints.
import 'dart:convert';

import 'package:clinic_core/src/data/database.dart';
import 'package:clinic_core/src/data/gateway.dart';
import 'package:clinic_core/src/data/repository.dart';
import 'package:clinic_core/src/data/supabase_gateway.dart';
import 'package:clinic_core/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repository_test.dart' show FakeGateway;

const _session = ClinicSession(
  userId: 'assistant',
  clinicId: 'clinic',
  clinicName: 'Fictional Clinic',
  role: ClinicRole.assistant,
  doctorId: 'doctor',
);

Patient _patient() => Patient(
  id: 'patient',
  clinicId: 'clinic',
  name: 'Test Patient',
  gender: 'Female',
  birthDate: DateTime.utc(2000, 1, 1),
  mobile: '01000000000',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  version: 1,
);

Appointment _appointment({int version = 0, String notes = ''}) => Appointment(
  id: 'appointment',
  clinicId: 'clinic',
  patientId: 'patient',
  doctorId: 'doctor',
  startsAt: DateTime.utc(2026, 9, 17, 9),
  version: version,
  notes: notes,
);

void main() {
  group('BUG-001 conflict discard', () {
    test(
      'a conflicting appointment save can be discarded, unblocks the queue, '
      'restores the server row and keeps the local content as evidence',
      () async {
        final gateway = FakeGateway();
        final repo = ClinicRepository(
          db: ClinicDatabase.memory(),
          session: _session,
          gateway: gateway,
        );
        addTearDown(repo.close);
        final server = _appointment(version: 7, notes: 'Server notes');
        gateway.bookings = [server];
        gateway.handler = (command) async {
          if (command.entityType == 'appointment') {
            throw SyncConflict(server.toMap());
          }
          return CommandReceipt({
            ...command.payload,
            'version': command.expectedVersion + 1,
          }, command.expectedVersion + 1);
        };
        // The patient syncs cleanly; only the appointment conflicts.
        await repo.savePatient(_patient());
        await repo.synchronize();
        expect((await repo.syncSummary()).clean, isTrue);

        await repo.saveAppointment(_appointment(notes: 'Local notes'));
        await repo.synchronize();
        final conflict = (await repo.pendingOperations()).single;
        expect(conflict['state'], 'conflict');
        expect(ClinicRepository.isDiscardable(conflict), isTrue);

        // A later, unrelated request is blocked behind the conflict.
        final cached = (await repo.patient('patient'))!;
        await repo.savePatient(cached.copyWith(notes: 'Queued behind'));
        await repo.synchronize();
        expect((await repo.syncSummary()).pending, 1);

        await repo.discardRejectedOperation(conflict['operation_id'] as String);
        await repo.synchronize();

        expect((await repo.syncSummary()).clean, isTrue);
        final restored = await repo.appointment('appointment');
        expect(restored!.version, 7);
        expect(restored.notes, 'Server notes');
        final evidence = await repo.db
            .customSelect(
              "SELECT choice,local_value,remote_value FROM sync_resolutions WHERE entity_id='appointment'",
            )
            .get();
        expect(evidence.single.data['choice'], 'discard:appointment');
        expect(
          jsonDecode(evidence.single.data['local_value'] as String),
          containsPair('notes', 'Local notes'),
        );
        expect(
          jsonDecode(evidence.single.data['remote_value'] as String),
          containsPair('notes', 'Server notes'),
        );
        // The evidence row is not mistaken for a patient recovery entry.
        expect(await repo.patientRecoveryHistory(), isEmpty);
      },
    );

    test('patient conflicts keep the merge review and are not discardable', () {
      expect(
        ClinicRepository.isDiscardable({
          'state': 'conflict',
          'entity_type': 'patient',
        }),
        isFalse,
      );
      expect(
        ClinicRepository.isDiscardable({
          'state': 'conflict',
          'entity_type': 'visit',
        }),
        isTrue,
      );
      for (final state in ['pending', 'sending']) {
        expect(
          ClinicRepository.isDiscardable({
            'state': state,
            'entity_type': 'appointment',
          }),
          isFalse,
          reason: 'a $state request may already have reached the server',
        );
      }
    });
  });

  group('BUG-002 transient server errors', () {
    test('retryable SQLSTATE and PostgREST codes are recognised', () {
      for (final code in [
        '40001', // serialization_failure
        '40P01', // deadlock_detected
        '55P03', // lock_not_available
        '57014', // query_canceled (statement_timeout)
        '57P01', // admin_shutdown
        '53300', // too_many_connections
        '08006', // connection_failure
        'PGRST001',
        'PGRST003',
      ]) {
        expect(isTransientPostgrestCode(code), isTrue, reason: code);
      }
    });

    test('verdicts on the request itself are not retried', () {
      for (final code in [
        '42501', // insufficient_privilege
        '23505', // unique_violation
        '23514', // check_violation
        '22007', // invalid_datetime_format
        'PGRST202', // function not found
        'PGRST205', // table not found
        'P0001', // raise_exception (domain errors)
        null,
      ]) {
        expect(isTransientPostgrestCode(code), isFalse, reason: '$code');
      }
    });
  });

  group('SEC-001 client-side bounds mirror the server', () {
    final today = DateTime.utc(2026, 9, 17);
    test('patient text fields are capped', () {
      expect(() => _patient().validate(today), returnsNormally);
      for (final oversized in [
        _patient().copyWith(notes: 'n' * (Patient.maxNotesLength + 1)),
        _patient().copyWith(alerts: 'a' * (Patient.maxAlertsLength + 1)),
        _patient().copyWith(address: 'a' * (Patient.maxAddressLength + 1)),
        _patient().copyWith(
          secondaryMobile: '1' * (Patient.maxSecondaryMobileLength + 1),
        ),
        _patient().copyWith(name: 'n' * (Patient.maxNameLength + 1)),
      ]) {
        expect(
          () => oversized.validate(today),
          throwsA(
            isA<ClinicFailure>().having((f) => f.code, 'code', 'validation'),
          ),
        );
      }
      expect(
        () => _patient()
            .copyWith(notes: 'n' * Patient.maxNotesLength)
            .validate(today),
        returnsNormally,
      );
    });

    test('appointment type and notes are capped', () {
      expect(() => _appointment().validate(), returnsNormally);
      expect(
        () => _appointment(
          notes: 'n' * (Appointment.maxNotesLength + 1),
        ).validate(),
        throwsA(isA<ClinicFailure>()),
      );
      expect(
        () => Appointment(
          id: 'a',
          clinicId: 'clinic',
          patientId: 'patient',
          doctorId: 'doctor',
          startsAt: DateTime.utc(2026),
          type: '',
        ).validate(),
        throwsA(isA<ClinicFailure>()),
      );
    });

    test('document notes are capped', () {
      ClinicDocument document(String notes) => ClinicDocument(
        id: 'd',
        clinicId: 'clinic',
        patientId: 'patient',
        fileName: 'report.pdf',
        contentType: 'application/pdf',
        category: ClinicDocumentCategory.other,
        objectPath: 'clinic/patient/d',
        bytes: 10,
        sha256Hex: 'ab' * 32,
        clinical: false,
        state: 'pending',
        uploadedBy: 'assistant',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        notes: notes,
      );
      expect(
        () => document('n' * ClinicDocument.maxNotesLength).validate(),
        returnsNormally,
      );
      expect(
        () => document('n' * (ClinicDocument.maxNotesLength + 1)).validate(),
        throwsA(isA<ClinicFailure>()),
      );
    });
  });
}
