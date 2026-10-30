import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';

/// The QA findings of T15 about help, the licences and the theme row.
void main() {
  setUpAll(initializeLocale);

  const tall = Size(390, 2400);

  Finder key(String value) => find.byKey(ValueKey(value));

  group('H-T15-2: contact while there is no support address', () {
    test('the default support address is ready to copy', () {
      expect(kSupportEmail, 'turnly@mainshai.com');
      expect(const AppConfig().supportEmail, kSupportEmail);
    });

    testWidgets('the row and the sheet say it is being set up', (tester) async {
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

      // «Preguntas frecuentes» comes first, then the contact row.
      expect(
        tester.getTopLeft(key('settings-faq')).dy,
        lessThan(tester.getTopLeft(key('settings-help')).dy),
      );
      // No promise of a reply on the row.
      expect(
        find.descendant(
          of: key('settings-help'),
          matching: find.text('Estamos preparando el correo de soporte'),
        ),
        findsOneWidget,
      );
      expect(find.text('Escríbenos si algo no va bien'), findsNothing);

      await tester.tap(key('settings-help'));
      await tester.pumpAndSettle();
      expect(
        find.text('El correo de soporte llegará con la versión de la tienda.'),
        findsOneWidget,
      );
      expect(key('help-copy-email'), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('H-T15-7: the sentence about the address is body text, not '
        'a bold title', (tester) async {
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
      await tester.tap(key('settings-help'));
      await tester.pumpAndSettle();

      final sentence = tester.widget<Text>(key('help-no-email')).style!;
      final paragraph = tester
          .widget<Text>(find.textContaining('Todavía no tenemos correo'))
          .style!;
      final title = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text('Ayuda y contacto'),
            ),
          )
          .style!;
      // Same size and weight as the paragraph above it, and far from the
      // sheet's title.
      expect(sentence.fontSize, paragraph.fontSize);
      expect(sentence.fontWeight, paragraph.fontWeight);
      expect(sentence.fontWeight, isNot(FontWeight.w700));
      expect(sentence.fontSize, lessThan(title.fontSize!));
    });

    testWidgets('with an address the row invites to write and offers it', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(supportEmail: 'hola@example.test'),
          ),
        ],
      );
      await app.openSettings();
      expect(find.text('Escríbenos si algo no va bien'), findsOneWidget);
      await tester.tap(key('settings-help'));
      await tester.pumpAndSettle();
      expect(find.text('hola@example.test'), findsOneWidget);
      expect(
        find.text('El correo de soporte llegará con la versión de la tienda.'),
        findsNothing,
      );
    });
  });

  group('H-T15-3: «Copiar versión» confirms', () {
    String? copied;

    setUp(() => copied = null);

    void mockClipboard(WidgetTester tester) {
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
    }

    testWidgets('the sheet closes and «Versión copiada» is on screen', (
      tester,
    ) async {
      mockClipboard(tester);
      final app = await AppUnderTest.pump(tester, size: tall);
      await app.openSettings();
      await tester.tap(key('settings-help'));
      await tester.pumpAndSettle();

      await tester.tap(key('help-copy-version'));
      await tester.pumpAndSettle();

      expect(copied, startsWith('Turnly'));
      // Not behind the sheet: the sheet is gone and the message is visible.
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Versión copiada'), findsOneWidget);
      final box = tester.getRect(find.byType(SnackBar));
      expect(box.bottom, lessThanOrEqualTo(tall.height));
      expect(box.top, greaterThan(0));
    });

    testWidgets('copying the address says «Correo copiado»', (tester) async {
      mockClipboard(tester);
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(supportEmail: 'hola@example.test'),
          ),
        ],
      );
      await app.openSettings();
      await tester.tap(key('settings-help'));
      await tester.pumpAndSettle();
      await tester.tap(key('help-copy-email'));
      await tester.pumpAndSettle();
      expect(copied, 'hola@example.test');
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Correo copiado'), findsOneWidget);
    });
  });

  group('H-T15-4: the licences page', () {
    testWidgets('has the app name, version and legalese in Spanish', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(appVersion: '0.6.1'),
          ),
        ],
      );
      await app.openSettings();
      await tester.tap(key('settings-about'));
      await tester.pumpAndSettle();
      await tester.tap(key('about-licenses'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      // Registered Spanish strings of Material: the title of the page.
      expect(find.text('Licencias'), findsWidgets);
      expect(find.text('Turnly'), findsWidgets);
      expect(find.text('Versión 0.6.1'), findsOneWidget);
      expect(
        find.text(
          'Turnly funciona sin conexión y sin cuenta: tus turnos se '
          'quedan en tu móvil.',
        ),
        findsOneWidget,
      );
      // Flutter writes this line itself, in English, without a localization:
      // it cannot be translated from here (see help_section.dart).
      expect(find.text('Powered by Flutter'), findsOneWidget);
    });
  });

  group('H-T15-5: «Sistema» says which theme it gives', () {
    testWidgets('light system: «Sistema (claro)»', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await app.openSettings();
      expect(
        find.descendant(
          of: key('settings-theme'),
          matching: find.text('Sistema (claro)'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('dark system: «Sistema (oscuro)», also in the sheet', (
      tester,
    ) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        platformBrightness: Brightness.dark,
      );
      await app.openSettings();
      expect(
        find.descendant(
          of: key('settings-theme'),
          matching: find.text('Sistema (oscuro)'),
        ),
        findsOneWidget,
      );
      await tester.tap(key('settings-theme'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Sistema (oscuro)'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('it follows the phone live', (tester) async {
      final app = await AppUnderTest.pump(tester, size: tall);
      await app.openSettings();
      expect(find.text('Sistema (claro)'), findsOneWidget);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(find.text('Sistema (oscuro)'), findsOneWidget);
      expect(find.text('Sistema (claro)'), findsNothing);
    });

    testWidgets('a forced theme does not mention the system', (tester) async {
      final app = await AppUnderTest.pump(
        tester,
        size: tall,
        platformBrightness: Brightness.dark,
      );
      await app.openSettings();
      await tester.tap(key('settings-theme'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Claro'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: key('settings-theme'),
          matching: find.text('Claro'),
        ),
        findsOneWidget,
      );
    });
  });
}
