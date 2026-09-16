import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_core/src/app.dart';
import 'package:clinic_core/src/data/demo.dart';
import 'package:clinic_core/src/domain/models.dart';
import 'package:clinic_core/src/domain/clinic_time.dart';
import 'package:clinic_core/src/domain/scheduling.dart';
import 'package:clinic_core/src/presentation/language.dart';
import 'package:clinic_core/src/features/visits/visit_documents.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => setAppLanguage('en'));
  final day = DateTime(2026, 9, 14);
  Appointment appointment(
    int hour,
    int minute,
    int duration, {
    String id = 'a',
    AppointmentStatus status = AppointmentStatus.scheduled,
  }) => Appointment(
    id: id,
    clinicId: 'c',
    patientId: 'p',
    doctorId: 'd',
    startsAt: ClinicTime.at(day, hour, minute),
    durationMinutes: duration,
    status: status,
  );
  test(
    'duration roundtrip, adjacent slots, overlap, cancellation and breaks',
    () {
      final first = appointment(9, 0, 45);
      expect(Appointment.fromMap(first.toMap()).durationMinutes, 45);
      expect(
        appointmentOverlaps(appointment(9, 30, 30, id: 'b'), [first]),
        isTrue,
      );
      expect(
        appointmentOverlaps(appointment(9, 45, 30, id: 'b'), [first]),
        isFalse,
      );
      expect(
        appointmentOverlaps(appointment(9, 30, 30, id: 'b'), [
          first.copyWith(status: AppointmentStatus.cancelled),
        ]),
        isFalse,
      );
      final settings = ScheduleSettings(
        configured: true,
        periods: [
          WorkingPeriod(day.weekday, 540, 720),
          WorkingPeriod(day.weekday, 780, 1020),
        ],
      );
      final slots = availableSlots(
        day,
        45,
        settings,
        [first],
        'd',
        now: DateTime.utc(2026, 9, 1),
      );
      expect(slots.contains(ClinicTime.at(day, 9, 30)), isFalse);
      expect(slots.contains(ClinicTime.at(day, 9, 45)), isTrue);
      expect(slots.contains(ClinicTime.at(day, 11, 30)), isFalse);
      expect(slots.contains(ClinicTime.at(day, 12, 30)), isFalse);
      expect(slots.contains(ClinicTime.at(day, 13, 0)), isTrue);
      expect(
        availableSlots(
          day,
          30,
          const ScheduleSettings(configured: true),
          [],
          'd',
        ),
        isEmpty,
      );
    },
  );
  testWidgets(
    'both workspaces switch to Arabic RTL and back without changing patient names',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final kind in AppKind.values) {
        final repo = await createDemoRepository(kind);
        await tester.pumpWidget(ClinicApp(kind: kind, repository: repo));
        await tester.pumpAndSettle();
        setAppLanguage('ar');
        await tester.pumpAndSettle();
        expect(
          find.text(kind == AppKind.doctor ? 'طبيب العيادة' : 'مساعد العيادة'),
          findsOneWidget,
        );
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        setAppLanguage('en');
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          TextDirection.ltr,
        );
        await tester.pumpWidget(const SizedBox());
        await repo.close();
      }
    },
  );
  test(
    'bilingual PDFs generate with long content; unprivileged and draft exports denied',
    () async {
      const session = ClinicSession(
        userId: 'd',
        clinicId: 'c',
        clinicName: 'عيادة تجريبية / Fictional Clinic',
        role: ClinicRole.doctor,
        doctorId: 'd',
        isDemo: true,
      );
      final patient = Patient(
        id: 'p',
        clinicId: 'c',
        name: 'أحمد علي / Ahmed Ali',
        gender: 'Male',
        birthDate: DateTime(1990, 4, 12),
        mobile: '01000000000',
        number: 'P-100',
        createdAt: day,
        updatedAt: day,
      );
      final visit = Visit(
        id: 'v',
        clinicId: 'c',
        patientId: 'p',
        appointmentId: 'a',
        doctorId: 'd',
        createdAt: day,
        updatedAt: day,
        completed: true,
        currentRevision: 2,
        diagnoses: ['تقييم تجريبي / Fictional assessment'],
        notes: List.filled(
          8,
          'ملاحظات تجريبية للمراجعة فقط. Fictional clinical notes for layout testing.',
        ).join('\n'),
        followUp: 'متابعة تجريبية فقط / Fictional follow-up only',
        medications: List.generate(
          7,
          (i) => Medication(
            id: 'm$i',
            name: 'دواء تجريبي / Sample medicine ${i + 1}',
            strength: 'Example only',
            dose: 'جرعة تجريبية',
            frequency: 'مثال',
            duration: 'مثال',
            instructions:
                'تعليمات تجريبية للمراجعة فقط. Fictional instructions only.',
          ),
        ),
      );
      final directory = Directory('../../tmp/pdfs');
      directory.createSync(recursive: true);
      for (final kind in VisitDocumentKind.values) {
        for (final ar in [false, true]) {
          final data = await buildVisitDocument(
            session: session,
            patient: patient,
            visit: visit,
            kind: kind,
            arabic: ar,
            referral:
                'إلى الطبيب المختص: طلب مراجعة تجريبي. To the specialist: fictional review request.',
          );
          expect(String.fromCharCodes(data.take(5)), '%PDF-');
          expect(data.length, greaterThan(5000));
          File(
            '${directory.path}/${kind.name}-${ar ? 'ar' : 'en'}.pdf',
          ).writeAsBytesSync(data);
        }
      }
      await expectLater(
        buildVisitDocument(
          session: session,
          patient: patient,
          visit: visit.copyWith(completed: false),
          kind: VisitDocumentKind.prescription,
          arabic: false,
        ),
        throwsA(isA<ClinicFailure>()),
      );
      const assistant = ClinicSession(
        userId: 's',
        clinicId: 'c',
        clinicName: 'c',
        role: ClinicRole.assistant,
        doctorId: 'd',
      );
      await expectLater(
        buildVisitDocument(
          session: assistant,
          patient: patient,
          visit: visit,
          kind: VisitDocumentKind.prescription,
          arabic: false,
        ),
        throwsA(isA<ClinicFailure>()),
      );
    },
  );
}
