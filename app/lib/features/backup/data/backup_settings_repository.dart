import 'dart:convert';

import '../../../core/database/app_database.dart';

/// Key in the `settings` table (JSON `true` / `false`).
const String autoBackupKey = 'backup.auto';

/// Key of the "Copia en iCloud" switch. A **device** setting
/// (`isDeviceSetting`): it never goes into a `.cuadrante` file and a restore
/// never turns it on, so a file from another phone (or a stranger) cannot send
/// the user's copies to iCloud.
const String cloudBackupKey = 'backup.cloud';

/// The backup switches. The "Copias automáticas" one is **on by default**: a missing or
/// unreadable value means on, so a restored file from an older version (or
/// one that never had the key) never leaves a phone without copies.
class BackupSettingsRepository {
  BackupSettingsRepository(this._db);

  final AppDatabase _db;

  Future<bool> loadAuto() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(autoBackupKey))).getSingleOrNull();
    if (row == null) return true;
    try {
      return jsonDecode(row.value) != false;
    } catch (_) {
      return true;
    }
  }

  Future<void> saveAuto(bool value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: autoBackupKey, value: jsonEncode(value)),
      );

  /// The "Copia en iCloud" switch (docs/copia-de-seguridad.md, "Dónde va
  /// iCloud"). **Off by default**: only an explicit `true` is on, so a missing
  /// or unreadable value never sends the copies (sick leave included) to iCloud
  /// Drive.
  Future<bool> loadCloud() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(cloudBackupKey))).getSingleOrNull();
    if (row == null) return false;
    try {
      return jsonDecode(row.value) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveCloud(bool value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: cloudBackupKey, value: jsonEncode(value)),
      );
}
