import 'package:flutter/painting.dart';

import '../../../core/theme/shift_palette.dart';

/// Arithmetic of the free colour picker of the shift editor («Más colores»,
/// `docs/paridad.md` A10): hue / saturation / lightness to the stored ARGB
/// value and back, and the hex text. Pure functions, no widgets.
///
/// Any colour is valid to store: what is drawn from it (tint, disc, and the
/// ink, always with AA contrast) is derived by `ShiftSwatch`.
class FreeColor {
  const FreeColor._();

  /// Stored colour [argb] as the picker keeps it: opaque, and never the exact
  /// grey of "Libre" (that value is special, it turns the shift into a rest
  /// cell), which moves to the neighbouring grey.
  static int normalize(int argb) {
    final opaque = 0xFF000000 | (argb & 0x00FFFFFF);
    return ShiftPalette.isRest(opaque) ? opaque + 1 : opaque;
  }

  /// Opaque ARGB value of a colour given as hue (0 to 360), saturation and
  /// lightness (both 0 to 1). Out-of-range values are clamped.
  static int fromHsl(double hue, double saturation, double lightness) =>
      normalize(
        HSLColor.fromAHSL(
          1,
          hue.clamp(0, 360).toDouble(),
          saturation.clamp(0, 1).toDouble(),
          lightness.clamp(0, 1).toDouble(),
        ).toColor().toARGB32(),
      );

  /// Hue / saturation / lightness of [argb].
  static HSLColor toHsl(int argb) => HSLColor.fromColor(Color(argb));

  /// `#RRGGBB`, upper case.
  static String toHex(int argb) =>
      '#${(argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// The colour typed as hex: `#RRGGBB`, `RRGGBB` or the short `#RGB` /
  /// `RGB`, in any case and with surrounding spaces. `null` when it is not
  /// one of those.
  static int? parseHex(String text) {
    var digits = text.trim();
    if (digits.startsWith('#')) digits = digits.substring(1);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(digits)) return null;
    if (digits.length == 3) {
      digits = digits.split('').map((c) => '$c$c').join();
    }
    if (digits.length != 6) return null;
    return normalize(int.parse(digits, radix: 16));
  }
}
