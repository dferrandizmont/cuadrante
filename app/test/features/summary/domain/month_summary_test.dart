import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../schedule/domain/fixtures.dart';

const _oct = CivilDate(2026, 10, 1);

/// 08:00-16:00 with a rate, for the hand-made schedules.
ShiftType _work(
  String id, {
  required int start,
  required int end,
  int? paid,
  bool? night,
  int? rate,
  ShiftCategory category = ShiftCategory.work,
}) => ShiftType(
  id: id,
  code: id.substring(0, 1).toUpperCase(),
  name: id,
  colorValue: 0xFF336699,
  category: category,
  startMinute: start,
  endMinute: end,
  paidMinutes: paid,
  nightOverride: night,
  hourlyRateCents: rate,
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

const _sick = ShiftType(
  id: 'sick',
  code: 'B',
  name: 'Baja',
  colorValue: 0xFF999999,
  category: ShiftCategory.absence,
);

/// A schedule made of single-day entries (`date -> shift ids`).
Schedule _days(List<ShiftType> types, Map<CivilDate, List<String>> days) =>
    Schedule(
      shiftTypes: types,
      entries: {
        for (final e in days.entries)
          e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
      },
    );

const _h = 60;

void main() {
  group('correturnos with rates (October 2026)', () {
    // 21-day cycle from Monday 5 October: M x5, L x2, T x5, L x2, N x5, L x2,
    // then M again on the 26th. October: M 5-9 and 26-30 (10), T 12-16 (5),
    // N 19-23 (5), L 10, 11, 17, 18, 24, 25 and 31 (7); 1-4 have no rotation.
    Schedule schedule() {
      final base = presetSchedule('correturnos', const CivilDate(2026, 10, 5));
      return base.copyWith(
        shiftTypes: [
          for (final t in base.shiftTypes)
            switch (t.id) {
              'morning' => t.copyWith(hourlyRateCents: 1000),
              'afternoon' => t.copyWith(hourlyRateCents: 1100),
              'night' => t.copyWith(hourlyRateCents: 1300),
              _ => t,
            },
        ],
      );
    }

    test('days, shifts, hours, night hours and pay', () {
      final s = summarizeMonth(schedule(), _oct);
      expect(s.month, _oct);
      expect(s.shiftsWorked, 20);
      expect(s.workedDays, 20);
      expect(s.workedMinutes, 160 * _h);
      expect(s.nightMinutes, 40 * _h);
      expect(s.dayMinutes, 120 * _h);
      expect(s.restDays, 7);
      expect(s.absenceDays, 0);
      // 80 h x 10 + 40 h x 11 + 40 h x 13 = 800 + 440 + 520.
      expect(s.earningsCents, 176000);
      expect(s.unpricedTypes, isEmpty);
      expect(s.isEmpty, isFalse);
    });

    test('per type: days, count, hours and pay, in the order of the types', () {
      final s = summarizeMonth(schedule(), _oct);
      expect(s.types.map((t) => t.type.id), [
        'morning',
        'afternoon',
        'night',
        'rest',
      ]);
      final morning = s.types[0];
      expect((morning.days, morning.count), (10, 10));
      expect(morning.paidMinutes, 80 * _h);
      expect(morning.nightMinutes, 0);
      expect(morning.earningsCents, 80000);
      final night = s.types[2];
      expect(night.paidMinutes, 40 * _h);
      expect(night.nightMinutes, 40 * _h);
      expect(night.earningsCents, 52000);
      final rest = s.types[3];
      expect(rest.days, 7);
      expect(rest.paidMinutes, 0);
      expect(rest.earningsCents, isNull);
      expect(s.workTypes.length, 3);
      expect(s.restTypes.single.type.id, 'rest');
      expect(s.absenceTypes, isEmpty);
    });

    test('holidays on a worked day and on the day after a night', () {
      final s = summarizeMonth(
        schedule(),
        _oct,
        holidays: {
          const CivilDate(2026, 10, 12),
          const CivilDate(2026, 10, 24),
        },
      );
      // 12 Oct is a Tarde (8 h). 24 Oct is a Libre, but the Noche of the 23rd
      // runs 6 h into it, and that part is on a holiday.
      expect(s.holidayShifts, 2);
      expect(s.holidayMinutes, 14 * _h);
    });

    test('a work shift without hours on a holiday adds no holiday shift', () {
      const noHours = ShiftType(
        id: 'guard',
        code: 'G',
        name: 'Guardia',
        colorValue: 0xFF336699,
        category: ShiftCategory.work,
      );
      final s = summarizeMonth(
        _days(
          [noHours, _work('day', start: 8 * 60, end: 16 * 60)],
          {
            const CivilDate(2026, 10, 12): ['guard'],
            const CivilDate(2026, 10, 13): ['day'],
          },
        ),
        _oct,
        holidays: {
          const CivilDate(2026, 10, 12),
          const CivilDate(2026, 10, 13),
        },
      );
      expect(s.shiftsWithoutTimes, 1);
      // Only the shift with hours is a holiday shift, with its 8 h.
      expect(s.holidayShifts, 1);
      expect(s.holidayMinutes, 8 * _h);
    });

    test('a month before the rotation is empty', () {
      final s = summarizeMonth(schedule(), const CivilDate(2026, 9, 1));
      expect(s.isEmpty, isTrue);
      expect(s.workedMinutes, 0);
      expect(s.earningsCents, isNull);
      expect(s.shiftsWorked, 0);
    });

    test('any day of the month gives the same month', () {
      expect(
        summarizeMonth(schedule(), const CivilDate(2026, 10, 17)).workedMinutes,
        160 * _h,
      );
      expect(
        summarizeMonth(schedule(), const CivilDate(2026, 10, 17)).month,
        _oct,
      );
    });
  });

  group('several shifts in a day', () {
    test('Mañana + Tarde counts both shifts and one worked day', () {
      final s = summarizeMonth(
        _days(
          [
            _work('morning', start: 6 * _h, end: 14 * _h, rate: 1000),
            _work('afternoon', start: 14 * _h, end: 22 * _h, rate: 1000),
          ],
          {
            const CivilDate(2026, 10, 7): ['morning', 'afternoon'],
          },
        ),
        _oct,
      );
      expect(s.shiftsWorked, 2);
      expect(s.workedDays, 1);
      expect(s.workedMinutes, 16 * _h);
      expect(s.types.map((t) => (t.days, t.count)), [(1, 1), (1, 1)]);
      expect(s.earningsCents, 16000);
    });

    test('the same type twice in a day: one day, two shifts', () {
      final s = summarizeMonth(
        _days(
          [_work('guard', start: 8 * _h, end: 20 * _h)],
          {
            const CivilDate(2026, 10, 7): ['guard', 'guard'],
          },
        ),
        _oct,
      );
      expect((s.types.single.days, s.types.single.count), (1, 2));
      expect(s.shiftsWorked, 2);
      expect(s.workedDays, 1);
      expect(s.workedMinutes, 24 * _h);
    });
  });

  group('midnight crossing', () {
    final night = _work('night', start: 22 * _h, end: 6 * _h, rate: 1200);
    final schedule = _days(
      [night],
      {
        const CivilDate(2026, 9, 30): ['night'],
        const CivilDate(2026, 10, 31): ['night'],
      },
    );

    test('the night of 31 October counts in October, in full', () {
      final october = summarizeMonth(schedule, _oct);
      expect(october.shiftsWorked, 1);
      expect(october.workedMinutes, 8 * _h);
      expect(october.nightMinutes, 8 * _h);
      expect(october.earningsCents, 9600);
    });

    test('the night of 30 September is September\'s, not October\'s', () {
      final september = summarizeMonth(schedule, const CivilDate(2026, 9, 1));
      expect(september.workedMinutes, 8 * _h);
      // Nothing of the night that ended on 1 October is in October on 1 Oct.
      expect(summarizeMonth(schedule, _oct).shiftsWorked, 1);
      final november = summarizeMonth(schedule, const CivilDate(2026, 11, 1));
      expect(november.isEmpty, isTrue);
      expect(november.workedMinutes, 0);
    });

    test('hours on a holiday after midnight belong to the start month', () {
      // 1 November is a holiday: 6 h of the night of 31 October fall on it.
      final october = summarizeMonth(
        schedule,
        _oct,
        holidays: {const CivilDate(2026, 11, 1)},
      );
      expect(october.holidayShifts, 1);
      expect(october.holidayMinutes, 6 * _h);
      expect(october.holidayMinutes, lessThanOrEqualTo(october.workedMinutes));
      final november = summarizeMonth(
        schedule,
        const CivilDate(2026, 11, 1),
        holidays: {const CivilDate(2026, 11, 1)},
      );
      expect(november.holidayMinutes, 0);
    });
  });

  group('24 hour guard', () {
    test('08:00-08:00 is 24 h, with 8 h of night', () {
      final s = summarizeMonth(
        _days(
          [_work('guard', start: 8 * _h, end: 8 * _h)],
          {
            const CivilDate(2026, 10, 5): ['guard'],
          },
        ),
        _oct,
      );
      expect(s.workedMinutes, 24 * _h);
      expect(s.nightMinutes, 8 * _h);
      expect(s.dayMinutes, 16 * _h);
    });

    test('split by calendar day for a holiday: 16 h + 8 h', () {
      final guard = _work('guard', start: 8 * _h, end: 8 * _h);
      final onTheDay = summarizeMonth(
        _days(
          [guard],
          {
            const CivilDate(2026, 10, 5): ['guard'],
          },
        ),
        _oct,
        holidays: {const CivilDate(2026, 10, 5)},
      );
      expect(onTheDay.holidayMinutes, 16 * _h);
      final nextDay = summarizeMonth(
        _days(
          [guard],
          {
            const CivilDate(2026, 10, 5): ['guard'],
          },
        ),
        _oct,
        holidays: {const CivilDate(2026, 10, 6)},
      );
      expect(nextDay.holidayMinutes, 8 * _h);
      expect(nextDay.holidayShifts, 1);
    });
  });

  group('night override', () {
    test(
      'true makes a day shift all night; false makes a night shift none',
      () {
        final s = summarizeMonth(
          _days(
            [
              _work('day', start: 8 * _h, end: 16 * _h, night: true),
              _work('night', start: 22 * _h, end: 6 * _h, night: false),
              _work('plain', start: 22 * _h, end: 6 * _h),
            ],
            {
              const CivilDate(2026, 10, 5): ['day'],
              const CivilDate(2026, 10, 6): ['night'],
              const CivilDate(2026, 10, 7): ['plain'],
            },
          ),
          _oct,
        );
        expect(s.types[0].nightMinutes, 8 * _h);
        expect(s.types[1].nightMinutes, 0);
        expect(s.types[2].nightMinutes, 8 * _h);
        expect(s.workedMinutes, 24 * _h);
        expect(s.nightMinutes, 16 * _h);
      },
    );

    test('a shift that starts in the early morning has night hours too', () {
      final s = summarizeMonth(
        _days(
          [_work('early', start: 4 * _h, end: 12 * _h)],
          {
            const CivilDate(2026, 10, 5): ['early'],
          },
        ),
        _oct,
      );
      expect(s.nightMinutes, 2 * _h);
    });
  });

  group('paid minutes with an unpaid break', () {
    test('hours and pay use the paid minutes', () {
      final s = summarizeMonth(
        _days(
          [_work('day', start: 8 * _h, end: 16 * _h, paid: 450, rate: 1250)],
          {
            const CivilDate(2026, 10, 5): ['day'],
            const CivilDate(2026, 10, 6): ['day'],
          },
        ),
        _oct,
      );
      expect(s.workedMinutes, 900);
      expect(s.types.single.paidMinutes, 900);
      // 15 h x 12,50 = 187,50.
      expect(s.earningsCents, 18750);
    });

    test('night hours never exceed the paid minutes of the shift', () {
      final s = summarizeMonth(
        _days(
          [_work('night', start: 22 * _h, end: 6 * _h, paid: 450, night: true)],
          {
            const CivilDate(2026, 10, 5): ['night'],
          },
        ),
        _oct,
      );
      expect(s.workedMinutes, 450);
      expect(s.nightMinutes, 450);
      expect(s.dayMinutes, 0);
    });

    test('pay is rounded to the cent, half up, once per type', () {
      // 7 h 30 min x 13,33 = 99,975 -> 99,98.
      final s = summarizeMonth(
        _days(
          [_work('day', start: 8 * _h, end: 16 * _h, paid: 450, rate: 1333)],
          {
            const CivilDate(2026, 10, 5): ['day'],
          },
        ),
        _oct,
      );
      expect(s.earningsCents, 9998);
    });
  });

  group('holiday hours', () {
    final night = _work('night', start: 22 * _h, end: 6 * _h);

    test(
      'a night shift that runs into a holiday counts the part after midnight',
      () {
        final s = summarizeMonth(
          _days(
            [night],
            {
              const CivilDate(2026, 12, 24): ['night'],
            },
          ),
          const CivilDate(2026, 12, 1),
          holidays: {const CivilDate(2026, 12, 25)},
        );
        expect(s.holidayShifts, 1);
        expect(s.holidayMinutes, 6 * _h);
      },
    );

    test(
      'a night shift that starts on a holiday counts the part before it',
      () {
        final s = summarizeMonth(
          _days(
            [night],
            {
              const CivilDate(2026, 12, 24): ['night'],
            },
          ),
          const CivilDate(2026, 12, 1),
          holidays: {const CivilDate(2026, 12, 24)},
        );
        expect(s.holidayMinutes, 2 * _h);
      },
    );

    test('both days holidays: the whole shift', () {
      final s = summarizeMonth(
        _days(
          [night],
          {
            const CivilDate(2026, 12, 24): ['night'],
          },
        ),
        const CivilDate(2026, 12, 1),
        holidays: {
          const CivilDate(2026, 12, 24),
          const CivilDate(2026, 12, 25),
        },
      );
      expect(s.holidayShifts, 1);
      expect(s.holidayMinutes, 8 * _h);
    });

    test('with an unpaid break the holiday minutes are prorated', () {
      final s = summarizeMonth(
        _days(
          [_work('night', start: 22 * _h, end: 6 * _h, paid: 450)],
          {
            const CivilDate(2026, 12, 24): ['night'],
          },
        ),
        const CivilDate(2026, 12, 1),
        holidays: {const CivilDate(2026, 12, 25)},
      );
      // 360 of 480 minutes on the holiday: 337,5 of the 450 paid -> 338.
      expect(s.holidayMinutes, 338);
    });

    test('rest days and absences on a holiday are not worked holidays', () {
      final s = summarizeMonth(
        _days(
          [_rest, _vacation],
          {
            const CivilDate(2026, 12, 25): ['rest'],
            const CivilDate(2026, 12, 26): ['vacation'],
          },
        ),
        const CivilDate(2026, 12, 1),
        holidays: {
          const CivilDate(2026, 12, 25),
          const CivilDate(2026, 12, 26),
        },
      );
      expect(s.holidayShifts, 0);
      expect(s.holidayMinutes, 0);
    });

    test('no holidays: zero', () {
      final s = summarizeMonth(
        _days(
          [night],
          {
            const CivilDate(2026, 12, 24): ['night'],
          },
        ),
        const CivilDate(2026, 12, 1),
      );
      expect((s.holidayShifts, s.holidayMinutes), (0, 0));
    });
  });

  group('rest days and absences', () {
    final schedule = _days(
      [_work('day', start: 8 * _h, end: 16 * _h), _rest, _vacation, _sick],
      {
        const CivilDate(2026, 10, 1): ['day'],
        const CivilDate(2026, 10, 2): ['rest'],
        const CivilDate(2026, 10, 3): ['rest'],
        const CivilDate(2026, 10, 4): ['vacation'],
        const CivilDate(2026, 10, 5): ['vacation'],
        const CivilDate(2026, 10, 6): ['vacation'],
        const CivilDate(2026, 10, 7): ['sick'],
        // Rest + absence: an absence day, not a rest day.
        const CivilDate(2026, 10, 8): ['rest', 'vacation'],
        // Rest + work: a worked day.
        const CivilDate(2026, 10, 9): ['rest', 'day'],
      },
    );

    test('days by absence type, rest days and the worked days', () {
      final s = summarizeMonth(schedule, _oct);
      expect(s.restDays, 2);
      expect(s.absenceDays, 5);
      expect(s.workedDays, 2);
      final byId = {for (final t in s.types) t.type.id: t};
      expect(byId['vacation']!.days, 4);
      expect(byId['sick']!.days, 1);
      expect(byId['rest']!.days, 4);
      expect(s.absenceTypes.map((t) => t.type.id), ['vacation', 'sick']);
      // Absences and rests never add hours.
      expect(s.workedMinutes, 16 * _h);
    });
  });

  group('rate missing', () {
    test('a worked type without rate is listed and adds nothing', () {
      final s = summarizeMonth(
        _days(
          [
            _work('priced', start: 8 * _h, end: 16 * _h, rate: 1000),
            _work('free', start: 16 * _h, end: 20 * _h),
          ],
          {
            const CivilDate(2026, 10, 5): ['priced'],
            const CivilDate(2026, 10, 6): ['free'],
          },
        ),
        _oct,
      );
      expect(s.earningsCents, 8000);
      expect(s.unpricedTypes.map((t) => t.id), ['free']);
      expect(s.types[1].earningsCents, isNull);
      expect(s.types[1].missingRate, isTrue);
      expect(s.types[0].missingRate, isFalse);
      expect(s.hasEarnings, isTrue);
    });

    test('no rate anywhere: no total at all (null, not zero)', () {
      final s = summarizeMonth(
        _days(
          [_work('free', start: 8 * _h, end: 16 * _h)],
          {
            const CivilDate(2026, 10, 5): ['free'],
          },
        ),
        _oct,
      );
      expect(s.earningsCents, isNull);
      expect(s.hasEarnings, isFalse);
      expect(s.workedMinutes, 8 * _h);
    });

    test('a rate on a type without hours or on a rest type adds nothing', () {
      final s = summarizeMonth(
        _days(
          [
            const ShiftType(
              id: 'untimed',
              code: 'U',
              name: 'Sin hora',
              colorValue: 0xFF123456,
              category: ShiftCategory.work,
              hourlyRateCents: 5000,
            ),
            _rest.copyWith(hourlyRateCents: 5000),
          ],
          {
            const CivilDate(2026, 10, 5): ['untimed'],
            const CivilDate(2026, 10, 6): ['rest'],
          },
        ),
        _oct,
      );
      expect(s.earningsCents, isNull);
      expect(s.unpricedTypes, isEmpty);
    });
  });

  group('shifts without a schedule', () {
    test('count as shifts but add no hours', () {
      final s = summarizeMonth(
        _days(
          [
            const ShiftType(
              id: 'untimed',
              code: 'U',
              name: 'Sin hora',
              colorValue: 0xFF123456,
              category: ShiftCategory.work,
            ),
          ],
          {
            const CivilDate(2026, 10, 5): ['untimed'],
            const CivilDate(2026, 10, 6): ['untimed'],
          },
        ),
        _oct,
        holidays: {const CivilDate(2026, 10, 6)},
      );
      expect(s.shiftsWorked, 2);
      expect(s.shiftsWithoutTimes, 2);
      expect(s.workedDays, 2);
      expect(s.workedMinutes, 0);
      // No hours, so nothing to show as holiday work: not a holiday shift
      // either (it used to read «0 h · 1 turno en festivo»).
      expect(s.holidayShifts, 0);
      expect(s.holidayMinutes, 0);
    });
  });

  group('daylight saving time', () {
    // The summary is in civil time (docs/motor-de-turnos.md): the night of the
    // clock change is 8 h, not 7 or 9. These months hold the changes of
    // 25 October 2026 and 28 March 2027.
    Schedule nights(CivilDate from, int count) => Schedule(
      shiftTypes: [_work('night', start: 22 * _h, end: 6 * _h, rate: 1000)],
      patterns: const [
        Pattern(
          id: 'p',
          name: 'N',
          steps: [
            ['night'],
          ],
        ),
      ],
      runs: [
        PatternRun(
          id: 'r',
          patternId: 'p',
          startDate: from,
          endDate: from.addDays(count - 1),
          seq: 1,
        ),
      ],
    );

    test('October 2026: the night of 24 to 25 October counts 8 h', () {
      final s = summarizeMonth(nights(const CivilDate(2026, 10, 23), 4), _oct);
      expect(s.shiftsWorked, 4);
      expect(s.workedMinutes, 4 * 8 * _h);
      expect(s.nightMinutes, 4 * 8 * _h);
      expect(s.earningsCents, 32000);
    });

    test('March 2027: the night of 27 to 28 March counts 8 h', () {
      final s = summarizeMonth(
        nights(const CivilDate(2027, 3, 26), 4),
        const CivilDate(2027, 3, 1),
      );
      expect(s.shiftsWorked, 4);
      expect(s.workedMinutes, 4 * 8 * _h);
      expect(s.nightMinutes, 4 * 8 * _h);
    });

    test('a month of 12 h shifts adds 12 h per shift', () {
      final base = presetSchedule('12h', const CivilDate(2026, 10, 1));
      // D N12 S L: 8 days D, 8 N12 in 31 days (ends on step 2 of a cycle).
      final s = summarizeMonth(base, _oct);
      expect(s.workedMinutes, (s.shiftsWorked) * 12 * _h);
    });
  });

  group('year totals', () {
    test('sum of the twelve months', () {
      final base = presetSchedule('6x4', jan1);
      final schedule = base.copyWith(
        shiftTypes: [
          for (final t in base.shiftTypes)
            t.id == 'morning' ? t.copyWith(hourlyRateCents: 1000) : t,
        ],
      );
      final year = summarizeYearTotals(schedule, 2026);
      expect(year.year, 2026);
      expect(year.months.length, 12);
      // 365 days = 36 cycles of 10 (6 mornings each) + 5 mornings.
      expect(year.shiftsWorked, 36 * 6 + 5);
      expect(year.workedMinutes, (36 * 6 + 5) * 8 * _h);
      expect(year.earningsCents, (36 * 6 + 5) * 8 * 1000);
      expect(year.restDays, 36 * 4);
      expect(year.nightMinutes, 0);
      expect(year.absenceDays, 0);
      expect(year.isEmpty, isFalse);
      expect(year.months.map((m) => m.month.month), [
        for (var m = 1; m <= 12; m++) m,
      ]);
    });

    test('a year without shifts is empty and has no pay', () {
      final year = summarizeYearTotals(
        presetSchedule('6x4', const CivilDate(2027, 6, 1)),
        2025,
      );
      expect(year.isEmpty, isTrue);
      expect(year.earningsCents, isNull);
      expect(year.workedMinutes, 0);
    });
  });
}
