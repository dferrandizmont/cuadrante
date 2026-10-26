import 'package:collection/collection.dart';

import '../../schedule/domain/schedule_domain.dart';

/// Biggest number of times «Repetir» offers.
const int maxRepeatTimes = 52;

/// One day of a [DayClipboard]: where it sits relative to the first one, the
/// shifts it had and (if any) its note, the reminder of the note and the
/// overtime and early-leave minutes. Those four travel together: they are
/// copied, pasted and repeated exactly when the notes are.
class ClipDay {
  const ClipDay({
    required this.offset,
    required this.shiftIds,
    this.note,
    this.noteReminderMinute,
    this.overtimeMinutes,
    this.earlyLeaveMinutes,
  });

  /// Days after [DayClipboard.origin].
  final int offset;

  /// The shifts the day *showed* when copied (override or rotation), in order.
  final List<String> shiftIds;
  final String? note;
  final int? noteReminderMinute;
  final int? overtimeMinutes;
  final int? earlyLeaveMinutes;

  /// Whether the day carries anything besides its shifts.
  bool get hasAnnotations =>
      note != null ||
      noteReminderMinute != null ||
      overtimeMinutes != null ||
      earlyLeaveMinutes != null;

  @override
  bool operator ==(Object other) =>
      other is ClipDay &&
      other.offset == offset &&
      other.note == note &&
      other.noteReminderMinute == noteReminderMinute &&
      other.overtimeMinutes == overtimeMinutes &&
      other.earlyLeaveMinutes == earlyLeaveMinutes &&
      const ListEquality<String>().equals(other.shiftIds, shiftIds);

  @override
  int get hashCode => Object.hash(
    offset,
    note,
    noteReminderMinute,
    overtimeMinutes,
    earlyLeaveMinutes,
    const ListEquality<String>().hash(shiftIds),
  );
}

/// Identity and explicit undo state of one cut operation. Shared by clipboard
/// snapshots, independent of the currently visible calendar or its contents.
class ClipboardCut {
  ClipboardCut({required this.sourceCalendarId});

  final String sourceCalendarId;
  bool _applied = false;
  bool get isApplied => _applied;
  bool _moved = false;
  bool get hasMoved => _moved;

  /// Only the controller applying, undoing or redoing this exact cut calls this.
  void setApplied(bool applied) => _applied = applied;
  void setMoved(bool moved) => _moved = moved;
}

/// Days copied from the calendar, with their relative offsets: copy a week and
/// paste it starting on another Monday and every day lands on the same weekday.
///
/// It holds what the days *showed*, so a day that came from the rotation is
/// pasted as its shifts (and stored as an override only where the rotation of
/// the destination gives something else). Holidays are never part of it.
class DayClipboard {
  DayClipboard({
    required this.origin,
    required Iterable<ClipDay> days,
    this.sourceCalendarId,
    this.cutOperation,
  }) : days = List.unmodifiable(days);

  /// Copies [days] (any order, repeats ignored) as seen in [schedule].
  /// [cutOperation] identifies «Cortar» and survives completed moves for undo.
  factory DayClipboard.capture(
    Schedule schedule,
    Iterable<CivilDate> days, {
    String? sourceCalendarId,
    ClipboardCut? cutOperation,
  }) {
    final sorted = days.toSet().toList()..sort();
    if (sorted.isEmpty) {
      return DayClipboard(origin: const CivilDate(2000, 1, 1), days: const []);
    }
    final origin = sorted.first;
    return DayClipboard(
      sourceCalendarId: sourceCalendarId,
      cutOperation: cutOperation,
      origin: origin,
      days: [
        for (final date in sorted)
          _capture(
            schedule.resolve(date),
            schedule.entries[date],
            date.differenceInDays(origin),
          ),
      ],
    );
  }

  static ClipDay _capture(ResolvedDay day, DayEntry? entry, int offset) {
    final note = day.note;
    final overtime = entry?.overtimeMinutes;
    final early = entry?.earlyLeaveMinutes;
    return ClipDay(
      offset: offset,
      shiftIds: day.shiftIds,
      note: note == null || note.trim().isEmpty ? null : note,
      noteReminderMinute: entry?.noteReminderMinute,
      // 0 minutes is the same as nothing.
      overtimeMinutes: overtime == null || overtime == 0 ? null : overtime,
      earlyLeaveMinutes: early == null || early == 0 ? null : early,
    );
  }

  /// Copy behaviour after a move, retaining its identity for undo/redo.
  DayClipboard afterPaste() => DayClipboard(
    origin: origin,
    days: days,
    sourceCalendarId: sourceCalendarId,
    cutOperation: cutOperation,
  );

  /// Calendar the days were captured from; absent for standalone pure planners.
  final String? sourceCalendarId;

  /// Identity of the cut, whose state changes only with its exact undo step.
  final ClipboardCut? cutOperation;

  /// First day copied.
  final CivilDate origin;

  /// Sorted by [ClipDay.offset].
  final List<ClipDay> days;

