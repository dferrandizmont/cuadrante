import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart' show AppColors, TonePair;
export 'app_typography.dart' show AppTypography;
export 'shift_palette.dart' show ShiftPalette, contrastRatio;
export 'shift_swatch.dart' show ShiftSwatch, kTextContrast;
export 'spacing.dart';

extension AppThemeContext on BuildContext {
  /// Colour tokens of the active theme.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// Text styles of the active theme.
  AppTypography get type => Theme.of(this).extension<AppTypography>()!;

  /// True when the surrounding text scale makes side-by-side layouts tight.
  bool get largeText => MediaQuery.textScalerOf(this).scale(14) > 14 * 1.3;
}
