import 'package:flutter/foundation.dart';

/// Where [debugLog] writes in tests (`null` = `debugPrint`).
@visibleForTesting
void Function(String line)? debugLogSink;

/// A line for the developer's console, in debug builds only.
///
/// `debugPrint` also prints in release builds, and on Android that is logcat,
/// readable by anyone who can attach `adb`. So nothing here ever runs in a
/// release build, and the callers pass only **non-content** text: a step name,
/// a count, an error's type. Never a note, a shift name or code, an id, a
/// path or an error message (they can quote any of them).
void debugLog(String line) {
  final sink = debugLogSink;
  if (sink != null) {
    sink(line);
    return;
  }
  if (kDebugMode) debugPrint(line);
}

/// [debugLog] for a failure that does not stop the app: [what] failed with an
/// error of that **type**; its message is dropped on purpose.
void debugLogFailure(String what, Object error) =>
    debugLog('$what (${error.runtimeType})');
