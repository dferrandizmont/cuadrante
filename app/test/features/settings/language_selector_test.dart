import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/l10n/app_locales.dart';
import 'package:cuadrante/features/schedule/domain/presets.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

/// Ajustes › Apariencia › Idioma (docs/datos.md, `appearance.language`).
void main() {
  setUpAll(initializeLocale);

  const tall = Size(390, 2200);

  Future<Preferences> stored(AppUnderTest app) =>
      app.real(() => PreferencesRepository(app.database).load());

  Future<void> pickLanguage(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('settings-language')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  Finder languageValue(String text) => find.descendant(
    of: find.byKey(const ValueKey('settings-language')),
    matching: find.text(text),
  );

  testWidgets('every language is offered, each in its own language', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    await app.openSettings();
    expect(languageValue('Sistema (Español)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-language')));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    final names = {
      'es': 'Español',
      'ca': 'Català',
      'gl': 'Galego',
      'eu': 'Euskara',
      'en': 'English',
    };
    for (final locale in appSupportedLocales) {
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(names[locale.languageCode]!),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: sheet, matching: find.text('Sistema (Español)')),
      findsOneWidget,
    );
  });

  testWidgets('a language applies at once, is stored and can be undone', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    await app.openSettings();

    await pickLanguage(tester, 'English');
    expect(find.text('Settings'), findsOneWidget);
    expect(languageValue('English'), findsOneWidget);
    expect((await stored(app)).language, AppLanguage.en);
    // What is created from now on takes the new language.
    expect(shiftTemplateByKey('postNight').name, 'Post-night');

    // «Sistema» on a Spanish phone: back to Spanish.
    await pickLanguage(tester, 'System (Español)');
    expect(find.text('Ajustes'), findsOneWidget);
    expect(languageValue('Sistema (Español)'), findsOneWidget);
    expect((await stored(app)).language, AppLanguage.system);
    expect(shiftTemplateByKey('postNight').name, 'Saliente');
  });

  testWidgets('a stored language wins over the phone', (tester) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      prepare: (db) => PreferencesRepository(db).setLanguage(AppLanguage.en),
    );
    await tester.pumpAndSettle();
    await app.openSettingsIn('Open settings');
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('«Sistema» follows the phone when it changes language', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
    await tester.pumpAndSettle();
    await app.openSettingsIn('Open settings');
    expect(find.text('Settings'), findsOneWidget);
    expect(languageValue('System (English)'), findsOneWidget);
  });

  testWidgets('a phone language the app does not have gives Spanish', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    tester.platformDispatcher.localesTestValue = const [
      Locale('fr', 'FR'),
      Locale('de', 'DE'),
    ];
    await tester.pumpAndSettle();
    await app.openSettings();
    expect(find.text('Ajustes'), findsOneWidget);
    expect(languageValue('Sistema (Español)'), findsOneWidget);
  });
}

extension on AppUnderTest {
  /// Opens Settings by the tooltip of another language.
  Future<void> openSettingsIn(String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }
}
