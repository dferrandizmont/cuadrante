import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/real_font.dart';

/// H-T15-1: on the real Settings screen the title «Calendarios» broke in the
/// middle of the word («Calenda» / «rios») when the value «Mi cuadrante» was
/// next to it and the text was big or the phone small.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    // Roboto, as on the phone: the test font is twice as wide.
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  const tall = 2600.0;

  /// Number of lines [word] is laid out on inside [row].
  int linesOfTitle(WidgetTester tester, Finder row, String word) {
    final title = find.descendant(of: row, matching: find.text(word));
    final paragraph = tester.renderObject<RenderParagraph>(title);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: word.length),
    );
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  for (final width in [412.0, 360.0, 320.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('«Calendarios» / «Mi cuadrante» at $width dp, text $scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final app = await AppUnderTest.pump(tester, size: Size(width, tall));
        await app.openSettings();

        final row = find.byKey(const ValueKey('settings-calendars'));
        expect(row, findsOneWidget);
        expect(
          find.descendant(of: row, matching: find.text('Mi cuadrante')),
          findsOneWidget,
        );

        // The word is whole, on one line: it is the value that gives way
        // (it goes under the title when they do not fit side by side).
        expect(linesOfTitle(tester, row, 'Calendarios'), 1);

        // And the value is whole too, or ellipsized only when it is longer
        // than the row; never clipped to a few letters.
        final value = tester.renderObject<RenderParagraph>(
          find.descendant(of: row, matching: find.text('Mi cuadrante')),
        );
        expect(value.didExceedMaxLines, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
