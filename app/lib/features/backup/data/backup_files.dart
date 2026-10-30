import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// `yyyyMMdd-HHmmss` in UTC: sorts as text in time order.
String backupStamp(DateTime t) {
  final u = t.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}'
      '-${two(u.hour)}${two(u.minute)}${two(u.second)}';
}

/// Name pattern of the files a folder of backups holds: `<prefix>-<stamp>`,
/// plus `-<n>` when several share a second, then `.turnly` or the legacy
/// `.cuadrante`. Automatic copies also accept the legacy `cuadrante` prefix.
/// Group 1 is the stamp, group 2 the optional counter.
RegExp backupNamePattern(String prefix) {
  final prefixes = prefix == 'turnly'
      ? '(?:turnly|cuadrante)'
      : RegExp.escape(prefix);
  return RegExp(
    '^$prefixes-(\\d{8}-\\d{6})(?:-(\\d+))?\\.(?:turnly|cuadrante)\$',
  );
}

/// A new `.turnly` name, counting both current and legacy copies of the
/// same second so the new copy sorts after all existing ones.
String nextBackupName(String prefix, DateTime at, Iterable<String> names) {
  final stamp = backupStamp(at);
  final pattern = backupNamePattern(prefix);
  var counter = 1;
  for (final name in names) {
    final match = pattern.firstMatch(name);
    if (match == null || match[1] != stamp) continue;
    final next = (int.tryParse(match[2] ?? '') ?? 1) + 1;
    if (next > counter) counter = next;
  }
  final suffix = counter == 1 ? '' : '-$counter';
  return '$prefix-$stamp$suffix.turnly';
}

/// Writes [bytes] to [target] so a crash never leaves half a file there: to a
/// temporary file in the same folder first, flushed to disk, then renamed.
Future<void> writeFileAtomically(File target, Uint8List bytes) async {
  final temp = File('${target.path}.tmp');
  try {
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target.path);
  } catch (_) {
    if (await temp.exists()) await temp.delete();
    rethrow;
  }
}

/// A file in [directory] named for [prefix] and [at] that does not exist yet
/// (a second one in the same second gets `-2`, `-3`...).
Future<File> newBackupFile(
  Directory directory,
  String prefix,
  DateTime at,
) async {
  await directory.create(recursive: true);
  final names = await directory
      .list()
      .where((e) => e is File)
      .map((e) => p.basename(e.path))
      .toList();
  return File(p.join(directory.path, nextBackupName(prefix, at, names)));
}

/// The files of [directory] that match [pattern] (see [backupNamePattern]),
/// newest first. Anything else in the folder is ignored.
Future<List<File>> listBackupFiles(Directory directory, RegExp pattern) async {
  if (!await directory.exists()) return [];
  final found = <(String, int, File)>[];
  await for (final entity in directory.list()) {
    if (entity is! File) continue;
    final match = pattern.firstMatch(p.basename(entity.path));
    if (match == null) continue;
    found.add((match[1]!, int.tryParse(match[2] ?? '') ?? 1, entity));
  }
  found.sort((a, b) {
    final byStamp = b.$1.compareTo(a.$1);
    if (byStamp != 0) return byStamp;
    final byCounter = b.$2.compareTo(a.$2);
    return byCounter != 0
        ? byCounter
        : p.basename(b.$3.path).compareTo(p.basename(a.$3.path));
  });
  return [for (final f in found) f.$3];
}

/// Deletes all but the [keep] newest files of [directory] matching
/// [pattern].
Future<void> pruneBackupFiles(
  Directory directory,
  RegExp pattern,
  int keep,
) async {
  final files = await listBackupFiles(directory, pattern);
  for (final file in files.skip(keep)) {
    await file.delete();
  }
}
