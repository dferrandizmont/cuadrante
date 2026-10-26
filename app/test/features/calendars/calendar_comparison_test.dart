import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/calendars/domain/calendar_comparison.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

const _work = ShiftType(
  id: 'work',
  code: 'M',
  name: 'Mañana',
  colorValue: 0xFFF5A524,
  category: ShiftCategory.work,
  startMinute: 6 * 60,
  endMinute: 14 * 60,
);
const _night = ShiftType(
  id: 'night',
  code: 'N',
  name: 'Noche',
  colorValue: 0xFF4B4FD1,
  category: ShiftCategory.work,
  startMinute: 22 * 60,
  endMinute: 6 * 60,
);
const _rest = ShiftType(
  id: 'rest',
  code: 'L',
  name: 'Libre',
  colorValue: 0xFFE4E4E7,
  category: ShiftCategory.rest,
);
const _vacation = ShiftType(
  id: 'vacation',
  code: 'V',
  name: 'Vacaciones',
  colorValue: 0xFF30A46C,
  category: ShiftCategory.absence,
);

const _types = [_work, _night, _rest, _vacation];

/// A schedule made of single-day entries (`date -> shift ids`), every other
/// day empty.
Schedule _days(Map<CivilDate, List<String>> days) => Schedule(
  shiftTypes: _types,
  entries: {
    for (final e in days.entries)
      e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
  },
);

CivilDate _oct(int day) => CivilDate(2026, 10, day);

ResolvedDay _resolve(List<String> ids) =>
    _days({_oct(1): ids}).resolve(_oct(1));

