import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/format/text_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';

/// H-T01-7: at 360 dp and text 2.0 the line «M 08–15, T 15–22, N 22–08 y
/// saliente» broke inside «22–08» («22–» / «08»).
void main() {
  setUpAll(initializeLocale);

  group('keepTimeRangesTogether', () {
    test('joins the two ends of a range and the tag before it', () {
      final joined = keepTimeRangesTogether(
        'M 08–15, T 15–22, N 22–08 y saliente',
      );
      expect(
        joined,
        contains(
          '22–$wordJoiner'
          '08',
        ),
      );
      expect(joined, contains('M${noBreakSpace}08'));
      // The visible text is the same.
      expect(
        joined.replaceAll(wordJoiner, '').replaceAll(noBreakSpace, ' '),
        'M 08–15, T 15–22, N 22–08 y saliente',
      );
    });

    test('keeps minutes in a range and leaves other text alone', () {
      expect(
        keepTimeRangesTogether('07:30–15 y guardia de 24 h'),
        '07:30–$wordJoiner'
        '15 y guardia de 24 h',
      );
      expect(keepTimeRangesTogether('Sin horas'), 'Sin horas');
    });
  });

  /// The text of every line a paragraph is laid out on.
  List<String> linesOf(RenderParagraph paragraph) {
    final text = paragraph.text.toPlainText();
    final lines = <int, StringBuffer>{};
    for (var i = 0; i < text.length; i++) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isEmpty) continue;
      lines
          .putIfAbsent(boxes.first.top.round(), StringBuffer.new)
          .write(text[i]);
    }
    return [for (final line in lines.values) line.toString()];
  }

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('profession hints never break inside a range at $width dp, '
          'text $scale', (tester) async {
        await FirstLaunch.open(
          tester,
          size: Size(width, 800),
          textScale: scale,
        );
        for (final id in ['nursing', 'police', 'industry', 'hospitality']) {
          final tile = key('onboarding-profession-$id');
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          final hint = find.descendant(
            of: tile,
            matching: find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').contains(RegExp(r'\d')),
            ),
          );
          final paragraph = tester.renderObject<RenderParagraph>(hint);
          for (final line in linesOf(paragraph)) {
            final shown = line.trim();
            expect(
              shown.endsWith('–') || shown.endsWith(wordJoiner),
              isFalse,
              reason: '«$shown» ends inside a range ($id)',
            );
            expect(
              RegExp(r'^\d{2}(\s|,|$)').hasMatch(shown) &&
                  !RegExp(r'^\d{2}–').hasMatch(shown),
              isFalse,
              reason: '«$shown» starts with the end of a range ($id)',
            );
          }
        }
      });
    }
  }
}
