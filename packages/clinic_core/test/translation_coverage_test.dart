// Guards Arabic completeness. Every string that reaches tr() at runtime must
// have an entry in arabicStrings, otherwise the app silently shows English
// while the user is in Arabic mode.
//
// Sinks that call tr() internally: SectionCard/EmptyPanel title+message,
// MedicalAlert message, runAction success, and safeError(), which forwards
// every ClinicFailure message.
import 'dart:io';

import 'package:clinic_core/src/presentation/arabic.dart';
import 'package:flutter_test/flutter_test.dart';

/// Values produced at runtime and rendered through `tr()`. They never appear
/// as literals at the call site, so they are listed explicitly.
const _runtimeValues = <String, List<String>>{
  'audit actor_role / membership role': ['doctor', 'assistant'],
  'audit object_type': [
    'clinic',
    'patient',
    'appointment',
    'visit',
    'attachment',
    'invitation',
    'membership',
    'schedule',
  ],
  // audit_events.action, built server-side as '<entity>.<action>'.
  'audit action': [
    'clinic.created',
    'patient.save',
    'appointment.save',
    'appointment.status',
    'appointment.send',
    'appointment.completed',
    'appointment.received',
    'visit.save',
    'visit.complete',
    'visit.amend',
    'attachment.staged',
    'attachment.finalized',
    'attachment.accessed',
    'attachment.archived',
    'attachment.restored',
    'attachment.failed',
    'staff.invited',
    'staff.joined',
    'staff.access_changed',
    'schedule.settings',
    'schedule.settings_clear',
    'schedule.waitlist_add',
    'schedule.waitlist_remove',
  ],
  'outbox entity_type': ['patient', 'appointment', 'visit'],
  'outbox action': ['save', 'status', 'send', 'complete', 'amend'],
  'outbox state': ['pending', 'sending', 'conflict', 'failed'],
};

/// Returns the text between the parentheses of the call starting at [open],
/// respecting nesting and string literals.
String _callBody(String src, int open) {
  var depth = 0, start = -1;
  String? quote;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (quote != null) {
      if (c == r'\') {
        i++;
        continue;
      }
      if (c == quote) quote = null;
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      continue;
    }
    if (c == '(') {
      if (depth == 0) start = i + 1;
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) return src.substring(start, i);
    }
  }
  return '';
}

// Single-quoted or double-quoted Dart string literal, built by concatenation
// so neither quote character has to be escaped inside a raw string.
const _literalPattern = r"'((?:[^'\\\n]|\\.)*)'"
    '|'
    r'"((?:[^"\\\n]|\\.)*)"';
final _literal = RegExp(_literalPattern);
final _dateFormat = RegExp(r'DateFormat\s*\([^)]*\)');

String _unescape(String v) => v
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\t', '\t');

/// String literals inside [text] that are displayed text, excluding map
/// indexes (`row['key']`), equality comparisons, map-literal keys, switch
/// patterns and `DateFormat` patterns.
List<String> _textLiterals(String text) {
  final masked = text.replaceAllMapped(
    _dateFormat,
    (m) => ' ' * m.group(0)!.length,
  );
  final out = <String>[];
  for (final m in _literal.allMatches(masked)) {
    final startsAt = m.start, endsAt = m.end;
    final before = masked.substring(0, startsAt).trimRight();
    final after = masked.substring(endsAt);
    if (before.endsWith('[') && after.startsWith(']')) continue;
    if (RegExp(r'[=!]=$').hasMatch(before)) continue;
    if (RegExp(r'^\s*:').hasMatch(after) &&
        RegExp(r'[{,]$').hasMatch(before)) {
      continue;
    }
    if (RegExp(r'^\s*=>').hasMatch(after)) continue;
    out.add(_unescape(m.group(1) ?? m.group(2)!));
  }
  return out;
}

