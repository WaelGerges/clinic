// Guards the ways the interface leaked English, or blanked out entirely,
// while the app was in Arabic:
//
//  1. `DateFormat` throws `LocaleDataException` unless the intl symbols for
//     the active locale were loaded, so every screen showing a date or a time
//     lost its content the moment the language became Arabic.
//  2. Literals rendered verbatim instead of through `tr()`, the bottom
//     navigation bar among them.
//  3. Sentences that reach `tr()` indirectly - through a server error table, a
//     ternary behind `success:`, or a `warning` field - and so are invisible to
//     the call-site scanner in translation_coverage_test.dart.
import 'dart:io';

import 'package:clinic_core/src/app.dart';
import 'package:clinic_core/src/data/demo.dart';
import 'package:clinic_core/src/domain/models.dart';
import 'package:clinic_core/src/presentation/arabic.dart';
import 'package:clinic_core/src/presentation/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Sinks that render their argument verbatim. `SectionCard`, `EmptyPanel` and
/// `MedicalAlert` are deliberately absent: they call `tr()` themselves.
const _verbatimSinks = [
  'label',
  'labelText',
  'hintText',
  'helperText',
  'tooltip',
  'semanticsLabel',
  'errorText',
  'prefixText',
  'suffixText',
];

/// Single- or double-quoted Dart string literal on one line.
final _literal = RegExp(
  "'((?:[^'\\\\\\n]|\\\\.)*)'" r'|"((?:[^"\\\n]|\\.)*)"',
);

/// `DateFormat` skeletons and SQL pragmas read as prose but are neither.
final _notProse = RegExp(
  "DateFormat\\s*\\(\\s*(?:'[^']*'|\"[^\"]*\")" r'|PRAGMA[^' "'" r'"]*',
);

/// SQL kept inline in the data layer, never shown to anyone.
const _sqlKeywords = [
  'SELECT ',
  'INSERT ',
  'UPDATE ',
  'DELETE ',
  'CREATE ',
  'DROP ',
  'ALTER ',
  'PRAGMA ',
];

String _unescape(String v) => v
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\n', '\n');

