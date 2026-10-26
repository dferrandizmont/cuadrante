import 'package:cuadrante/features/calendar/presentation/grid_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 7 x 6 cells of 50 x 100.
  const g = GridGeometry(width: 350, height: 600);

  test('maps positions to row-major cell indices', () {
    expect(g.cellAt(const Offset(0, 0)), 0);
    expect(g.cellAt(const Offset(49.9, 99.9)), 0);
    expect(g.cellAt(const Offset(50, 0)), 1);
    expect(g.cellAt(const Offset(349.9, 0)), 6);
    expect(g.cellAt(const Offset(0, 100)), 7);
    expect(g.cellAt(const Offset(349.9, 599.9)), 41);
  });

  test('positions outside the grid hit nothing', () {
    expect(g.cellAt(const Offset(-1, 10)), isNull);
    expect(g.cellAt(const Offset(10, -1)), isNull);
    expect(g.cellAt(const Offset(350, 10)), isNull);
    expect(g.cellAt(const Offset(10, 600)), isNull);
  });

  test('a short segment inside one cell yields that cell', () {
    expect(g.cellsAlong(const Offset(10, 10), const Offset(20, 15)), [0]);
  });

  test('a fast horizontal drag does not skip cells', () {
    // One pointer event from cell 0 to cell 4.
    expect(g.cellsAlong(const Offset(25, 50), const Offset(225, 50)), [
      0,
      1,
      2,
      3,
      4,
    ]);
  });

  test('a fast drag to the left lists cells in travel order', () {
    expect(g.cellsAlong(const Offset(225, 50), const Offset(25, 50)), [
      4,
      3,
      2,
      1,
      0,
    ]);
  });

  test('a diagonal drag follows the line cell by cell', () {
    // From the centre of cell 0 to the centre of cell 16 (row 2, col 2).
    final cells = g.cellsAlong(const Offset(25, 50), const Offset(125, 250));
    expect(cells.first, 0);
    expect(cells.last, 16);
    // Every step moves to a cell that touches the previous one.
    for (var i = 1; i < cells.length; i++) {
      final dr = (cells[i] ~/ 7 - cells[i - 1] ~/ 7).abs();
      final dc = (cells[i] % 7 - cells[i - 1] % 7).abs();
      expect(dr <= 1 && dc <= 1 && (dr + dc) > 0, isTrue, reason: '$cells');
    }
  });

  test('parts of the segment outside the grid are ignored', () {
    expect(g.cellsAlong(const Offset(-50, 50), const Offset(75, 50)), [0, 1]);
  });
  group('content-dependent week heights', () {
    const varied = GridGeometry(
      width: 350,
      height: 540,
      gutter: 0,
      rowHeights: [60, 60, 240, 60, 60, 60],
    );

    test('maps both sides of every unequal week boundary', () {
      expect(varied.cellAt(const Offset(25, 59.9)), 0);
      expect(varied.cellAt(const Offset(25, 60)), 7);
      expect(varied.cellAt(const Offset(25, 119.9)), 7);
      expect(varied.cellAt(const Offset(25, 120)), 14);
      expect(varied.cellAt(const Offset(25, 359.9)), 14);
      expect(varied.cellAt(const Offset(25, 360)), 21);
      expect(varied.cellAt(const Offset(349.9, 539.9)), 41);
      expect(varied.cellAt(const Offset(25, 540)), isNull);
    });

    test(
      'fast vertical strokes keep every crossed date in either direction',
      () {
        expect(varied.cellsAlong(const Offset(25, 30), const Offset(25, 510)), [
          0,
          7,
          14,
          21,
          28,
          35,
        ]);
        expect(varied.cellsAlong(const Offset(25, 510), const Offset(25, 30)), [
          35,
          28,
          21,
          14,
          7,
          0,
        ]);
      },
    );

    test('week number gutter remains outside all variable-height cells', () {
      const gutter = GridGeometry(
        width: 374,
        height: 540,
        gutter: 24,
        rowHeights: [60, 60, 240, 60, 60, 60],
      );
      expect(gutter.cellAt(const Offset(23.9, 240)), isNull);
      expect(gutter.cellAt(const Offset(24, 240)), 14);
      expect(gutter.cellAt(const Offset(373.9, 360)), 27);
    });
  });
}
