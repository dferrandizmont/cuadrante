import 'dart:async';

import '../domain/auto_backup_policy.dart';
import '../domain/backup_store.dart';

/// Where the automatic copies stand, for the status line of the screen.
class AutoBackupStatus {
  const AutoBackupStatus({
    this.running = false,
    this.pending = false,
    this.lastSuccessAt,
    this.lastFailureAt,
    this.lastError,
    this.dueAt,
  });

  /// A copy is being written right now.
  final bool running;

  /// There are changes waiting for their copy.
  final bool pending;

  /// When the last copy of this session worked (the clock of the app; the
  /// persistent "last copy" comes from the store itself).
  final DateTime? lastSuccessAt;

  /// When and why the newest attempt failed; `null` when it did not (a later
  /// success clears them).
  final DateTime? lastFailureAt;
  final Object? lastError;

  /// When the copy for the waiting changes is due (the debounce and the
  /// spacing of the policy, so up to 15 min after the last copy), or `null`
  /// while nothing is waiting or the wait is not scheduled yet. The status
  /// line tells the user this time instead of promising «unos segundos».
  final DateTime? dueAt;

  /// The newest attempt of this session failed.
  bool get failing => lastFailureAt != null;

  AutoBackupStatus _with({
    bool? running,
    bool? pending,
    DateTime? lastSuccessAt,
    ({DateTime at, Object error})? failure,
    bool clearFailure = false,
    DateTime? dueAt,
    bool clearDue = false,
  }) => AutoBackupStatus(
    running: running ?? this.running,
    pending: pending ?? this.pending,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    lastFailureAt: clearFailure ? null : (failure?.at ?? lastFailureAt),
    lastError: clearFailure ? null : (failure?.error ?? lastError),
    dueAt: clearDue ? null : (dueAt ?? this.dueAt),
  );
}

/// Makes a timer; tests pass a fake that they fire by hand.
typedef TimerFactory = Timer Function(Duration delay, void Function() onFire);

/// Takes the automatic copies: collects "something changed" notices, waits
/// for the [policy] (debounce, spacing), and then runs [perform] in the
/// background. It never throws at the caller of [noteChange]: a failed copy
/// is recorded in [status], reported through [onFailure] and retried later.
///
/// A plain class (no Flutter, no Riverpod) so the timing is tested with a
/// fake clock and a fake timer.
class AutoBackupRunner {
  AutoBackupRunner({
    required this.policy,
    required this.now,
    required this.perform,
    this.onStatus,
    this.onFailure,
    TimerFactory? timerFactory,
    this._enabled = true,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final AutoBackupPolicy policy;
  final DateTime Function() now;

  /// Writes one copy and returns it. Throws if it could not be stored.
  final Future<BackupEntry> Function() perform;

  final void Function(AutoBackupStatus status)? onStatus;
  final void Function(Object error, StackTrace stack)? onFailure;
  final TimerFactory _timerFactory;

  AutoBackupStatus _status = const AutoBackupStatus();
  AutoBackupStatus get status => _status;

  bool _enabled;
  bool _disposed = false;
  Timer? _timer;
  DateTime? _firstChange;
  DateTime? _lastChange;
  DateTime? _lastAttempt;
  Future<BackupEntry>? _running;

  bool get enabled => _enabled;

  /// Turning copies off drops the wait (nothing already saved is touched);
  /// turning them on asks for a copy soon, since the data may have changed
  /// while they were off.
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (value) {
      noteChange();
    } else {
      _timer?.cancel();
      _timer = null;
      _firstChange = null;
      _lastChange = null;
      _publish(_status._with(pending: false, clearDue: true));
    }
  }

  /// Something the user owns changed: a copy will follow.
  void noteChange() {
    if (_disposed || !_enabled) return;
    final t = now();
    _firstChange ??= t;
    _lastChange = t;
    _publish(_status._with(pending: true));
    _schedule();
  }

  /// "Hacer copia ahora": a copy right away, whatever the policy says. Waits
  /// for the one in flight (if any), then takes a fresh one. Throws if it
  /// could not be stored (the failure is also recorded in [status]).
  Future<BackupEntry> backupNow() async {
    if (_disposed) throw StateError('disposed');
    // Loop, not `if`: several waiters wake up together when the copy ends,
    // and only the first may start the next one; the others wait for it.
    for (var inFlight = _running; inFlight != null; inFlight = _running) {
      try {
        await inFlight;
      } catch (_) {
        // That attempt failed and was recorded; this one is the user's.
      }
    }
    if (_disposed) throw StateError('disposed');
    _timer?.cancel();
    _timer = null;
    return _attempt();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    // A copy in flight reschedules when it ends.
    if (_running != null) return;
    final first = _firstChange;
    final last = _lastChange;
    if (first == null || last == null) return;
    final delay = policy.delayFor(
      now: now(),
      firstChange: first,
      lastChange: last,
      lastAttempt: _lastAttempt,
    );
    _timer = _timerFactory(delay, _fire);
    _publish(_status._with(dueAt: now().add(delay)));
  }

  void _fire() {
    _timer = null;
    if (_disposed || !_enabled || _lastChange == null || _running != null) {
      return;
    }
    // Errors are recorded by `_attempt`; nothing to do with them here.
    unawaited(_attempt().then<void>((_) {}, onError: (Object _) {}));
  }

  Future<BackupEntry> _attempt() {
    final started = now();
    _lastAttempt = started;
    // Changes that arrive while the copy is being written start a new burst.
    final firstChange = _firstChange;
    _firstChange = null;
    _lastChange = null;
    _publish(_status._with(running: true, pending: false, clearDue: true));

    final run = _run(started, firstChange);
    _running = run;
    return run.whenComplete(() {
      _running = null;
      if (!_disposed && _enabled && _lastChange != null) _schedule();
    });
  }

  Future<BackupEntry> _run(DateTime started, DateTime? firstChange) async {
    try {
      final entry = await perform();
      _publish(
        _status._with(
          running: false,
          pending: _lastChange != null,
          lastSuccessAt: now(),
          clearFailure: true,
          clearDue: true,
        ),
      );
      return entry;
    } catch (error, stack) {
      // Still unsaved: ask for another try after the spacing of the policy.
      _firstChange ??= firstChange ?? started;
      _lastChange ??= started;
      _publish(
        _status._with(
          running: false,
          pending: true,
          failure: (at: now(), error: error),
          clearDue: true,
        ),
      );
      try {
        onFailure?.call(error, stack);
      } catch (_) {
        // Reporting must never hide the failure it reports.
      }
      rethrow;
    }
  }

  void _publish(AutoBackupStatus status) {
    _status = status;
    if (!_disposed) onStatus?.call(status);
  }
}
