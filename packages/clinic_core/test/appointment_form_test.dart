import 'package:clinic_core/src/data/demo.dart';
import 'package:clinic_core/src/domain/models.dart';
import 'package:clinic_core/src/features/appointments/appointment_screen.dart';
import 'package:clinic_core/src/presentation/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final search = find.byKey(const Key('appointment-patient-search'));
  final selected = find.byKey(const Key('appointment-selected-patient'));

  Future<void> pumpForm(
    WidgetTester tester,
    AppointmentFormScreen form,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await createDemoRepository(AppKind.assistant);
    addTearDown(repo.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: form),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('choosing a patient replaces the search and the list', (
    tester,
  ) async {
    await pumpForm(tester, const AppointmentFormScreen());
    expect(search, findsOneWidget);
    final choices = find.byType(RadioListTile<String>);
    expect(choices, findsWidgets);
    final name =
        ((tester.widget<RadioListTile<String>>(choices.first).title!) as Text)
            .data!;

    await tester.tap(choices.first);
    await tester.pumpAndSettle();

    expect(search, findsNothing);
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(selected, findsOneWidget);
    expect(
      find.descendant(of: selected, matching: find.text(name)),
      findsOneWidget,
    );

    await tester.tap(find.text('Change patient'));
    await tester.pumpAndSettle();
    expect(search, findsOneWidget);
    expect(selected, findsNothing);
  });

  testWidgets('a form opened for a patient shows only that patient', (
    tester,
  ) async {
    final repo = await createDemoRepository(AppKind.assistant);
    final patient = (await repo.patients()).first;
    await repo.close();

    await pumpForm(tester, AppointmentFormScreen(patientId: patient.id));
    expect(search, findsNothing);
    expect(find.byType(RadioListTile<String>), findsNothing);
    expect(
      find.descendant(of: selected, matching: find.text(patient.name)),
      findsOneWidget,
    );
  });
}
