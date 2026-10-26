import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/widgets/button_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'import_ui_support.dart';

/// H-T14-1: at text x2.0 the bar of the import wizard split «Atrás» into
/// «Atrá / s» and took a third of the screen. The buttons now stack when a
/// word does not fit beside the other button, and never split a word.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('the bar of steps 2 to 5 at $width dp, text $scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        const height = 800.0;
        final app = await AppUnderTest.pump(
          tester,
          size: Size(width, height),
          overrides: importOverrides(
            phone: phoneWithShifts(),
            picker: FakePicker(),
          ),
        );
        await app.openSettings();
        await tester.ensureVisible(byKey('settings-import'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-import'));
        await tester.pumpAndSettle();

        void checkBar(String where) {
          final bar = find.byType(AdaptiveButtonRow);
          expect(bar, findsOneWidget, reason: where);
          // No word of any button is split.
          for (final element
              in find
                  .descendant(of: bar, matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            expect(
              wrapsOnlyBetweenWords(paragraph),
              isTrue,
              reason: '$where: ${paragraphLines(paragraph).join(' | ')}',
            );
          }
          // Both buttons are whole and on screen.
          for (final k in ['import-back', 'import-next']) {
            final b = byKey(k);
            if (b.evaluate().isEmpty) continue;
            final r = tester.getRect(b);
            expect(r.left, greaterThanOrEqualTo(0), reason: '$where $k');
            expect(r.right, lessThanOrEqualTo(width), reason: '$where $k');
            expect(r.bottom, lessThanOrEqualTo(height), reason: '$where $k');
          }
          // The bar leaves room for the step.
          expect(
            tester.getSize(bar).height,
            lessThan(height * 0.3),
            reason: '$where: the bar is too tall',
          );
          expect(tester.takeException(), isNull, reason: where);
        }

        await tapKey(tester, 'import-source-device');
        await tapKey(tester, 'import-calendar-cal-1');
        checkBar('step 2');
        await tapKey(tester, 'import-next');
        checkBar('step 3');
        await tapKey(tester, 'import-next');
        checkBar('step 4');
        await tapKey(tester, 'import-next');
        checkBar('step 5');
        expect(byKey('import-apply'), findsOneWidget);

        // «Atrás» still goes back.
        await tapKey(tester, 'import-back');
        expect(stepOf(tester), 'Paso 4 de 5');
      });
    }
  }
}
