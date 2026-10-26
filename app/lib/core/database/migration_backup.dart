import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Number of pre-migration backups kept.
const int migrationBackupsToKeep = 3;

final _backupName = RegExp(r'^pre-v(\d+)-a-v(\d+)-(\d{8}-\d{6})\.sqlite$');

/// `PRAGMA user_version` of the SQLite file at [file] (the version Drift
/// stores there), or `null` when the file does not exist or is empty.
///
/// Reads with `package:sqlite3` before Drift opens the database, so this must
/// not need the generated code. Opened read-write on purpose: a journal left
/// by a crash makes a read-only open fail (the app would not start), while a
/// read-write open lets SQLite recover it, so the backup copies a consistent
/// file.
int? readUserVersion(File file) {
  if (!file.existsSync() || file.lengthSync() == 0) return null;
  final db = sqlite3.open(file.path, mode: OpenMode.readWrite);
  try {
    return db.select('PRAGMA user_version').first.values.first as int;
  } finally {
    db.close();
  }
}

/// Copies [databaseFile] to
/// `[backupsDirectory]/pre-v{from}-a-v{to}-{yyyyMMdd-HHmmss}.sqlite` when the
/// file is on an older schema than [targetVersion] (and not brand new:
/// `user_version` > 0), then keeps only the [keep] newest backups.
///
/// **One copy per target.** If a `pre-v*-a-v{targetVersion}-*` copy already
/// exists, none is made: a migration that keeps failing midway (v1 -> v2 done,
/// v2 -> v3 failing) would otherwise write a new copy, already at v2, on every
/// launch and, three launches later, prune the only copy of the data as it was
/// before the first step (`pre-v1-a-v3-*`). The copy that exists is the
/// oldest, so it is the one that matters. Pruning never deletes the oldest
/// copy of the current target either ([pruneMigrationBackups]).
///
/// Returns the backup, or `null` when none was needed. Throws if the copy
/// fails, so the migration never runs without its safety copy.
Future<File?> backupBeforeMigration({
  required File databaseFile,
  required int targetVersion,
  required Directory backupsDirectory,
  DateTime Function()? now,
  int keep = migrationBackupsToKeep,
}) async {
  final from = readUserVersion(databaseFile);
  if (from == null || from <= 0 || from >= targetVersion) return null;

  await backupsDirectory.create(recursive: true);
  if (!await _backupsFor(backupsDirectory, targetVersion).isEmpty) {
    return null;
  }
  final stamp = _stamp((now ?? DateTime.now)().toUtc());
  final target = File(
    p.join(backupsDirectory.path, 'pre-v$from-a-v$targetVersion-$stamp.sqlite'),
  );
  await databaseFile.copy(target.path);
  await pruneMigrationBackups(
    backupsDirectory,
    keep,
    protectOldestOfTarget: targetVersion,
  );
  return target;
}

/// `yyyyMMdd-HHmmss` (UTC).
String _stamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}${two(t.month)}${two(t.day)}'
      '-${two(t.hour)}${two(t.minute)}${two(t.second)}';
}

/// The backups in [directory] whose name says they go to [target].
Stream<File> _backupsFor(Directory directory, int target) async* {
  await for (final entity in directory.list()) {
    if (entity is! File) continue;
    final match = _backupName.firstMatch(p.basename(entity.path));
    if (match != null && int.parse(match[2]!) == target) yield entity;
  }
}

/// Deletes all but the [keep] newest backups (by the date in the name; ties by
/// name). Files that do not look like ours are left alone. With
/// [protectOldestOfTarget], the oldest backup that goes to that version is
/// kept even when it is not among the newest: it is the data as it was before
/// the first step of that migration chain.
@visibleForTesting
Future<void> pruneMigrationBackups(
  Directory directory,
  int keep, {
  int? protectOldestOfTarget,
}) async {
  final backups = <(String, File, int)>[];
  await for (final entity in directory.list()) {
    if (entity is! File) continue;
    final match = _backupName.firstMatch(p.basename(entity.path));
    if (match != null) {
      backups.add((match[3]!, entity, int.parse(match[2]!)));
    }
  }
  backups.sort((a, b) {
    final byDate = b.$1.compareTo(a.$1);
    return byDate != 0 ? byDate : b.$2.path.compareTo(a.$2.path);
  });
  // Newest first, so the oldest of the target is the last one that matches.
  final protected = protectOldestOfTarget == null
      ? null
      : backups.where((b) => b.$3 == protectOldestOfTarget).lastOrNull;
  for (final backup in backups.skip(keep)) {
    if (identical(backup, protected)) continue;
    await backup.$2.delete();
  }
}
