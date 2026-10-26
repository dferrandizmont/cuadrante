import '../../schedule/domain/schedule_domain.dart';
import 'calendar.dart';

/// Comparing two calendars (`docs/paridad.md` A4): the shifts of each one on
/// the same days and the days on which both are free. Pure Dart on top of two
/// [Schedule]s, read-only.
///
/// **A free day** is a day without any shift of the `work` category: an empty
/// day (no shift at all, or a rotation that has not started or has ended), a
/// day with only rest shifts (Libre, Saliente) and a day with only absences
/// (Vacaciones, Baja, Libre disposición...) are all free. A day with at least
/// one work shift is busy, however short, and so is a day that mixes an
/// absence and a work shift.
///
/// As everywhere in the engine, a shift belongs to the day it STARTS: the day
/// after a night shift is free by this definition even if the night ends in
/// its morning (the Saliente automático marks it as rest anyway).
bool isFreeDay(ResolvedDay day) =>
    !day.shifts.any((shift) => shift.category == ShiftCategory.work);

/// The two calendars to compare among [calendars] (non-archived, in order):
/// [firstId] and [secondId] when they exist and differ; otherwise the first
/// is the calendar on screen ([activeId]) and the second the next one in the
/// list (the first one again after the last). `null` with fewer than two
/// calendars: there is nothing to compare.
({Calendar first, Calendar second})? resolveComparePair(
  List<Calendar> calendars, {
  required String activeId,
  String? firstId,
  String? secondId,
}) {
  if (calendars.length < 2) return null;
  Calendar? byId(String? id) {
    for (final calendar in calendars) {
      if (calendar.id == id) return calendar;
    }
    return null;
  }

  final first = byId(firstId) ?? byId(activeId) ?? calendars.first;
  var second = byId(secondId);
  if (second == null || second.id == first.id) {
    final index = calendars.indexOf(first);
    second = calendars[(index + 1) % calendars.length];
  }
  return (first: first, second: second);
}

/// One day seen in both calendars.
class ComparedDay {
  const ComparedDay({required this.date, required this.a, required this.b});

  final CivilDate date;

  /// The day in the first and in the second calendar.
  final ResolvedDay a;
  final ResolvedDay b;

  bool get freeA => isFreeDay(a);
  bool get freeB => isFreeDay(b);

  /// Both calendars are free: the days to meet.
  bool get bothFree => freeA && freeB;
}

/// The days `[from, to]` (both included) in both schedules.
List<ComparedDay> compareDays(
  Schedule a,
  Schedule b,
  CivilDate from,
  CivilDate to,
) {
  final daysA = a.resolveRange(from, to);
  final daysB = b.resolveRange(from, to);
  return [
    for (var i = 0; i < daysA.length; i++)
      ComparedDay(date: daysA[i].date, a: daysA[i], b: daysB[i]),
  ];
}

/// The comparison of one calendar month.
class MonthComparison {
  const MonthComparison({required this.month, required this.days});

  /// First day of the month.
  final CivilDate month;

  /// Every day of the month, in order.
  final List<ComparedDay> days;

  /// The days of the month on which both calendars are free, in order.
  List<CivilDate> get commonFreeDays => [
    for (final day in days)
      if (day.bothFree) day.date,
  ];

  /// How many: «X días libres en común este mes».
  int get commonFreeCount => days.where((d) => d.bothFree).length;
}

/// Compares the month that contains [anyDay].
MonthComparison compareMonth(Schedule a, Schedule b, CivilDate anyDay) {
  final first = anyDay.firstDayOfMonth;
  return MonthComparison(
    month: first,
    days: compareDays(a, b, first, first.lastDayOfMonth),
  );
}