  /// A cut clip carries annotations while applied and not yet moved.
  /// Undo restores them to the source explicitly; matching unrelated data
  /// (even in the source calendar) never changes this decision.
  bool get isCut => cutOperation != null && !cutOperation!.hasMoved;

  bool get isEmpty => days.isEmpty;
  int get length => days.length;

  /// Whether any copied day had a note, a reminder, overtime or early leave
  /// (the paste offers «Incluir notas», which covers all of them).
  bool get hasNotes => days.any((d) => d.hasAnnotations);

  /// Length of the block in calendar days, gaps included: from the first to
  /// the last day copied. «Repetir» puts each copy this many days after the
  /// previous one.
  int get span => days.isEmpty ? 0 : days.last.offset + 1;

  /// Last day a paste starting on [start] reaches: the block keeps its gaps,
  /// so it can be well past `start + length` (copied 21, 22 and 28 pasted on
  /// the 3rd end on the 10th).
  CivilDate pasteEnd(CivilDate start) => start.addDays(span - 1);

  /// Last day touched by [times] repetitions of the block.
  CivilDate repeatEnd(int times) => origin.addDays(span * (times + 1) - 1);
}

/// A cut must move every annotation until its exact operation is undone.
bool pasteMovesAnnotations(DayClipboard clip) =>
    clip.isCut && (clip.cutOperation?.isApplied ?? false);

/// [date]'s entry with its shifts replaced by [ids] (duplicates and unknown
/// ids dropped). Normalized against the rotation: an override equal to what
/// the rotation gives is not stored. The note stays.
DayEntry entryWithShifts(Schedule schedule, CivilDate date, List<String> ids) {
  final wanted = [
    for (final id in ids.toSet())
      if (schedule.shiftTypeById(id) != null) id,
  ];
  final sameAsPattern = const ListEquality<String>().equals(
    wanted,
    schedule.resolvePattern(date).shiftIds,
  );
  return (schedule.entries[date] ?? DayEntry(date: date)).withShiftTypeIds(
    sameAsPattern ? null : wanted,
  );
}

/// [entry] with what [day] carries on top of it: a copied note, reminder,
/// overtime or early leave replaces the entry's own; one the copied day does
/// not have leaves the entry's alone.
DayEntry withAnnotationsOf(ClipDay day, DayEntry entry) {
  final note = day.note;
  return entry.copyWith(
    note: note?.trim(),
    noteReminderMinute: day.noteReminderMinute,
    overtimeMinutes: day.overtimeMinutes,
    earlyLeaveMinutes: day.earlyLeaveMinutes,
  );
}

/// Where [clip] lands when its first day goes on each of [starts]: the new
/// entries by date (not yet normalized for emptiness; the controller drops
/// those with neither override nor note).
///
/// Shifts always replace the destination's. With [includeNotes] a copied note
/// replaces the destination's; a copied day without a note leaves the
/// destination's note alone (same rule as «Duplicar en otro día»). The
/// reminder, the overtime and the early-leave minutes follow exactly the
/// same rule, each on its own. Without it, none of them is ever touched on
/// the destination.
Map<CivilDate, DayEntry> planPlacements(
  Schedule schedule,
  DayClipboard clip,
  Iterable<CivilDate> starts, {
  bool includeNotes = false,
}) {
  final after = <CivilDate, DayEntry>{};
  for (final start in starts) {
    for (final day in clip.days) {
      final date = start.addDays(day.offset);
      final withShifts = entryWithShifts(schedule, date, day.shiftIds);
      after[date] = includeNotes
          ? withAnnotationsOf(day, withShifts)
          : withShifts;
    }
  }
  return after;
}

/// Ends the rotation [runId] on the day before [firstFreeDay] (that day is
/// the first without it), as ONE undoable step. `null` when there is no such
/// run, when [firstFreeDay] would leave it with no days (use [planDeleteRun])
/// or when it already ends before that day. Days changed by hand stay.
ScheduleChange? planEndRun(
  Schedule schedule,
  String runId,
  CivilDate firstFreeDay,
) {
  final run = schedule.runs.firstWhereOrNull((r) => r.id == runId);
  if (run == null || !firstFreeDay.isAfter(run.startDate)) return null;
  final lastDay = firstFreeDay.addDays(-1);
  final end = run.endDate;
  if (end != null && !end.isAfter(lastDay)) return null;
  return ScheduleChange(
    runsBefore: schedule.runs,
    runsAfter: [
      for (final r in schedule.runs)
        if (r.id == runId) r.copyWith(endDate: lastDay) else r,
    ],
  );
}

/// Removes the rotation [runId] from the calendar, as ONE undoable step. The
/// manual days (overrides and notes) stay as they are. `null` when there is
/// no such run.
ScheduleChange? planDeleteRun(Schedule schedule, String runId) {
  if (!schedule.runs.any((r) => r.id == runId)) return null;
  return ScheduleChange(
    runsBefore: schedule.runs,
    runsAfter: [
      for (final r in schedule.runs)
        if (r.id != runId) r,
    ],
  );
}