Iterable<File> _sources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => setAppLanguage('en'));

  test('every date and time pattern in the apps formats in Arabic', () async {
    await loadClinicDateSymbols();
    setAppLanguage('ar');
    final when = DateTime(2026, 9, 12, 14, 5);
    for (final format in [
      DateFormat('EEEE, d MMMM'),
      DateFormat('d MMM, HH:mm'),
      DateFormat('d MMM y, HH:mm'),
      DateFormat.yMMMd(),
      DateFormat.yMMMMd(),
      DateFormat.yMMMMEEEEd(),
      DateFormat.Hm(),
      DateFormat.yMMMd().add_Hm(),
    ]) {
      final text = format.format(when);
      expect(text, isNotEmpty);
      expect(
        RegExp(r'[A-Za-z]').hasMatch(text),
        isFalse,
        reason: '"${format.pattern}" still formats in English: $text',
      );
      // intl's 'ar' renders month names in Arabic but keeps 0-9, which is
      // what the rest of the interface uses. Guard that, so a locale change
      // to ar_EG (which emits ٠-٩) cannot silently mix numerals on screen.
      expect(
        RegExp('[٠-٩]').hasMatch(text),
        isFalse,
        reason: '"${format.pattern}" mixes Arabic-Indic digits into the UI',
      );
    }
  });

  testWidgets('the bottom navigation bar of both apps is translated', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await loadClinicDateSymbols();
    const expected = {
      AppKind.assistant: ['الرئيسية', 'المرضى', 'المواعيد', 'الانتظار'],
      AppKind.doctor: ['الحالي', 'السجلات'],
    };
    for (final kind in AppKind.values) {
      final repo = await createDemoRepository(kind);
      await tester.pumpWidget(ClinicApp(kind: kind, repository: repo));
      await tester.pumpAndSettle();
      setAppLanguage('ar');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final bar = find.byType(NavigationBar);
      expect(bar, findsOneWidget);
      for (final label in [...expected[kind]!, 'المزيد']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
          reason: '${kind.name} navigation bar is missing "$label"',
        );
      }
      for (final label in ['Home', 'Patients', 'Queue', 'Current', 'More']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsNothing,
          reason: '${kind.name} navigation bar still shows "$label"',
        );
      }
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    }
  });

  test('user-visible literals are passed through tr()', () {
    expect(
      Directory('lib').existsSync(),
      isTrue,
      reason: 'run this test from packages/clinic_core',
    );

    // A quoted string, optionally preceded by `const` and by a `Text(`
    // wrapper for the sinks that take a widget rather than a string.
    final argument = RegExp(
      '^(?:const\\s+)?(?:Text\\s*\\(\\s*)?(?:const\\s+)?(?:${_literal.pattern})',
    );
    final patterns = <String, RegExp>{
      'Text': RegExp(r'\bText\s*\(\s*'),
      for (final sink in _verbatimSinks) sink: RegExp('\\b$sink\\s*:\\s*'),
    };

    final untranslated = <String>[];
    for (final file in _sources()) {
      final name = file.path.replaceAll(r'\', '/');
      // The dictionary itself, and the picker that names each language in
      // that language, are deliberately not translated.
      if (name.endsWith('presentation/arabic.dart') ||
          name.endsWith('presentation/language.dart')) {
        continue;
      }
      final src = file.readAsStringSync();
      for (final entry in patterns.entries) {
        for (final match in entry.value.allMatches(src)) {
          final found = argument.firstMatch(src.substring(match.end));
          if (found == null) continue;
          final text = found.group(1) ?? found.group(2)!;
          if (!RegExp(r'[A-Za-z]{2}').hasMatch(text)) continue;
          final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
          untranslated.add('$name:$line ${entry.key}: $text');
        }
      }
    }

    expect(
      untranslated..sort(),
      isEmpty,
      reason:
          'These literals are rendered verbatim instead of through tr(), so '
          'they stay in English while the app is in Arabic:\n  '
          '${untranslated.join('\n  ')}',
    );
  });

  test('every English sentence in lib/ is translated or declared internal', () {
    expect(
      Directory('lib').existsSync(),
      isTrue,
      reason: 'run this test from packages/clinic_core',
    );

    // demo.dart holds fictional patient records, and visit_documents.dart
    // pairs every PDF string with its own Arabic half through label().
    const skipFiles = [
      'data/demo.dart',
      'features/visits/visit_documents.dart',
      'presentation/arabic.dart',
      'presentation/language.dart',
    ];
    // Programmer-facing text that never reaches safeError() or tr().
    const internalOnly = {
      'Encrypted SQLite is unavailable. Refusing to open medical data.',
      'Invalid clinic audit event',
      'Invalid doctor delivery state',
      'Clinic session required',
    };

    final untranslated = <String>[];
    for (final file in _sources()) {
      final name = file.path.replaceAll(r'\', '/');
      if (skipFiles.any(name.endsWith)) continue;
      final src = file.readAsStringSync().replaceAllMapped(
        _notProse,
        (m) => ' ' * m.group(0)!.length,
      );
      for (final match in _literal.allMatches(src)) {
        final text = _unescape(match.group(1) ?? match.group(2)!);
        // Sentence-shaped: opens like a sentence, holds more than one word,
        // and is long enough not to be an identifier, a code or a column name.
        if (!RegExp(r'^[A-Z]').hasMatch(text)) continue;
        if (!text.contains(' ') || text.length < 12) continue;
        if (RegExp(r'[<>{}=|;]').hasMatch(text)) continue;
        if (text.contains(r'$')) continue;
        if (_sqlKeywords.any(text.contains)) continue;
        if (arabicStrings.containsKey(text) || internalOnly.contains(text)) {
          continue;
        }
        final line = '\n'.allMatches(src.substring(0, match.start)).length + 1;
        untranslated.add('$name:$line $text');
      }
    }

    expect(
      untranslated..sort(),
      isEmpty,
      reason:
          'These sentences have no entry in arabicStrings, so they stay in '
          'English while the app is in Arabic. Translate them, or list them in '
          'internalOnly if the user never reads them:\n  '
          '${untranslated.join('\n  ')}',
    );
  });
}
