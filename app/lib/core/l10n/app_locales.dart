import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Spanish: the language of the template ARB and the one the app falls back
/// to when the phone's language is not one it has.
const Locale fallbackLocale = Locale('es');

/// The languages that have an ARB file, Spanish first.
final List<Locale> appSupportedLocales = [
  fallbackLocale,
  for (final locale in AppLocalizations.supportedLocales)
    if (locale.languageCode != fallbackLocale.languageCode) locale,
];

/// The app locale for the phone's preferred [device] languages, in order:
/// the first one the app has (by language, so `ca_ES` and `ca_AD` both give
/// `ca`), else Spanish.
Locale resolveAppLocale(List<Locale>? device, [Iterable<Locale>? supported]) {
  final codes = {
    for (final l in supported ?? appSupportedLocales) l.languageCode,
  };
  for (final locale in device ?? const <Locale>[]) {
    if (codes.contains(locale.languageCode)) return Locale(locale.languageCode);
  }
  return fallbackLocale;
}
