import 'package:cuadrante/core/widgets/value_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// H-T11-6. The test font (Ahem) is twice as wide as a real one, so the rows
/// here use half the size of the app's body text: 7.5 px per glyph is what
/// 15 sp of Roboto averages. The row widths are those of a settings row on a
/// 360 dp and a 320 dp screen (the screen minus the page margin, the row inset
/// and the chevron column).
const double _glyph = 7.5;
const double _chevron = 16;
const double _chevronGap = 4;
const double _valueGap = 8;

const _titleKey = ValueKey('title');
const _valueKey = ValueKey('value');
const _chevronKey = ValueKey('chevron');

/// (title, value) pairs from the QA findings.
const _cases = [
  ('Texto del aviso', 'El de siempre'),
  ('Calendarios', 'Mi cuadrante'),
  ('Antes del turno', '1 h 30 min'),
];

Widget _row(String title, String? value, {double width = 280, Key? key}) {
  const style = TextStyle(fontSize: _glyph);
  return Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      child: ValueRow(
        key: key,
        title: Text(title, key: _titleKey, style: style),
        value: value == null
            ? null
            : Text(
                value,
                key: _valueKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: style,
              ),
        trailing: const SizedBox(key: _chevronKey, width: _chevron, height: 24),
        trailingGap: _chevronGap,
        valueGap: _valueGap,
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget child, double scale) =>
    tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child),
        ),
      ),
    );

RenderParagraph _paragraph(WidgetTester tester, Key key) =>
    tester.renderObject<RenderParagraph>(find.byKey(key));

