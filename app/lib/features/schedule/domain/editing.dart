import 'package:collection/collection.dart';

import 'civil_date.dart';
import 'pattern.dart';
import 'schedule.dart';

const _idsEq = ListEquality<String>();

enum PaintMode { replace, add, erase }

/// Brush of paint mode.
class PaintTool {
  /// The day becomes `[id]`.
  const PaintTool.replace(String id)
    : mode = PaintMode.replace,
      shiftTypeId = id;

  /// "Double up": adds [id] after the day's effective shifts if not present.
  const PaintTool.add(String id) : mode = PaintMode.add, shiftTypeId = id;

  /// The day becomes empty.
  const PaintTool.erase() : mode = PaintMode.erase, shiftTypeId = null;

  final PaintMode mode;
  final String? shiftTypeId;

  /// Resulting shift ids given the day's current effective ids.
  List<String> apply(List<String> current) => switch (mode) {
    PaintMode.replace => [shiftTypeId!],
    PaintMode.add =>
      current.contains(shiftTypeId) ? current : [...current, shiftTypeId!],
    PaintMode.erase => const [],
  };

  @override
  bool operator ==(Object other) =>
      other is PaintTool &&
      other.mode == mode &&
      other.shiftTypeId == shiftTypeId;

  @override
  int get hashCode => Object.hash(mode, shiftTypeId);
}

/// Before/after of one day's entry; `null` = no entry stored.
class EntryChange {
  const EntryChange(this.before, this.after);

  final DayEntry? before;
  final DayEntry? after;

  EntryChange get inverse => EntryChange(after, before);

  @override
  bool operator ==(Object other) =>
      other is EntryChange && other.before == before && other.after == after;

  @override
  int get hashCode => Object.hash(before, after);
}

/// Exact, invertible change to the `entries` map.
class EntriesPatch {
  const EntriesPatch(this.changes);

  static const empty = EntriesPatch({});

  final Map<CivilDate, EntryChange> changes;

  bool get isEmpty => changes.isEmpty;

  /// Returns a new map; [entries] is not modified.
  Map<CivilDate, DayEntry> applyTo(Map<CivilDate, DayEntry> entries) {
    final result = {...entries};
    for (final MapEntry(:key, :value) in changes.entries) {
      final after = value.after;
      if (after == null) {
        result.remove(key);
      } else {
        result[key] = after;
      }
    }
    return result;
  }

  EntriesPatch inverse() => EntriesPatch({
    for (final MapEntry(:key, :value) in changes.entries) key: value.inverse,
  });

  @override
  bool operator ==(Object other) =>
      other is EntriesPatch &&
      const MapEquality<CivilDate, EntryChange>().equals(
        other.changes,
        changes,
      );

  @override
  int get hashCode => const MapEquality<CivilDate, EntryChange>().hash(changes);
}

/// One undoable step: a patch of the entries and, optionally, a new list of
/// runs (`null` = runs untouched).
class ScheduleChange {
  const ScheduleChange({
    this.patch = EntriesPatch.empty,
    this.runsBefore,
    this.runsAfter,
  });

  final EntriesPatch patch;
  final List<PatternRun>? runsBefore;
  final List<PatternRun>? runsAfter;

  bool get isEmpty => patch.isEmpty && runsAfter == null;

  ScheduleChange inverse() => ScheduleChange(
    patch: patch.inverse(),
    runsBefore: runsAfter,
    runsAfter: runsBefore,
  );
}

/// Undo/redo history. A whole drag is a single [push]. Mutable; keep it
/// outside the immutable [Schedule].
class UndoStack {
  UndoStack({this.limit = 100});

  final int limit;
  final _undo = <ScheduleChange>[];
  final _redo = <ScheduleChange>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// The step [undo] would take back, without taking it (`null` = none).
  ScheduleChange? get last => _undo.isEmpty ? null : _undo.last;

  /// Records an applied change and drops the redo history. Empty changes are
  /// ignored; the oldest step is discarded beyond [limit].
  void push(ScheduleChange change) {
    if (change.isEmpty) return;
    _undo.add(change);
    _redo.clear();
    if (_undo.length > limit) _undo.removeAt(0);
  }

  /// Replaces the latest step by [change] (`null` removes it): a step that
  /// keeps growing, like a note being typed. The redo history is untouched
  /// (it is empty while the step being replaced is the latest one).
  void replaceLast(ScheduleChange? change) {
    if (_undo.isEmpty) return;
    if (change == null || change.isEmpty) {
      _undo.removeLast();
    } else {
      _undo[_undo.length - 1] = change;
    }
  }

