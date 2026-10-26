import 'package:collection/collection.dart';

import '../../schedule/domain/schedule_domain.dart';
import '../../shift_types/domain/shift_type_draft.dart';
import 'event_grouping.dart';
import 'import_models.dart';

/// What to do with one group of events.
sealed class GroupMapping {
  const GroupMapping();
}

/// The events of the group are not imported.
class IgnoreGroup extends GroupMapping {
  const IgnoreGroup();

  @override
  bool operator ==(Object other) => other is IgnoreGroup;

  @override
  int get hashCode => 0;
}

/// The events become the existing shift type [typeId].
class MapToType extends GroupMapping {
  const MapToType(this.typeId);

  final String typeId;

  @override
  bool operator ==(Object other) =>
      other is MapToType && other.typeId == typeId;

  @override
  int get hashCode => typeId.hashCode;
}

/// The events become a shift type that is created with the import. [id] is
/// the id the type will have; [draft] is what the user edited.
class CreateType extends GroupMapping {
  const CreateType(this.id, this.draft);

  final String id;
  final ShiftTypeDraft draft;

  /// Whether the draft can become a shift type (a name and a code of 1 to 3
  /// characters). An uncreatable mapping imports nothing.
  bool get isCreatable {
    final code = draft.code.trim();
    return draft.name.trim().isNotEmpty &&
        code.isNotEmpty &&
        code.length <= maxShiftCodeLength;
  }

  @override
  bool operator ==(Object other) =>
      other is CreateType && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(id, draft);
}

/// What happens on a day that already has shifts (from the rotation or from
/// a day painted by hand) and the import brings others.
enum ConflictPolicy {
  /// The imported shifts take the day.
  replace,

  /// The day stays as it is («Mantener lo mío»).
  keep,
}

/// The result of an import before it is applied.
class ImportPlan {
  const ImportPlan({
    required this.change,
    required this.newTypes,
    required this.result,
    required this.written,
    required this.conflicts,
    required this.kept,
    required this.unchanged,
    required this.ignoredEvents,
    required this.conflictDates,
    required this.changedDates,
    this.notesWritten = 0,
  });

  /// The single undoable step (no runs; the days only).
  final ScheduleChange change;

  /// Shift types the import creates (only those a written day uses).
  final List<ShiftType> newTypes;

  /// The schedule after the import: what the preview draws.
  final Schedule result;

  /// Days the import writes.
  final int written;

  /// Days that already had other shifts, whatever the policy says.
  final int conflicts;

  /// Of those, days left as they were ([ConflictPolicy.keep]).
  final int kept;

  /// Days where the source and the calendar already agree.
  final int unchanged;

  /// Events (one per day) not imported because their group is ignored.
  final int ignoredEvents;

  /// The conflicting days, in order.
  final List<CivilDate> conflictDates;

  /// The days written, in order.
  final List<CivilDate> changedDates;

  /// Of the days written, those that got a note from the source.
  final int notesWritten;

  bool get isEmpty => change.isEmpty;
}

/// The note of a day after importing [imported] over [existing].
///
/// Notes are the user's own text, so nothing is lost: an empty day takes the
/// imported note; a day that already has it (an earlier import of the same
/// file) is left alone, which is what keeps a second import from duplicating
/// notes; a different note is kept and the imported one goes under it on a
/// new line, unless the user asked to keep what they have
/// ([ConflictPolicy.keep]).
String mergeImportedNote(
  String? existing,
  String imported,
  ConflictPolicy policy,
) {
  final mine = existing?.trim() ?? '';
  if (mine.isEmpty) return imported;
  if (imported.isEmpty) return existing!;
  // A previous import appends a whole block after a newline. Padding both
  // notes also covers the first and last blocks, including multiline notes,
  // without treating part of a line as an already imported note.
  if ('\n$mine\n'.contains('\n$imported\n')) return existing!;
  if (policy == ConflictPolicy.keep) return existing!;
  return '$mine\n$imported';
}

