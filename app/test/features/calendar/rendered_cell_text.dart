import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bounds after ancestor paint transforms, including a FittedBox's scale.
Rect renderedTextRect(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  return MatrixUtils.transformRect(
    paragraph.getTransformTo(null),
    Offset.zero & paragraph.size,
  );
}

/// A large layout fontSize alone does not prove the glyphs are readable:
/// an ancestor FittedBox can shrink the entire code/time column at paint time.
void expectUnscaledCellText(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final transform = paragraph.getTransformTo(null);
  final origin = MatrixUtils.transformPoint(transform, Offset.zero);
  for (final axis in [const Offset(1, 0), const Offset(0, 1)]) {
    final unit = MatrixUtils.transformPoint(transform, axis) - origin;
    expect(
      unit.distance,
      closeTo(1, 0.0001),
      reason: 'text is not paint-scaled',
    );
  }
  expect(paragraph.didExceedMaxLines, isFalse);
}
