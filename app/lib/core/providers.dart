import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'diagnostics/crash_reporting.dart';

/// Build-time configuration. Override in tests.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);

/// The crash reporter in use; a no-op unless `main` overrides it. Always
/// behind a [RedactingCrashReporter]: an error's message never leaves.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const RedactingCrashReporter(NoopCrashReporter()),
);

/// "Now". Tests override it to fix today.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// "Now" truncated to the minute, refreshed when the minute changes. The
/// countdown of the "today" card (and anything that depends on the hour or on
/// the day rolling over) watches this instead of polling.
///
/// Built on [clockProvider], so a test that fixes the clock gets a fixed
/// minute; one that moves its fake clock and lets the fake time run for a
/// minute gets the new value. One timer at a time (cancelled on dispose); no
/// animation involved.
final minuteClockProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  final untilNextMinute =
      const Duration(minutes: 1) -
      Duration(
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond,
      );
  final timer = Timer(untilNextMinute, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  // Subtract elapsed time so both occurrences of an autumn DST minute stay distinct.
  return now.subtract(
    Duration(
      seconds: now.second,
      milliseconds: now.millisecond,
      microseconds: now.microsecond,
    ),
  );
});