/// Turns the grouped [occurrences] and the user's [mappings] (by
/// [EventGroup.key]) into ONE [ScheduleChange] on [schedule].
///
/// A day gets the shifts of its events in time order (all-day first), without
/// repeats. Like painting, an override equal to what the rotation gives is not
/// stored and a note is kept. Days whose effective shifts already match are
/// left alone; days that have other shifts are conflicts, decided by
/// [policy]. [notes] are day notes of the source (see [mergeImportedNote]);
/// they are written whatever happens to the shifts of the day. Pure: the
/// preview and the application both use this function.
ImportPlan buildImportPlan({
  required Schedule schedule,
  required Iterable<EventOccurrence> occurrences,
  required Map<String, GroupMapping> mappings,
  required ConflictPolicy policy,
  Map<CivilDate, String> notes = const {},
}) {
  // The types the mappings would create, usable from now on.
  final created = <String, ShiftType>{};
  for (final mapping in mappings.values) {
    if (mapping is CreateType && mapping.isCreatable) {
      created[mapping.id] = mapping.draft.toShiftType(mapping.id);
    }
  }
  final base = schedule.copyWith(
    shiftTypes: [
      ...schedule.shiftTypes,
      for (final t in created.values)
        if (schedule.shiftTypeById(t.id) == null) t,
    ],
  );

  final sorted = occurrences.toList()
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return (a.startMinute ?? -1).compareTo(b.startMinute ?? -1);
    });

  final wanted = <CivilDate, List<String>>{};
  var ignored = 0;
  for (final o in sorted) {
    final mapping = mappings[normalizeTitle(o.title)];
    final id = switch (mapping) {
      MapToType(:final typeId) => typeId,
      CreateType(:final id) => id,
      _ => null,
    };
    if (id == null || base.shiftTypeById(id) == null) {
      ignored++;
      continue;
    }
    final ids = wanted.putIfAbsent(o.date, () => []);
    if (!ids.contains(id)) ids.add(id);
  }

  const equal = ListEquality<String>();
  final changes = <CivilDate, EntryChange>{};
  final conflictDates = <CivilDate>[];
  var kept = 0;
  var unchanged = 0;
  var notesWritten = 0;
  final dates = {...wanted.keys, ...notes.keys}.toList()..sort();
  for (final date in dates) {
    final ids = wanted[date];
    final before = base.entries[date];
    var after = before ?? DayEntry(date: date);
    var sameShifts = false;
    if (ids != null) {
      final current = base.resolve(date).shiftIds;
      if (equal.equals(current, ids)) {
        sameShifts = true;
      } else {
        final isConflict = current.isNotEmpty;
        if (isConflict) conflictDates.add(date);
        if (isConflict && policy == ConflictPolicy.keep) {
          kept++;
        } else {
          final sameAsPattern = equal.equals(
            ids,
            base.resolvePattern(date).shiftIds,
          );
          after = after.withShiftTypeIds(sameAsPattern ? null : ids);
        }
      }
    }
    var noteChanged = false;
    final note = notes[date];
    if (note != null && note.isNotEmpty) {
      final merged = mergeImportedNote(after.note, note, policy);
      if (merged != after.note) {
        after = after.copyWith(note: merged);
        noteChanged = true;
      }
    }
    final normalized = after.isEmpty ? null : after;
    if (normalized != before) {
      changes[date] = EntryChange(before, normalized);
      if (noteChanged) notesWritten++;
    } else if (sameShifts) {
      unchanged++;
    }
  }

  final change = ScheduleChange(patch: EntriesPatch(changes));
  final usedIds = <String>{
    for (final c in changes.values) ...?c.after?.shiftTypeIds,
  };
  final newTypes = [
    for (final t in created.values)
      if (schedule.shiftTypeById(t.id) == null && usedIds.contains(t.id)) t,
  ];
  final result = schedule
      .copyWith(shiftTypes: [...schedule.shiftTypes, ...newTypes])
      .apply(change);
  return ImportPlan(
    change: change,
    newTypes: newTypes,
    result: result,
    written: changes.length,
    conflicts: conflictDates.length,
    kept: kept,
    unchanged: unchanged,
    ignoredEvents: ignored,
    conflictDates: conflictDates,
    changedDates: (changes.keys.toList()..sort()),
    notesWritten: notesWritten,
  );
}
