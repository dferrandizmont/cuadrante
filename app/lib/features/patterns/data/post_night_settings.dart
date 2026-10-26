import 'dart:convert';

import '../../../core/database/app_database.dart';

/// Key in the `settings` table (JSON `true` / `false`).
const String postNightAutoKey = 'postNight.auto';

/// "Saliente automático" (docs/roadmap.md: off by default): when on, the day
/// after a night shift that would be empty or Libre becomes Saliente.
class PostNightSettingsRepository {
  PostNightSettingsRepository(this._db);

  final AppDatabase _db;

  /// What is stored; `false` when nothing is, or the value cannot be read.
  Future<bool> loadAuto() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(postNightAutoKey))).getSingleOrNull();
    if (row == null) return false;
    try {
      return jsonDecode(row.value) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveAuto(bool value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(
          key: postNightAutoKey,
          value: jsonEncode(value),
        ),
      );
}
