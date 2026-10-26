import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Geometry of the month grid (a lattice of [columns] x [rows] cells filling
/// [width] x [height], after a [gutter] at the left for the week numbers);
/// maps pointer positions to cell indices (`row * columns + column`).
///
/// The paint gesture lives in one layer over the whole grid, so it needs
/// this instead of per-cell hit testing.
class GridGeometry {
  const GridGeometry({
    required this.width,
    required this.height,
    this.columns = 7,
    this.rows = 6,
    this.gutter = 0,
    this.rowHeights,
  });

  final double width;
  final double height;
  final int columns;
  final int rows;

  /// Content-dependent week heights; omitted for a uniform lattice.
  final List<double>? rowHeights;
  double rowHeight(int row) {
    assert(rowHeights == null || rowHeights!.length == rows);
    return rowHeights?[row] ?? cellHeight;
  }

  /// Width at the left of the first column that belongs to no cell (the week
  /// numbers): a pointer there hits nothing.
  final double gutter;

  double get cellWidth => (width - gutter) / columns;
  double get cellHeight => height / rows;

  int get cellCount => columns * rows;

  /// Cell under [position] (grid-local), or null outside the grid.
  int? cellAt(Offset position) {
    final x = position.dx - gutter;
    final y = position.dy;
    if (x < 0 || y < 0 || x >= width - gutter || y >= height) return null;
    final column = math.min(columns - 1, x ~/ cellWidth);
    var bottom = 0.0;
    for (var row = 0; row < rows; row++) {
      bottom += rowHeight(row);
      if (y < bottom) return row * columns + column;
    }
    return null;
  }

  /// Cells crossed by the segment [from] -> [to], in order, without
  /// consecutive repeats. The segment is sampled every quarter of the
  /// smallest cell side, so a fast or diagonal drag between two pointer
  /// events cannot skip a cell it passed through.
  List<int> cellsAlong(Offset from, Offset to) {
    final smallestHeight = rowHeights?.reduce(math.min) ?? cellHeight;
    final step = math.min(cellWidth, smallestHeight) / 4;
    final distance = (to - from).distance;
    final samples = step <= 0 ? 1 : math.max(1, (distance / step).ceil());
    final cells = <int>[];
    for (var i = 0; i <= samples; i++) {
      final cell = cellAt(Offset.lerp(from, to, i / samples)!);
      if (cell != null && (cells.isEmpty || cells.last != cell)) {
        cells.add(cell);
      }
    }
    return cells;
  }
}
