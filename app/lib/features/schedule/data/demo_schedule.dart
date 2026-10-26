import '../domain/schedule_domain.dart';

/// Demo schedule (seeded into an empty database when `USE_DEMO_DATA` is on):
/// every preset shift type and pattern, an open-ended "correturnos" rotation
/// that started on the Monday three months before [today], and a few manual
/// overrides around [today].
///
/// A pure function of [today] so tests can fix the date.
///
/// Shift type ids are the template keys (`morning`, `night`, `rest`...).
Schedule buildDemoSchedule(CivilDate today) {
  final shiftTypes = [for (final t in shiftTemplates) t.toShiftType(t.key)];
  final ids = {for (final t in shiftTemplates) t.key: t.key};
  final patterns = [for (final p in patternPresets) p.materialize(ids)];

  final start = _mondayOnOrBefore(_monthsBefore(today, 3));
  final run = PatternRun(
    id: 'run-1',
    patternId: 'correturnos',
    startDate: start,
    seq: 1,
  );

  CivilDate day(int offset) => today.addDays(offset);
  final entries = <CivilDate, DayEntry>{
    // A note on top of whatever the rotation says.
    day(1): DayEntry(date: day(1), note: 'Cambio con Marta si sale el turno'),
    // Two shifts in one day ("doblar").
    day(2): DayEntry(
      date: day(2),
      shiftTypeIds: const ['morning', 'afternoon'],
    ),
    // A day cleared on purpose, even if the rotation has a shift.
    day(3): DayEntry(date: day(3), shiftTypeIds: const []),
    // Two vacation days.
    day(8): DayEntry(date: day(8), shiftTypeIds: const ['vacation']),
    day(9): DayEntry(date: day(9), shiftTypeIds: const ['vacation']),
  };

  return Schedule(
    shiftTypes: shiftTypes,
    patterns: patterns,
    runs: [run],
    entries: entries,
  );
}

CivilDate _monthsBefore(CivilDate d, int months) {
  final index = d.year * 12 + (d.month - 1) - months;
  final year = index ~/ 12;
  final month = index % 12 + 1;
  final first = CivilDate(year, month, 1);
  return CivilDate(
    year,
    month,
    d.day > first.daysInMonth ? first.daysInMonth : d.day,
  );
}

CivilDate _mondayOnOrBefore(CivilDate d) => d.addDays(-(d.weekday - 1));
