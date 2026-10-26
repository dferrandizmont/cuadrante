import 'package:cuadrante/features/calendar/presentation/puck_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/real_font.dart';
import '../../support/text_lines.dart';

// QA campaign, T02 (H-T02-6): with text x2.0 the name of a tool split in the
// middle of a word («Mañan / a») and the chosen one («Saliente») was cut.
// The pucks were measured with the bare style, not with the one the Text
// draws with (the default style of the tree adds the font, the letter
// spacing...), so on a phone the measure came out short.

const _style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

Widget _app({required Widget child, double scale = 2.0, TextStyle? base}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: DefaultTextStyle(
            style: base ?? const TextStyle(fontFamily: 'Roboto'),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  for (final label in [
    'Mañana',
    'Saliente',
    'Vacaciones',
    'Libre disposición',
  ]) {
    testWidgets('«$label»: the puck is as wide as the Text really draws, '
        'also when the tree adds letter spacing to the style', (tester) async {
      late double width;
      await tester.pumpWidget(
        _app(
          base: const TextStyle(fontFamily: 'Roboto', letterSpacing: 14),
          child: Builder(
            builder: (context) {
              width = puckWidth(
                context,
                label: label,
                style: _style,
                minWidth: 40,
              );
              return SizedBox(
                width: width,
                child: PuckLabel(label: label, style: _style),
              );
            },
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(wrapsOnlyBetweenWords(paragraph), isTrue);
      expect(paragraph.didExceedMaxLines, isFalse);
      // Drawn at full size: the puck was wide enough, nothing was shrunk.
      expect(
        tester.widget<Text>(find.text(label)).style!.fontSize,
        _style.fontSize,
      );
    });
  }

  testWidgets('a box narrower than the longest word shrinks the name, it '
      'never splits the word', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SizedBox(
          width: 82,
          child: PuckLabel(label: 'Mañana', style: _style),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text('Mañana'));
    expect(paragraphLines(paragraph), ['Mañana']);
    expect(paragraph.didExceedMaxLines, isFalse);
    final size = tester.widget<Text>(find.text('Mañana')).style!.fontSize!;
    expect(size, lessThan(12));
    expect(size, greaterThanOrEqualTo(12 * PuckLabel.minScale - 0.01));
  });

  testWidgets('the shrinking stops at its floor', (tester) async {
    await tester.pumpWidget(
      _app(
        child: SizedBox(
          width: 20,
          child: PuckLabel(label: 'Mañana', style: _style),
        ),
      ),
    );
    final size = tester.widget<Text>(find.text('Mañana')).style!.fontSize!;
    expect(size, closeTo(12 * PuckLabel.minScale, 0.5));
  });
}
