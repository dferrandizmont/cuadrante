import 'dart:math' as math;

import 'package:cuadrante/core/diagnostics/crash_reporting.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

/// Counts calls, can delay or fail them, and checks they never overlap.
class ProbeRepository extends ScheduleRepository {
  ProbeRepository(super.db, {super.now, this.delay, this.failCalls = const {}});

  final Duration Function(int call)? delay;
  final Set<int> failCalls;
  final calls = <ScheduleChange>[];
  final finished = <int>[];
  int _active = 0;
  int maxActive = 0;

  @override
  Future<void> apply(String calendarId, ScheduleChange change) async {
    final call = calls.length;
    calls.add(change);
    _active++;
    maxActive = math.max(maxActive, _active);
    try {
      final wait = delay?.call(call);
      if (wait != null) await Future<void>.delayed(wait);
      if (failCalls.contains(call)) {
        throw StateError('disk full: secret note text');
      }
      await super.apply(calendarId, change);
      finished.add(call);
    } finally {
      _active--;
    }
  }
}

class RecordingCrashReporter implements CrashReporter {
  final errors = <Object>[];

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {
    errors.add(error);
  }
}
