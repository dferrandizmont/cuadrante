import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/l10n/app_locales.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/real_font.dart';

/// The longest languages on a small phone with big text: the month, the
/// day sheet and Settings in Catalan and Basque at 320 dp and text 1.3, with
/// Roboto (the test font is twice as wide), overflow nothing. The palette is
/// seeded in the language too, so its names and codes are laid out as well.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });
  tearDown(() => debugPhoneLocales = const [Locale('es', 'ES')]);

  final languages = [
    for (final l in appSupportedLocales)
      if (l.languageCode == 'ca' || l.languageCode == 'eu') l.languageCode,
  ];

  for (final lang in languages) {
    group(lang, () {
      final l10n = lookupAppLocalizations(Locale(lang));

      Future<AppUnderTest> pump(WidgetTester tester, Size size) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        debugPhoneLocales = [Locale(lang)];
        final app = await AppUnderTest.pump(tester, size: size);
        // The harness puts the phone in Spanish; this one is in [lang].
        tester.platformDispatcher.localesTestValue = [Locale(lang)];
        await tester.pumpAndSettle();
        expect(find.byTooltip(l10n.settingsOpenTooltip), findsOneWidget);
        return app;
      }

      testWidgets('the month at 320 dp, text 1.3', (tester) async {
        await pump(tester, const Size(320, 640));
        expect(find.text(l10n.paintFab), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the day sheet at 320 dp, text 1.3', (tester) async {
        await pump(tester, const Size(320, 640));
        // The rows of the grid are tall with big text: the day is brought
        // into view before the tap.
        await tester.ensureVisible(dayCell(harnessToday));
        await tester.pumpAndSettle();
        await tester.tap(dayCell(harnessToday));
        await tester.pumpAndSettle();
        expect(find.text(l10n.daySheetNote), findsWidgets);
        expect(tester.takeException(), isNull);

        // And the day after, with its own shifts.
        await tester.tapAt(const Offset(160, 20));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Settings at 320 dp, text 1.3', (tester) async {
        await pump(tester, const Size(320, 3000));
        await tester.tap(find.byTooltip(l10n.settingsOpenTooltip));
        await tester.pumpAndSettle();
        expect(find.text(l10n.settingsTitle), findsWidgets);
        expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);
        expect(find.text(l10n.settingsAboutTitle), findsOneWidget);
        expect(tester.takeException(), isNull);

        // The language sheet too.
        await tester.tap(find.byKey(const ValueKey('settings-language')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
