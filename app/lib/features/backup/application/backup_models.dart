import '../data/platform_backup_channel.dart';
import '../domain/backup_store.dart';

/// Where a copy listed on the screen came from.
enum BackupCopyKind {
  /// Made by the app (automatically or with "Hacer copia ahora").
  local,

  /// The copy `restore` writes of the current data right before replacing it,
  /// so a restore can be undone.
  safety,
}

/// One copy in the list of the backup screen.
class BackupCopy {
  const BackupCopy(this.kind, this.entry, {this.appVersion});

  final BackupCopyKind kind;
  final BackupEntry entry;

  /// The version of the app that wrote the copy, read from the file's header
  /// (`BackupCodec.peekAppVersion`); `null` when it could not be read.
  /// Informational: the list shows it so the copies from before an update
  /// can be told from the new ones.
  final String? appVersion;

  /// A key that is stable for the file (tests, list items).
  String get id => entry.id;
}

/// Where the file being previewed came from, for the wording of the preview.
enum BackupImportOrigin {
  /// Picked with "Importar archivo".
  pickedFile,

  /// Handed to the app by another app (WhatsApp, Files, Drive).
  sharedFile,

  /// A copy of this phone ([BackupCopyKind.local]).
  localCopy,

  /// The copy made before a restore ([BackupCopyKind.safety]).
  safetyCopy,

  /// A copy in the iCloud folder. An **external** file for all purposes: the
  /// folder is visible in Files on every device of the Apple ID and anybody
  /// with access can drop a file in it, so it is decoded, previewed and
  /// confirmed like any other file, and its date (from the file name) can be
  /// false.
  cloudCopy,
}

/// What the preview screen is asked to show: where the bytes come from, and a
/// loader that returns them (or why they could not be read). Nothing is
/// restored until the user confirms there.
class BackupImportRequest {
  const BackupImportRequest({
    required this.origin,
    required this.load,
    this.copyDate,
  });

  final BackupImportOrigin origin;

  /// The file's bytes, or the reason they could not be read.
  final Future<IncomingFile> Function() load;

  /// The date of the stored copy, for [BackupImportOrigin.localCopy],
  /// [BackupImportOrigin.safetyCopy] and [BackupImportOrigin.cloudCopy] (the
  /// last one comes from a file name: informational).
  final DateTime? copyDate;
}

/// A restore that did not finish.
class RestoreFailure implements Exception {
  const RestoreFailure({required this.dataReplaced, required this.cause});

  /// The data was replaced but the screens could not be refreshed from it
  /// (the restore itself is all or nothing, so `false` means nothing changed).
  final bool dataReplaced;
  final Object cause;

  @override
  String toString() => 'RestoreFailure(dataReplaced: $dataReplaced, $cause)';
}

/// `cuadrante-2026-11-10-143005.cuadrante`: the name of an exported file, with
/// the date and time as the user sees them (local). The time makes every
/// export a file of its own, so the delayed delete of one export can never
/// reach a newer one.
String exportFileName(DateTime now) {
  final t = now.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'cuadrante-${t.year.toString().padLeft(4, '0')}-${two(t.month)}-'
      '${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}.cuadrante';
}
