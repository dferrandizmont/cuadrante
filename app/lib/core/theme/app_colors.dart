import 'package:flutter/material.dart';

/// Background / foreground pair used by icon discs and callouts.
@immutable
class TonePair {
  const TonePair(this.bg, this.fg);

  final Color bg;
  final Color fg;

  static TonePair lerp(TonePair a, TonePair b, double t) =>
      TonePair(Color.lerp(a.bg, b.bg, t)!, Color.lerp(a.fg, b.fg, t)!);

  @override
  bool operator ==(Object other) =>
      other is TonePair && other.bg == bg && other.fg == fg;

  @override
  int get hashCode => Object.hash(bg, fg);
}

/// Colour tokens of direction B "Noche" (`docs/diseno.md`, which rules over
/// any value here). The single place where hex values of the interface
/// live; widgets read them through `context.colors`. The shift colours
/// (user-editable) live in `shift_palette.dart` and are derived per theme in
/// `shift_swatch.dart`.
///
/// Dark is a real night mode for people working nights: near-black
/// background, muted tones, amber as the accent. Light is the same structure
/// with another palette. All text tokens reach 4.5:1 on their surfaces.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentSoft,
    required this.controlBorder,
    required this.highlight,
    required this.onHighlight,
    required this.todayRing,
    required this.holiday,
    required this.primaryButton,
    required this.onPrimaryButton,
    required this.fab,
    required this.onFab,
    required this.fabBorder,
    required this.danger,
    required this.dangerContainer,
    required this.success,
    required this.successContainer,
    required this.scrim,
    required this.softShadow,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;

  /// Days of the neighbouring months in the grid.
  final Color surfaceMuted;

  /// Round buttons and unselected pucks.
  final Color surfaceRaised;
  final Color border;

  /// Borders of controls.
  final Color borderStrong;
  final Color textPrimary;

  /// Hours on the "today" card, day numbers.
  final Color textSecondary;

  /// Weekday headers, small hours, secondary text: >= 4.5:1 on `surface`.
  final Color textMuted;

  /// Links, switches, labels. Indigo, the "night" shift colour.
  final Color accent;
  final Color onAccent;

  /// Accent for small text and icons on `background` / `surface`: >= 4.5:1.
  final Color accentText;

  /// Soft accent fill (active pill, selected row), readable under
  /// `textPrimary`.
  final Color accentSoft;

  /// Resting outline of inputs, checkboxes and off switches: >= 3:1.
  final Color controlBorder;

  /// Countdown chip, brush icon, selection in dark mode (amber).
  final Color highlight;
  final Color onHighlight;

  /// Ring of today's cell and of the selected shift puck.
  final Color todayRing;

  /// Holiday day numbers (and their dot).
  final Color holiday;

  /// "Listo" and the main button.
  final Color primaryButton;
  final Color onPrimaryButton;

  /// The "Pintar" button (its brush icon is [highlight]). [fabBorder] is
  /// transparent in light mode.
  final Color fab;
  final Color onFab;
  final Color fabBorder;

  /// Destructive text/icon colour on [dangerContainer].
  final Color danger;
  final Color dangerContainer;
  final Color success;
  final Color successContainer;

  /// Dimmer behind overlays.
  final Color scrim;

  /// Very soft shadow colour for sheets (transparent in dark).
  final Color softShadow;

  bool get isDark => brightness == Brightness.dark;

  /// Same as [accent]; kept as a name for "icons / large elements" uses.
  Color get accentStrong => accent;

  /// Label colour of secondary buttons.
  Color get secondaryLabel => textPrimary;

  /// Icons and labels of a control that does nothing right now: the muted
  /// text colour, softened, so it never looks like an active one.
  Color get disabledContent => textMuted.withValues(alpha: 0.5);

  /// Unchecked checkbox outline.
  Color get checkboxBorder => controlBorder;

  /// Disc colours of callouts and empty states.
  TonePair get accentTone => TonePair(accentSoft, accentText);

  /// Placeholder blocks of skeleton loading.
  Color get skeleton => isDark ? border : surfaceMuted;

  static const AppColors light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFF2F2F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFECECF1),
    surfaceRaised: Color(0xFFF4F4F7),
    border: Color(0xFFDCDCE2),
    borderStrong: Color(0xFFC9C9D2),
    textPrimary: Color(0xFF15151A),
    textSecondary: Color(0xFF3A3A44),
    textMuted: Color(0xFF5A5A64),
    accent: Color(0xFF4B4FD1),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFF4B4FD1),
    accentSoft: Color(0xFFE3E4FA),
    controlBorder: Color(0xFF858592),
    highlight: Color(0xFFF5A524),
    onHighlight: Color(0xFF15151A),
    todayRing: Color(0xFF15151A),
    holiday: Color(0xFFD93036),
    primaryButton: Color(0xFF15151A),
    onPrimaryButton: Color(0xFFFFFFFF),
    fab: Color(0xFF15151A),
    onFab: Color(0xFFFFFFFF),
    fabBorder: Color(0x00000000),
    danger: Color(0xFFC1272D),
    dangerContainer: Color(0xFFFBE3E4),
    success: Color(0xFF1B7448),
    successContainer: Color(0xFFDDF2E7),
    scrim: Color(0x66000000),
    softShadow: Color(0x14111114),
  );

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0D),
    surface: Color(0xFF15151B),
    surfaceMuted: Color(0xFF0F0F13),
    surfaceRaised: Color(0xFF1C1C23),
    border: Color(0xFF23232B),
    borderStrong: Color(0xFF34343E),
    textPrimary: Color(0xFFECECF1),
    textSecondary: Color(0xFFC9C9D2),
    textMuted: Color(0xFF8E8E99),
    accent: Color(0xFFA5A8FF),
    onAccent: Color(0xFF0A0A0D),
    accentText: Color(0xFFA5A8FF),
    accentSoft: Color(0xFF23245A),
    controlBorder: Color(0xFF6C6C78),
    highlight: Color(0xFFF5B547),
    onHighlight: Color(0xFF0A0A0D),
    todayRing: Color(0xFFF5B547),
    holiday: Color(0xFFFF6369),
    primaryButton: Color(0xFFF5B547),
    onPrimaryButton: Color(0xFF0A0A0D),
    fab: Color(0xFF1C1C23),
    onFab: Color(0xFFF5B547),
    fabBorder: Color(0xFF34343E),
    danger: Color(0xFFFF8E92),
    dangerContainer: Color(0xFF3A1417),
    success: Color(0xFF5FD398),
    successContainer: Color(0xFF0F2A1D),
    scrim: Color(0x99000000),
    softShadow: Color(0x00000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentText: c(accentText, other.accentText),
      accentSoft: c(accentSoft, other.accentSoft),
      controlBorder: c(controlBorder, other.controlBorder),
      highlight: c(highlight, other.highlight),
      onHighlight: c(onHighlight, other.onHighlight),
      todayRing: c(todayRing, other.todayRing),
      holiday: c(holiday, other.holiday),
      primaryButton: c(primaryButton, other.primaryButton),
      onPrimaryButton: c(onPrimaryButton, other.onPrimaryButton),
      fab: c(fab, other.fab),
      onFab: c(onFab, other.onFab),
      fabBorder: c(fabBorder, other.fabBorder),
      danger: c(danger, other.danger),
      dangerContainer: c(dangerContainer, other.dangerContainer),
      success: c(success, other.success),
      successContainer: c(successContainer, other.successContainer),
      scrim: c(scrim, other.scrim),
      softShadow: c(softShadow, other.softShadow),
    );
  }
}
