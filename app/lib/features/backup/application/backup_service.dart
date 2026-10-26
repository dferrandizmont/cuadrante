import 'dart:typed_data';

import '../../schedule/domain/schedule_domain.dart';
import '../data/backup_repository.dart';
import '../domain/backup_codec.dart';
import '../domain/backup_errors.dart';
import '../domain/backup_store.dart';
import '../domain/backup_task_runner.dart';
import '../domain/restore_summary.dart';

export '../domain/backup_task_runner.dart';

/// A file read and ready to restore: what it holds and what restoring would
/// replace. Nothing has been written yet.
class PendingRestore {
  const PendingRestore({required this.file, required this.summary});

  final BackupFile file;
  final RestoreSummary summary;
}

/// The backup operations the screens need, over a [BackupRepository], a
/// [BackupCodec] and a [BackupStore] (local files now, iCloud on iOS later).
class BackupService {
  BackupService({
    required this._repository,
    required this._store,
    required this._appVersion,
    this._codec = const BackupCodec(),
    BackupTaskRunner? runner,
    DateTime Function()? now,
  }) : _runner = runner ?? runInBackgroundIsolate,
       _now = now ?? DateTime.now;

  final BackupRepository _repository;
  final BackupStore _store;
  final String _appVersion;
  final BackupCodec _codec;
  final BackupTaskRunner _runner;
  final DateTime Function() _now;

  /// The `.cuadrante` bytes of the current data, e.g. to share.
  Future<Uint8List> exportBytes() => _encodeCurrent(_now());

  Future<Uint8List> _encodeCurrent(DateTime at) async {
    final data = await _repository.readAll();
    final codec = _codec;
    final version = _appVersion;
    return _runner(
      () => codec.encode(data, appVersion: version, exportedAt: at),
    );
  }

  /// Decode a persisted file through the same runner as imported files.
  Future<BackupFile> decodeFile(Uint8List bytes, {BackupCodec? codec}) {
    final reader = codec ?? _codec;
    return _runner(() => reader.decode(bytes));
  }

  /// Exports the current data into the store. Throws if it could not be
  /// saved.
  Future<BackupEntry> backupNow() async {
    final now = _now();
    final bytes = await _encodeCurrent(now);
    return _store.save(bytes, at: now);
  }

  /// Reads [bytes] (an imported file or a stored backup) without writing
  /// anything. Throws a [BackupException] if it is unusable.
  ///
  /// The decoding (inflate, JSON, canonical form and checksum, validation) is
  /// the expensive part and the bytes may come from anyone, so it runs through
  /// the runner (an isolate in the app), never on the UI isolate. Only the
  /// database summary, which is cheap, runs here.
  Future<PendingRestore> inspect(Uint8List bytes) async {
    final file = await decodeFile(bytes);
    return PendingRestore(
      file: file,
      summary: await _repository.preview(file.data),
    );
  }

  /// Replaces the current data with [pending]'s. The caller reloads the
  /// schedule afterwards.
  Future<void> restore(PendingRestore pending) =>
      _repository.restore(pending.file.data);

  /// "Probar restauración" on the newest stored backup, or `null` when the
  /// store has none.
  Future<RestoreVerification?> verifyLatest({required CivilDate today}) async {
    final latest = await _store.latest();
    if (latest == null) return null;
    return _repository.verifyRestore(await _store.read(latest), today: today);
  }
}
