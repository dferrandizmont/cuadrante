import 'package:cuadrante/features/backup/domain/auto_backup_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AutoBackupPolicy();
  final t0 = DateTime.utc(2026, 10, 19, 12);

  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  group('defaults', () {
    test('debounce 10 s, cap 2 min, spacing 15 min', () {
      expect(policy.debounce, const Duration(seconds: 10));
      expect(policy.maxDebounce, const Duration(minutes: 2));
      expect(policy.minInterval, const Duration(minutes: 15));
    });
  });

  group('debounce', () {
    test('one change is due 10 s later', () {
      expect(policy.dueAt(now: t0, firstChange: t0, lastChange: t0), at(10));
      expect(
        policy.delayFor(now: t0, firstChange: t0, lastChange: t0),
        const Duration(seconds: 10),
      );
    });

    test('a burst waits for its last change', () {
      // Changes at 0 s, 5 s and 12 s: due 10 s after the last one.
      expect(
        policy.dueAt(now: at(12), firstChange: at(0), lastChange: at(12)),
        at(22),
      );
    });

    test('a user who never pauses still gets a copy after 2 min', () {
      // Editing every 5 s for 5 minutes: the cap wins over the debounce.
      expect(
        policy.dueAt(now: at(300), firstChange: at(0), lastChange: at(300)),
        at(120),
      );
      // ...and a wait that is already over is zero, not negative.
      expect(
        policy.delayFor(now: at(300), firstChange: at(0), lastChange: at(300)),
        Duration.zero,
      );
    });
  });

  group('spacing', () {
    test('not sooner than 15 min after the previous attempt', () {
      final lastAttempt = t0.subtract(const Duration(minutes: 5));
      final due = policy.dueAt(
        now: t0,
        firstChange: t0,
        lastChange: t0,
        lastAttempt: lastAttempt,
      );
      expect(due, lastAttempt.add(const Duration(minutes: 15)));
      expect(
        policy.delayFor(
          now: t0,
          firstChange: t0,
          lastChange: t0,
          lastAttempt: lastAttempt,
        ),
        const Duration(minutes: 10),
      );
    });

    test('an old attempt does not delay a change', () {
      expect(
        policy.dueAt(
          now: t0,
          firstChange: t0,
          lastChange: t0,
          lastAttempt: t0.subtract(const Duration(hours: 2)),
        ),
        at(10),
      );
    });

    test('an attempt in the future (clock moved back) is ignored', () {
      expect(
        policy.dueAt(
          now: t0,
          firstChange: t0,
          lastChange: t0,
          lastAttempt: t0.add(const Duration(hours: 5)),
        ),
        at(10),
      );
    });

    test('custom rules', () {
      const quick = AutoBackupPolicy(
        debounce: Duration(seconds: 1),
        maxDebounce: Duration(seconds: 3),
        minInterval: Duration(seconds: 30),
      );
      expect(quick.dueAt(now: t0, firstChange: t0, lastChange: t0), at(1));
      expect(
        quick.dueAt(
          now: at(2),
          firstChange: t0,
          lastChange: at(2),
          lastAttempt: at(1),
        ),
        at(31),
      );
    });
  });
}
