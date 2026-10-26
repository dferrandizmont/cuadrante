import 'package:cuadrante/features/calendar/application/today_status.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

void main() {
  const mon = CivilDate(2026, 10, 19);

  Schedule schedule(Map<CivilDate, List<String>> days) => Schedule(
    shiftTypes: allTypes,
    entries: {
      for (final e in days.entries)
        e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
    },
  );

  TodayStatus at(Schedule s, int hour, [int minute = 0, CivilDate day = mon]) =>
      todayStatus(s, DateTime(day.year, day.month, day.day, hour, minute));

  String ids(Iterable<ShiftType> shifts) => shifts.map((s) => s.id).join('+');

  group('phase', () {
    final s = schedule({
      mon: ['night'],
      mon.addDays(1): ['night'],
    });

    test('a night shift later today is "tonight", with the countdown', () {
      final status = at(s, 18, 20);
      expect(status.phase, TodayPhase.tonight);
      expect(status.main!.id, 'night');
      expect(status.minutes, 3 * 60 + 40);
      expect(status.others, isEmpty);
      expect(ids(status.tomorrow), 'night');
    });

    test('a shift that starts before 20:00 is "today"', () {
      final status = at(
        schedule({
          mon: ['morning', 'afternoon'],
        }),
        5,
      );
      expect(status.phase, TodayPhase.today);
      expect(status.main!.id, 'morning');
      expect(status.minutes, 60);
      // The others come in one line.
      expect(ids(status.others), 'afternoon');
    });

    test('20:00 sharp already counts as tonight', () {
      final status = at(
        schedule({
          mon: ['night12'],
        }),
        12,
      );
      expect(status.phase, TodayPhase.tonight);
    });

    test('the shift in progress is "now" and counts down to its end', () {
      final status = at(s, 23, 30);
      expect(status.phase, TodayPhase.now);
      expect(status.main!.id, 'night');
      expect(status.minutes, 6 * 60 + 30);
      expect(status.timed!.end, DateTime(2026, 10, 20, 6));
    });

    test('yesterday\'s overnight shift is still "now" after midnight', () {
      final status = at(s, 3, 0, mon.addDays(1));
      expect(status.phase, TodayPhase.now);
      expect(status.main!.id, 'night');
      expect(status.minutes, 3 * 60);
      // Today's own night shift comes after.
      expect(ids(status.others), 'night');
    });

    test('the end of a shift is not "now" any more', () {
      final status = at(
        schedule({
          mon: ['morning'],
        }),
        14,
      );
      // The day was worked: it is over, not free.
      expect(status.phase, TodayPhase.done);
      expect(status.main!.id, 'morning');
    });

    test('the one that started last wins when two overlap', () {
      final status = at(
        schedule({
          mon: ['afternoon', 'night12'],
        }),
        21,
      );
      expect(status.phase, TodayPhase.now);
      expect(status.main!.id, 'night12');
    });
  });

  group('free day', () {
    test('shows the next shift with its countdown', () {
      final s = schedule({
        mon: ['rest'],
        mon.addDays(1): [],
        mon.addDays(2): ['morning'],
      });
      final status = at(s, 10);
      expect(status.phase, TodayPhase.free);
      expect(status.main, isNull);
      expect(status.restShift!.id, 'rest');
      expect(status.timed!.shift.id, 'morning');
      expect(status.timed!.start, DateTime(2026, 10, 21, 6));
      // Monday 10:00 to Wednesday 06:00.
      expect(status.minutes, 44 * 60);
      expect(status.tomorrow, isEmpty);
    });

    test('an empty schedule has nothing next', () {
      final status = at(schedule({}), 10);
      expect(status.phase, TodayPhase.free);
      expect(status.timed, isNull);
      expect(status.minutes, isNull);
      expect(status.restShift, isNull);
    });

    test('after the last shift of today the next one is shown', () {
      final s = schedule({
        mon: ['morning'],
        mon.addDays(1): ['afternoon'],
      });
      final status = at(s, 15);
      expect(status.phase, TodayPhase.done);
      expect(status.timed!.shift.id, 'afternoon');
      expect(status.minutes, 23 * 60);
    });
  });

  group('after the last shift of today (done)', () {
    test('Tarde over at 22:30: done, with what ended and what comes next', () {
      final s = schedule({
        mon: ['afternoon'],
        mon.addDays(1): ['morning'],
      });
      final status = at(s, 22, 30);
      expect(status.phase, TodayPhase.done);
      expect(status.main!.id, 'afternoon');
      expect(status.finished!.end, DateTime(2026, 10, 19, 22));
      expect(status.restShift, isNull);
      expect(status.timed!.shift.id, 'morning');
      expect(status.timed!.start, DateTime(2026, 10, 20, 6));
      // 22:30 to 06:00.
      expect(status.minutes, 7 * 60 + 30);
      expect(ids(status.tomorrow), 'morning');
    });

    test('the minute the shift ends it is done', () {
      final s = schedule({
        mon: ['afternoon'],
      });
      expect(at(s, 21, 59).phase, TodayPhase.now);
      expect(at(s, 22).phase, TodayPhase.done);
    });

    test('with two shifts, the one that ended last is named', () {
      final s = schedule({
        mon: ['morning', 'afternoon'],
      });
      expect(at(s, 14, 30).phase, TodayPhase.now);
      final status = at(s, 23);
      expect(status.phase, TodayPhase.done);
      expect(status.main!.id, 'afternoon');
    });

    test('a night shift that started today is not over until tomorrow', () {
      final s = schedule({
        mon: ['night'],
      });
      expect(at(s, 23).phase, TodayPhase.now);
      // The next morning the shift belongs to yesterday: today is free.
      final next = at(s, 8, 0, mon.addDays(1));
      expect(next.phase, TodayPhase.free);
      expect(next.finished, isNull);
    });

    test('the night of yesterday does not make today "done"', () {
      final s = schedule({
        mon: ['night'],
        mon.addDays(1): ['rest'],
      });
      final status = at(s, 10, 0, mon.addDays(1));
      expect(status.phase, TodayPhase.free);
      expect(status.restShift!.id, 'rest');
    });

    test('a rest day, a vacation and an empty day are never done', () {
      final s = schedule({
        mon: ['rest'],
        mon.addDays(1): ['vacation'],
      });
      expect(at(s, 23).phase, TodayPhase.free);
      expect(at(s, 23, 0, mon.addDays(1)).phase, TodayPhase.today);
      expect(at(s, 23, 0, mon.addDays(2)).phase, TodayPhase.free);
    });

    test('with nothing else scheduled it has no next shift to show', () {
      final s = schedule({
        mon: ['morning'],
      });
      final status = at(s, 20);
      expect(status.phase, TodayPhase.done);
      expect(status.timed, isNull);
      expect(status.minutes, isNull);
    });
  });

  test('a shift without hours (vacation) is "today", with no countdown', () {
    final status = at(
      schedule({
        mon: ['vacation'],
      }),
      9,
    );
    expect(status.phase, TodayPhase.today);
    expect(status.main!.id, 'vacation');
    expect(status.timed, isNull);
    expect(status.minutes, isNull);
  });

  test('the countdown is real elapsed time across a DST change', () {
    // 2026-10-25 (Europe/Madrid, as CI runs): clocks go back at 03:00, so
    // 01:00 -> 06:00 is 6 hours, not 5.
    const sun = CivilDate(2026, 10, 25);
    final s = schedule({
      sun: ['morning'],
    });
    final status = todayStatus(s, DateTime(2026, 10, 25, 1));
    expect(status.timed!.start, DateTime(2026, 10, 25, 6));
    expect(status.minutes, 6 * 60);
  });

  for (final (utcHour, minutes) in [(0, 270), (1, 210)]) {
    test('repeated October 02:30 at UTC $utcHour retains its countdown', () {
      const sun = CivilDate(2026, 10, 25);
      final instant = DateTime.utc(2026, 10, 25, utcHour, 30, 45).toLocal();
      expect((instant.hour, instant.minute), (2, 30));
      final status = todayStatus(
        schedule({
          sun: ['morning'],
        }),
        instant,
      );
      expect(status.timed!.start, DateTime(2026, 10, 25, 6));
      expect(status.minutes, minutes);
    });
  }

  test('seconds are ignored', () {
    final s = schedule({
      mon: ['night'],
    });
    final status = todayStatus(s, DateTime(2026, 10, 19, 18, 20, 45));
    expect(status.minutes, 3 * 60 + 40);
  });
}
