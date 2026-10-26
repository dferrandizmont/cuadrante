import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'backup_ui_support.dart';

/// H-T13-2: in «Copias automáticas» the switch took width off the title and,
/// at x2.0 on a 320 dp phone, the title came out as «Copias / automática / s».
/// The switch now goes under the text when a word no longer fits beside it.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        testWidgets(
          'the title keeps its words whole at $width dp, text $scale, '
          '${brightness.name}',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            tester.platformDispatcher.platformBrightnessTestValue = brightness;
            addTearDown(tester.platformDispatcher.clearAllTestValues);
            final h = BackupUiHarness(tester);
            await h.open(size: Size(width, 4000));
            final row = find.byKey(const ValueKey('backup-auto-row'));
            expect(row, findsOneWidget);

            final title = find.descendant(
              of: row,
              matching: find.text('Copias automáticas'),
            );
            expect(
              wrapsOnlyBetweenWords(tester.renderObject<RenderParagraph>(title)),
              isTrue,
              reason: paragraphLines(
                tester.renderObject<RenderParagraph>(title),
              ).join(' | '),
            );
            // Every paragraph of the row too (the subtitle).
            for (final element in find
                .descendant(of: row, matching: find.byType(RichText))
                .evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              expect(
                wrapsOnlyBetweenWords(paragraph),
                isTrue,
                reason: paragraphLines(paragraph).join(' | '),
              );
            }

            // The switch is on screen, inside the row, and still toggles.
            final toggle = tester.getRect(
              find.byKey(const ValueKey('backup-auto-switch')),
            );
            expect(toggle.right, lessThanOrEqualTo(width));
            expect(toggle.left, greaterThanOrEqualTo(0));
            expect(
              tester.getRect(row).contains(toggle.center),
              isTrue,
              reason: 'the switch is inside its row',
            );
            await tester.tap(find.byKey(const ValueKey('backup-auto-switch')));
            await pumpIo(tester);
            expect(find.textContaining('Desactivadas'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
