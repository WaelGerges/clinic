import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'arabic.dart';

final appLanguage = ValueNotifier<Locale>(const Locale('en'));

/// Loads the intl date symbols for every language the apps offer.
///
/// Without this, `DateFormat` throws `LocaleDataException` as soon as
/// `Intl.defaultLocale` is Arabic, which blanked every screen that shows a
/// date or a time. Both locales are loaded up front so switching the language
/// can never render before its symbols exist.
Future<void> loadClinicDateSymbols() async {
  await initializeDateFormatting('en');
  await initializeDateFormatting('ar');
}

Future<void> loadLanguage() async {
  await loadClinicDateSymbols();
  try {
    final saved = await const FlutterSecureStorage().read(
      key: 'clinic_language',
    );
    setAppLanguage(
      saved ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
  } catch (_) {
    setAppLanguage('en');
  }
}

void setAppLanguage(String code) {
  final language = code == 'ar' ? 'ar' : 'en';
  // Synchronous in practice, and repeated calls are cheap. It keeps callers
  // that reach setAppLanguage without loadLanguage (tests, deep links) from
  // formatting a date before the symbols are registered.
  initializeDateFormatting(language);
  Intl.defaultLocale = language;
  appLanguage.value = Locale(language);
}

Future<void> saveLanguage(String code) async {
  await const FlutterSecureStorage().write(key: 'clinic_language', value: code);
  setAppLanguage(code);
}

String tr(String text, [List<Object?> args = const []]) {
  var result = appLanguage.value.languageCode == 'ar'
      ? arabicStrings[text] ?? text
      : text;
  for (var i = 0; i < args.length; i++) {
    result = result.replaceAll('{$i}', args[i].toString());
  }
  return result;
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: appLanguage,
    builder: (context, locale, _) => DropdownButtonFormField<String>(
      initialValue: locale.languageCode,
      key: ValueKey(locale.languageCode),
      decoration: const InputDecoration(labelText: 'Language / اللغة'),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'ar', child: Text('العربية')),
      ],
      onChanged: (value) async {
        if (value == null) return;
        try {
          await saveLanguage(value);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr('Language preference could not be saved.')),
              ),
            );
          }
        }
      },
    ),
  );
}
