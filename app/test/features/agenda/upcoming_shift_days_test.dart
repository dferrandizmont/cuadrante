import 'package:cuadrante/features/agenda/domain/agenda.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

// «Turnos» of the agenda: every one of the next days with its shifts.

const _today = CivilDate(2026, 10, 19);

ShiftType _type(String id, {String? name}) => ShiftType(
  id: id,
  code: id.toUpperCase(),
  name: name ?? id,
  colorValue: 0xFF2255AA,
  category: ShiftCategory.work,
  startMinute: 360,
  endMinute: 840,
);

/// Rotation morning, afternoon, day off, from [_today].
Schedule _schedule({Map<CivilDate, DayEntry> entries = const {}}) => Schedule(
  shiftTypes: [_type('m'), _type('t'), _type('vac')],
  patterns: const [
    Pattern(
      id: 'p',
      name: 'p',
      steps: [
        ['m'],
        ['t'],
        [],
      ],
    ),
  ],
  runs: const [PatternRun(id: 'r', patternId: 'p', startDate: _today, seq: 1)],
  entries: entries,
);

String _ids(AgendaItem item) => item.shifts.map((s) => s.id).join('+');

void main() {
  group('upcomingShiftDays', () {
    test('follows the rotation, day by day, from today', () {
      final items = upcomingShiftDays(_schedule(), const [], _today);
      expect(
        [for (final i in items.take(7)) _ids(i)],
        ['m', 't', '', 'm', 't', '', 'm'],
      );
      expect(items.first.date, _today);
      expect(items[1].date, _today.addDays(1));
    });

    test('a day changed by hand shows the override, not the rotation', () {
      final schedule = _schedule(
        entries: {
          _today.addDays(3): DayEntry(
            date: _today.addDays(3),
            shiftTypeIds: const ['vac'],
          ),
          // An empty override beats the rotation too: a day off.
          _today.addDays(4): DayEntry(
            date: _today.addDays(4),
            shiftTypeIds: const [],
          ),
        },
      );
      final items = upcomingShiftDays(schedule, const [], _today);
      expect(_ids(items[3]), 'vac'); // the rotation says «m»
      expect(items[4].shifts, isEmpty); // the rotation says «t»
    });

    test('a day off is in the list, with an empty list of shifts', () {
      final items = upcomingShiftDays(_schedule(), const [], _today);
      final off = items[2];
      expect(off.date, _today.addDays(2));
      expect(off.shifts, isEmpty);
      expect(off.note, isNull);
      expect(off.ownHoliday, isNull);
    });

    test('a day with a second shift lists both, in order', () {
      final schedule = _schedule(
        entries: {
          _today.addDays(1): DayEntry(
            date: _today.addDays(1),
            shiftTypeIds: const ['t', 'm'],
          ),
        },
      );
      final items = upcomingShiftDays(schedule, const [], _today);
      expect(_ids(items[1]), 't+m');
      expect(items[1].shifts, hasLength(2));
    });

    test('a split shift (two time ranges) is one shift of the day', () {
      final split = ShiftType(
        id: 'p',
        code: 'P',
        name: 'Partido',
        colorValue: 0xFFAA5522,
        category: ShiftCategory.work,
        startMinute: 540,
        endMinute: 780,
        segment2StartMinute: 1020,
        segment2DurationMinutes: 240,
      );
      final schedule = Schedule(
        shiftTypes: [split],
        patterns: const [
          Pattern(
            id: 'p',
            name: 'p',
            steps: [
              ['p'],
            ],
          ),
        ],
        runs: const [
          PatternRun(id: 'r', patternId: 'p', startDate: _today, seq: 1),
        ],
      );
      final first = upcomingShiftDays(schedule, const [], _today).first;
      expect(first.shifts, hasLength(1));
      expect(first.shifts.single.hasSegment2, isTrue);
    });

    test('the note and the own holiday of the day come with it; official '
        'holidays do not', () {
      final schedule = _schedule(
        entries: {
          _today.addDays(4): DayEntry(
            date: _today.addDays(4),
            note: 'Revisión coche',
            noteReminderMinute: 480,
          ),
        },
      );
      final items = upcomingShiftDays(schedule, [
        Holiday(
          date: _today.addDays(4),
          name: 'Patrón',
          scope: HolidayScope.local,
          source: HolidaySource.user,
        ),
        Holiday(
          date: _today.addDays(5),
          name: 'Inmaculada',
          scope: HolidayScope.national,
        ),
      ], _today);
      expect(items[4].note, 'Revisión coche');
      expect(items[4].reminderMinute, 480);
      expect(items[4].ownHoliday?.name, 'Patrón');
      // The rotation still gives the shifts of that day (the note does not
      // replace them).
      expect(_ids(items[4]), 't');
      expect(items[5].ownHoliday, isNull);
    });

    test('the window: 60 days with today in, the 61st out', () {
      final items = upcomingShiftDays(_schedule(), const [], _today);
      expect(items, hasLength(agendaShiftDays));
      expect(agendaShiftDays, 60);
      expect(items.first.date, _today);
      expect(items.last.date, _today.addDays(59));
      expect(items.any((i) => i.date == _today.addDays(60)), isFalse);
      expect(items.any((i) => i.date == _today.addDays(-1)), isFalse);
      // Every day once, in order.
      for (var i = 0; i < items.length; i++) {
        expect(items[i].date, _today.addDays(i));
      }
    });

    test('a note on day 59 is in, one on day 60 is out', () {
      final schedule = _schedule(
        entries: {
          _today.addDays(59): DayEntry(
            date: _today.addDays(59),
            note: 'Dentro',
          ),
          _today.addDays(60): DayEntry(date: _today.addDays(60), note: 'Fuera'),
        },
      );
      final items = upcomingShiftDays(schedule, const [], _today);
      expect(items.last.note, 'Dentro');
      expect(items.where((i) => i.note == 'Fuera'), isEmpty);
    });

    test('days is configurable and crosses the end of the year', () {
      expect(
        upcomingShiftDays(_schedule(), const [], _today, days: 1).single.date,
        _today,
      );
      expect(
        upcomingShiftDays(_schedule(), const [], _today, days: 0),
        isEmpty,
      );
      final late = upcomingShiftDays(
        _schedule(),
        const [],
        const CivilDate(2026, 12, 30),
        days: 4,
      );
      expect(
        [for (final i in late) i.date],
        [
          const CivilDate(2026, 12, 30),
          const CivilDate(2026, 12, 31),
          const CivilDate(2027, 1, 1),
          const CivilDate(2027, 1, 2),
        ],
      );
      // Before the rotation starts, days are empty, but they are listed.
      expect(
        upcomingShiftDays(
          _schedule(),
          const [],
          _today.addDays(-3),
          days: 2,
        ).map((i) => i.shifts),
        [isEmpty, isEmpty],
      );
    });

    test('a schedule with no shift types gives 60 empty days', () {
      final items = upcomingShiftDays(Schedule(), const [], _today);
      expect(items, hasLength(60));
      expect(items.every((i) => i.shifts.isEmpty), isTrue);
    });
  });
}
