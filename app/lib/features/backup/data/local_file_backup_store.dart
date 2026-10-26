import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../domain/backup_store.dart';
import 'backup_files.dart';

/// [BackupStore] over a folder of files `<prefix>-<stamp>.cuadrante`: what
/// Android uses for now and what the tests use. Keeps the [keep] newest, or
/// whatever [retain] says when it is given.
///
/// The automatic copies use the prefix `cuadrante`; a second store over the
/// same folder with the prefix `pre-restore` lists the safety copies that
/// `BackupRepository.restore` writes (the two never see each other's files).
class LocalFileBackupStore implements BackupStore {
  LocalFileBackupStore(
    this.directory, {
    this.keep = 5,
    this.prefix = 'cuadrante',
    this.retain,
    this.pruneOnSave = true,
  }) : assert(keep >= 1, 'a store must keep at least one backup'),
       _name = backupNamePattern(prefix);

  final Directory directory;
  final int keep;
  final String prefix;

  /// Decides which entries survive a [save], replacing the plain "newest
  /// [keep]" rule (see `BackupRetention`). The copy just saved always
  /// survives, and a file that cannot be deleted is left for the next time
  /// rather than failing the save.
  final Set<String> Function(List<BackupEntry> entries)? retain;

  /// Whether [save] drops the copies the store does not keep. A caller that
  /// wants to check the new copy first sets it to `false` and calls [prune]
  /// itself once the copy is known to be good, so a bad copy never costs an
  /// old good one.
  final bool pruneOnSave;

  final RegExp _name;

  @override
  Future<BackupEntry> save(Uint8List bytes, {required DateTime at}) async {
    final file = await newBackupFile(directory, prefix, at);
    await writeFileAtomically(file, bytes);
    final saved = await _entry(file);
    if (pruneOnSave) await _prune(protect: saved.id);
    return saved;
  }

  /// Drops the copies the store does not keep ([retain], or the newest
  /// [keep]). The newest copy is never dropped.
  Future<void> prune() => _prune();

  /// Deletes [entry] (e.g. a copy that turned out not to be readable). Only
  /// files of this store can be deleted.
  Future<void> delete(BackupEntry entry) async {
    _checkOwn(entry);
    final file = File(p.join(directory.path, entry.id));
    if (await file.exists()) await file.delete();
  }

  Future<void> _prune({String? protect}) async {
    final retain = this.retain;
    if (retain == null) {
      await pruneBackupFiles(directory, _name, keep);
      return;
    }
    final entries = await list();
    if (entries.isEmpty) return;
    final keepIds = {...retain(entries), entries.first.id, ?protect};
    for (final entry in entries) {
      if (keepIds.contains(entry.id)) continue;
      try {
        await delete(entry);
      } on FileSystemException {
        // Left for the next save.
      }
    }
  }

  void _checkOwn(BackupEntry entry) {
    // The id came from this store; refuse anything that is not one of its
    // file names (no path separators, nothing outside the folder).
    if (!_name.hasMatch(entry.id)) {
      throw ArgumentError.value(
        entry.id,
        'entry',
        'not a backup of this store',
      );
    }
  }

  @override
  Future<BackupEntry?> latest() async {
    final files = await listBackupFiles(directory, _name);
    return files.isEmpty ? null : _entry(files.first);
  }

  @override
  Future<List<BackupEntry>> list() async => [
    for (final file in await listBackupFiles(directory, _name))
      await _entry(file),
  ];

  @override
  Future<Uint8List> read(BackupEntry entry) {
    _checkOwn(entry);
    return File(p.join(directory.path, entry.id)).readAsBytes();
  }

  /// The first [maxBytes] of [entry] (or all of it, if shorter), without
  /// reading the rest: enough to peek at the header of a copy.
  Future<Uint8List> readHead(BackupEntry entry, int maxBytes) async {
    _checkOwn(entry);
    final file = await File(p.join(directory.path, entry.id)).open();
    try {
      return await file.read(maxBytes);
    } finally {
      await file.close();
    }
  }

  /// The time is the one in the file name (the `at` given to [save]), not
  /// the modification time of the file system.
  Future<BackupEntry> _entry(File file) async {
    final name = p.basename(file.path);
    final stamp = _name.firstMatch(name)![1]!;
    return BackupEntry(
      id: name,
      modifiedAt: DateTime.parse(
        '${stamp.substring(0, 8)}T${stamp.substring(9)}Z',
      ),
      sizeBytes: await file.length(),
    );
  }
}
