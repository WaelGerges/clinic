import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clinic_core/src/app.dart';
import 'package:clinic_core/src/data/database.dart';
import 'package:clinic_core/src/data/demo.dart';
import 'package:clinic_core/src/data/gateway.dart';
import 'package:clinic_core/src/data/repository.dart';
import 'package:clinic_core/src/domain/clinic_time.dart';
import 'package:clinic_core/src/domain/models.dart';
import 'package:clinic_core/src/features/audit/audit_screen.dart';
import 'package:clinic_core/src/features/auth/auth_screen.dart';
import 'package:clinic_core/src/presentation/common.dart';
import 'repository_test.dart' show FakeGateway, patientConflict;

class FakeAuditGateway extends FakeGateway
    implements ClinicAuditGateway, ClinicDeliveryGateway {
  List<ClinicAuditEvent> rows = [];
  ClinicFailure? failure;
  final requests = <({int offset, int limit})>[];
  DoctorDeliveryState delivery = DoctorDeliveryState(
    serverNow: DateTime.utc(2026, 8, 29, 12),
    doctorOnline: true,
    serviceAvailable: true,
    presenceExpiresAt: DateTime.utc(2026, 8, 29, 12, 1),
  );

  @override
  Future<List<ClinicAuditEvent>> auditEvents(
    String clinicId, {
    int offset = 0,
    int limit = 25,
  }) async {
    requests.add((offset: offset, limit: limit));
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    return rows.skip(offset).take(limit).toList(growable: false);
  }

  @override
  Future<DoctorDeliveryState> doctorHeartbeat(
    String clinicId,
    String deviceId,
  ) async => delivery;

  @override
  Future<DoctorDeliveryState> doctorDeliveryState(
    String clinicId,
    String doctorId, {
    String? appointmentId,
  }) async => delivery;

  @override
  Future<DoctorDeliveryState> acknowledgeAppointment(
    String clinicId,
    String appointmentId,
    String deviceId,
    String operationId,
    int expectedVersion,
  ) async {
    delivery = DoctorDeliveryState(
      serverNow: delivery.serverNow,
      doctorOnline: true,
      serviceAvailable: true,
      presenceExpiresAt: delivery.presenceExpiresAt,
      acknowledgedAt: DateTime.utc(2026, 8, 29, 12, 0, 10),
      appointmentVersion: expectedVersion,
    );
    return delivery;
  }
}

ClinicSession auditSession({bool isAdmin = true}) => ClinicSession(
  userId: '00000000-0000-0000-0000-000000000002',
  clinicId: '00000000-0000-0000-0000-000000000001',
  clinicName: 'Fictional Audit Clinic',
  role: ClinicRole.doctor,
  doctorId: '00000000-0000-0000-0000-000000000002',
  isAdmin: isAdmin,
);

ClinicAuditEvent auditEvent(int id) => ClinicAuditEvent.fromMap({
  'id': id,
  'clinic_id': '00000000-0000-0000-0000-000000000001',
  'actor_id': '00000000-0000-0000-0000-000000000002',
  'actor_role': 'doctor',
  'action': 'fictional.action.$id',
  'object_type': 'visit',
  'object_id': '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}',
  'occurred_at': DateTime.utc(2026, 8, 29, 12, id % 60).toIso8601String(),
  'previous_value': {'diagnosis': 'SENSITIVE-PREVIOUS'},
  'new_value': {'diagnosis': 'SENSITIVE-NEW'},
});

Patient deliveryPatient() => Patient(
  id: 'patient',
  clinicId: '00000000-0000-0000-0000-000000000001',
  name: 'Fictional Delivery Patient',
  gender: 'Female',
  birthDate: DateTime.utc(1990, 4, 12),
  mobile: '01000000000',
  number: 'P-1',
  createdAt: DateTime.utc(2026, 8, 29),
  updatedAt: DateTime.utc(2026, 8, 29),
);

Appointment deliveryAppointment() => Appointment(
  id: 'appointment',
  clinicId: '00000000-0000-0000-0000-000000000001',
  patientId: 'patient',
  doctorId: '00000000-0000-0000-0000-000000000002',
  startsAt: ClinicTime.at(DateTime.utc(2026, 8, 29), 12, 0),
  status: AppointmentStatus.withDoctor,
  version: 4,
);