void main() {
  test('every string shown through tr() has an Arabic translation', () {
    final lib = Directory('lib');
    expect(
      lib.existsSync(),
      isTrue,
      reason: 'run this test from packages/clinic_core',
    );

    final sources = lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .toList();
    expect(sources.length, greaterThan(5));

    final sinks = <String, String>{}; // literal -> where it came from

    void record(String? value, String where) {
      if (value == null) return;
      if (!RegExp(r'[A-Za-z]{2}').hasMatch(value)) return; // placeholders only
      if (value.contains(r'$')) return; // interpolated; cannot be a key
      sinks.putIfAbsent(value, () => where);
    }

    for (final file in sources) {
      final src = file.readAsStringSync();
      final name = file.path.replaceAll(r'\', '/');
      if (name.endsWith('presentation/arabic.dart')) continue;
      final isLanguageFile = name.endsWith('presentation/language.dart');

      for (final m in RegExp(r'\btr\s*\(').allMatches(src)) {
        for (final lit in _textLiterals(_callBody(src, m.start))) {
          record(lit, name);
        }
      }
      for (final m in RegExp(
        r'\b(?:SectionCard|EmptyPanel|MedicalAlert)\s*\(',
      ).allMatches(src)) {
        final body = _callBody(src, m.start);
        for (final a in RegExp(
          '(?:title|message)\\s*:\\s*($_literalPattern)',
        ).allMatches(body)) {
          final lits = _textLiterals(a.group(1)!);
          if (lits.isNotEmpty) record(lits.first, name);
        }
      }
      for (final m in RegExp(r'\brunAction\s*\(').allMatches(src)) {
        final body = _callBody(src, m.start);
        for (final a in RegExp(
          'success\\s*:\\s*($_literalPattern)',
        ).allMatches(body)) {
          final lits = _textLiterals(a.group(1)!);
          if (lits.isNotEmpty) record(lits.first, name);
        }
      }
      // ClinicFailure('code', 'user message') -> message reaches tr() via safeError.
      for (final m in RegExp(r'\bClinicFailure\s*\(').allMatches(src)) {
        final body = _callBody(src, m.start);
        final comma = body.indexOf(',');
        if (comma < 0) continue;
        final lits = _textLiterals(body.substring(comma + 1));
        if (lits.isNotEmpty) record(lits.first, name);
      }
      // Enum labels, e.g. scheduled('Scheduled'), lab('Lab').
      if (!isLanguageFile) {
        for (final m in RegExp(
          r"""^\s*[a-z][A-Za-z]*\('((?:[^'\\]|\\.)*)'\)\s*[,;]""",
          multiLine: true,
        ).allMatches(src)) {
          record(_unescape(m.group(1)!), name);
        }
      }
    }

    for (final entry in _runtimeValues.entries) {
      for (final value in entry.value) {
        record(value, entry.key);
      }
    }

    expect(
      sinks.length,
      greaterThan(300),
      reason: 'the scanner found suspiciously few strings; it is likely broken',
    );

    final missing = <String>[
      for (final e in sinks.entries)
        if (!arabicStrings.containsKey(e.key)) '${e.value}: ${e.key}',
    ]..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'These strings reach tr() but have no entry in arabicStrings, so they '
          'render in English while the app is in Arabic:\n  '
          '${missing.join('\n  ')}',
    );
  });

  test('arabicStrings has no untranslated or empty values', () {
    // Language names stay in their own language in the picker.
    const deliberatelyIdentical = {'English'};
    final suspicious = <String>[
      for (final e in arabicStrings.entries)
        if (!deliberatelyIdentical.contains(e.key) &&
            (e.value.trim().isEmpty ||
                (!RegExp(r'[؀-ۿ]').hasMatch(e.value) &&
                    RegExp(r'[A-Za-z]{3}').hasMatch(e.value) &&
                    e.value == e.key)))
          e.key,
    ];
    expect(
      suspicious,
      isEmpty,
      reason: 'entries that are empty or identical to their English key',
    );
  });
}