  /// The change to apply to go back one step (the inverse), or `null`.
  ScheduleChange? undo() {
    if (_undo.isEmpty) return null;
    final change = _undo.removeLast();
    _redo.add(change);
    return change.inverse();
  }

  /// The change to re-apply, or `null`.
  ScheduleChange? redo() {
    if (_redo.isEmpty) return null;
    final change = _redo.removeLast();
    _undo.add(change);
    return change;
  }

  /// Forgets only [step] in the redo history, preserving every other step.
  /// Used when an import's deleted types can no longer be restored by redo.
  void discardRedo(ScheduleChange step) {
    _redo.removeWhere((change) => identical(change, step));
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}

extension ScheduleEditing on Schedule {
  /// Patch that paints [days] with [tool]. Normalized: an override equal to
  /// what the pattern gives is dropped (keeping the note, its reminder and
  /// the overtime and early-leave minutes), an entry left with nothing of
  /// that is not stored, and unchanged days are omitted.
  EntriesPatch paint(PaintTool tool, Iterable<CivilDate> days) {
    final changes = <CivilDate, EntryChange>{};
    for (final d in days.toSet()) {
      final before = entries[d];
      final newIds = tool.apply(resolve(d).shiftIds);
      final override = _idsEq.equals(newIds, resolvePattern(d).shiftIds)
          ? null
          : newIds;
      final after = (before ?? DayEntry(date: d)).withShiftTypeIds(override);
      final normalized = after.isEmpty ? null : after;
      if (normalized != before) changes[d] = EntryChange(before, normalized);
    }
    return EntriesPatch(changes);
  }

  /// Applies pattern [patternId] from [from] (to [until] inclusive, `null` =
  /// open). Open: runs still active on [from] are cut at `from - 1` and runs
  /// starting on or after [from] are deleted. Bounded: earlier runs are kept
  /// and resume after [until]; only runs inside `[from, until]` are deleted.
  /// The new run gets `seq = max + 1` of this schedule's runs, or [seq] when
  /// given. In the database `seq` is unique across **all calendars**, so a
  /// caller that saves the change must pass `ScheduleRepository.nextRunSeq()`
  /// here (and, with it, the default [runId] `run-<seq>` is unique too).
  /// With [clearOverrides] the shift overrides in the range are removed (notes
  /// stay). [runId] defaults to `run-<seq>`.
  ScheduleChange applyPattern(
    String patternId,
    CivilDate from, {
    CivilDate? until,
    int stepOffset = 0,
    bool clearOverrides = false,
    String? runId,
    int? seq,
  }) {
    if (patternById(patternId) == null) {
      throw ArgumentError.value(patternId, 'patternId', 'unknown pattern');
    }
    if (until != null && until.isBefore(from)) {
      throw ArgumentError.value(until, 'until', 'before from');
    }
    final newSeq = seq ?? runs.fold(0, (m, r) => r.seq > m ? r.seq : m) + 1;
    final after = <PatternRun>[
      if (until == null)
        for (final r in runs)
          if (r.startDate.isBefore(from))
            r.endDate == null || !r.endDate!.isBefore(from)
                ? r.copyWith(endDate: from.addDays(-1))
                : r,
      // Bounded: the new run (highest seq) shadows the others inside the
      // range, and they resume after [until]. Only fully covered runs go.
      if (until != null)
        for (final r in runs)
          if (r.startDate.isBefore(from) ||
              r.endDate == null ||
              r.endDate!.isAfter(until))
            r,
      PatternRun(
        id: runId ?? 'run-$newSeq',
        patternId: patternId,
        startDate: from,
        endDate: until,
        stepOffset: stepOffset,
        seq: newSeq,
      ),
    ];

    final changes = <CivilDate, EntryChange>{};
    if (clearOverrides) {
      for (final MapEntry(key: d, value: before) in entries.entries) {
        if (before.shiftTypeIds == null ||
            d.isBefore(from) ||
            (until != null && d.isAfter(until))) {
          continue;
        }
        final cleared = before.copyWith(clearShiftTypeIds: true);
        changes[d] = EntryChange(before, cleared.isEmpty ? null : cleared);
      }
    }
    return ScheduleChange(
      patch: EntriesPatch(changes),
      runsBefore: runs,
      runsAfter: after,
    );
  }

  /// Schedule with [change] applied (pass `change.inverse()` to undo it).
  Schedule apply(ScheduleChange change) => copyWith(
    runs: change.runsAfter ?? runs,
    entries: change.patch.applyTo(entries),
  );
}
