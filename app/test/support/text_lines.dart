import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The lines of [paragraph] as laid out, each as the text it shows (a line
/// break at a space keeps the space out of the line). Lets a test check that
/// a text wrapped between words and not in the middle of one.
List<String> paragraphLines(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  final rows = <double, StringBuffer>{};
  for (var i = 0; i < text.length; i++) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: i + 1),
    );
    if (boxes.isEmpty) continue;
    final top = boxes.first.top.roundToDouble();
    rows.putIfAbsent(top, StringBuffer.new).write(text[i]);
  }
  final tops = rows.keys.toList()..sort();
  return [for (final t in tops) rows[t].toString().trim()];
}

/// Whether [paragraph] wraps only between words: no word of its text is split
/// across two lines.
bool wrapsOnlyBetweenWords(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  final words = text.trim().split(RegExp(r'\s+'));
  final fragments = [
    for (final line in paragraphLines(paragraph)) ...line.split(RegExp(r'\s+')),
  ];
  // A split word turns into more fragments than the text has words.
  return fragments.length == words.length;
}

/// The lines of every paragraph on screen that breaks inside a word or a
/// number (see [wrapsOnlyBetweenWords]); empty when all of them wrap between
/// words. Icons count as one-character paragraphs.
List<String> brokenParagraphs(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    if (!wrapsOnlyBetweenWords(element.renderObject! as RenderParagraph))
      paragraphLines(element.renderObject! as RenderParagraph).join(' | '),
];
