import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/presentation/holidays_settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/real_font.dart';
import '../../support/text_lines.dart';

// QA campaign, T10 (H-T10-1): «Comunidad autónoma» stacked its value under
// the title while «Municipio» kept it on the right, two rows in a row with
// different formats.

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at $width dp, text $scale: Comunidad and Municipio show '
          'their value the same way', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final app = await AppUnderTest.pump(tester, size: Size(width, 900));
        await tester.runAsync(
          () => app.container.read(municipalityIndexProvider.future),
        );
        await app.container
            .read(holidayControllerProvider.notifier)
            .setPlace(regionCode: 'ES-CT', municipalityCode: '08019');
        await app.openSettings();
        await tester.ensureVisible(_key('settings-holidays'));
        await tester.pumpAndSettle();
        await tester.tap(_key('settings-holidays'));
        await tester.pumpAndSettle();

        ({Rect title, Rect value}) parts(String row, String value) {
          final texts = find.descendant(
            of: _key(row),
            matching: find.byType(Text),
          );
          final title = tester.getRect(texts.first);
          final valueFinder = find.descendant(
            of: _key(row),
            matching: find.text(value),
          );
          expect(valueFinder, findsOneWidget, reason: row);
          return (title: title, value: tester.getRect(valueFinder));
        }

        final region = parts('holidays-region', 'Catalunya');
        final municipality = parts('holidays-municipality', 'Barcelona');

        bool stacked(({Rect title, Rect value}) r) =>
            r.value.top >= r.title.bottom - 0.5;

        if (scale >= 1.3) {
          expect(stacked(region), isTrue, reason: 'Comunidad stacked');
          expect(stacked(municipality), isTrue, reason: 'Municipio stacked');
          expect(region.value.left, closeTo(region.title.left, 0.6));
          expect(
            municipality.value.left,
            closeTo(municipality.title.left, 0.6),
          );
        } else {
          // Text 1.0: side by side when they fit; never cut either way.
          for (final r in [region, municipality]) {
            if (!stacked(r)) {
              expect(r.value.left, greaterThanOrEqualTo(r.title.right));
            }
          }
        }
        // No title cut or broken in either row.
        for (final row in ['holidays-region', 'holidays-municipality']) {
          for (final e
              in find
                  .descendant(of: _key(row), matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = e.renderObject! as RenderParagraph;
            expect(paragraph.didExceedMaxLines, isFalse, reason: row);
            expect(wrapsOnlyBetweenWords(paragraph), isTrue, reason: row);
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
