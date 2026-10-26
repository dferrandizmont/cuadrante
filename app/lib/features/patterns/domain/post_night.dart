import '../../schedule/domain/schedule_domain.dart';

/// Id of the "Saliente" shift type (the key of its template).
const String postNightTypeId = 'postNight';

/// An open-ended pattern is only checked for post-night days this far ahead
/// of its start (one year): the day after a night becomes an exception, and
/// exceptions are written one by one.
const int postNightHorizonDays = 366;

/// A work shift that crosses midnight and ends in the morning (a night, a
/// 24 h guard): the day after it is the worker's "saliente".
bool endsNextMorning(ShiftType type) =>
    type.category == ShiftCategory.work &&
    type.crossesMidnight &&
    type.lastEndMinute! <= 12 * 60;

/// "Libre": the plain rest day (`rest` template: no hours, rest category).
/// A saliente, a holiday in lieu or any other shift is not.
bool isLibre(ShiftType type) {
  final libre = shiftTemplateByKey('rest');
  return type.category == ShiftCategory.rest &&
      !type.hasTimes &&
      type.id == libre.key;
}

/// Days after a night that [schedule] shows empty or Libre (the only ones
/// the automatic saliente may take), for the nights on [sourceDays].
Set<CivilDate> postNightDays(
  Schedule schedule,
  Iterable<CivilDate> sourceDays,
) {
  final result = <CivilDate>{};
  for (final day in sourceDays) {
    if (!schedule.resolve(day).shifts.any(endsNextMorning)) continue;
    final next = day.addDays(1);
    final shifts = schedule.resolve(next).shifts;
    if (shifts.isEmpty || shifts.every(isLibre)) result.add(next);
  }
  return result;
}

/// Patch that makes Saliente the day after each night of [sourceDays] that
/// would otherwise be empty or Libre. Normalised like any paint stroke (an
/// override equal to what the pattern gives is dropped).
EntriesPatch postNightPatch(
  Schedule schedule,
  Iterable<CivilDate> sourceDays, {
  String postNightId = postNightTypeId,
}) {
  final days = postNightDays(schedule, sourceDays);
  if (days.isEmpty) return EntriesPatch.empty;
  return schedule.paint(PaintTool.replace(postNightId), days);
}

/// [first] followed by [second] as ONE patch: `before` is what [first] saw,
/// `after` what [second] left (days that end up unchanged are dropped), so
/// its inverse restores the original exactly.
EntriesPatch combinePatches(EntriesPatch first, EntriesPatch second) {
  final changes = <CivilDate, EntryChange>{};
  for (final date in {...first.changes.keys, ...second.changes.keys}) {
    final a = first.changes[date];
    final b = second.changes[date];
    final before = a != null ? a.before : b!.before;
    final after = b != null ? b.after : a!.after;
    if (before != after) changes[date] = EntryChange(before, after);
  }
  return EntriesPatch(changes);
}
