import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'harness.dart';

// QA campaign, T02 (H-T02-11, H-T02-6): the title of paint mode showed
// «Mañ… · 08:00–15:00» at 412 dp and text x1.0 with the room of the whole
// screen width next to it, and at x2.0 the names of the tools broke inside
// a word. With the real font, on every width and text size: a name is only
// cut when it does not fit even the full width, and no word of a tool is
// ever split.

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('at $width dp, text $scale: no name is cut that fits, no '
          'word is split', (tester) async {
        await pumpCalendar(tester, size: Size(width, 900), textScale: scale);
        await enterPaintMode(tester);
        final ids = [
          for (final s in containerOf(
            tester,
          ).read(scheduleControllerProvider).palette)
            s.id,
        ];

        for (final id in ids) {
          final tool = find.byKey(ValueKey('tool-$id'));
          await tester.ensureVisible(tool);
          await tester.pumpAndSettle();
          await tester.tap(tool);
          await tester.pumpAndSettle();

          // The title: one Text when it fits whole, or the name and the
          // hours as two. The name is only ellipsized if the whole line is
          // wider than the most room it could have.
          // The most room a title can have: the width of the screen less the
          // margins, as when it goes under the buttons.
          final room = width - 2 * 20;
          final texts = find
              .descendant(
                of: find.byKey(const ValueKey('paint-title')),
                matching: find.byType(RichText),
              )
              .evaluate()
              .map((e) => e.renderObject! as RenderParagraph)
              .toList();
          var natural = 0.0;
          for (final p in texts) {
            natural += p.getMaxIntrinsicWidth(double.infinity);
          }
          final cut = texts.any((p) => p.didExceedMaxLines);
          if (cut) {
            expect(
              natural,
              greaterThan(room),
              reason:
                  '$id is cut at $width dp x$scale but fits: '
                  '$natural in $room',
            );
          }
          // The hours are never cut.
          for (final p in texts) {
            if (p.text.toPlainText().contains('–')) {
              expect(p.didExceedMaxLines, isFalse, reason: '$id hours');
            }
          }

          // The names of the tools: whole words.
          for (final other in ids) {
            final label = find.descendant(
              of: find.byKey(ValueKey('tool-$other')),
              matching: find.byType(Text),
            );
            final paragraph = tester.renderObject<RenderParagraph>(label.last);
            expect(
              wrapsOnlyBetweenWords(paragraph),
              isTrue,
              reason: '$other breaks a word while $id is chosen',
            );
            expect(paragraph.didExceedMaxLines, isFalse, reason: other);
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
