import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;

import '../../../core/database/app_database.dart';
import '../domain/preferences.dart';

/// Reads and writes the [Preferences] as one JSON row each of the `settings`
/// table (`appearance.themeMode`, `calendar.weekStart`,
/// `calendar.weekNumbers`, `appearance.language`).
///
/// A row that is missing, is not JSON or holds a value the app does not offer
/// falls back to the default: a bad preference never blocks the app.
class PreferencesRepository {
  PreferencesRepository(this._db);

  final AppDatabase _db;

  Future<Preferences> load() async {
    final rows = await (_db.select(
      _db.settings,
    )..where((s) => s.key.isIn(_keys))).get();
    final values = {for (final row in rows) row.key: _decode(row.value)};
    const defaults = Preferences.defaults;
    final weekStart = values[PreferenceKeys.weekStart];
    final weekNumbers = values[PreferenceKeys.weekNumbers];
    return Preferences(
      themeMode: themeModeFromStored(values[PreferenceKeys.themeMode]),
      weekStart: weekStart is int && WeekStart.isValid(weekStart)
          ? weekStart
          : defaults.weekStart,
      weekNumbers: weekNumbers is bool ? weekNumbers : defaults.weekNumbers,
      language: AppLanguage.fromStored(values[PreferenceKeys.language]),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _write(PreferenceKeys.themeMode, themeModeToStored(mode));

  /// Throws [ArgumentError] unless [weekStart] is Monday (1) or Sunday (7).
  Future<void> setWeekStart(int weekStart) async {
    if (!WeekStart.isValid(weekStart)) {
      throw ArgumentError.value(weekStart, 'weekStart', 'must be 1 or 7');
    }
    await _write(PreferenceKeys.weekStart, weekStart);
  }

  Future<void> setWeekNumbers(bool show) =>
      _write(PreferenceKeys.weekNumbers, show);

  Future<void> setLanguage(AppLanguage language) =>
      _write(PreferenceKeys.language, language.stored);

  static const _keys = [
    PreferenceKeys.themeMode,
    PreferenceKeys.weekStart,
    PreferenceKeys.weekNumbers,
    PreferenceKeys.language,
  ];

  Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(String key, Object value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: jsonEncode(value)),
      );
}