Future<void> seedDeliveryCache(ClinicDatabase db) async {
  final patient = deliveryPatient().toMap()
    ..['mobile_digits'] = '01000000000'
    ..['archived'] = 0;
  await db.customStatement(
    'INSERT INTO cached_patients (${patient.keys.join(',')}) '
    'VALUES (${List.filled(patient.length, '?').join(',')})',
    patient.values.toList(),
  );
  final appointment = deliveryAppointment().toMap();
  await db.customStatement(
    'INSERT INTO cached_appointments (${appointment.keys.join(',')}) '
    'VALUES (${List.filled(appointment.length, '?').join(',')})',
    appointment.values.toList(),
  );
}

Future<void> loadScreenshotFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    const fontPath = String.fromEnvironment('SCREENSHOT_FONT');
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(await File(fontPath).readAsBytes()),
          ),
        );
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
}

void main() {
  testWidgets(
    'Doctor must explicitly acknowledge before opening consultation',
    (tester) async {
      final gateway = FakeAuditGateway();
      final db = ClinicDatabase.memory();
      final repository = ClinicRepository(
        db: db,
        session: auditSession(),
        gateway: gateway,
        deviceId: '00000000-0000-4000-8000-000000000001',
      );
      addTearDown(repository.close);
      await seedDeliveryCache(db);
      await tester.pumpWidget(
        ClinicApp(kind: AppKind.doctor, repository: repository),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acknowledge patient received'), findsOneWidget);
      expect(find.text('Open consultation'), findsNothing);
      await tester.tap(find.text('Acknowledge patient received'));
      await tester.pumpAndSettle();
      expect(find.text('Open consultation'), findsOneWidget);
      expect(find.textContaining('Receipt confirmed at'), findsOneWidget);
    },
  );

  testWidgets(
    'Assistant sees assignment and explicit receipt as separate states',
    (tester) async {
      final gateway = FakeAuditGateway();
      final db = ClinicDatabase.memory();
      final repository = ClinicRepository(
        db: db,
        session: const ClinicSession(
          userId: 'assistant',
          clinicId: '00000000-0000-0000-0000-000000000001',
          clinicName: 'Fictional Delivery Clinic',
          role: ClinicRole.assistant,
          doctorId: '00000000-0000-0000-0000-000000000002',
        ),
        gateway: gateway,
      );
      addTearDown(repository.close);
      await seedDeliveryCache(db);
      await tester.pumpWidget(
        ClinicApp(kind: AppKind.assistant, repository: repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Queue').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Awaiting explicit Doctor-device receipt'),
        findsOneWidget,
      );
      gateway.delivery = DoctorDeliveryState(
        serverNow: gateway.delivery.serverNow,
        doctorOnline: true,
        serviceAvailable: true,
        presenceExpiresAt: gateway.delivery.presenceExpiresAt,
        acknowledgedAt: DateTime.utc(2026, 8, 29, 12, 0, 10),
        appointmentVersion: 4,
      );
      repository.reportConnectionFailure();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Doctor receipt confirmed at'),
        findsOneWidget,
      );
    },
  );

  testWidgets('audit review rejects non-admin sessions before querying', (
    tester,
  ) async {
    final gateway = FakeAuditGateway();
    final repository = ClinicRepository(
      db: ClinicDatabase.memory(),
      session: auditSession(isAdmin: false),
      gateway: gateway,
    );
    addTearDown(repository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AuditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Online doctor administrator access required'),
      findsOneWidget,
    );
    expect(gateway.requests, isEmpty);
  });

  testWidgets('audit review paginates safe fields without clinical payloads', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = FakeAuditGateway()..rows = List.generate(26, auditEvent);
    final repository = ClinicRepository(
      db: ClinicDatabase.memory(),
      session: auditSession(),
      gateway: gateway,
    );
    addTearDown(repository.close);
    await tester.pumpWidget(
      ClinicApp(kind: AppKind.doctor, repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit and access'));
    await tester.pumpAndSettle();

    expect(find.text('fictional.action.0'), findsOneWidget);
    expect(find.text('SENSITIVE-PREVIOUS'), findsNothing);
    expect(find.text('SENSITIVE-NEW'), findsNothing);
    expect(find.textContaining('00000000…0002'), findsWidgets);
    expect(
      find.textContaining('00000000-0000-0000-0000-000000000002'),
      findsNothing,
    );
    expect(gateway.requests, [(offset: 0, limit: 25)]);

    await tester.scrollUntilVisible(
      find.text('Load older events'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Load older events'));
    await tester.pumpAndSettle();
    expect(find.text('fictional.action.25'), findsOneWidget);
    expect(gateway.requests, [(offset: 0, limit: 25), (offset: 25, limit: 25)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audit review exposes safe error, retry, and empty states', (
    tester,
  ) async {
    final gateway = FakeAuditGateway()
      ..failure = const ClinicFailure('unavailable', 'Safe audit failure.');
    final repository = ClinicRepository(
      db: ClinicDatabase.memory(),
      session: auditSession(),
      gateway: gateway,
    );
    addTearDown(repository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AuditScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load audit history'), findsOneWidget);
    expect(find.text('Safe audit failure.'), findsOneWidget);

    gateway.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No audit events yet'), findsOneWidget);
    expect(gateway.requests.length, 2);
  });

  test('auth callbacks are restricted to each app', () {
    expect(
      authRedirect(AppKind.assistant),
      'dev.homeversion.clinic.assistant://auth-callback/',
    );
    expect(
      authRedirect(AppKind.doctor),
      'dev.homeversion.clinic.doctor://auth-callback/',
    );
    expect(
      isPasswordRecoveryCallback(
        AppKind.assistant,
        Uri.parse(
          'dev.homeversion.clinic.assistant://auth-callback/?code=test-code',
        ),
      ),
      isTrue,
    );
    expect(
      isPasswordRecoveryCallback(
        AppKind.doctor,
        Uri.parse(
          'dev.homeversion.clinic.assistant://auth-callback/?code=test-code',
        ),
      ),
      isFalse,
    );
    expect(
      isPasswordRecoveryCallback(
        AppKind.assistant,
        Uri.parse('dev.homeversion.clinic.assistant://auth-callback/'),
      ),
      isFalse,
    );
  });

  test('each app says which one opens a membership it cannot open', () {
    // The clinic list shows every membership the account has, so a doctor
    // account signed into the Assistant App sees its clinic there. Tapping it
    // used to fail with the reason rendered below the fold; the row now
    // carries the reason and refuses the tap.
    expect(clinicRoleMismatch(AppKind.assistant, 'assistant'), isNull);
    expect(clinicRoleMismatch(AppKind.doctor, 'doctor'), isNull);
    expect(
      clinicRoleMismatch(AppKind.assistant, 'doctor'),
      'Use the Doctor App for this clinic role.',
    );
    expect(
      clinicRoleMismatch(AppKind.doctor, 'assistant'),
      'Use the Assistant App for this clinic role.',
    );
    // An unrecognised role is refused rather than opened.
    for (final kind in AppKind.values) {
      expect(clinicRoleMismatch(kind, 'auditor'), isNotNull);
    }
  });

  testWidgets('password recovery validates and submits the replacement', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordRecoveryPanel(
            busy: false,
            onSubmit: (value) async => submitted = value,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('recovery-password')),
      'long-enough-password',
    );
    await tester.enterText(
      find.byKey(const Key('recovery-confirmation')),
      'different-password',
    );
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(submitted, isNull);

    await tester.enterText(
      find.byKey(const Key('recovery-confirmation')),
      'long-enough-password',
    );
    await tester.tap(find.text('Update password'));
    await tester.pump();
    expect(submitted, 'long-enough-password');
  });

  testWidgets('phone home supports large accessibility text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = await createDemoRepository(AppKind.assistant);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
    });
    await tester.pumpWidget(
      ClinicApp(kind: AppKind.assistant, repository: repo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
  for (final kind in AppKind.values) {
    testWidgets('${kind.name} phone layout and patient navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = await createDemoRepository(kind);
      await tester.pumpWidget(ClinicApp(kind: kind, repository: repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('LOCAL PREVIEW'), findsOneWidget);
      expect(find.text('Ahmed Ali'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.text(kind == AppKind.doctor ? 'Records' : 'Patients').last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sara Hassan'), findsOneWidget);
      await tester.tap(find.text('Sara Hassan'));
      await tester.pumpAndSettle();
      expect(find.text('Patient record'), findsOneWidget);
      if (kind == AppKind.assistant) {
        await tester.tap(find.text('Visits'));
        await tester.pumpAndSettle();
        expect(find.text('Clinical access restricted'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await repo.close();
    });
  }
  testWidgets(
    'doctor can open the append only completed visit amendment form',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = await createDemoRepository(AppKind.doctor);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
      });
      await tester.pumpWidget(
        ClinicApp(kind: AppKind.doctor, repository: repo),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Records').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahmed Ali').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visits'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Completed · revision 1'), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Amend visit'));
      await tester.tap(find.text('Amend visit'));
      await tester.pumpAndSettle();
      expect(find.text('Amend completed visit'), findsOneWidget);
      expect(find.text('Reason for amendment'), findsOneWidget);
      expect(find.text('Submit amendment'), findsOneWidget);
      expect(
        find.textContaining('Submitting creates revision 2'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('tablet layout uses navigation rail and supports scaled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = await createDemoRepository(AppKind.doctor);
    await tester.pumpWidget(ClinicApp(kind: AppKind.doctor, repository: repo));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await repo.close();
  });
  testWidgets(
    'patient conflict review and encrypted history work on a phone with scaled text',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = await patientConflict(), repo = fixture.repo;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repo.close();
      });
      const export = bool.fromEnvironment('EXPORT_SCREENSHOTS');
      if (export) await loadScreenshotFonts(tester);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: ClinicApp(kind: AppKind.assistant, repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('patient · save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('patient · save'));
      await tester.pumpAndSettle();
      expect(find.text('Patient changes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (export) {
        final rendered =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final directory = await Directory(
            'test-artifacts',
          ).create(recursive: true);
          final image = await rendered.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/assistant-patient-conflict.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.scrollUntilVisible(
        find.text('Keep server version'),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The doctor controls medical alerts'),
        findsOneWidget,
      );
      expect(find.text('Use this device’s medical alerts'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Keep server version'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep server version').last);
      await tester.pumpAndSettle();
      expect(await repo.pendingOperations(), isEmpty);
      await tester.ensureVisible(find.text('Recovery history'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recovery history'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kept server version'), findsOneWidget);
      await tester.tap(find.text('Test Patient').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Original device: Local notes'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Server at review: Server notes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'export fictional implemented screens when explicitly requested',
    (tester) async {
      const enabled = bool.fromEnvironment('EXPORT_SCREENSHOTS');
      if (!enabled) return;
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final directory = Directory('test-artifacts');
      await tester.runAsync(() async {
        await directory.create(recursive: true);
      });
      // Test-only host font. No system font is copied into the app or repo.
      await loadScreenshotFonts(tester);
      for (final kind in AppKind.values) {
        for (final dark in [false, true]) {
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          final repo = await createDemoRepository(kind);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: ClinicApp(kind: kind, repository: repo),
            ),
          );
          await tester.pumpAndSettle();
          final rendered =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          Future<void> capture(String name) async {
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.runAsync(() async {
              final image = await rendered.toImage(pixelRatio: 2);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '${directory.path}/$name.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }

          await capture('${kind.name}-${dark ? 'dark' : 'light'}');
          if (!dark) {
            if (kind == AppKind.assistant) {
              for (final label in ['Patients', 'Schedule', 'Queue']) {
                await tester.tap(find.text(label).last);
                await capture('assistant-${label.toLowerCase()}');
              }
            } else {
              await tester.tap(find.text('Open consultation'));
              await capture('doctor-consultation');
              await tester.pageBack();
              await tester.pumpAndSettle();
              await tester.tap(find.text('Medical history and patient record'));
              await capture('doctor-patient-profile');
              await tester.tap(find.text('Visits'));
              await capture('doctor-history');
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await repo.close();
        }
      }
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    },
  );
}
