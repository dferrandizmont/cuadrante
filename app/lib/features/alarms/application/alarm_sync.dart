import 'dart:async';

import '../../schedule/domain/schedule_domain.dart';
import '../data/alarm_scheduler.dart';
import '../domain/alarm_planner.dart';
import '../domain/alarm_settings.dart';
import '../domain/alarm_strings.dart';

/// Keeps the alarms on the device equal to the plan for the current schedule
/// and settings.
///
/// - [resync] runs now; [requestResync] waits [debounce] of quiet first (the
///   calendar emits a change for every day painted).
/// - Runs are serialised and coalesced: while one is in flight, further
///   requests only mark it dirty and it runs once more, so a burst of changes
///   costs at most two reschedules.
/// - Without permission nothing is scheduled (and what was is cancelled);
///   it is picked up on the next resume.
class AlarmSync {
  AlarmSync({
    required this.scheduler,
    required this.loadSettings,
    required this.readSchedule,
    required this.now,
    this.strings,
    this.debounce = const Duration(seconds: 1),
    this.onError,
  });

  final AlarmScheduler scheduler;
  final Future<AlarmSettings> Function() loadSettings;
  final FutureOr<Schedule> Function() readSchedule;
  final DateTime Function() now;
  final Duration debounce;

  /// Called with errors of a run (it never stops later runs).
  final void Function(Object error, StackTrace stack)? onError;

  /// Texts of the current locale. Until they are set (the host sets them as
  /// soon as it has a context) runs wait; setting them triggers a resync.
  AlarmStrings? strings;

  Timer? _timer;
  Future<void>? _loop;
  bool _dirty = false;
  bool _disposed = false;

  /// Number of runs that reached the scheduler (for tests and diagnostics).
  int runs = 0;

  /// Debounced: the plan is recomputed [debounce] after the last call.
  void requestResync() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      _timer = null;
      unawaited(resync());
    });
  }

  /// Completes when the (possibly coalesced) schedule is up to date.
  Future<void> resync() {
    if (_disposed) return Future.value();
    _timer?.cancel();
    _timer = null;
    _dirty = true;
    return _loop ??= _run();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _run() async {
    await null; // never complete synchronously (see `_loop = null` below)
    try {
      while (_dirty && !_disposed) {
        _dirty = false;
        try {
          await _once();
        } catch (error, stack) {
          // A failed run must not stop later ones; the next change retries.
          // Once disposed nobody is left to report to.
          if (!_disposed) onError?.call(error, stack);
        }
      }
    } finally {
      _loop = null;
    }
  }

  Future<void> _once() async {
    final texts = strings;
    if (texts == null) return;
    final settings = await loadSettings();
    if (_disposed) return;

    // Texts first: the iOS notification actions take their labels from them
    // when the plugin is initialized.
    await scheduler.configure(texts);
    await scheduler.initialize();

    final permission = await scheduler.permissionStatus();
    final granted = permission == AlarmPermission.granted;
    final plan = granted
        ? planAlarms(
            schedule: await readSchedule(),
            settings: settings,
            now: now(),
            strings: texts,
            location: await scheduler.planningZone(),
          )
        : const <PlannedAlarm>[];
    if (_disposed) return;
    runs++;
    await scheduler.replaceAll(plan);
    // A snoozed alarm survives a resync (it is not part of the plan), but
    // not turning the alarms off or losing the permission.
    if (!granted || !settings.anyActive) await scheduler.cancelSnoozes();
  }
}
