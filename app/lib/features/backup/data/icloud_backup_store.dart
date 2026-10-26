import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/backup_codec.dart';
import '../domain/backup_store.dart';
import '../domain/icloud_errors.dart';
import 'backup_files.dart';

/// What the iCloud copy looks like right now (Ajustes > Copia de seguridad,
/// matrix row R8).
class ICloudStatus {
  const ICloudStatus({required this.available, this.reason, this.lastCopyAt});

  /// iCloud missing, or no native side.
  const ICloudStatus.unavailable({this.reason})
    : available = false,
      lastCopyAt = null;

  final bool available;

  /// Why it is not available, as the native side says it (`signed_out`,
  /// `disabled`, `no_container`); `null` when available or unknown.
  final String? reason;

  /// The date of the newest copy in iCloud (UTC), or `null` when there is
  /// none or iCloud cannot be asked.
  final DateTime? lastCopyAt;
}

/// [BackupStore] over the iCloud container of the app, through the
/// `app.cuadrante/icloud` channel to the Swift side (about 150 lines, written
/// in the Mac phase). The channel contract is in docs/copia-de-seguridad.md,
/// "Copia en iCloud", and docs/mac-ios.md, 4.3.
///
/// Same file names and the same retention rules as `LocalFileBackupStore`:
/// `<prefix>-<yyyyMMdd-HHmmss>.cuadrante`, plus `-<n>` for several in one
/// second. The id of an entry is its file name; its date is the one in the
/// name (the `at` given to [save]), not iCloud's modification time. Files in
/// the folder that are not of this store are ignored: the folder is visible in
/// Files and the user may drop things in it.
///
/// **Never a crash.** With no native side (`MissingPluginException`: Android,
/// iOS before the Swift channel exists, tests) every call behaves as "iCloud
/// no disponible": [isAvailable] is `false`, [list] and [latest] are empty,
/// and [save], [read] and [delete] throw [ICloudUnavailable].
class ICloudBackupStore implements BackupStore {
  ICloudBackupStore({
    MethodChannel? channel,
    this.keep = 5,
    this.prefix = 'cuadrante',
    this.retain,
    this.pruneOnSave = true,
    this.callTimeout = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : assert(keep >= 1, 'a store must keep at least one backup'),
       _channel = channel ?? const MethodChannel(channelName),
       _now = now ?? DateTime.now,
       _name = backupNamePattern(prefix);

  static const String channelName = 'app.cuadrante/icloud';

  final MethodChannel _channel;
  final int keep;
  final String prefix;

  /// Decides which entries survive a [save], replacing "the newest [keep]"
  /// (see `BackupRetention`). The newest copy and the one just saved always
  /// survive; a copy that cannot be deleted is left for the next time.
  final Set<String> Function(List<BackupEntry> entries)? retain;

  /// Whether [save] drops the copies the store does not keep. The caller that
  /// verifies a copy before pruning sets it to `false` and calls [prune].
  final bool pruneOnSave;

  /// Dart-side deadline of one native call. The Swift side has its own
  /// (`icloud_timeout`); this one covers a native side that never answers.
  final Duration callTimeout;

  final DateTime Function() _now;
  final RegExp _name;

  /// How far ahead of now the date in a file name may be before the file is
  /// ignored: the folder is visible in Files and a name is easy to forge.
  static const Duration maxFutureSkew = Duration(days: 1);

  /// Whether iCloud can be used right now. Never throws.
  Future<bool> isAvailable() async => (await status()).available;

  /// Whether iCloud works and the date of its newest copy. Never throws.
  Future<ICloudStatus> status() async {
    try {
      final reply = await _call<Map<Object?, Object?>>('status');
      if (reply == null || reply['available'] != true) {
        final reason = reply?['reason'];
        return ICloudStatus.unavailable(
          reason: reason is String ? reason : null,
        );
      }
      DateTime? last;
      try {
        last = (await latest())?.modifiedAt;
      } catch (_) {
        // Available but the listing failed: still available, date unknown.
      }
      return ICloudStatus(available: true, lastCopyAt: last);
    } catch (_) {
      // Whatever the native side answers, this never throws.
      return const ICloudStatus.unavailable();
    }
  }

  @override
  Future<BackupEntry> save(Uint8List bytes, {required DateTime at}) async {
    final taken = {for (final e in await _listOrThrow()) e.id};
    final stamp = backupStamp(at);
    var name = '$prefix-$stamp.cuadrante';
    for (var n = 2; taken.contains(name); n++) {
      name = '$prefix-$stamp-$n.cuadrante';
    }
    final reply = await _call<Map<Object?, Object?>>('save', {
      'name': name,
      'bytes': bytes,
    });
    final saved = reply == null ? null : _entryFromNative(reply, name);
    if (saved == null) {
      throw const ICloudFailed('save: unexpected reply from the native side');
    }
    if (pruneOnSave) await _prune(protect: saved.id);
    return saved;
  }

  @override
  Future<BackupEntry?> latest() async {
    final all = await list();
    return all.isEmpty ? null : all.first;
  }

  /// The copies in iCloud, newest first. Empty when iCloud is unavailable
  /// (see [status] to tell "none" from "cannot ask").
  @override
  Future<List<BackupEntry>> list() async {
    try {
      return await _listOrThrow();
    } on ICloudUnavailable {
      return const [];
    }
  }

  @override
  Future<Uint8List> read(BackupEntry entry) async {
    _checkOwn(entry);
    // The size comes before the bytes: a file that is not a backup (the
    // folder is visible in Files) is never downloaded or held in memory.
    if (entry.sizeBytes > BackupCodec.maxFileBytes) {
      throw const ICloudFailed('read: too large');
    }
    final bytes = await _call<Uint8List>('read', {'id': entry.id});
    if (bytes == null) {
      throw const ICloudFailed('read: unexpected reply from the native side');
    }
    if (bytes.length > BackupCodec.maxFileBytes) {
      throw const ICloudFailed('read: too large');
    }
    return bytes;
  }

  /// Deletes [entry] from iCloud (retention, or a copy that did not verify).
  Future<void> delete(BackupEntry entry) async {
    _checkOwn(entry);
    await _call<void>('delete', {'id': entry.id});
  }

  /// Drops the copies the store does not keep ([retain], or the newest
  /// [keep]). The newest copy is never dropped. A copy that cannot be deleted
  /// is left for the next time.
  Future<void> prune() => _prune();

  Future<void> _prune({String? protect}) async {
    final entries = await _listOrThrow();
    if (entries.isEmpty) return;
    final decide = retain;
    final keepIds = {
      if (decide == null)
        for (final e in entries.take(keep)) e.id
      else
        ...decide(entries),
      entries.first.id,
      ?protect,
    };
    for (final entry in entries) {
      if (keepIds.contains(entry.id)) continue;
      try {
        await delete(entry);
      } on ICloudException {
        // Left for the next save.
      }
    }
  }

  Future<List<BackupEntry>> _listOrThrow() async {
    final reply = await _call<List<Object?>>('list');
    final entries = <BackupEntry>[];
    for (final item in reply ?? const <Object?>[]) {
      if (item is! Map) continue;
      final name = item['name'] ?? item['id'];
      if (name is! String) continue;
      final entry = _entryFromNative(item, name);
      if (entry != null) entries.add(entry);
    }
    entries.sort(_newestFirst);
    return entries;
  }

  /// `null` when [name] is not one of this store's files (a foreign file in
  /// the folder).
  BackupEntry? _entryFromNative(Map<Object?, Object?> item, String name) {
    final match = _name.firstMatch(name);
    if (match == null) return null;
    final stamp = match[1]!;
    final date = DateTime.tryParse(
      '${stamp.substring(0, 8)}T${stamp.substring(9)}Z',
    );
    // A stamp that is not a real moment (`20261399-999999`) or that lies in
    // the future is not a copy of ours: the date shown comes from the name.
    if (date == null || backupStamp(date) != stamp) return null;
    if (date.isAfter(_now().toUtc().add(maxFutureSkew))) return null;
    final size = item['sizeBytes'];
    return BackupEntry(
      id: name,
      modifiedAt: date,
      sizeBytes: size is int ? size : 0,
    );
  }

  /// The same order as `listBackupFiles`: by stamp, then by counter (`-2`
  /// after the plain name).
  int _newestFirst(BackupEntry a, BackupEntry b) {
    final ma = _name.firstMatch(a.id)!;
    final mb = _name.firstMatch(b.id)!;
    final byStamp = mb[1]!.compareTo(ma[1]!);
    if (byStamp != 0) return byStamp;
    final na = int.tryParse(ma[2] ?? '') ?? 1;
    final nb = int.tryParse(mb[2] ?? '') ?? 1;
    return nb.compareTo(na);
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

  /// One native call, with the failures of the contract turned into
  /// [ICloudException]s.
  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel
          .invokeMethod<T>(method, arguments)
          .timeout(callTimeout);
    } on MissingPluginException {
      throw const ICloudUnavailable();
    } on TimeoutException {
      throw const ICloudTimeout();
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'icloud_unavailable' => const ICloudUnavailable(),
        'icloud_full' => const ICloudFull(),
        'icloud_timeout' => const ICloudTimeout(),
        'too_large' => ICloudFailed('$method: too large'),
        _ => ICloudFailed('$method: ${e.code} ${e.message ?? ''}'.trim()),
      };
    } catch (e) {
      // A reply of another shape than the contract's (a `TypeError` from the
      // cast of the channel): typed like any other failure, never a crash.
      throw ICloudFailed('$method: $e');
    }
  }
}
