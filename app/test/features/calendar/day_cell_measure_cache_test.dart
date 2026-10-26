import 'package:cuadrante/features/calendar/presentation/day_cell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const style = TextStyle(fontSize: 10);
  const scale = TextScaler.noScaling;
  const largeScale = TextScaler.linear(2);

  setUp(debugClearCellMeasures);
  tearDown(debugClearCellMeasures);

  test('measurements distinguish text, style and scale', () {
    final wideStyle = style.copyWith(fontSize: 20, letterSpacing: 2);
    final height = textHeight(style, scale);
    final width = textWidth('M', style, scale);
    expect(textHeight(style, largeScale), greaterThan(height));
    expect(textHeight(wideStyle, scale), greaterThan(height));
    expect(textWidth('M', style, largeScale), greaterThan(width));
    expect(textWidth('M', wideStyle, scale), greaterThan(width));
    expect(textWidth('MM', style, scale), greaterThan(width));
    expect(textHeight(style, scale), height);
    expect(textWidth('M', style, scale), width);
    expect(debugCellMeasureKeys.heights, hasLength(3));
    expect(debugCellMeasureKeys.widths, hasLength(4));
  });

  test('both caches evict the least recently used entry above 256', () {
    for (var i = 0; i < 256; i++) {
      textHeight(style.copyWith(fontSize: 10 + i.toDouble()), scale);
      textWidth('$i', style, scale);
    }
    expect(debugCellMeasureKeys.heights, hasLength(256));
    expect(debugCellMeasureKeys.widths, hasLength(256));
    // Refresh the oldest entry. The second entry must now be evicted.
    textHeight(style, scale);
    textWidth('0', style, scale);
    textHeight(style.copyWith(fontSize: 300), scale);
    textWidth('256', style, scale);
    expect(debugCellMeasureKeys.heights, hasLength(256));
    expect(debugCellMeasureKeys.widths, hasLength(256));
    expect(debugCellMeasureKeys.heights, contains((style, scale)));
    expect(debugCellMeasureKeys.widths, contains(('0', style, scale)));
    expect(
      debugCellMeasureKeys.heights,
      isNot(contains((style.copyWith(fontSize: 11), scale))),
    );
    expect(debugCellMeasureKeys.widths, isNot(contains(('1', style, scale))));
    // Re-measuring an evicted entry remains correct and keeps the bound.
    final height = textHeight(style.copyWith(fontSize: 11), scale);
    final width = textWidth('1', style, scale);
    expect(height, greaterThan(0));
    expect(width, greaterThan(0));
    expect(debugCellMeasureKeys.heights, hasLength(256));
    expect(debugCellMeasureKeys.widths, hasLength(256));
  });
}
