import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:uuid/uuid.dart';

import '../data/import_file_picker.dart';
import '../domain/import_models.dart';

/// Runs [computation] off the UI isolate. Tests override it to run inline
/// (an isolate does not run inside a fake-async widget test).
///
/// What goes in the closure must be sendable (bytes, plain objects): build it
/// in a function that only holds those, never next to a `Ref`.
typedef ImportRunner = Future<T> Function<T>(T Function() computation);

final importRunnerProvider = Provider<ImportRunner>(
  (ref) =>
      <T>(T Function() computation) => Isolate.run<T>(computation),
);

/// How long a background job may take before the wizard stops waiting. Tests
/// override it.
final importTimeoutProvider = Provider<Duration>((ref) => importWorkTimeout);

/// The system file picker for `.ics` and CSV files. Tests override it.
final importFilePickerProvider = Provider<ImportFilePicker>(
  (ref) => pickImportFile,
);

/// IANA id of the phone's time zone (for `.ics` times in UTC or other zones).
/// `Europe/Madrid` when it cannot be read. Tests override it.
final importTimeZoneProvider = Provider<Future<String> Function()>(
  (ref) => () async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return 'Europe/Madrid';
    }
  },
);

/// Ids of the shift types an import creates. Tests override it.
final importIdGeneratorProvider = Provider<String Function()>(
  (ref) =>
      () => const Uuid().v4(),
);
