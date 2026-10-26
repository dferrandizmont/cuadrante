import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../domain/alarm_settings.dart';

/// Key of the alarm settings in the `settings` table (JSON value).
const String alarmSettingsKey = 'alarms';

/// Reads and writes [AlarmSettings] as one JSON row of the `settings` table.
class AlarmSettingsRepository {
  AlarmSettingsRepository(this._db);

  final AppDatabase _db;

  /// What is stored, or everything off when there is nothing (or the stored
  /// value cannot be read: alarms never block the app).
  Future<AlarmSettings> load() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(alarmSettingsKey))).getSingleOrNull();
    if (row == null) return AlarmSettings.disabled;
    try {
      final json = jsonDecode(row.value);
      if (json is Map) {
        return AlarmSettings.fromJson(json.cast<String, Object?>());
      }
    } catch (_) {
      // Unreadable in any way: fall through to the defaults.
    }
    return AlarmSettings.disabled;
  }

  Future<void> save(AlarmSettings settings) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(
          key: alarmSettingsKey,
          value: jsonEncode(settings.toJson()),
        ),
      );
}
