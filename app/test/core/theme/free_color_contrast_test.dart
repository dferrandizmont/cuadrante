import 'dart:ui' show Brightness;

import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:cuadrante/features/shift_types/domain/free_color.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Más colores» (docs/paridad.md A10): whatever colour the free picker
/// produces, the ink the swatch derives reaches AA (4.5:1) on the cell tint
/// and on the disc, in both themes, in the month and outside it. The grid
/// colours are covered by `editor_colors_test.dart`; this sweeps the whole
/// hue / saturation / lightness space the sliders reach.
void main() {
  final colors = <int>[
    for (var hue = 0.0; hue < 360; hue += 12)
      for (final saturation in [0.0, 0.1, 0.35, 0.6, 0.85, 1.0])
        for (final lightness in [
          0.0,
          0.05,
          0.2,
          0.35,
          0.5,
          0.65,
          0.8,
          0.95,
          1.0,
        ])
          FreeColor.fromHsl(hue, saturation, lightness),
    // The corners and the awkward ones.
    0xFF000000,
    0xFFFFFFFF,
    0xFF808080,
    0xFFFFFF00,
    0xFF00FFFF,
    0xFFFF00FF,
    0xFF0000FF,
    0xFFFF0000,
    0xFF00FF00,
  ];

  for (final brightness in Brightness.values) {
    for (final outOfMonth in [false, true]) {
      test(
        '${colors.length} free colours in ${brightness.name}'
        '${outOfMonth ? ' (out of month)' : ''}: ink >= 4.5 on tint and disc',
        () {
          var worst = double.infinity;
          for (final color in colors) {
            final swatch = ShiftSwatch.forColor(
              color,
              brightness,
              outOfMonth: outOfMonth,
            );
            final onTint = contrastRatio(swatch.ink, swatch.tint);
            final onDisc = contrastRatio(swatch.ink, swatch.disc);
            final hex = color.toRadixString(16);
            expect(
              onTint,
              greaterThanOrEqualTo(kTextContrast),
              reason: '$hex on the tint',
            );
            expect(
              onDisc,
              greaterThanOrEqualTo(kTextContrast),
              reason: '$hex on the disc',
            );
            if (onTint < worst) worst = onTint;
          }
          expect(worst, greaterThanOrEqualTo(kTextContrast));
        },
      );
    }
  }

  test('dark mode lifts a near-black bar so it shows on the dark surface', () {
    for (final color in colors) {
      final bar = ShiftSwatch.forColor(color, Brightness.dark).bar;
      final swatch = ShiftSwatch.forColor(color, Brightness.dark);
      if (swatch.isRest) continue;
      expect(
        bar.computeLuminance(),
        greaterThanOrEqualTo(ShiftSwatch.minDarkBarLuminance - 0.001),
        reason: color.toRadixString(16),
      );
    }
  });

  test('no free colour turns into the special grey of Libre', () {
    for (final color in colors) {
      expect(ShiftPalette.isRest(color), isFalse, reason: '$color');
    }
    expect(ShiftPalette.isRest(FreeColor.normalize(0xFFE4E4E7)), isFalse);
    expect(ShiftPalette.isRest(FreeColor.parseHex('#E4E4E7')!), isFalse);
  });
}
