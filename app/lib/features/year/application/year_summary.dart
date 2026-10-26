import '../../schedule/domain/schedule_domain.dart';

/// How many days of a year each shift type appears on ("turnos por tipo").
class YearSummary {
  const YearSummary(this.counts);

  /// Days per shift type id, in the order of the schedule's shift types;
  /// only types that appear.
  final Map<String, int> counts;

  int countOf(String shiftTypeId) => counts[shiftTypeId] ?? 0;

  bool get isEmpty => counts.isEmpty;
}

/// Counts, over every day of [year], the shifts [schedule] gives (an
/// override, the pattern...). A day with two shifts counts once for each.
YearSummary summarizeYear(Schedule schedule, int year) {
  final raw = <String, int>{};
  final days = schedule.resolveRange(
    CivilDate(year, 1, 1),
    CivilDate(year, 12, 31),
  );
  for (final day in days) {
    for (final shift in day.shifts) {
      raw[shift.id] = (raw[shift.id] ?? 0) + 1;
    }
  }
  return YearSummary({
    for (final type in schedule.shiftTypes)
      if (raw.containsKey(type.id)) type.id: raw[type.id]!,
  });
}
