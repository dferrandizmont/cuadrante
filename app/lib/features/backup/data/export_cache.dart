import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// The folder where an exported `.cuadrante` waits for the share sheet:
/// `<cache>/export/`.
///
/// The file holds the whole schedule (sick leave included), so it must not
/// pile up in the cache for the system to find months later:
/// - every export first empties the folder (a leftover of an earlier one);
/// - once the share sheet has returned, the file is deleted after
///   [graceBeforeDelete] (the receiving app, Drive or WhatsApp, may still be
///   reading the shared URI when the sheet reports back);
/// - the app empties the folder at start ([sweep]), which also covers a
///   process that died before the delayed delete ran.
class ExportCache {
  ExportCache(
    Directory cacheRoot, {
    this.graceBeforeDelete = const Duration(minutes: 2),
  }) : directory = Directory(p.join(cacheRoot.path, folderName));

  /// Name of the folder inside the cache.
  static const String folderName = 'export';

  final Directory directory;
  final Duration graceBeforeDelete;

  Timer? _timer;
  Future<void>? _lastCleanup;

  /// The delayed delete started by the last [share] (tests wait on it).
  @visibleForTesting
  Future<void>? get lastCleanup => _lastCleanup;

  /// Deletes everything in the folder. Never throws: it is housekeeping.
  Future<void> sweep() async {
    try {
      if (!await directory.exists()) return;
      await for (final entity in directory.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {
          // Left for the next sweep.
        }
      }
    } catch (_) {
      // Same.
    }
  }

  /// Writes [bytes] as [fileName] (only the last path segment is used) into
  /// the folder, after emptying it.
  Future<File> write(Uint8List bytes, String fileName) async {
    await sweep();
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, p.basename(fileName)));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Writes the file, hands it to [send] (the share sheet) and schedules its
  /// deletion for when [send] has returned, whether it finished or failed.
  Future<void> share(
    Uint8List bytes,
    String fileName,
    Future<void> Function(File file) send,
  ) async {
    final file = await write(bytes, fileName);
    try {
      await send(file);
    } finally {
      _scheduleDelete(file);
    }
  }

  void _scheduleDelete(File file) {
    _timer?.cancel();
    final done = Completer<void>();
    _lastCleanup = done.future;
    Future<void> delete() async {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        // The next export or start-up sweep removes it.
      } finally {
        done.complete();
      }
    }

    if (graceBeforeDelete == Duration.zero) {
      unawaited(delete());
    } else {
      _timer = Timer(graceBeforeDelete, delete);
    }
  }
}
