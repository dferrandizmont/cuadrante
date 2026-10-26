import 'dart:ui' show Brightness;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import 'app_colors.dart';
import 'shift_palette.dart';

/// Minimum contrast of any text on its real background (WCAG AA).
const double kTextContrast = 4.5;

/// Dark mode inks aim higher than the AA minimum: at night the dimmed tints
/// need a brighter code to read at a glance (docs/diseno.md, mockup B).
const double kDarkInkContrast = 6.5;

/// Colours of one shift on screen, derived from the single colour the user
/// stores per shift type (`docs/diseno.md`, "Color de cada turno"). Pure
/// colour maths, no widgets: the app, the widget contract and the tests share
/// it. Derived at paint time, never stored.
@immutable
class ShiftSwatch {
  const ShiftSwatch({
    required this.bar,
    required this.tint,
    required this.disc,
    required this.ink,
    this.isRest = false,
  });

  /// Bottom bar of the day cell and the "today" card; border of the stroke.
  final Color bar;

  /// Background of the day cell: a soft mix of the shift colour on `surface`.
  final Color tint;

  /// Background of the paint puck and of the badge of the "today" card.
  final Color disc;

  /// Code and any text in the shift's hue: at least 4.5:1 on [tint] and on
  /// [disc].
  final Color ink;

  /// "Libre": no tint, neutral bar and ink.
  final bool isRest;

  /// Share of the shift colour in [tint] (light, dark).
  static const double lightTintShare = 0.10;
  static const double darkTintShare = 0.14;

  /// Share of the shift colour in [disc] (light, dark).
  static const double lightDiscShare = 0.18;
  static const double darkDiscShare = 0.28;

  /// In dark mode a bar darker than this luminance is lightened to it.
  static const double minDarkBarLuminance = 0.18;

  /// Opacity of the bar on days of the neighbouring months.
  static const double outOfMonthBarOpacity = 0.45;

  /// Lightness step of the contrast search (HSL, 0 to 1).
  static const double _lightnessStep = 0.01;

  /// Swatch of a stored ARGB colour value. With [outOfMonth] (days of the
  /// neighbouring months): `surfaceMuted` background, no tint, `textMuted`
  /// code and the bar at 45 % (blended on `surfaceMuted`, so it is opaque).
  factory ShiftSwatch.forColor(
    int colorValue,
    Brightness brightness, {
    bool outOfMonth = false,
  }) {
    // The grid asks for the same few swatches on every frame of a stroke.
    final key = colorValue * 4 + brightness.index * 2 + (outOfMonth ? 1 : 0);
    return _cache[key] ??= ShiftSwatch._derive(
      colorValue,
      brightness,
      outOfMonth,
    );
  }

  static final _cache = <int, ShiftSwatch>{};

  factory ShiftSwatch._derive(
    int colorValue,
    Brightness brightness,
    bool outOfMonth,
  ) {
    final c = _tokens(brightness);
    final dark = brightness == Brightness.dark;
    final isRest = ShiftPalette.isRest(colorValue);
    final stored = Color(colorValue);

    final bar = isRest
        ? c.borderStrong
        : dark
        ? _liftBar(stored)
        : stored;

    if (outOfMonth) {
      return ShiftSwatch(
        bar: Color.alphaBlend(
          bar.withValues(alpha: outOfMonthBarOpacity),
          c.surfaceMuted,
        ),
        tint: c.surfaceMuted,
        disc: c.surfaceMuted,
        ink: c.textMuted,
        isRest: isRest,
      );
    }
    if (isRest) {
      return ShiftSwatch(
        bar: bar,
        tint: c.surface,
        disc: c.surfaceRaised,
        ink: c.textMuted,
        isRest: true,
      );
    }

    final tint = Color.lerp(
      c.surface,
      stored,
      dark ? darkTintShare : lightTintShare,
    )!;
    final disc = Color.lerp(
      c.surface,
      stored,
      dark ? darkDiscShare : lightDiscShare,
    )!;
    return ShiftSwatch(
      bar: bar,
      tint: tint,
      disc: disc,
      ink: _adjustLightness(
        stored,
        [tint, disc],
        lighter: dark,
        target: dark ? kDarkInkContrast : kTextContrast,
      ),
    );
  }

  /// A day without shift: plain `surface` (or `surfaceMuted` outside the
  /// month), no bar. Lets the day number and the holiday colour be checked
  /// the same way as on a shift.
  factory ShiftSwatch.none(Brightness brightness, {bool outOfMonth = false}) {
    final c = _tokens(brightness);
    final background = outOfMonth ? c.surfaceMuted : c.surface;
    return ShiftSwatch(
      bar: const Color(0x00000000),
      tint: background,
      disc: background,
      ink: c.textMuted,
    );
  }

  /// [token] (a text or icon colour) as it must be drawn on [tint] (or on
  /// [background], when the cell is drawn on another colour, like the disc of
  /// a chosen day): itself when it already has 4.5:1, otherwise the closest
  /// lightness that does (lighter on a dark cell, darker on a light one).
  Color legible(Color token, {Color? background}) {
    final back = background ?? tint;
    if (contrastRatio(token, back) >= kTextContrast) return token;
    return _adjustLightness(
      token,
      [back],
      lighter: token.computeLuminance() > back.computeLuminance(),
    );
  }

  static AppColors _tokens(Brightness brightness) =>
      brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  /// Dark mode: a bar below the minimum luminance vanishes on the near-black
  /// background, so its HSL lightness goes up until it reaches it.
  static Color _liftBar(Color color) {
    if (color.computeLuminance() >= minDarkBarLuminance) return color;
    final hsl = HSLColor.fromColor(color);
    for (var i = 1; i <= 100; i++) {
      final candidate = hsl
          .withLightness((hsl.lightness + i * _lightnessStep).clamp(0.0, 1.0))
          .toColor();
      if (candidate.computeLuminance() >= minDarkBarLuminance) return candidate;
    }
    return const Color(0xFFFFFFFF);
  }

  /// Moves the HSL lightness of [color] (hue and saturation kept) in steps
  /// until it has [target] contrast on every colour of [backgrounds];
  /// [color] itself when it already does.
  static Color _adjustLightness(
    Color color,
    List<Color> backgrounds, {
    required bool lighter,
    double target = kTextContrast,
  }) {
    bool reads(Color c) =>
        backgrounds.every((b) => contrastRatio(c, b) >= target);
    if (reads(color)) return color;
    final hsl = HSLColor.fromColor(color);
    for (var i = 1; i <= 100; i++) {
      final lightness = hsl.lightness + (lighter ? i : -i) * _lightnessStep;
      final candidate = hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
      if (reads(candidate)) return candidate;
    }
    return lighter ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  @override
  bool operator ==(Object other) =>
      other is ShiftSwatch &&
      other.bar == bar &&
      other.tint == tint &&
      other.disc == disc &&
      other.ink == ink &&
      other.isRest == isRest;

  @override
  int get hashCode => Object.hash(bar, tint, disc, ink, isRest);

  @override
  String toString() =>
      'ShiftSwatch(bar: $bar, tint: $tint, disc: $disc, ink: $ink, '
      'rest: $isRest)';
}
