import 'package:flutter/painting.dart';

/// Default shift colours (turnos-spec.md section 4). The user can edit them,
/// so these are only the starting values; never read them from widgets to
/// colour a shift, use the colour stored with the shift.
///
/// What is drawn on screen is derived from the stored colour, per theme, in
/// `shift_swatch.dart` (bar, tint, disc and ink); nothing here is a screen
/// colour.
class ShiftPalette {
  const ShiftPalette._();

  static const Color morning = Color(0xFFF5A524);
  static const Color afternoon = Color(0xFFF06A3F);
  static const Color night = Color(0xFF4B4FD1);
  static const Color guard = Color(0xFFE5484D);
  static const Color postNight = Color(0xFF8E7CC3);
  static const Color vacation = Color(0xFF30A46C);
  static const Color personalDay = Color(0xFF12A594);

  /// Stored colour of "Libre". It is special: no tint, and its bar and ink
  /// come from the neutral tokens (`borderStrong`, `textMuted`), so it reads
  /// as a calm cell in both themes.
  static const Color rest = Color(0xFFE4E4E7);

  static bool isRest(int colorValue) => colorValue == rest.toARGB32();

  /// Every saturated default, in display order (without rest).
  static const List<Color> defaults = [
    morning,
    afternoon,
    night,
    guard,
    postNight,
    vacation,
    personalDay,
  ];

  /// Extra colours the shift editor offers next to the defaults (16 hues
  /// around the wheel, none of them the special rest grey). Whatever the
  /// user picks, the swatch derives an ink with at least 4.5:1 on its tint
  /// and disc in both themes (`shift_swatch.dart`).
  static const List<Color> extras = [
    Color(0xFFD6336C),
    Color(0xFFF783AC),
    Color(0xFFE8590C),
    Color(0xFFF2C94C),
    Color(0xFF94D82D),
    Color(0xFF2F9E44),
    Color(0xFF20C997),
    Color(0xFF15AABF),
    Color(0xFF3B9AE1),
    Color(0xFF1C7ED6),
    Color(0xFF4C6EF5),
    Color(0xFF7950F2),
    Color(0xFFAE3EC9),
    Color(0xFF8D6E63),
    Color(0xFF868E96),
    Color(0xFF495057),
  ];

  /// The colours of the shift editor's grid, in order: the eight of the
  /// specification (section 4), then [extras].
  static const List<Color> editorChoices = [
    morning,
    afternoon,
    night,
    rest,
    guard,
    postNight,
    vacation,
    personalDay,
    ...extras,
  ];
}

/// WCAG 2.x contrast ratio between two opaque colours (1.0 to 21.0).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
