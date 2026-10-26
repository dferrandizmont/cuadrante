import 'dart:ui' show Brightness;

import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:flutter_test/flutter_test.dart';

/// The colours the shift editor offers (the eight of the specification plus
/// 16 more) must read in both themes: whatever the user picks, the code ink
/// reaches AA on the cell tint and on the disc.
void main() {
  test('the grid has the eight defaults and 16 extra hues, all different', () {
    expect(ShiftPalette.extras, hasLength(16));
    expect(ShiftPalette.editorChoices, hasLength(24));
    expect(
      ShiftPalette.editorChoices.map((c) => c.toARGB32()).toSet(),
      hasLength(24),
    );
    // Only the specification's Libre is the special grey.
    expect(
      ShiftPalette.extras.where((c) => ShiftPalette.isRest(c.toARGB32())),
      isEmpty,
    );
  });

  for (final brightness in Brightness.values) {
    for (final color in ShiftPalette.editorChoices) {
      final hex = color.toARGB32().toRadixString(16);
      test('$hex in ${brightness.name}: ink >= 4.5 on tint and disc', () {
        final swatch = ShiftSwatch.forColor(color.toARGB32(), brightness);
        expect(
          contrastRatio(swatch.ink, swatch.tint),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(swatch.ink, swatch.disc),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }

  test('the bars of the extras show against the dark background', () {
    for (final color in ShiftPalette.extras) {
      final swatch = ShiftSwatch.forColor(color.toARGB32(), Brightness.dark);
      expect(
        contrastRatio(swatch.bar, AppColors.dark.surface),
        greaterThanOrEqualTo(3),
        reason: color.toARGB32().toRadixString(16),
      );
    }
  });
}