void main() {
  group('isFreeDay: the precise definition', () {
    test('an empty day is free', () {
      expect(isFreeDay(_resolve(const [])), isTrue);
      expect(isFreeDay(_days(const {}).resolve(_oct(7))), isTrue);
    });

    test('a rest day is free', () {
      expect(isFreeDay(_resolve(const ['rest'])), isTrue);
    });

    test('an absence is free (vacation, sick leave...)', () {
      expect(isFreeDay(_resolve(const ['vacation'])), isTrue);
    });

    test('rest plus absence is free', () {
      expect(isFreeDay(_resolve(const ['rest', 'vacation'])), isTrue);
    });

    test('any work shift makes the day busy', () {
      expect(isFreeDay(_resolve(const ['work'])), isFalse);
      expect(isFreeDay(_resolve(const ['night'])), isFalse);
      expect(isFreeDay(_resolve(const ['work', 'night'])), isFalse);
    });

    test('work mixed with rest or an absence is still busy', () {
      expect(isFreeDay(_resolve(const ['rest', 'work'])), isFalse);
      expect(isFreeDay(_resolve(const ['vacation', 'night'])), isFalse);
    });

    test('a shift counts on the day it starts: the morning after a night is '
        'free', () {
      final schedule = _days({
        _oct(5): ['night'],
      });
      expect(isFreeDay(schedule.resolve(_oct(5))), isFalse);
      expect(isFreeDay(schedule.resolve(_oct(6))), isTrue);
    });

    test('a note alone does not make a day busy', () {
      final schedule = Schedule(
        shiftTypes: _types,
        entries: {_oct(1): DayEntry(date: _oct(1), note: 'Cena')},
      );
      expect(isFreeDay(schedule.resolve(_oct(1))), isTrue);
    });
  });

  group('compareMonth', () {
    // A works 1-3 and rests 4-5; B works 2 and 5 and is on vacation on 4.
    final a = _days({
      _oct(1): ['work'],
      _oct(2): ['work'],
      _oct(3): ['night'],
      _oct(4): ['rest'],
      _oct(5): ['rest'],
    });
    final b = _days({
      _oct(2): ['work'],
      _oct(4): ['vacation'],
      _oct(5): ['night'],
    });

    test('has every day of the month, in order', () {
      final month = compareMonth(a, b, _oct(17));
      expect(month.month, _oct(1));
      expect(month.days, hasLength(31));
      expect(month.days.first.date, _oct(1));
      expect(month.days.last.date, _oct(31));
      for (var i = 1; i < month.days.length; i++) {
        expect(month.days[i].date, month.days[i - 1].date.addDays(1));
      }
    });

    test('each day carries both calendars', () {
      final month = compareMonth(a, b, _oct(1));
      final day = month.days[1]; // 2 October
      expect(day.a.shiftIds, ['work']);
      expect(day.b.shiftIds, ['work']);
      expect(day.freeA, isFalse);
      expect(day.freeB, isFalse);
      expect(day.bothFree, isFalse);
      final fourth = month.days[3];
      expect(fourth.freeA, isTrue);
      expect(fourth.freeB, isTrue);
      expect(fourth.bothFree, isTrue);
    });

    test('the days free in both: empty days count, and rest + absence', () {
      final month = compareMonth(a, b, _oct(1));
      // 1: A busy. 2: both busy. 3: A busy. 4: both free (rest + vacation).
      // 5: B busy. 6-31: both empty, so both free.
      expect(month.commonFreeDays, [
        _oct(4),
        for (var d = 6; d <= 31; d++) _oct(d),
      ]);
      expect(month.commonFreeCount, 27);
    });

    test('is symmetric', () {
      final ab = compareMonth(a, b, _oct(1));
      final ba = compareMonth(b, a, _oct(1));
      expect(ab.commonFreeDays, ba.commonFreeDays);
      expect(ab.commonFreeCount, ba.commonFreeCount);
    });

    test('a calendar compared with itself is free on its free days', () {
      final month = compareMonth(a, a, _oct(1));
      expect(month.commonFreeDays.first, _oct(4));
      expect(month.commonFreeCount, 28); // all but 1, 2 and 3
    });

    test('a month with no free day in common says zero', () {
      final busy = Schedule(
        shiftTypes: _types,
        entries: {
          for (var d = 1; d <= 31; d++)
            _oct(d): DayEntry(date: _oct(d), shiftTypeIds: const ['work']),
        },
      );
      final month = compareMonth(busy, busy, _oct(1));
      expect(month.commonFreeCount, 0);
      expect(month.commonFreeDays, isEmpty);
    });

    test('February of a leap year has 29 days', () {
      final month = compareMonth(a, b, const CivilDate(2028, 2, 10));
      expect(month.days, hasLength(29));
      expect(month.commonFreeCount, 29);
    });
  });

  group('with real rotations', () {
    // Correturnos from two different Mondays: the same cycle, shifted.
    final a = presetSchedule('correturnos', const CivilDate(2026, 10, 5));
    final b = presetSchedule('correturnos', const CivilDate(2026, 10, 12));

    test('agrees with doing it by hand, day by day', () {
      for (final month in [
        const CivilDate(2026, 9, 1),
        const CivilDate(2026, 10, 1),
        const CivilDate(2026, 11, 1),
        const CivilDate(2026, 12, 1),
      ]) {
        final byHand = <CivilDate>[
          for (
            var d = month;
            !d.isAfter(month.lastDayOfMonth);
            d = d.addDays(1)
          )
            if (a
                    .resolve(d)
                    .shifts
                    .every((s) => s.category != ShiftCategory.work) &&
                b
                    .resolve(d)
                    .shifts
                    .every((s) => s.category != ShiftCategory.work))
              d,
        ];
        final month0 = compareMonth(a, b, month);
        expect(month0.commonFreeDays, byHand, reason: '$month');
        expect(month0.commonFreeCount, byHand.length);
      }
    });

    test('before the rotations start every day is free', () {
      final month = compareMonth(a, b, const CivilDate(2026, 8, 1));
      expect(month.commonFreeCount, 31);
    });

    test('the same rotation shifted by a week still shares its rest days', () {
      final month = compareMonth(a, b, const CivilDate(2026, 10, 1));
      // Not all days, not none: some meeting days exist.
      expect(month.commonFreeCount, greaterThan(0));
      expect(month.commonFreeCount, lessThan(31));
    });
  });

  group('resolveComparePair', () {
    const one = Calendar(id: 'one', name: 'Uno', colorValue: 1, sortOrder: 0);
    const two = Calendar(id: 'two', name: 'Dos', colorValue: 2, sortOrder: 1);
    const three = Calendar(
      id: 'three',
      name: 'Tres',
      colorValue: 3,
      sortOrder: 2,
    );
    const all = [one, two, three];

    test('needs two calendars', () {
      expect(resolveComparePair(const [], activeId: 'one'), isNull);
      expect(resolveComparePair(const [one], activeId: 'one'), isNull);
    });

    test('by default the calendar on screen and the next one', () {
      final pair = resolveComparePair(all, activeId: 'two')!;
      expect((pair.first.id, pair.second.id), ('two', 'three'));
    });

    test('after the last one it wraps to the first', () {
      final pair = resolveComparePair(all, activeId: 'three')!;
      expect((pair.first.id, pair.second.id), ('three', 'one'));
    });

    test('with two calendars they are the two', () {
      final pair = resolveComparePair(const [one, two], activeId: 'two')!;
      expect((pair.first.id, pair.second.id), ('two', 'one'));
    });

    test('asked ones win, when they exist and differ', () {
      final pair = resolveComparePair(
        all,
        activeId: 'one',
        firstId: 'three',
        secondId: 'two',
      )!;
      expect((pair.first.id, pair.second.id), ('three', 'two'));
    });

    test('the same one twice, or an unknown one, falls back to the next', () {
      final same = resolveComparePair(
        all,
        activeId: 'one',
        firstId: 'two',
        secondId: 'two',
      )!;
      expect((same.first.id, same.second.id), ('two', 'three'));
      final unknown = resolveComparePair(
        all,
        activeId: 'one',
        firstId: 'gone',
        secondId: 'gone',
      )!;
      expect((unknown.first.id, unknown.second.id), ('one', 'two'));
    });

    test('an active id that is not in the list uses the first calendar', () {
      final pair = resolveComparePair(all, activeId: 'archived')!;
      expect((pair.first.id, pair.second.id), ('one', 'two'));
    });
  });

  group('compareDays', () {
    test('a range that ends before it starts is empty', () {
      final empty = _days(const {});
      expect(compareDays(empty, empty, _oct(5), _oct(4)), isEmpty);
    });

    test('a single day', () {
      final empty = _days(const {});
      final days = compareDays(empty, empty, _oct(5), _oct(5));
      expect(days, hasLength(1));
      expect(days.single.bothFree, isTrue);
    });

    test('works across months', () {
      final empty = _days(const {});
      final days = compareDays(
        empty,
        empty,
        const CivilDate(2026, 10, 30),
        const CivilDate(2026, 11, 2),
      );
      expect(days.map((d) => d.date.toIso()), [
        '2026-10-30',
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
      ]);
    });
  });

  group('overtime, early leave and reminders do not matter (0.6.0)', () {
    test('a free day with overtime or a reminder is still free; a busy day '
        'with extras is still busy; the comparison is unchanged', () {
      final plain = _days({
        _oct(5): ['work'],
        _oct(6): ['rest'],
        _oct(7): ['vacation'],
      });
      final annotated = Schedule(
        shiftTypes: _types,
        entries: {
          _oct(5): DayEntry(
            date: _oct(5),
            shiftTypeIds: const ['work'],
            overtimeMinutes: 60,
            earlyLeaveMinutes: 15,
            note: 'Nota',
            noteReminderMinute: 480,
          ),
          _oct(6): DayEntry(
            date: _oct(6),
            shiftTypeIds: const ['rest'],
            overtimeMinutes: 90,
          ),
          _oct(7): DayEntry(
            date: _oct(7),
            shiftTypeIds: const ['vacation'],
            noteReminderMinute: 600,
          ),
          // Nothing but an extra: the day is empty, so free.
          _oct(8): DayEntry(date: _oct(8), overtimeMinutes: 30),
        },
      );
      expect(isFreeDay(annotated.resolve(_oct(5))), isFalse);
      expect(isFreeDay(annotated.resolve(_oct(6))), isTrue);
      expect(isFreeDay(annotated.resolve(_oct(7))), isTrue);
      expect(isFreeDay(annotated.resolve(_oct(8))), isTrue);

      final a = compareMonth(plain, annotated, _oct(1));
      final b = compareMonth(plain, plain, _oct(1));
      expect(
        [for (final d in a.days.take(7)) (d.freeA, d.freeB)],
        [for (final d in b.days.take(7)) (d.freeA, d.freeB)],
      );
      expect(a.days[4].a.shiftIds, ['work']);
      expect(a.days[4].b.shiftIds, ['work']);
    });
  });
}
