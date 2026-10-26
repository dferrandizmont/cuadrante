import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onboarding_support.dart';

/// The header of the first-use flow: back arrow, dots and «Saltar». A real
/// 412 dp phone wrapped «Saltar» onto two lines because the button sat in a
/// box 56 dp wide that squeezed it.
void main() {
  setUpAll(initializeLocale);

  final skip = find.byKey(const ValueKey('onboarding-skip'));

  /// Number of distinct lines the text is laid out on.
  int lines(WidgetTester tester) {
    final label = find.descendant(of: skip, matching: find.text('Saltar'));
    final paragraph = tester.renderObject<RenderParagraph>(label);
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 'Saltar'.length),
    );
    return boxes.map((box) => box.top.round()).toSet().length;
  }

  for (final width in [320.0, 360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('«Saltar» is one line at $width dp, text scale $scale', (
        tester,
      ) async {
        await FirstLaunch.open(
          tester,
          size: Size(width, 800),
          textScale: scale,
        );
        expect(skip, findsOneWidget);
        expect(lines(tester), 1);
        expect(tester.takeException(), isNull);

        // The button is whole on screen and the dots are still there.
        final box = tester.getRect(skip);
        expect(box.right, lessThanOrEqualTo(width));
        expect(find.byKey(const ValueKey('onboarding-dots')), findsOneWidget);
      });
    }
  }
}
