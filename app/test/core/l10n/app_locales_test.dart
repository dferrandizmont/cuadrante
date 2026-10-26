import 'package:cuadrante/core/l10n/app_locales.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = [Locale('es'), Locale('ca'), Locale('gl'), Locale('en')];

  test('Spanish is first, then every language with an ARB file', () {
    expect(appSupportedLocales.first, const Locale('es'));
    expect(
      appSupportedLocales.toSet(),
      AppLocalizations.supportedLocales.toSet(),
    );
  });

  group('«Sistema» follows the phone', () {
    test('the phone language, whatever its region', () {
      expect(
        resolveAppLocale(const [Locale('ca', 'ES')], supported),
        const Locale('ca'),
      );
      expect(
        resolveAppLocale(const [Locale('en', 'GB')], supported),
        const Locale('en'),
      );
    });

    test('the first preferred language the app has', () {
      expect(
        resolveAppLocale(const [
          Locale('fr', 'FR'),
          Locale('gl', 'ES'),
          Locale('es', 'ES'),
        ], supported),
        const Locale('gl'),
      );
    });

    test('a language the app does not have falls back to Spanish', () {
      expect(
        resolveAppLocale(const [Locale('fr', 'FR')], supported),
        const Locale('es'),
      );
      expect(
        resolveAppLocale(const [Locale('pt', 'PT')], supported),
        const Locale('es'),
      );
      expect(resolveAppLocale(null, supported), const Locale('es'));
      expect(resolveAppLocale(const [], supported), const Locale('es'));
    });
  });

  test('each option forces its own locale; «Sistema» forces none', () {
    expect(AppLanguage.system.locale, isNull);
    expect(AppLanguage.eu.locale, const Locale('eu'));
    expect(AppLanguage.fromStored('ca'), AppLanguage.ca);
    expect(AppLanguage.fromStored('xx'), AppLanguage.system);
    expect(AppLanguage.fromStored(null), AppLanguage.system);
  });
}
