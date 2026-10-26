import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'migration_backup.dart';

/// `driftDatabase(name: ...)` appends `.sqlite`.
const String databaseName = 'cuadrante';
const String databaseFileName = '$databaseName.sqlite';
const String backupsDirectoryName = 'backups';

/// Opens the on-disk database: `cuadrante.sqlite` in Application Support (not
/// Documents, not cache: docs/datos.md), making the pre-migration backup
/// first when the file is on an older schema.
///
/// [directory] replaces Application Support (tests use a temp directory).
Future<AppDatabase> openAppDatabase({
  Directory? directory,
  DateTime Function()? now,
}) async {
  final dir = directory ?? await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  // The app never switches the journal to WAL, so the main file is complete.
  await backupBeforeMigration(
    databaseFile: File(p.join(dir.path, databaseFileName)),
    targetVersion: AppDatabase.latestSchemaVersion,
    backupsDirectory: Directory(p.join(dir.path, backupsDirectoryName)),
    now: now,
  );
  return AppDatabase(
    driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        databaseDirectory: () async => dir,
        // Outside the app (no path_provider plugin) keep sqlite's default.
        tempDirectoryPath: directory == null ? null : () async => null,
      ),
    ),
  );
}
