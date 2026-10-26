import 'package:flutter/material.dart' show Locale, ThemeMode;

/// Keys of the `settings` table (JSON text values) for the preferences the
/// Settings screen edits (docs/datos.md, "Ajustes").
abstract final class PreferenceKeys {
  /// `"system"`, `"light"` or `"dark"`.
  static const themeMode = 'appearance.themeMode';

  /// `1` (Monday) or `7` (Sunday), like [DateTime.weekday].
  static const weekStart = 'calendar.weekStart';

  /// `true` shows the ISO week number at the left of every row of the month.
  static const weekNumbers = 'calendar.weekNumbers';

  /// `"system"` or a language code of [AppLanguage] (`"es"`, `"ca"`...).
  static const language = 'appearance.language';
}

/// The language the user picked in Ajustes › Apariencia › Idioma.
/// [system] follows the phone and falls back to Spanish when the phone's
/// language is not one the app has.
enum AppLanguage {
  system,
  es,
  ca,
  gl,
  eu,
  en;

  /// The locale to force, or `null` to follow the phone.
  Locale? get locale => this == system ? null : Locale(name);

  /// The stored value (`"system"`, `"es"`...).
  String get stored => name;

  /// The language of a stored value; anything unknown is [system].
  static AppLanguage fromStored(Object? value) {
    for (final language in values) {
      if (language.name == value) return language;
    }
    return system;
  }
}

/// The first day of the week the user can pick.
abstract final class WeekStart {
  static const int monday = DateTime.monday;
  static const int sunday = DateTime.sunday;

  /// Whether [value] is one the app offers.
  static bool isValid(int value) => value == monday || value == sunday;
}

/// What the Settings screen lets the user change about how the app looks and
/// how the month is laid out. Defaults: follow the system theme and language,
/// weeks start on Monday, no week numbers.
class Preferences {
  const Preferences({
    this.themeMode = ThemeMode.system,
    this.weekStart = WeekStart.monday,
    this.weekNumbers = false,
    this.language = AppLanguage.system,
  }) : assert(weekStart == WeekStart.monday || weekStart == WeekStart.sunday);

  static const Preferences defaults = Preferences();

  final ThemeMode themeMode;

  /// [WeekStart.monday] or [WeekStart.sunday].
  final int weekStart;
  final bool weekNumbers;
  final AppLanguage language;

  Preferences copyWith({
    ThemeMode? themeMode,
    int? weekStart,
    bool? weekNumbers,
    AppLanguage? language,
  }) => Preferences(
    themeMode: themeMode ?? this.themeMode,
    weekStart: weekStart ?? this.weekStart,
    weekNumbers: weekNumbers ?? this.weekNumbers,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.themeMode == themeMode &&
      other.weekStart == weekStart &&
      other.weekNumbers == weekNumbers &&
      other.language == language;

  @override
  int get hashCode => Object.hash(themeMode, weekStart, weekNumbers, language);

  @override
  String toString() =>
      'Preferences(${themeMode.name}, weekStart $weekStart, '
      'weekNumbers $weekNumbers, language ${language.name})';
}

/// The stored name of a theme mode.
String themeModeToStored(ThemeMode mode) => mode.name;

/// The theme mode of a stored value; anything unknown is "system".
ThemeMode themeModeFromStored(Object? value) {
  for (final mode in ThemeMode.values) {
    if (mode.name == value) return mode;
  }
  return ThemeMode.system;
}
