import 'dart:async';

import 'package:cuadrante/features/backup/application/auto_backup_runner.dart';
import 'package:cuadrante/features/backup/domain/auto_backup_policy.dart';
import 'package:cuadrante/features/backup/domain/backup_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// A clock and the timers that run on it, moved by hand.
class FakeClock {
  FakeClock(this.now);

  DateTime now;
  final List<_FakeTimer> _timers = [];

  Timer timer(Duration delay, void Function() onFire) {
    final t = _FakeTimer(now.add(delay), onFire);
    _timers.add(t);
    return t;
  }

  int get activeTimers => _timers.where((t) => t.isActive).length;

  /// Moves time forward, firing the timers that fall due in order.
  Future<void> advance(Duration by) async {
    final target = now.add(by);
    while (true) {
      final due =
          _timers.where((t) => t.isActive && !t.at.isAfter(target)).toList()
            ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final next = due.first;
      if (next.at.isAfter(now)) now = next.at;
      next.fire();
      await pump();
    }
    now = target;
    await pump();
  }

  /// Lets the futures of the runner (the "copy" in flight) finish.
  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.at, this._onFire);

  final DateTime at;
  final void Function() _onFire;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _onFire();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  late FakeClock clock;
  late List<DateTime> copies;
  late List<Object> failures;
  late bool failNext;
  Completer<void>? hold;
  var inPerform = 0;
  var maxInPerform = 0;
  late AutoBackupRunner runner;
  final statuses = <AutoBackupStatus>[];

  AutoBackupRunner make({bool enabled = true}) => AutoBackupRunner(
    policy: const AutoBackupPolicy(),
    now: () => clock.now,
    timerFactory: clock.timer,
    enabled: enabled,
    onStatus: statuses.add,
    onFailure: (error, stack) => failures.add(error),
    perform: () async {
      inPerform++;
      if (inPerform > maxInPerform) maxInPerform = inPerform;
      try {
        if (hold != null) await hold!.future;
        if (failNext) throw StateError('disk full');
      } finally {
        inPerform--;
      }
      copies.add(clock.now);
      return BackupEntry(
        id: 'cuadrante-${copies.length}.cuadrante',
        modifiedAt: clock.now.toUtc(),
        sizeBytes: 10,
      );
    },
  );

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 10, 19, 12));
    copies = [];
    failures = [];
    failNext = false;
    hold = null;
    inPerform = 0;
    maxInPerform = 0;
    statuses.clear();
    runner = make();
  });

  tearDown(() => runner.dispose());

  test('a change is copied 10 s later, not before', () async {
    runner.noteChange();
    expect(runner.status.pending, isTrue);

    await clock.advance(const Duration(seconds: 9));
    expect(copies, isEmpty);

    await clock.advance(const Duration(seconds: 1));
    expect(copies, hasLength(1));
    expect(runner.status.pending, isFalse);
    expect(runner.status.running, isFalse);
    expect(runner.status.lastSuccessAt, clock.now);
    expect(runner.status.failing, isFalse);
  });

  test('a burst of changes makes one copy, 10 s after the last', () async {
    runner.noteChange();
    await clock.advance(const Duration(seconds: 6));
    runner.noteChange();
    await clock.advance(const Duration(seconds: 6));
    runner.noteChange();
    await clock.advance(const Duration(seconds: 9));
    expect(copies, isEmpty, reason: 'still inside the debounce');

    await clock.advance(const Duration(seconds: 1));
    expect(copies, hasLength(1));
    await clock.advance(const Duration(hours: 1));
    expect(copies, hasLength(1), reason: 'nothing changed since');
  });

  test('constant editing still gets a copy within 2 minutes', () async {
    for (var i = 0; i < 40; i++) {
      runner.noteChange();
      await clock.advance(const Duration(seconds: 5));
    }
    expect(copies, isNotEmpty);
    expect(
      copies.first.difference(DateTime.utc(2026, 10, 19, 12)),
      const Duration(minutes: 2),
    );
  });

  test('copies are at least 15 min apart', () async {
    runner.noteChange();
    await clock.advance(const Duration(seconds: 10));
    expect(copies, hasLength(1));

    // A new change a minute later has to wait for the spacing.
    await clock.advance(const Duration(minutes: 1));
    runner.noteChange();
    await clock.advance(const Duration(minutes: 13));
    expect(copies, hasLength(1));
    await clock.advance(const Duration(minutes: 2));
    expect(copies, hasLength(2));
    expect(copies.last.difference(copies.first), const Duration(minutes: 15));
  });

  test('the status tells when the copy is due (H-T13-1)', () async {
    expect(runner.status.dueAt, isNull);
    runner.noteChange();
    expect(runner.status.dueAt, DateTime.utc(2026, 10, 19, 12, 0, 10));

    await clock.advance(const Duration(seconds: 10));
    expect(copies, hasLength(1));
    expect(runner.status.dueAt, isNull, reason: 'nothing is waiting now');

    // A minute later: the 15 min spacing, counted from the previous copy.
    await clock.advance(const Duration(minutes: 1));
    runner.noteChange();
    expect(runner.status.pending, isTrue);
    expect(runner.status.dueAt, DateTime.utc(2026, 10, 19, 12, 15, 10));

    await clock.advance(const Duration(minutes: 14));
    expect(copies, hasLength(2));
    expect(runner.status.dueAt, isNull);
  });

  test('a change while a copy is written is copied afterwards', () async {
    hold = Completer<void>();
    runner.noteChange();
    await clock.advance(const Duration(seconds: 10));
    expect(runner.status.running, isTrue);

    runner.noteChange();
    hold!.complete();
    hold = null;
    await clock.pump();
    expect(copies, hasLength(1));
    expect(runner.status.pending, isTrue);

    await clock.advance(const Duration(minutes: 15));
    expect(copies, hasLength(2));
  });

  group('failures', () {
    test('are recorded, reported and retried after the spacing', () async {
      failNext = true;
      runner.noteChange();
      await clock.advance(const Duration(seconds: 10));

      expect(copies, isEmpty);
      expect(runner.status.failing, isTrue);
      expect(runner.status.lastFailureAt, clock.now);
      expect(runner.status.lastError, isA<StateError>());
      expect(runner.status.pending, isTrue, reason: 'still unsaved');
      expect(failures, hasLength(1));

      // Not hammered before the spacing is over...
      await clock.advance(const Duration(minutes: 14));
      expect(failures, hasLength(1));

      // ...then it tries again, and a good copy clears the failure.
      failNext = false;
      await clock.advance(const Duration(minutes: 1));
      expect(copies, hasLength(1));
      expect(runner.status.failing, isFalse);
      expect(runner.status.lastError, isNull);
      expect(runner.status.pending, isFalse);
    });

    test('a failing reporter does not hide the failure', () async {
      final noisy = AutoBackupRunner(
        policy: const AutoBackupPolicy(),
        now: () => clock.now,
        timerFactory: clock.timer,
        perform: () async => throw StateError('boom'),
        onFailure: (error, stack) => throw StateError('reporter down'),
      );
      addTearDown(noisy.dispose);
      noisy.noteChange();
      await clock.advance(const Duration(seconds: 10));
      expect(noisy.status.failing, isTrue);
    });
  });

  group('switch', () {
    test('off: changes are not copied', () async {
      runner.dispose();
      runner = make(enabled: false);
      runner.noteChange();
      await clock.advance(const Duration(hours: 1));
      expect(copies, isEmpty);
      expect(runner.status.pending, isFalse);
    });

    test('turned off while waiting drops the copy', () async {
      runner.noteChange();
      runner.enabled = false;
      await clock.advance(const Duration(minutes: 5));
      expect(copies, isEmpty);
      expect(clock.activeTimers, 0);
    });

    test('turned on asks for a copy soon', () async {
      runner.dispose();
      runner = make(enabled: false);
      runner.enabled = true;
      await clock.advance(const Duration(seconds: 10));
      expect(copies, hasLength(1));
    });
  });

  group('hacer copia ahora', () {
    test('copies right away and counts as an attempt', () async {
      final entry = await runner.backupNow();
      expect(entry.id, 'cuadrante-1.cuadrante');
      expect(copies, hasLength(1));

      // A change right after it waits for the spacing.
      runner.noteChange();
      await clock.advance(const Duration(minutes: 14));
      expect(copies, hasLength(1));
      await clock.advance(const Duration(minutes: 1));
      expect(copies, hasLength(2));
    });

    test('clears the pending change it covers', () async {
      runner.noteChange();
      await runner.backupNow();
      expect(runner.status.pending, isFalse);
      await clock.advance(const Duration(hours: 1));
      expect(copies, hasLength(1));
    });

    test('throws when it fails, and records it', () async {
      failNext = true;
      await expectLater(runner.backupNow(), throwsStateError);
      expect(runner.status.failing, isTrue);
      expect(failures, hasLength(1));
    });

    test('waits for the copy in flight', () async {
      hold = Completer<void>();
      runner.noteChange();
      await clock.advance(const Duration(seconds: 10));
      expect(runner.status.running, isTrue);

      final manual = runner.backupNow();
      hold!.complete();
      hold = null;
      await manual;
      expect(copies, hasLength(2));
    });
  });

  test(
    'two manual copies while one is in flight never write in parallel',
    () async {
      hold = Completer<void>();
      runner.noteChange();
      await clock.advance(const Duration(seconds: 10));
      expect(runner.status.running, isTrue);

      final first = runner.backupNow();
      final second = runner.backupNow();
      hold!.complete();
      // The copies that follow also take their time.
      final next = hold = Completer<void>();
      await clock.pump();
      expect(
        maxInPerform,
        1,
        reason: 'one copy at a time, no same-second twins',
      );
      next.complete();
      hold = null;
      await Future.wait([first, second]);
      expect(copies, hasLength(3), reason: 'in flight + one per request');
      expect(
        maxInPerform,
        1,
        reason: 'one copy at a time, no same-second twins',
      );
    },
  );

  test('dispose cancels the wait', () async {
    runner.noteChange();
    runner.dispose();
    await clock.advance(const Duration(hours: 1));
    expect(copies, isEmpty);
    runner.noteChange(); // ignored
    expect(clock.activeTimers, 0);
  });
}
