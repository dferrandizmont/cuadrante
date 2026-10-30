import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/features/patterns/application/post_night_provider.dart';
import 'package:cuadrante/features/patterns/data/post_night_settings.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app_harness.dart';

class _FailingPostNightSettings extends PostNightSettingsRepository {
  _FailingPostNightSettings(super.db);

  @override
  Future<void> saveAuto(bool value) async => throw StateError('disk full');
}

void main() {
  setUpAll(initializeLocale);

  // Tall enough for the whole screen without scrolling.
  const tall = Size(390, 2200);

  Future<Preferences> stored(AppUnderTest app) =>
      app.real(() => PreferencesRepository(app.database).load());

  Future<void> pickTheme(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('settings-theme')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the saliente automático switch is stored and survives', (
    tester,
  ) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    await app.openSettings();
    final row = find.byKey(const ValueKey('settings-post-night-switch'));
    expect(tester.widget<Switch>(row).value, isFalse);

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(row).value, isTrue);
    expect(
      await app.real(
        () => PostNightSettingsRepository(app.database).loadAuto(),
      ),
      isTrue,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      await app.real(
        () => PostNightSettingsRepository(app.database).loadAuto(),
      ),
      isFalse,
    );
  });

  testWidgets('a saliente automático switch that cannot be stored says so and '
      'goes back', (tester) async {
    final app = await AppUnderTest.pump(
      tester,
      size: tall,
      overrides: [
        postNightSettingsRepositoryProvider.overrideWith(
          (ref) => _FailingPostNightSettings(ref.watch(appDatabaseProvider)),
        ),
      ],
    );
    await app.openSettings();
    final row = find.byKey(const ValueKey('settings-post-night-switch'));
    expect(tester.widget<Switch>(row).value, isFalse);

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(
      find.text('No se ha podido guardar el ajuste. Prueba otra vez.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Switch>(row).value,
      isFalse,
      reason: 'it does not show a value that is not stored',
    );
  });

  testWidgets('shows every section of the screen', (tester) async {
    final app = await AppUnderTest.pump(tester, size: tall);
    await app.openSettings();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    for (final heading in [
      'TU CUADRANTE',
      'APARIENCIA',
      'AVISOS Y DATOS',
      'AYUDA',
    ]) {
      expect(find.text(heading), findsOneWidget, reason: heading);
    }
    for (final title in [
      'Mis turnos',
      'Calendarios',
      'Tema',
      'Primer día de la semana',
      'Mostrar número de semana',
      'Festivos',
      'Alarmas',
      'Copia de seguridad',
      'Ayuda y contacto',
      'Acerca de',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Próximamente'), findsNothing);
    // Defaults.
    expect(find.text('Sistema (claro)'), findsOneWidget);
    expect(find.text('Lunes'), findsOneWidget);
    // The calendars row shows the one on screen.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('settings-calendars')),
        matching: find.text('Mi cuadrante'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the settings button of the month screen opens it and back '
      'returns', (tester) async {
    final app = await AppUnderTest.pump(tester);
    await app.openSettings();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await app.back();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
  });

  group('theme', () {
    testWidgets('Oscuro applies the dark theme over a light system and '
        'persists', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      expect(app.theme.brightness, Brightness.light);
      await app.openSettings();

      await pickTheme(tester, 'Oscuro');
      expect(app.theme.brightness, Brightness.dark);
      expect(app.container.read(preferencesProvider).themeMode, ThemeMode.dark);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-theme')),
          matching: find.text('Oscuro'),
        ),
        findsOneWidget,
      );
      expect((await stored(app)).themeMode, ThemeMode.dark);
    });

    testWidgets('Claro wins over a dark system', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        platformBrightness: Brightness.dark,
      );
      expect(app.theme.brightness, Brightness.dark, reason: 'follows system');
      await app.openSettings();
      await pickTheme(tester, 'Claro');
      expect(app.theme.brightness, Brightness.light);
      expect((await stored(app)).themeMode, ThemeMode.light);
    });

    testWidgets('Sistema goes back to following the system', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        platformBrightness: Brightness.dark,
        prepare: (db) =>
            PreferencesRepository(db).setThemeMode(ThemeMode.light),
      );
      expect(app.theme.brightness, Brightness.light, reason: 'stored Claro');
      await app.openSettings();
      await pickTheme(tester, 'Sistema (oscuro)');
      expect(app.theme.brightness, Brightness.dark);
      expect((await stored(app)).themeMode, ThemeMode.system);
    });

    testWidgets('the stored theme is the one of the first frame', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        prepare: (db) => PreferencesRepository(db).setThemeMode(ThemeMode.dark),
      );
      expect(app.theme.brightness, Brightness.dark);
    });
  });

  group('first day of the week and week numbers', () {
    testWidgets('Domingo reorders the month and persists', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await app.openSettings();

      await tester.tap(find.byKey(const ValueKey('settings-week-start')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Domingo'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-week-start')),
          matching: find.text('Domingo'),
        ),
        findsOneWidget,
      );
      expect((await stored(app)).weekStart, 7);

      await app.back();
      await tester.pumpAndSettle();
      final sunday = tester.getCenter(find.byKey(const ValueKey('weekday-7')));
      final monday = tester.getCenter(find.byKey(const ValueKey('weekday-1')));
      expect(sunday.dx, lessThan(monday.dx));
    });

    testWidgets('the number-of-week switch shows the column and persists', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await app.openSettings();
      final toggle = find.byKey(const ValueKey('settings-week-numbers'));
      expect(tester.widget<Switch>(toggle).value, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(toggle).value, isTrue);
      expect((await stored(app)).weekNumbers, isTrue);

      await app.back();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('week-2026-09-28')), findsOneWidget);

      await app.openSettings();
      // The whole row toggles it back.
      await tester.tap(find.text('Mostrar número de semana'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(toggle).value, isFalse);
      expect((await stored(app)).weekNumbers, isFalse);
    });
  });

  group('help and about', () {
    testWidgets('help without a contact address offers to copy the version', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(supportEmail: ''),
          ),
        ],
      );
      await app.openSettings();

      await tester.tap(find.byKey(const ValueKey('settings-help')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('ten a mano la versión que usas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Turnly · Versión de desarrollo'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('help-copy-email')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('help-copy-version')));
      await tester.pumpAndSettle();
      expect(copied, 'Turnly · Versión de desarrollo');
      expect(find.text('Versión copiada'), findsOneWidget);
    });

    testWidgets('help with an address offers to copy it', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              appVersion: '0.3.0',
              supportEmail: 'hola@example.test',
            ),
          ),
        ],
      );
      await app.openSettings();
      await tester.tap(find.byKey(const ValueKey('settings-help')));
      await tester.pumpAndSettle();
      expect(find.text('hola@example.test'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('help-copy-email')));
      await tester.pumpAndSettle();
      expect(copied, 'hola@example.test');
    });

    testWidgets('about shows the version and opens the licences page', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(appVersion: '0.3.0'),
          ),
        ],
      );
      await app.openSettings();
      // The value of the row is the version.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-about')),
          matching: find.text('Versión 0.3.0'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('settings-about')));
      await tester.pumpAndSettle();
      expect(find.text('Turnly'), findsOneWidget);
      expect(find.textContaining('sin conexión y sin cuenta'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('about-licenses')));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  testWidgets('"Mis turnos" pushes /ajustes/turnos', (tester) async {
    // The editor is another screen; a stub stands in for its route.
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (c, s) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/ajustes/turnos',
          builder: (c, s) => const Scaffold(body: Text('editor de turnos')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await AppUnderTest.pump(
      tester,
      size: tall,
      expectMonth: false,
      overrides: [routerProvider.overrideWithValue(router)],
    );
    await tester.tap(find.byKey(const ValueKey('settings-shifts')));
    await tester.pumpAndSettle();
    expect(find.text('editor de turnos'), findsOneWidget);
  });
}
