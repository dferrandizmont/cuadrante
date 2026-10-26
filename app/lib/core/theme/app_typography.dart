import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles on the system font (SF Pro on iOS, Roboto on Android): no
/// bundled fonts, so the app feels native (`docs/diseno.md`, "Tipografía").
///
/// The `cell*` styles, [bodyStrong] (hours on the "today" card) and [button]
/// use tabular figures so digits line up from one cell to the next and a
/// countdown does not jitter. Flutter has no weight between two hundreds, so
/// the design's 650 and 750 round up to w700 and w800.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  /// Smallest calendar labels before the user's accessibility text scaling.
  static const double cellCodeMinSize = 8;
  static const double cellTimeMinSize = 8;

  const AppTypography({
    required this.display,
    required this.title,
    required this.headline,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.button,
    required this.meta,
    required this.caption,
    required this.cellDay,
    required this.cellCode,
    required this.cellCodeMulti,
    required this.cellTime,
  });

  /// `null` = the platform system font.
  static String? get family => _family;
  static String? _family;

  /// Tests that need real glyph widths pick the family they loaded
  /// (`test/support/real_font.dart`): a text style without a family renders
  /// in the test font (Ahem, about twice as wide) wherever a widget sets its
  /// own default style (list tiles, buttons), whatever fonts were loaded.
  @visibleForTesting
  static set debugFamily(String? value) => _family = value;

  /// 36 / 800, -0.6: shift name on the "today" card.
  final TextStyle display;

  /// 21 / 750: the month ("Octubre"), screen titles.
  final TextStyle title;

  /// 24 / 800: paint mode header, sheet titles.
  final TextStyle headline;

  /// 15 / 400: general text.
  final TextStyle body;

  /// 19 / 600: hours on the "today" card.
  final TextStyle bodyStrong;

  /// 13 / 700, +0.6: eyebrows ("ESTA NOCHE", "PINTANDO"). The text is
  /// upper-cased by the widget, a [TextStyle] cannot do it.
  final TextStyle label;

  /// 16 / 700: text of buttons ("Listo", "Pintar", "Doblar").
  final TextStyle button;

  /// 13 / 400: subtitles, metadata (muted colour).
  final TextStyle meta;

  /// 12 / 600: weekday headers, puck labels (muted colour).
  final TextStyle caption;

  /// 11 / 650 (today 900): day number inside a calendar cell.
  final TextStyle cellDay;

  /// 20 / 800 (14 with several shifts): shift code inside a calendar cell.
  final TextStyle cellCode;

  /// 14 / 800: the codes of a day with several shifts, stacked.
  final TextStyle cellCodeMulti;

  /// 10 / 600: small time range under the code.
  final TextStyle cellTime;

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color, {
    double letterSpacing = 0,
    bool tabularFigures = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
    fontFeatures: tabularFigures ? const [FontFeature.tabularFigures()] : null,
  );

  factory AppTypography.from(AppColors c) => AppTypography(
    display: _style(
      36,
      40,
      FontWeight.w800,
      c.textPrimary,
      letterSpacing: -0.6,
    ),
    title: _style(21, 28, FontWeight.w800, c.textPrimary),
    headline: _style(24, 30, FontWeight.w800, c.textPrimary),
    body: _style(15, 22, FontWeight.w400, c.textPrimary),
    bodyStrong: _style(
      19,
      24,
      FontWeight.w600,
      c.textPrimary,
      tabularFigures: true,
    ),
    label: _style(13, 18, FontWeight.w700, c.textPrimary, letterSpacing: 0.6),
    button: _style(
      16,
      22,
      FontWeight.w700,
      c.textPrimary,
      tabularFigures: true,
    ),
    meta: _style(13, 18, FontWeight.w400, c.textMuted),
    caption: _style(12, 16, FontWeight.w600, c.textMuted),
    cellDay: _style(
      11,
      14,
      FontWeight.w700,
      c.textSecondary,
      tabularFigures: true,
    ),
    cellCode: _style(
      20,
      22,
      FontWeight.w800,
      c.textPrimary,
      tabularFigures: true,
    ),
    cellCodeMulti: _style(
      14,
      16,
      FontWeight.w800,
      c.textPrimary,
      tabularFigures: true,
    ),
    cellTime: _style(
      10,
      12,
      FontWeight.w600,
      c.textMuted,
      tabularFigures: true,
    ),
  );

  /// Tabular figures on any style (times, amounts, counters).
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Flutter [TextTheme] mapping so stock Material widgets stay on-brand.
  TextTheme toTextTheme() => TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: display,
    headlineLarge: title,
    headlineMedium: title,
    headlineSmall: title,
    titleLarge: headline,
    titleMedium: bodyStrong,
    titleSmall: bodyStrong,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: meta,
    labelLarge: button,
    labelMedium: caption,
    labelSmall: caption,
  );

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      display: l(display, other.display),
      title: l(title, other.title),
      headline: l(headline, other.headline),
      body: l(body, other.body),
      bodyStrong: l(bodyStrong, other.bodyStrong),
      label: l(label, other.label),
      button: l(button, other.button),
      meta: l(meta, other.meta),
      caption: l(caption, other.caption),
      cellDay: l(cellDay, other.cellDay),
      cellCode: l(cellCode, other.cellCode),
      cellCodeMulti: l(cellCodeMulti, other.cellCodeMulti),
      cellTime: l(cellTime, other.cellTime),
    );
  }
}
