import 'package:cuadrante/features/summary/application/offscreen_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the render objects of the off-screen drawing are disposed', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => renderWidgetToPng(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: Color(0xFF336699),
            child: SizedBox(width: 100, height: 50),
          ),
        ),
        width: 100,
        pixelRatio: 1,
      ),
    );
    expect(png, isNotNull);
    expect(png!.length, greaterThan(8));
    expect(debugLastOffscreenBoundary, isNotNull);
    expect(debugLastOffscreenBoundary!.debugDisposed, isTrue);
  });
}
