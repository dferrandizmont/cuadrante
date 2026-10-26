import '../../calendars/domain/calendar.dart';
import '../domain/schedule_domain.dart';
import 'demo_schedule.dart';
import 'schedule_repository.dart';

/// Fills an **empty** database (no shift types) in one transaction:
/// - the shift types of [shiftTemplates] (id = template key, `sort_order` in
///   the order of the table) and the patterns of [patternPresets];
/// - with [demo], also the demo rotation and days of [buildDemoSchedule]
///   for [today], in the `main` calendar (which the database creates with
///   the file).
///
/// A database with any shift type is left untouched, so this never overwrites
/// data. Returns whether it seeded.
Future<bool> seedIfEmpty(
  ScheduleRepository repository, {
  required bool demo,
  required CivilDate today,
}) => repository.transaction(() async {
  if (!await repository.isEmpty()) return false;

  final ids = {for (final t in shiftTemplates) t.key: t.key};
  for (final (index, template) in shiftTemplates.indexed) {
    await repository.saveShiftType(
      template.toShiftType(template.key),
      sortOrder: index,
    );
  }
  for (final preset in patternPresets) {
    await repository.savePattern(preset.materialize(ids));
  }

  if (demo) {
    final sample = buildDemoSchedule(today);
    await repository.apply(
      mainCalendarId,
      ScheduleChange(
        patch: EntriesPatch({
          for (final entry in sample.entries.values)
            entry.date: EntryChange(null, entry),
        }),
        runsAfter: sample.runs,
      ),
    );
  }
  return true;
});
