import 'dart:ui' show Brightness;

import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/core/theme/shift_swatch.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const named = <String, Color>{
    'morning': ShiftPalette.morning,
    'afternoon': ShiftPalette.afternoon,
    'night': ShiftPalette.night,
    'guard': ShiftPalette.guard,
    'postNight': ShiftPalette.postNight,
    'vacation': ShiftPalette.vacation,
    'personalDay': ShiftPalette.personalDay,
  };

  ShiftSwatch swatch(Color c, Brightness b, {bool outOfMonth = false}) =>
      ShiftSwatch.forColor(c.toARGB32(), b, outOfMonth: outOfMonth);

  test('contrastRatio is symmetric and spans 1 to 21', () {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    expect(contrastRatio(black, white), closeTo(21, 0.01));
    expect(contrastRatio(white, black), closeTo(21, 0.01));
    expect(contrastRatio(white, white), closeTo(1, 0.001));
  });

  test('the defaults list holds every saturated colour', () {
    expect(ShiftPalette.defaults.toSet(), named.values.toSet());
  });

  test('only the stored grey is "Libre"', () {
    expect(ShiftPalette.isRest(ShiftPalette.rest.toARGB32()), isTrue);
    for (final c in named.values) {
      expect(ShiftPalette.isRest(c.toARGB32()), isFalse);
    }
  });

  group('ShiftSwatch (docs/diseno.md, "Color de cada turno")', () {
    const light = AppColors.light;
    const dark = AppColors.dark;

    test('light: bar is the stored colour, tint 10 % and disc 18 % of it', () {
      for (final c in named.values) {
        final s = swatch(c, Brightness.light);
        expect(s.bar, c);
        expect(s.tint, Color.lerp(light.surface, c, 0.10));
        expect(s.disc, Color.lerp(light.surface, c, 0.18));
        expect(s.isRest, isFalse);
      }
    });

    test('dark: tint 14 % and disc 28 % of the colour on the surface', () {
      for (final c in named.values) {
        final s = swatch(c, Brightness.dark);
        expect(s.tint, Color.lerp(dark.surface, c, 0.14));
        expect(s.disc, Color.lerp(dark.surface, c, 0.28));
      }
    });

    test('dark: a dull bar is lightened to luminance 0.15, others kept', () {
      // Night is the only default below 0.15.
      for (final c in named.values) {
        final bar = swatch(c, Brightness.dark).bar;
        if (c.computeLuminance() >= ShiftSwatch.minDarkBarLuminance) {
          expect(bar, c, reason: '$c is bright enough');
        } else {
          expect(
            bar.computeLuminance(),
            greaterThanOrEqualTo(ShiftSwatch.minDarkBarLuminance),
          );
          expect(bar, isNot(c));
        }
      }
      final night = swatch(ShiftPalette.night, Brightness.dark).bar;
      // Same hue, lighter: it is still the indigo of the night shift.
      expect(
        HSLColor.fromColor(night).hue,
        closeTo(HSLColor.fromColor(ShiftPalette.night).hue, 2),
      );
      expect(
        HSLColor.fromColor(night).lightness,
        greaterThan(HSLColor.fromColor(ShiftPalette.night).lightness),
      );
    });

    test('ink keeps hue and saturation: only the lightness moves', () {
      for (final c in named.values) {
        final base = HSLColor.fromColor(c);
        final inkLight = HSLColor.fromColor(swatch(c, Brightness.light).ink);
        final inkDark = HSLColor.fromColor(swatch(c, Brightness.dark).ink);
        expect(inkLight.lightness, lessThanOrEqualTo(base.lightness));
        expect(inkDark.lightness, greaterThanOrEqualTo(base.lightness));
        for (final ink in [inkLight, inkDark]) {
          expect(ink.hue, closeTo(base.hue, 3));
          expect(ink.saturation, closeTo(base.saturation, 0.03));
        }
      }
    });

    test('ink is the colour itself when it already reads', () {
      // The indigo of the night shift reads on its light tint and disc.
      final s = swatch(ShiftPalette.night, Brightness.light);
      expect(s.ink, ShiftPalette.night);
    });

    test('dark inks reach the higher night target on tint and disc', () {
      for (final color in ShiftPalette.defaults) {
        final s = swatch(color, Brightness.dark);
        if (s.isRest) continue;
        expect(contrastRatio(s.ink, s.tint), greaterThanOrEqualTo(6.5));
        expect(contrastRatio(s.ink, s.disc), greaterThanOrEqualTo(6.5));
      }
    });

    test('Libre: no tint, neutral bar and ink, a raised disc', () {
      for (final (b, c) in [
        (Brightness.light, light),
        (Brightness.dark, dark),
      ]) {
        final s = swatch(ShiftPalette.rest, b);
        expect(s.isRest, isTrue);
        expect(s.tint, c.surface);
        expect(s.bar, c.borderStrong);
        expect(s.ink, c.textMuted);
        expect(s.disc, c.surfaceRaised);
      }
    });

    test('out of month: muted background, muted code, bar at 45 %', () {
      for (final (b, c) in [
        (Brightness.light, light),
        (Brightness.dark, dark),
      ]) {
        for (final color in [...named.values, ShiftPalette.rest]) {
          final s = swatch(color, b, outOfMonth: true);
          final inMonth = swatch(color, b);
          expect(s.tint, c.surfaceMuted);
          expect(s.disc, c.surfaceMuted);
          expect(s.ink, c.textMuted);
          expect(
            s.bar,
            Color.alphaBlend(
              inMonth.bar.withValues(alpha: 0.45),
              c.surfaceMuted,
            ),
          );
          expect(s.isRest, inMonth.isRest);
        }
      }
    });

    test('none: plain surface, no bar', () {
      expect(ShiftSwatch.none(Brightness.dark).tint, dark.surface);
      expect(
        ShiftSwatch.none(Brightness.light, outOfMonth: true).tint,
        light.surfaceMuted,
      );
      expect(ShiftSwatch.none(Brightness.light).bar.a, 0);
    });

    test('legible darkens on a light tint and lightens on a dark one', () {
      // Holiday red on the afternoon tint (light) is just under AA.
      final lightTint = swatch(ShiftPalette.afternoon, Brightness.light);
      expect(contrastRatio(light.holiday, lightTint.tint), lessThan(4.5));
      final fixedLight = lightTint.legible(light.holiday);
      expect(
        fixedLight.computeLuminance(),
        lessThan(light.holiday.computeLuminance()),
      );
      expect(
        contrastRatio(fixedLight, lightTint.tint),
        greaterThanOrEqualTo(4.5),
      );

      // Muted text on the morning tint (dark) is just under AA.
      final darkTint = swatch(ShiftPalette.morning, Brightness.dark);
      expect(contrastRatio(dark.textMuted, darkTint.tint), lessThan(4.5));
      final fixedDark = darkTint.legible(dark.textMuted);
      expect(
        fixedDark.computeLuminance(),
        greaterThan(dark.textMuted.computeLuminance()),
      );
      expect(
        contrastRatio(fixedDark, darkTint.tint),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('equal inputs give equal swatches', () {
      expect(
        swatch(ShiftPalette.night, Brightness.dark),
        swatch(ShiftPalette.night, Brightness.dark),
      );
      expect(
        swatch(ShiftPalette.night, Brightness.dark),
        isNot(swatch(ShiftPalette.night, Brightness.light)),
      );
    });
  });

  group('interface colours', () {
    test('dark text is never pure white, background is near-black', () {
      expect(AppColors.dark.textPrimary, isNot(const Color(0xFFFFFFFF)));
      expect(AppColors.dark.background.computeLuminance(), lessThan(0.01));
    });

    test('the table of docs/diseno.md', () {
      const l = AppColors.light;
      const d = AppColors.dark;
      expect(l.background, const Color(0xFFF2F2F6));
      expect(d.background, const Color(0xFF0A0A0D));
      expect(l.surface, const Color(0xFFFFFFFF));
      expect(d.surface, const Color(0xFF15151B));
      expect(l.surfaceMuted, const Color(0xFFECECF1));
      expect(d.surfaceMuted, const Color(0xFF0F0F13));
      expect(l.surfaceRaised, const Color(0xFFF4F4F7));
      expect(d.surfaceRaised, const Color(0xFF1C1C23));
      expect(l.border, const Color(0xFFDCDCE2));
      expect(d.border, const Color(0xFF23232B));
      expect(l.borderStrong, const Color(0xFFC9C9D2));
      expect(d.borderStrong, const Color(0xFF34343E));
      expect(l.textPrimary, const Color(0xFF15151A));
      expect(d.textPrimary, const Color(0xFFECECF1));
      expect(l.textSecondary, const Color(0xFF3A3A44));
      expect(d.textSecondary, const Color(0xFFC9C9D2));
      expect(l.textMuted, const Color(0xFF5A5A64));
      expect(d.textMuted, const Color(0xFF8E8E99));
      expect(l.accent, const Color(0xFF4B4FD1));
      expect(d.accent, const Color(0xFFA5A8FF));
      expect(l.highlight, const Color(0xFFF5A524));
      expect(d.highlight, const Color(0xFFF5B547));
      expect(l.onHighlight, const Color(0xFF15151A));
      expect(d.onHighlight, const Color(0xFF0A0A0D));
      expect(l.todayRing, const Color(0xFF15151A));
      expect(d.todayRing, const Color(0xFFF5B547));
      expect(l.holiday, const Color(0xFFD93036));
      expect(d.holiday, const Color(0xFFFF6369));
      expect(l.primaryButton, const Color(0xFF15151A));
      expect(l.onPrimaryButton, const Color(0xFFFFFFFF));
      expect(d.primaryButton, const Color(0xFFF5B547));
      expect(d.onPrimaryButton, const Color(0xFF0A0A0D));
      expect(l.fab, const Color(0xFF15151A));
      expect(l.onFab, const Color(0xFFFFFFFF));
      expect(d.fab, const Color(0xFF1C1C23));
      expect(d.onFab, const Color(0xFFF5B547));
      expect(d.fabBorder, const Color(0xFF34343E));
    });

    for (final c in [AppColors.light, AppColors.dark]) {
      test('${c.brightness.name}: danger and success read on their fills', () {
        expect(
          contrastRatio(c.danger, c.dangerContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(c.success, c.successContainer),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}
