import 'dart:typed_data';

/// One backup kept by a [BackupStore].
class BackupEntry {
  const BackupEntry({
    required this.id,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  /// Opaque to callers: pass it back to [BackupStore.read]. For the local
  /// store it is the file name.
  final String id;

  /// UTC.
  final DateTime modifiedAt;
  final int sizeBytes;

  @override
  bool operator ==(Object other) =>
      other is BackupEntry &&
      other.id == id &&
      other.modifiedAt == modifiedAt &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(id, modifiedAt, sizeBytes);

  @override
  String toString() => 'BackupEntry($id, $modifiedAt, $sizeBytes B)';
}

/// Where automatic backups live. The bytes are always a `.cuadrante` file
/// made by `BackupCodec`; a store only keeps them.
///
/// - Android and tests: `LocalFileBackupStore` (a folder of files).
/// - iOS: `ICloudBackupStore`, over the iCloud container through the Swift
///   channel `app.cuadrante/icloud`. Same contract; see
///   docs/copia-de-seguridad.md. It is the second place of the app's copies
///   (`BackupTools.cloudStore`): the first one is always on the phone.
abstract interface class BackupStore {
  /// Stores [bytes] as the newest backup and drops the oldest ones the store
  /// does not keep. Throws if the bytes could not be stored (the caller
  /// reports it: a failed backup must never look like a good one).
  Future<BackupEntry> save(Uint8List bytes, {required DateTime at});

  /// The newest backup, or `null` when there is none.
  Future<BackupEntry?> latest();

  /// All backups, newest first.
  Future<List<BackupEntry>> list();

  /// The bytes of [entry].
  Future<Uint8List> read(BackupEntry entry);
}
