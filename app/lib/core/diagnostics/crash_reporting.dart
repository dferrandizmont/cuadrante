import 'dart:async';

import 'package:flutter/foundation.dart';

/// Crash reports behind one interface. Today only [NoopCrashReporter] exists;
/// a Crashlytics implementation will be added later behind the same
/// interface, with the same privacy rules:
/// - no user identifier, no custom keys, no breadcrumb logs;
/// - errors leave the device as their **type** plus the stack trace, never the
///   message (a message can quote a note or a shift name);
/// - only release builds send anything; debug builds just print.
///
/// **Implementations must redact**: [record] may be handed any error (a
/// `FormatException` quoting a note, a database error with a shift name), so a
/// real backend must send only `redactError(error).type` and the stack. The
/// app never installs a bare backend: `main` and [installCrashReporting] wrap
/// it in a [RedactingCrashReporter], which does it for every caller.
abstract class CrashReporter {
  /// Turns collection on or off.
  Future<void> setEnabled(bool enabled);

  /// Records an uncaught error: type and stack only.
  Future<void> record(Object error, StackTrace? stack, {required bool fatal});
}

/// Does nothing: tests, dev builds, platforms without a crash backend.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {}
}

/// What may leave the device instead of the original error: its runtime type,
/// never its message.
class RedactedError implements Exception {
  const RedactedError(this.type);

  /// `runtimeType` of the original error ("RangeError", "_TypeError").
  final String type;

  @override
  String toString() => type;
}

/// The redacted form of [error] that may leave the device.
RedactedError redactError(Object error) =>
    RedactedError(error.runtimeType.toString());

/// Decorator that redacts every error before it reaches [inner]: whatever the
/// caller passes, the backend only ever sees a [RedactedError] (the runtime
/// type) and the stack trace. The one place that enforces the privacy rule,
/// so a call site that forgets `redactError` cannot leak a message.
class RedactingCrashReporter implements CrashReporter {
  const RedactingCrashReporter(this.inner);

  final CrashReporter inner;

  @override
  Future<void> setEnabled(bool enabled) => inner.setEnabled(enabled);

  @override
  Future<void> record(Object error, StackTrace? stack, {required bool fatal}) =>
      inner.record(
        error is RedactedError ? error : redactError(error),
        stack,
        fatal: fatal,
      );
}

/// Wires the global error handlers. In release, uncaught Flutter and
/// platform errors go to [reporter] (redacted) and are **not** printed: the
/// console would carry the message, which can quote user data. In debug and
/// profile builds they are only printed, as Flutter does by default. Call
/// once, before `runApp`.
Future<void> installCrashReporting(
  CrashReporter reporter, {
  required bool enabled,
  bool release = kReleaseMode,
}) async {
  // Whatever is passed in, nothing but the redacted form reaches it.
  if (reporter is! RedactingCrashReporter) {
    reporter = RedactingCrashReporter(reporter);
  }
  try {
    await reporter.setEnabled(enabled && release);
  } catch (e) {
    debugPrint('crash reports init failed: ${e.runtimeType}');
  }
  if (!release) return; // debug / profile: print only.
  // Flutter's default handler dumps the exception, message included, to the
  // console, and on Android that is logcat (readable over adb) even in
  // release: so in release it is replaced, not chained. The only trace left
  // is the redacted report.
  FlutterError.onError = (details) {
    unawaited(
      reporter
          .record(details.exception, details.stack, fatal: true)
          .catchError((Object _) {}),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      reporter.record(error, stack, fatal: true).catchError((Object _) {}),
    );
    return true;
  };
}
