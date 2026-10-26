import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/import_models.dart';
import 'lrhsoft_reader.dart' show looksLikeSqlite;

/// What kind of file the user wants to bring. [lrhsoft] is the `.Shifter`
/// backup of LRHSoft «Calendario de Turnos», a SQLite database.
enum ImportFileKind { ics, csv, lrhsoft }

/// A file the user picked (or the system handed to the app): its [name] and
/// its [bytes], or the [problem] that stopped them being read.
class PickedImportFile {
  const PickedImportFile.bytes(this.name, Uint8List this.bytes)
    : problem = null;
  const PickedImportFile.problem(this.problem) : name = '', bytes = null;

  final String name;
  final Uint8List? bytes;
  final ImportProblem? problem;

  /// The name the user can recognise, or `null` when the system made it up:
  /// Android ends every file whose type it does not know with «.bin» (a
  /// `.Shifter` backup comes as `application/octet-stream`), and the app
  /// must not repeat that made-up name to the user (H-T22-10).
  String? get realName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().endsWith('.bin')) return null;
    return trimmed;
  }

  /// What the file is, by its name and, when that does not say, by its first
  /// bytes (`BEGIN:VCALENDAR` is an `.ics`, `SQLite format 3` an LRHSoft
  /// backup: so a `.Shifter` picked as a CSV is still read as what it is).
  ImportFileKind get kind {
    final lower = name.toLowerCase();
    if (lower.endsWith('.shifter') ||
        (bytes != null && looksLikeSqlite(bytes!))) {
      return ImportFileKind.lrhsoft;
    }
    if (lower.endsWith('.ics') || lower.endsWith('.ical')) {
      return ImportFileKind.ics;
    }
    if (lower.endsWith('.csv') || lower.endsWith('.txt')) {
      return ImportFileKind.csv;
    }
    final head = bytes == null
        ? ''
        : String.fromCharCodes(bytes!.take(512).where((b) => b < 128))
              .toUpperCase();
    return head.contains('BEGIN:VCALENDAR')
        ? ImportFileKind.ics
        : ImportFileKind.csv;
  }
}

/// Asks the user for a file. `null` when they cancel. Tests override it.
typedef ImportFilePicker = Future<PickedImportFile?> Function(
  ImportFileKind kind,
);

/// The system file picker. On Android no type filter is passed: phones label
/// `.ics` and `.csv` files with many MIME types (or none) and `.Shifter` comes
/// as `application/octet-stream`, and a filter could hide the very file the
/// user wants; the content is checked anyway. The size
/// is checked before the bytes are read into the app, but on Android the
/// plugin has already copied the whole file into the cache by then (known
/// limit, docs/importar.md); the copy is deleted afterwards.
Future<PickedImportFile?> pickImportFile(ImportFileKind kind) async {
  final groups = Platform.isAndroid
      ? const <XTypeGroup>[]
      : [
          switch (kind) {
            ImportFileKind.ics => const XTypeGroup(
              label: 'Calendario',
              extensions: ['ics'],
              uniformTypeIdentifiers: [
                'public.calendar-event',
                'com.apple.ical.ics',
              ],
            ),
            ImportFileKind.csv => const XTypeGroup(
              label: 'CSV',
              extensions: ['csv', 'txt'],
              uniformTypeIdentifiers: [
                'public.comma-separated-values-text',
                'public.plain-text',
              ],
            ),
            // `.Shifter` has no type the system knows: any file may be
            // chosen and its content is checked.
            ImportFileKind.lrhsoft => const XTypeGroup(
              label: 'LRHSoft',
              extensions: ['Shifter', 'shifter'],
              uniformTypeIdentifiers: ['public.data'],
            ),
          },
        ];
  final file = await openFile(acceptedTypeGroups: groups);
  if (file == null) return null;
  return readPickedFile(file, cacheDir: getTemporaryDirectory);
}

/// Reads what the picker returned, within the size limit, and then deletes the
/// copy the picker left in the app's cache (Android copies the whole file
/// there before the app sees it). Only a file inside the cache folder is
/// deleted: a path anywhere else (a file picked in place) is never touched.
Future<PickedImportFile> readPickedFile(
  XFile file, {
  required Future<Directory> Function() cacheDir,
}) async {
  try {
    final length = await file.length();
    if (length > maxLrhsoftFileBytes) {
      return const PickedImportFile.problem(ImportProblem.tooComplex);
    }
    if (length > maxImportFileBytes && !await _isSqlite(file)) {
      // Only an LRHSoft backup (photos and drawings inside) may be this big.
      return const PickedImportFile.problem(ImportProblem.fileTooLarge);
    }
    return PickedImportFile.bytes(file.name, await file.readAsBytes());
  } catch (_) {
    return const PickedImportFile.problem(ImportProblem.fileUnreadable);
  } finally {
    await deleteIfCached(file.path, cacheDir);
  }
}

/// Whether [file] starts like a SQLite database; reads only its first bytes.
Future<bool> _isSqlite(XFile file) async {
  try {
    final head = <int>[];
    await for (final chunk in file.openRead(0, 16)) {
      head.addAll(chunk);
      if (head.length >= 16) break;
    }
    return looksLikeSqlite(head);
  } catch (_) {
    return false;
  }
}

/// Deletes [path] only when it is inside the folder [cacheDir] gives. Never
/// throws.
Future<void> deleteIfCached(
  String path,
  Future<Directory> Function() cacheDir,
) async {
  try {
    if (path.isEmpty) return;
    final cache = p.canonicalize((await cacheDir()).path);
    final target = p.canonicalize(path);
    if (!p.isWithin(cache, target)) return;
    final file = File(target);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // A copy that stays in the cache is harmless; the system clears it.
  }
}