/// The widest word of [text] as laid out (scaled): the narrowest the text
/// can get without breaking a word in two.
double _longestWord(String text, double scale) {
  var widest = 0.0;
  for (final word in text.split(' ')) {
    final painter = TextPainter(
      text: TextSpan(
        text: word,
        style: const TextStyle(fontSize: _glyph),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  return widest;
}

void main() {
  const widths = {'360 dp': 280.0, '320 dp': 240.0};
  for (final MapEntry(key: label, value: width) in widths.entries) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final (title, value) in _cases) {
        testWidgets('$label, text $scale: «$title» / «$value» keeps the '
            'value whole, no word broken, chevron in place', (tester) async {
          await _pump(tester, _row(title, value, width: width), scale);
          expect(tester.takeException(), isNull);

          final titleBox = tester.getRect(find.byKey(_titleKey));
          final valueBox = tester.getRect(find.byKey(_valueKey));
          final chevron = tester.getRect(find.byKey(_chevronKey));

          // No ellipsis on the value, and the value is as wide as its text.
          expect(_paragraph(tester, _valueKey).didExceedMaxLines, isFalse);
          expect(
            valueBox.width,
            greaterThanOrEqualTo(
              _paragraph(
                    tester,
                    _valueKey,
                  ).getMaxIntrinsicWidth(double.infinity) -
                  0.5,
            ),
            reason: 'value not cut',
          );
          // No word of the title in two: its box is at least as wide as its
          // longest word.
          expect(
            titleBox.width,
            greaterThanOrEqualTo(_longestWord(title, scale) - 0.5),
            reason: 'title not broken mid-word',
          );
          // Chevron flush at the trailing edge of the row, in the row.
          expect(chevron.right, closeTo(width, 0.01));
          final row = tester.getRect(find.byType(ValueRow));
          expect(chevron.top, greaterThanOrEqualTo(row.top));
          expect(chevron.bottom, lessThanOrEqualTo(row.bottom));
          // Neither overlaps the other nor the chevron.
          expect(valueBox.right, lessThanOrEqualTo(chevron.left + 0.01));
          expect(titleBox.right, lessThanOrEqualTo(chevron.left + 0.01));

          final inline = (valueBox.center.dy - titleBox.center.dy).abs() < 4;
          if (inline) {
            // Side by side: the value ends just before the chevron.
            expect(valueBox.right, closeTo(chevron.left - _chevronGap, 0.5));
          } else {
            // Stacked: the value is under the title, starting where it does.
            expect(valueBox.top, greaterThanOrEqualTo(titleBox.bottom));
            expect(valueBox.left, closeTo(titleBox.left, 0.01));
          }
        });
      }
    }
  }

  testWidgets('at text 1.0 a short value stays beside its title', (
    tester,
  ) async {
    await _pump(tester, _row('Antes del turno', '1 h 30 min'), 1.0);
    final title = tester.getRect(find.byKey(_titleKey));
    final value = tester.getRect(find.byKey(_valueKey));
    expect(value.center.dy, closeTo(title.center.dy, 0.5));
    expect(value.left, greaterThan(title.right));
  });

  testWidgets('from text 1.3, a title and value that do not both fit on '
      'one line stack, with the chevron still on the right and centred', (
    tester,
  ) async {
    await _pump(tester, _row('Texto del aviso', 'El de siempre'), 1.3);
    final title = tester.getRect(find.byKey(_titleKey));
    final value = tester.getRect(find.byKey(_valueKey));
    final chevron = tester.getRect(find.byKey(_chevronKey));
    final row = tester.getRect(find.byType(ValueRow));
    expect(value.top, greaterThanOrEqualTo(title.bottom));
    expect(chevron.right, closeTo(280, 0.01));
    expect(chevron.center.dy, closeTo(row.center.dy, 0.5));
  });

  testWidgets('a value that fits inline at 1.0 but would cut at 1.3 is the '
      'QA case of «El de sie…»', (tester) async {
    // Same strings, same width: inline at 1.0, stacked and whole at 1.3.
    await _pump(tester, _row('Texto del aviso', 'El de siempre'), 1.0);
    expect(
      tester.getRect(find.byKey(_valueKey)).center.dy,
      closeTo(tester.getRect(find.byKey(_titleKey)).center.dy, 0.5),
    );
    await _pump(tester, _row('Texto del aviso', 'El de siempre'), 1.3);
    expect(_paragraph(tester, _valueKey).didExceedMaxLines, isFalse);
  });

  testWidgets('a value that would force a word of the title to break '
      'stacks even at text 1.0', (tester) async {
    // «Calendarios» is 82 wide, the value 186: 82 + 8 + 186 > 220 - 20.
    await _pump(
      tester,
      _row('Calendarios', 'Mi calendario de trabajo', width: 220),
      1.0,
    );
    final title = tester.getRect(find.byKey(_titleKey));
    final value = tester.getRect(find.byKey(_valueKey));
    expect(title.width, greaterThanOrEqualTo(11 * _glyph - 0.5));
    expect(value.top, greaterThanOrEqualTo(title.bottom));
    expect(_paragraph(tester, _valueKey).didExceedMaxLines, isFalse);
  });

  testWidgets('a value longer than the whole row is ellipsized, never the '
      'title', (tester) async {
    await _pump(
      tester,
      _row('Calendarios', 'Un nombre de calendario larguísimo que no cabe'),
      1.0,
    );
    expect(tester.takeException(), isNull);
    expect(_paragraph(tester, _valueKey).didExceedMaxLines, isTrue);
    expect(_paragraph(tester, _titleKey).didExceedMaxLines, isFalse);
    expect(
      tester.getRect(find.byKey(_titleKey)).width,
      greaterThanOrEqualTo(11 * _glyph - 0.5),
    );
  });

  testWidgets('without a value the title takes the free space', (tester) async {
    await _pump(tester, _row('Mis turnos', null), 1.0);
    final title = tester.getRect(find.byKey(_titleKey));
    final chevron = tester.getRect(find.byKey(_chevronKey));
    expect(title.left, 0);
    expect(chevron.right, closeTo(280, 0.01));
    expect(title.right, lessThanOrEqualTo(chevron.left));
  });

  testWidgets('right-to-left puts the chevron at the left edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: _row('Antes del turno', '1 h 30 min')),
        ),
      ),
    );
    final chevron = tester.getRect(find.byKey(_chevronKey));
    final row = tester.getRect(find.byType(ValueRow));
    expect(chevron.left, closeTo(row.left, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a leading widget keeps its column in both layouts', (
    tester,
  ) async {
    Widget withLeading(String title, String value) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 280,
        child: ValueRow(
          leading: const SizedBox(key: ValueKey('lead'), width: 40, height: 40),
          title: Text(
            title,
            key: _titleKey,
            style: const TextStyle(fontSize: 7.5),
          ),
          value: Text(
            value,
            key: _valueKey,
            maxLines: 1,
            style: const TextStyle(fontSize: 7.5),
          ),
        ),
      ),
    );
    for (final scale in [1.0, 2.0]) {
      await _pump(tester, withLeading('Calendarios', 'Mi cuadrante'), scale);
      expect(tester.getRect(find.byKey(const ValueKey('lead'))).left, 0);
      expect(tester.getRect(find.byKey(_titleKey)).left, 40);
      expect(tester.takeException(), isNull);
    }
  });

  group('H-T11-6 reserve: a long value wraps under the title', () {
    // A plain `Text`: the row gives it its three lines, its ellipsis and its
    // alignment (a settings row with a custom «Texto del aviso»).
    Widget plain(String title, String value, {double width = 240}) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: ValueRow(
          title: Text(
            title,
            key: _titleKey,
            style: const TextStyle(fontSize: _glyph),
          ),
          value: Text(
            value,
            key: _valueKey,
            style: const TextStyle(fontSize: _glyph),
          ),
          trailing: const SizedBox(
            key: _chevronKey,
            width: _chevron,
            height: 24,
          ),
          trailingGap: _chevronGap,
        ),
      ),
    );

    const long = 'Preparar la mochila y llevar el uniforme de refuerzo';

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('text $scale: up to three lines, whole words, left edge '
          'on the title\'s', (tester) async {
        await _pump(tester, plain('Texto del aviso', long), scale);
        expect(tester.takeException(), isNull);
        final title = tester.getRect(find.byKey(_titleKey));
        final value = tester.getRect(find.byKey(_valueKey));
        final paragraph = _paragraph(tester, _valueKey);

        // Under the title, starting where it starts (not pushed to the right).
        expect(value.top, greaterThanOrEqualTo(title.bottom));
        expect(value.left, closeTo(title.left, 0.01));
        // More than one line, at most three.
        final lines = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: long.length),
            )
            .map((b) => b.top.round())
            .toSet();
        expect(lines.length, inInclusiveRange(2, 3));
        // No ellipsis while it fits in three lines, and no word broken.
        if (scale <= 1.3) expect(paragraph.didExceedMaxLines, isFalse);
        final fragments = <String>[];
        for (final top in lines.toList()..sort()) {
          final text = StringBuffer();
          for (var i = 0; i < long.length; i++) {
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: i, extentOffset: i + 1),
            );
            if (boxes.isNotEmpty && boxes.first.top.round() == top) {
              text.write(long[i]);
            }
          }
          fragments.addAll(text.toString().trim().split(' '));
        }
        if (!paragraph.didExceedMaxLines) {
          expect(fragments.length, long.split(' ').length);
        }
      });
    }

    testWidgets('longer than three lines: the third ends in an ellipsis', (
      tester,
    ) async {
      final huge = List.filled(6, long).join(' ');
      await _pump(tester, plain('Texto del aviso', huge), 2.0);
      final paragraph = _paragraph(tester, _valueKey);
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(
        paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: huge.length),
            )
            .map((b) => b.top.round())
            .toSet()
            .length,
        3,
      );
    });

    testWidgets('a short value stays one line, flush at the right, with the '
        'title beside it', (tester) async {
      await _pump(tester, plain('Antes del turno', '1 h 30'), 1.0);
      final title = tester.getRect(find.byKey(_titleKey));
      final value = tester.getRect(find.byKey(_valueKey));
      final chevron = tester.getRect(find.byKey(_chevronKey));
      expect(value.center.dy, closeTo(title.center.dy, 0.5));
      expect(value.right, closeTo(chevron.left - _chevronGap, 0.5));
    });
  });

  group('a detail under the value (H-T08-1)', () {
    const detailKey = ValueKey('detail');
    const style = TextStyle(fontSize: _glyph);

    Widget withDetail(
      String title,
      String value,
      String detail, {
      bool forceStacked = false,
    }) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 280,
        child: ValueRow(
          crossAxisAlignment: CrossAxisAlignment.start,
          forceStacked: forceStacked,
          title: Text(title, key: _titleKey, style: style),
          value: Text(value, key: _valueKey, style: style),
          detail: Text(detail, key: detailKey, style: style),
        ),
      ),
    );

    testWidgets('side by side the value and the detail are both flush right', (
      tester,
    ) async {
      await _pump(tester, withDetail('Horas extra', '+2 h', '+20 €'), 1.0);
      final value = tester.getRect(find.byKey(_valueKey));
      final detail = tester.getRect(find.byKey(detailKey));
      expect(value.right, closeTo(280, 0.01));
      expect(detail.right, closeTo(280, 0.01));
      expect(detail.top, greaterThanOrEqualTo(value.bottom - 0.01));
      // The title is on the first line, next to the value.
      expect(
        tester.getRect(find.byKey(_titleKey)).top,
        closeTo(value.top, 0.5),
      );
    });

    testWidgets('stacked, the value and the detail go under the title, '
        'aligned with it, never floating', (tester) async {
      await _pump(
        tester,
        withDetail('Salidas anticipadas', '−1 h', '−10,00 € en el estimado'),
        2.0,
      );
      final title = tester.getRect(find.byKey(_titleKey));
      final value = tester.getRect(find.byKey(_valueKey));
      final detail = tester.getRect(find.byKey(detailKey));
      expect(value.left, closeTo(title.left, 0.01));
      expect(detail.left, closeTo(title.left, 0.01));
      expect(value.top, greaterThanOrEqualTo(title.bottom - 0.01));
      expect(detail.top, greaterThanOrEqualTo(value.bottom - 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('forceStacked stacks a row that would fit beside its '
        'title', (tester) async {
      await _pump(
        tester,
        withDetail('Municipio', 'Barcelona', '', forceStacked: true),
        1.0,
      );
      final title = tester.getRect(find.byKey(_titleKey));
      final value = tester.getRect(find.byKey(_valueKey));
      expect(value.top, greaterThanOrEqualTo(title.bottom - 0.01));
      expect(value.left, closeTo(title.left, 0.01));

      await _pump(tester, _row('Municipio', 'Barcelona'), 1.0);
      expect(
        tester.getRect(find.byKey(_valueKey)).center.dy,
        closeTo(tester.getRect(find.byKey(_titleKey)).center.dy, 0.5),
        reason: 'without forceStacked it stays beside',
      );
    });
  });
}
