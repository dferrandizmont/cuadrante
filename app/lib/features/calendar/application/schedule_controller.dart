import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/crash_reporting.dart';
import '../../../core/providers.dart';
import '../../calendars/application/calendars_providers.dart';
import '../../calendars/domain/calendar.dart';
import '../../patterns/application/post_night_provider.dart';
import '../../patterns/domain/pattern_application.dart';
import '../../patterns/domain/post_night.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/data/schedule_snapshot.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/range_editing.dart';

/// Current schedule plus what the undo history allows.
class ScheduleState {
  ScheduleState({
    required this.schedule,
    List<ShiftType>? palette,
    this.canUndo = false,
    this.canRedo = false,
    this.saveErrors = 0,
    this.strokeDays = const {},
    this.calendarId = mainCalendarId,
  }) : palette = palette ?? schedule.shiftTypes;

  final Schedule schedule;

  /// The calendar [schedule] belongs to (the active one): every change is
  /// written to it.
  final String calendarId;

  /// Shift types the paint bar offers: the non-archived ones, in order.
  /// [schedule] also holds the archived ones so past days still resolve.
  final List<ShiftType> palette;
  final bool canUndo;
  final bool canRedo;

  /// How many writes failed so far. The UI listens for increments to tell
  /// the user ("No se ha podido guardar el cambio"); the schedule has already
  /// been reloaded from the database by then.
  final int saveErrors;

  /// Days touched by the stroke in progress (empty between strokes): the
  /// grid highlights them while the finger is down.
  final Set<CivilDate> strokeDays;

  ScheduleState copyWith({
    Schedule? schedule,
    List<ShiftType>? palette,
    bool? canUndo,
    bool? canRedo,
    int? saveErrors,
    Set<CivilDate>? strokeDays,
    String? calendarId,
  }) => ScheduleState(
    schedule: schedule ?? this.schedule,
    palette: palette ?? this.palette,
    canUndo: canUndo ?? this.canUndo,
    canRedo: canRedo ?? this.canRedo,
    saveErrors: saveErrors ?? this.saveErrors,
    strokeDays: strokeDays ?? this.strokeDays,
    calendarId: calendarId ?? this.calendarId,
  );
}

/// What the undo of an import did.
class UndoImportResult {
  const UndoImportResult({required this.undone, this.keptTypes = const []});

  /// The import was not undone: it was not the latest thing done.
  const UndoImportResult.notUndone() : this(undone: false);

  /// The import was undone.
  const UndoImportResult.undone() : this(undone: true, keptTypes: const []);

  /// Whether the import was undone.
  final bool undone;

  /// The names of the shift types that stay because something uses them.
  final List<String> keptTypes;
}

/// Holds the schedule being edited and its undo history, and saves every
/// committed change to the database.
///
/// The state changes in memory at once (the UI stays synchronous); each
/// committed change (end of a stroke, undo, redo) is then queued and written
/// **in order** by a single serial queue. Nothing is written during a stroke.
/// If a write fails, the error goes to the [CrashReporter], the schedule is
/// reloaded from the database (what is stored is the truth), the undo history
/// is dropped (it no longer matches) and [ScheduleState.saveErrors] goes up.
///
/// Painting works in strokes: [beginStroke], then [paintDay] for each day
/// the finger touches, then [endStroke]. While the stroke is open the state
/// shows the live result; nothing reaches the undo history until
/// [endStroke], which pushes ONE step for the whole stroke. A single tap is a
/// stroke of one day.
class ScheduleController extends Notifier<ScheduleState> {
  late UndoStack _undo;

  // Associate the exact undo step with its cut; comparing entry values can
  // mistake an unrelated edit or another calendar for an undo.
  final _cutOperations = Expando<ClipboardCut>();
  final _pasteOperations = Expando<ClipboardCut>();

  // Open stroke: schedule before it, the brush and the days touched so far.
  Schedule? _strokeBase;
  PaintTool? _strokeTool;
  final _strokeDays = <CivilDate>{};

  // Serial write queue. A job whose epoch is older than [_epoch] was queued
  // against a state that a failed write has since discarded: it is skipped.
  Future<void> _queue = Future.value();
  int _epoch = 0;

  // Undo step of the latest note save, to join the next one of the same day
  // to it ([setNote] with `continuesTyping`).
  ScheduleChange? _noteStep;
  CivilDate? _noteStepDate;

  // Latest [switchCalendar] call; an older one that finishes later gives up.
  int _switchToken = 0;

  @override
  ScheduleState build() {
    _undo = UndoStack();
    _noteStep = null;
    _noteStepDate = null;
    _strokeBase = null;
    _strokeTool = null;
    _strokeDays.clear();
    _queue = Future.value();
    _epoch = 0;
    _switchToken = 0;
    // Start loading "Saliente automático" now, so the first stroke sees it.
    ref.read(postNightAutoProvider);
    final initial = ref.read(initialScheduleProvider);
    return ScheduleState(
      schedule: initial.schedule,
      palette: initial.palette,
      calendarId: initial.calendarId,
    );
  }

  bool get strokeActive => _strokeBase != null;

  /// Completes when every write queued so far has finished (or failed and
  /// been recovered). For tests and orderly shutdown.
  Future<void> get pendingWrites => _queue;

  /// Starts a stroke with [tool]. An unfinished previous stroke is closed
  /// first, so a lost gesture can never leave state behind.
  void beginStroke(PaintTool tool) {
    if (strokeActive) endStroke();
    _strokeBase = state.schedule;
    _strokeTool = tool;
    _strokeDays.clear();
  }

  /// Adds [day] to the open stroke and shows the result live. Returns false
  /// when there is no open stroke or the day was already part of it.
  bool paintDay(CivilDate day) {
    final base = _strokeBase;
    final tool = _strokeTool;
    if (base == null || tool == null || !_strokeDays.add(day)) return false;
    final patch = base.paint(tool, _strokeDays);
    state = state.copyWith(
      schedule: base.apply(ScheduleChange(patch: patch)),
      strokeDays: Set.of(_strokeDays),
    );
    return true;
  }

  /// Closes the stroke: its whole effect becomes one undo step. A stroke
  /// that changed nothing leaves no step and writes nothing.
  void endStroke() {
    // A grid may finish its drag just after being disposed. The entire
    // provider scope may have gone away with it.
    if (!ref.mounted) return;
    final base = _strokeBase;
    final tool = _strokeTool;
    if (base == null || tool == null) return;
    final plan = _withPostNight(
      base,
      ScheduleChange(patch: base.paint(tool, _strokeDays)),
      Set.of(_strokeDays),
    );
    _strokeBase = null;
    _strokeTool = null;
    _strokeDays.clear();
    _undo.push(plan.change);
    _emit(plan.schedule, newTypes: plan.newTypes);
    _enqueueWrite(plan.change, newTypes: plan.newTypes);
  }

  bool undo() {
    if (strokeActive) return false;
    final cut = _undo.last == null ? null : _cutOperations[_undo.last!];
    final pasted = _undo.last == null ? null : _pasteOperations[_undo.last!];
    final change = _undo.undo();
    if (change == null) return false;
    cut?.setApplied(false);
    pasted?.setMoved(false);
    _emit(state.schedule.apply(change));
    _enqueueWrite(change);
    return true;
  }

  /// Undoes [step] (what [copyDay] or [applyPatternRun] returned) only while
  /// it is still the latest step of the history. For the "Deshacer" of a
  /// snack bar: if the user did something else since, that is left alone.
  /// Returns whether it undid anything.
  bool undoIfLast(ScheduleChange step) {
    if (!ref.mounted || strokeActive) return false;
    if (!identical(_undo.last, step)) return false;
    undo();
    return true;
  }

  /// Undoes an import ([step]) and takes away the shift types it created
  /// ([createdTypeIds]) when nothing uses them any more: no day of any
  /// calendar, no rotation, no other calendar. The ones that are still used
  /// stay, and their names come back, so the UI can say which ones stayed.
  ///
  /// The import is only undone while it is still the latest thing done (as
  /// with [undoIfLast]): what the user did after it is left alone.
  Future<UndoImportResult> undoImport(
    ScheduleChange step,
    List<String> createdTypeIds,
  ) async {
    if (!ref.mounted || strokeActive) return const UndoImportResult.notUndone();
    if (!identical(_undo.last, step)) {
      return const UndoImportResult.notUndone();
    }
    final change = _undo.undo();
    if (change == null) return const UndoImportResult.notUndone();
    _emit(state.schedule.apply(change));
    _enqueueWrite(change);
    if (createdTypeIds.isEmpty) {
      return const UndoImportResult(undone: true);
    }
    final kept = await _removeUnusedTypes(
      createdTypeIds,
      onRemoved: (id) {
        // Do this after each confirmed deletion, even if a later one fails.
        _undo.discardRedo(step);
        if (!ref.mounted) return;
        _dropTypes([id]);
        _emit(state.schedule);
      },
    );
    return UndoImportResult(undone: true, keptTypes: kept);
  }

  /// Takes away the shift types of [ids] that nothing uses any more. The
  /// ones that are used stay, and their names come back.
  Future<List<String>> _removeUnusedTypes(
    List<String> ids, {
    required void Function(String id) onRemoved,
  }) async {
    // The days of the import are gone from the database before the check:
    // a type that only the import used is free to go.
    await pendingWrites;
    if (!ref.mounted) return const [];
    final kept = <String>[];
    for (final id in ids) {
      final type = state.schedule.shiftTypeById(id);
      if (type == null) continue;
      if (_usedInSchedule(id)) {
        kept.add(type.name);
        continue;
      }
      final deleted = await ref
          .read(scheduleRepositoryProvider)
          .deleteShiftTypeIfUnused(id);
      if (deleted) {
        onRemoved(id);
      } else {
        kept.add(type.name);
      }
    }
    return kept;
  }

  /// Whether a day of the calendar being shown or a rotation uses [id].
  bool _usedInSchedule(String id) {
    for (final entry in state.schedule.entries.values) {
      if (entry.shiftTypeIds?.contains(id) ?? false) return true;
    }
    for (final pattern in state.schedule.patterns) {
      if (pattern.steps.any((step) => step.contains(id))) return true;
    }
    return false;
  }

  /// Takes the shift types of [ids] out of the schedule and the palette.
  void _dropTypes(List<String> ids) {
    final gone = ids.toSet();
    state = state.copyWith(
      schedule: state.schedule.copyWith(
        shiftTypes: [
          for (final t in state.schedule.shiftTypes)
            if (!gone.contains(t.id)) t,
        ],
      ),
      palette: [
        for (final t in state.palette)
          if (!gone.contains(t.id)) t,
      ],
    );
  }

  bool redo() {
    if (strokeActive) return false;
    final change = _undo.redo();
    if (change == null) return false;
    _cutOperations[change]?.setApplied(true);
    _pasteOperations[change]?.setMoved(true);
    _emit(state.schedule.apply(change));
    _enqueueWrite(change);
    return true;
  }

  void _emit(Schedule schedule, {List<ShiftType> newTypes = const []}) {
    state = state.copyWith(
      schedule: schedule,
      palette: newTypes.isEmpty ? null : [...state.palette, ...newTypes],
      canUndo: _undo.canUndo,
      canRedo: _undo.canRedo,
      strokeDays: const {},
    );
  }

  void _enqueueWrite(
    ScheduleChange change, {
    List<ShiftType> newTypes = const [],
    Pattern? newPattern,
  }) {
    if (change.isEmpty) return;
    // The calendar the change was made on, even if the user switches before
    // the write runs.
    final calendarId = state.calendarId;
    if (newTypes.isEmpty && newPattern == null) {
      _enqueueTask((repository) => repository.apply(calendarId, change));
      return;
    }
    // What the change refers to goes first (a run needs its pattern, a day
    // its shift type), all in one transaction: nothing half-written.
    _enqueueTask(
      (repository) => repository.transaction(() async {
        for (final type in newTypes) {
          await repository.saveShiftType(type);
        }
        if (newPattern != null) await repository.savePattern(newPattern);
        await repository.apply(calendarId, change);
      }),
    );
  }

  /// Queues [task] behind every write already queued.
  void _enqueueTask(Future<void> Function(ScheduleRepository repository) task) {
    final epoch = _epoch;
    // The tail of the queue must never be a rejected future (that would skip
    // every later write for good), so a job swallows whatever escapes it.
    _queue = _queue
        .then((_) async {
          if (epoch != _epoch || !ref.mounted) return;
          try {
            try {
              await task(ref.read(scheduleRepositoryProvider));
            } catch (error, stack) {
              await _recover(error, stack);
            }
          } catch (_) {
            // Recovery itself failed: nothing left to do, the queue goes on.
          }
        })
        .catchError((Object _) {});
  }

  void _report(Object error, StackTrace stack) {
    try {
      unawaited(
        ref
            .read(crashReporterProvider)
            .record(redactError(error), stack, fatal: false)
            .catchError((Object _) {}),
      );
    } catch (_) {
      // A reporter that throws synchronously must not stop the recovery.
    }
  }

  /// Forgets everything computed against the in-memory state that is being
  /// replaced: queued writes (by bumping the epoch), the undo history and the
  /// open stroke.
  void _dropHistory() {
    _epoch++;
    _undo.clear();
    _strokeBase = null;
    _strokeTool = null;
    _strokeDays.clear();
  }

  /// Replaces the schedule and the palette with what the database holds now.
  /// Call it after something else rewrote the data (a restore). It first lets
  /// the writes already queued finish, then drops the undo history, any open
  /// stroke and every write queued before this point, since none of them
  /// matches the new data. The calendar shown is the stored active one again
  /// (a restore may have replaced the calendars). Throws if the database
  /// cannot be read (the state then stays as it was).
  Future<void> reload() async {
    await pendingWrites;
    if (!ref.mounted) return;
    _dropHistory();
    final calendarId = await ref.read(calendarsRepositoryProvider).activeId();
    final stored = await ref.read(scheduleRepositoryProvider).load(calendarId);
    if (!ref.mounted) return;
    // A stroke may have been committed while the database was read.
    _dropHistory();
    _switchToken++;
    state = state.copyWith(
      schedule: stored.schedule,
      palette: stored.palette,
      calendarId: calendarId,
      canUndo: false,
      canRedo: false,
      strokeDays: const {},
    );
  }

  /// Shows another calendar: [id] becomes the stored active calendar
  /// (`calendars.active`), the schedule and palette are loaded for it, and
  /// the undo history and any open stroke are cleared (they belong to the
  /// calendar being left).
  ///
  /// Changes already made on the calendar being left keep their writes (each
  /// one is tied to the calendar it was made on), so nothing is lost; the
  /// switch waits for them before reading. Switching to the calendar already
  /// shown does nothing. Throws [CalendarNotFound] for an unknown or archived
  /// calendar, or whatever the database throws (the state then stays as it
  /// was). If a newer call starts while this one is loading, this one stops
  /// without changing anything.
  Future<void> switchCalendar(String id) async {
    if (id == state.calendarId) return;
    final token = ++_switchToken;
    final calendars = ref.read(calendarsRepositoryProvider);
    final target = await calendars.get(id);
    if (target == null || target.archived) throw CalendarNotFound(id);
    await pendingWrites;
    if (!ref.mounted || token != _switchToken) return;
    final stored = await ref.read(scheduleRepositoryProvider).load(id);
    if (!ref.mounted || token != _switchToken) return;
    await calendars.setActive(id);
    if (!ref.mounted || token != _switchToken) return;
    _undo.clear();
    _strokeBase = null;
    _strokeTool = null;
    _strokeDays.clear();
    state = state.copyWith(
      schedule: stored.schedule,
      palette: stored.palette,
      calendarId: id,
      canUndo: false,
      canRedo: false,
      strokeDays: const {},
    );
  }

  /// Runs [action] (something that rewrites the stored data, i.e. a restore)
  /// in order with the writes: after every one queued before it, before any
  /// queued later. If it succeeds, the writes queued while it ran are
  /// dropped, as they were computed against the data it replaced; call
  /// [reload] afterwards to adopt the new data. If it fails, nothing is
  /// dropped. The error reaches the caller.
  Future<void> runExclusive(Future<void> Function() action) {
    final done = Completer<void>();
    _queue = _queue
        .then((_) async {
          try {
            await action();
          } catch (error, stack) {
            done.completeError(error, stack);
            return;
          }
          _dropHistory();
          done.complete();
        })
        .catchError((Object _) {});
    return done.future;
  }

  /// A write failed: report it, show what is really stored and tell the UI.
  Future<void> _recover(Object error, StackTrace stack) async {
    _report(error, stack);
    ScheduleSnapshot? stored;
    try {
      stored = await ref
          .read(scheduleRepositoryProvider)
          .load(state.calendarId);
    } catch (reloadError, reloadStack) {
      _report(reloadError, reloadStack);
    }
    if (!ref.mounted) return;
    // Writes queued before this point were computed against the discarded
    // in-memory state: drop them. Later ones start from what we adopt now.
    _dropHistory();
    state = state.copyWith(
      schedule: stored?.schedule,
      palette: stored?.palette,
      canUndo: false,
      canRedo: false,
      saveErrors: state.saveErrors + 1,
      strokeDays: const {},
    );
  }

  // ---- Day detail and shift types ---------------------------------------
  // Every day edit below is ONE undoable step; shift type edits are written
  // through the same queue, so the order of writes is the order of the calls.

  /// Makes the shifts of [date] exactly [shiftTypeIds], in that order
  /// (duplicates and unknown ids are dropped). Normalized like painting: an
  /// override equal to what the rotation gives is not stored (the note stays),
  /// and an entry left with neither override nor note disappears.
  ScheduleChange? setDayShifts(CivilDate date, List<String> shiftTypeIds) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    return _editEntries({
      date: _withShifts(state.schedule, date, shiftTypeIds),
    });
  }

  /// The day keeps no shifts at all, whatever the rotation says ("Borrar
  /// día"): an empty override, or nothing when the rotation is empty too.
  ScheduleChange? clearDay(CivilDate date) => setDayShifts(date, const []);

  /// «Borrar día» of the day detail: the day is left with nothing of its own
  /// (H-T09-2). The shifts are emptied like [clearDay], and the note, its
  /// reminder and the extra and missing minutes go too. ONE undo step brings
  /// all of it back. Returns the step, or `null` when the day already was
  /// like that. (The person's own holiday is not part of the schedule; the
  /// sheet removes it separately.)
  ScheduleChange? clearDayCompletely(CivilDate date) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final rotationIsEmpty = state.schedule.resolvePattern(date).shifts.isEmpty;
    return _editEntries({
      date: DayEntry(
        date: date,
        shiftTypeIds: rotationIsEmpty ? null : const [],
      ),
    });
  }

  /// Sets the note of [date]; blank or `null` removes it. Shifts stay as
  /// they are.
  ///
  /// With [continuesTyping] the save joins the undo step of the previous note
  /// save of the same day as long as nothing else was done since: a note typed
  /// over several autosaves (H-T19-1) is ONE undo step. Every save is still
  /// written to the database as it happens.
  void setNote(CivilDate date, String? note, {bool continuesTyping = false}) {
    if (!ref.mounted) return;
    if (strokeActive) endStroke();
    final before = state.schedule.entries[date];
    final edited = _withNote(before, date, note);
    final after = edited.isEmpty ? null : edited;
    if (after == before) return;
    final change = ScheduleChange(
      patch: EntriesPatch({date: EntryChange(before, after)}),
    );
    final previous = _noteStep;
    if (continuesTyping &&
        previous != null &&
        _noteStepDate == date &&
        identical(_undo.last, previous)) {
      // The step now goes from how the day was before typing to the new text
      // (or disappears when the text is back to what it was).
      final original = previous.patch.changes[date]!.before;
      _noteStep = original == after
          ? null
          : ScheduleChange(
              patch: EntriesPatch({date: EntryChange(original, after)}),
            );
      _undo.replaceLast(_noteStep);
    } else {
      _undo.push(change);
      _noteStep = change;
    }
    _noteStepDate = date;
    _emit(state.schedule.apply(change));
    _enqueueWrite(change);
  }

  /// Sets the time at which the note of [date] rings as a reminder
  /// (`minute`: minutes after 00:00, 0 to 1439), or removes the reminder when
  /// [minute] is `null`. The reminder is independent of the text of the note
  /// (a day can have one without a note) and everything else the day holds
  /// stays. ONE undoable step through the normal write queue. Returns the
  /// step (for [undoIfLast]), or `null` when nothing changed.
  ScheduleChange? setNoteReminder(CivilDate date, int? minute) {
    if (!ref.mounted) return null;
    if (minute != null && !DayEntry.isReminderMinute(minute)) {
      throw ArgumentError.value(minute, 'minute', 'must be 0 to 1439');
    }
    if (strokeActive) endStroke();
    final base = state.schedule.entries[date] ?? DayEntry(date: date);
    return _editEntries({
      date: minute == null
          ? base.copyWith(clearNoteReminder: true)
          : base.copyWith(noteReminderMinute: minute),
    });
  }

  /// Drops the manual override of [date] so the rotation applies again
  /// ("Volver al patrón"). The note stays. Does nothing without an override.
  void resetToPattern(CivilDate date) {
    if (!ref.mounted) return;
    if (strokeActive) endStroke();
    final before = state.schedule.entries[date];
    if (before == null || before.shiftTypeIds == null) return;
    _editEntries({date: before.copyWith(clearShiftTypeIds: true)});
  }

  /// Copies the effective shifts of [from] and its note onto [to]
  /// ("Duplicar en otro día"), with the reminder of the note and the overtime
  /// and early-leave minutes. What [from] does not have, the one [to] already
  /// has stays. Normalized against the rotation of [to]. Returns the undo
  /// step it pushed (for [undoIfLast]), or `null` when nothing changed.
  ScheduleChange? copyDay(CivilDate from, CivilDate to) {
    if (!ref.mounted || from == to) return null;
    if (strokeActive) endStroke();
    final schedule = state.schedule;
    final source = schedule.resolve(from);
    final clip = DayClipboard.capture(schedule, [from]).days.single;
    final withShifts = _withShifts(schedule, to, source.shiftIds);
    return _editEntries({to: withAnnotationsOf(clip, withShifts)});
  }

  /// Creates or updates a shift type. A new one goes last in the palette; an
  /// edited one keeps its place (and stays archived if it was). Days show the
  /// new look at once. The undo history is kept: it only talks about days
  /// and the ids it uses do not change.
  void saveShiftType(ShiftType type) {
    if (!ref.mounted) return;
    if (strokeActive) endStroke();
    final schedule = state.schedule;
    final exists = schedule.shiftTypeById(type.id) != null;
    final inPalette = state.palette.any((t) => t.id == type.id);
    state = state.copyWith(
      schedule: schedule.copyWith(
        shiftTypes: exists
            ? [for (final t in schedule.shiftTypes) t.id == type.id ? type : t]
            : [...schedule.shiftTypes, type],
      ),
      palette: inPalette
          ? [for (final t in state.palette) t.id == type.id ? type : t]
          : exists
          ? state.palette
          : [...state.palette, type],
    );
    _enqueueTask((repository) => repository.saveShiftType(type));
  }

  /// Takes [id] out of the palette. Days that already use it keep showing it.
  void archiveShiftType(String id) {
    if (!ref.mounted || !state.palette.any((t) => t.id == id)) return;
    if (strokeActive) endStroke();
    state = state.copyWith(
      palette: [
        for (final t in state.palette)
          if (t.id != id) t,
      ],
    );
    _enqueueTask((repository) => repository.archiveShiftType(id));
  }

  /// The shift types that were archived: in the schedule (past days still
  /// show them) but out of the palette, in the order they had.
  List<ShiftType> get archivedShiftTypes {
    final inPalette = {for (final t in state.palette) t.id};
    return [
      for (final t in state.schedule.shiftTypes)
        if (!inPalette.contains(t.id)) t,
    ];
  }

  /// Brings the archived shift type [id] back to the palette (H-T05-3), where
  /// it was before (the schedule keeps the order of every type, archived or
  /// not; one that was reordered out goes last). The way back from
  /// [archiveShiftType].
  void restoreShiftType(String id) {
    if (!ref.mounted) return;
    if (!archivedShiftTypes.any((t) => t.id == id)) return;
    if (strokeActive) endStroke();
    final wanted = {for (final t in state.palette) t.id}..add(id);
    state = state.copyWith(
      palette: [
        for (final t in state.schedule.shiftTypes)
          if (wanted.contains(t.id)) t,
      ],
    );
    _enqueueTask((repository) => repository.unarchiveShiftType(id));
  }

  /// Puts the palette in the order of [orderedIds] (every id of the current
  /// palette, once). Anything else is ignored.
  void reorderShiftTypes(List<String> orderedIds) {
    if (!ref.mounted) return;
    final byId = {for (final t in state.palette) t.id: t};
    if (orderedIds.length != byId.length ||
        orderedIds.toSet().length != orderedIds.length ||
        !orderedIds.every(byId.containsKey)) {
      return;
    }
    final ordered = [for (final id in orderedIds) byId[id]!];
    if (ordered.indexed.every((e) => state.palette[e.$1].id == e.$2.id)) return;
    if (strokeActive) endStroke();
    final archived = [
      for (final t in state.schedule.shiftTypes)
        if (!byId.containsKey(t.id)) t,
    ];
    final all = [...ordered, ...archived];
    state = state.copyWith(
      schedule: state.schedule.copyWith(shiftTypes: all),
      palette: ordered,
    );
    _enqueueTask(
      (repository) => repository.transaction(() async {
        for (final (index, type) in all.indexed) {
          await repository.saveShiftType(type, sortOrder: index);
        }
      }),
    );
  }

  /// [date]'s entry with its shifts replaced (normalized against the
  /// rotation).
  DayEntry _withShifts(Schedule schedule, CivilDate date, List<String> ids) {
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

  /// [entry] (or an empty entry for [date]) with the note replaced.
  DayEntry _withNote(DayEntry? entry, CivilDate date, String? note) {
    final text = note?.trim();
    final base = entry ?? DayEntry(date: date);
    return text == null || text.isEmpty
        ? base.copyWith(clearNote: true)
        : base.copyWith(note: text);
  }

  /// Applies the new entries as ONE undo step and queues the write. Entries
  /// with neither override nor note are removed; days that do not change are
  /// left out. Returns the step, or `null` when nothing changed.
  ScheduleChange? _editEntries(Map<CivilDate, DayEntry> after) {
    final schedule = state.schedule;
    final changes = <CivilDate, EntryChange>{};
    for (final MapEntry(key: date, value: entry) in after.entries) {
      final normalized = entry.isEmpty ? null : entry;
      final before = schedule.entries[date];
      if (normalized != before) changes[date] = EntryChange(before, normalized);
    }
    if (changes.isEmpty) return null;
    final change = ScheduleChange(patch: EntriesPatch(changes));
    _undo.push(change);
    _emit(schedule.apply(change));
    _enqueueWrite(change);
    return change;
  }

  /// Sets the overtime and the early leave of [date], in minutes (docs/
  /// paridad.md, A6). `null` leaves that value as it is; 0 (or less) clears
  /// it; more than [maxDayExtraMinutes] is cut to it. One undo step, shifts,
  /// note and reminder stay. Returns the step, or `null` when nothing changed.
  ScheduleChange? setDayExtras(
    CivilDate date, {
    int? overtimeMinutes,
    int? earlyLeaveMinutes,
  }) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final before = state.schedule.entries[date] ?? DayEntry(date: date);
    int? clamp(int minutes) =>
        minutes <= 0 ? null : minutes.clamp(1, maxDayExtraMinutes);
    var entry = before;
    if (overtimeMinutes != null) {
      final minutes = clamp(overtimeMinutes);
      entry = minutes == null
          ? entry.copyWith(clearOvertime: true)
          : entry.copyWith(overtimeMinutes: minutes);
    }
    if (earlyLeaveMinutes != null) {
      final minutes = clamp(earlyLeaveMinutes);
      entry = minutes == null
          ? entry.copyWith(clearEarlyLeave: true)
          : entry.copyWith(earlyLeaveMinutes: minutes);
    }
    return _editEntries({date: entry});
  }

  // ---- Patterns and automatic saliente (docs/motor-de-turnos.md) ----------
  // Everything below belongs to the pattern wizard / "Saliente automático".

  /// Applies a pattern as ONE undoable step (new run, runs cut or deleted,
  /// overrides replaced when asked, automatic saliente when it is on).
  ///
  /// The new run takes `seq` from `ScheduleRepository.nextRunSeq()` (unique
  /// across calendars). Shift types the pattern needs that do not exist (a
  /// template the user deleted) and the pattern itself, when it is new, are
  /// created together with the change. Returns the undo step (for
  /// [undoIfLast]), or `null` when nothing was applied (the calendar was
  /// switched while waiting).
  Future<ScheduleChange?> applyPatternRun(PatternRequest request) async {
    if (strokeActive) endStroke();
    final calendarId = state.calendarId;
    // Runs still queued are not in the database yet: wait for them, so the
    // next seq is really the next one.
    await pendingWrites;
    final seq = await ref.read(scheduleRepositoryProvider).nextRunSeq();
    if (!ref.mounted || state.calendarId != calendarId) return null;
    final plan = planPatternApplication(
      state.schedule,
      request,
      seq: seq,
      postNightAuto: ref.read(postNightAutoProvider),
      palette: state.palette,
    );
    _undo.push(plan.change);
    _emit(plan.schedule, newTypes: plan.newTypes);
    _enqueueWrite(
      plan.change,
      newTypes: plan.newTypes,
      newPattern: plan.newPattern,
    );
    return plan.change.isEmpty ? null : plan.change;
  }

  /// Applies a change computed against the CURRENT schedule by [plan] (the
  /// import of events from a calendar or a file) as ONE undoable step, with
  /// the shift types it creates saved in the same transaction. [plan] gets the
  /// schedule as it is right now, so what it computed is what is applied.
  /// Returns the undo step (for [undoIfLast]), or `null` when it was empty.
  ScheduleChange? applyPlanned(
    ({ScheduleChange change, List<ShiftType> newTypes}) Function(
      Schedule current,
    )
    plan,
  ) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final base = state.schedule;
    final planned = plan(base);
    if (planned.change.isEmpty) return null;
    _undo.push(planned.change);
    _emit(
      base
          .copyWith(shiftTypes: [...base.shiftTypes, ...planned.newTypes])
          .apply(planned.change),
      newTypes: planned.newTypes,
    );
    _enqueueWrite(planned.change, newTypes: planned.newTypes);
    return planned.change;
  }

  /// [change] on top of [base] plus, with "Saliente automático" on, the
  /// Saliente the nights of [days] ask for (same undo step). The Saliente
  /// type is created when it does not exist; one the user archived is
  /// respected (no automatic saliente then).
  ({Schedule schedule, ScheduleChange change, List<ShiftType> newTypes})
  _withPostNight(Schedule base, ScheduleChange change, Set<CivilDate> days) {
    final plain = (
      schedule: base.apply(change),
      change: change,
      newTypes: const <ShiftType>[],
    );
    if (change.isEmpty || !ref.read(postNightAutoProvider)) return plain;
    var schedule = plain.schedule;
    final created = <ShiftType>[];
    if (schedule.shiftTypeById(postNightTypeId) == null) {
      created.add(shiftTemplateByKey('postNight').toShiftType(postNightTypeId));
      schedule = schedule.copyWith(
        shiftTypes: [...schedule.shiftTypes, ...created],
      );
    } else if (!state.palette.any((t) => t.id == postNightTypeId)) {
      return plain;
    }
    final extra = postNightPatch(schedule, days);
    if (extra.isEmpty) return plain;
    return (
      schedule: schedule.apply(ScheduleChange(patch: extra)),
      change: ScheduleChange(patch: combinePatches(change.patch, extra)),
      newTypes: created,
    );
  }

  // ---- Range editing and rotations (selection mode) ------------------------
  // Every method below is ONE undoable step through the same write queue and
  // returns it (for [undoIfLast]), or `null` when nothing changed. Days are
  // normalized against the rotation and notes are kept, as when painting.

  /// Makes the shifts of every day in [days] exactly [shiftTypeId] ("Poner
  /// turno"). With "Saliente automático" on, a night turns the next day into
  /// Saliente like painting does.
  ScheduleChange? setShiftOnDays(
    Iterable<CivilDate> days,
    String shiftTypeId,
  ) => _paintDays(PaintTool.replace(shiftTypeId), days);

  /// Adds [shiftTypeId] after the shifts each day in [days] already has
  /// ("Doblar con"); days that have it are left alone.
  ScheduleChange? doubleShiftOnDays(
    Iterable<CivilDate> days,
    String shiftTypeId,
  ) => _paintDays(PaintTool.add(shiftTypeId), days);

  /// Every day in [days] keeps no shifts at all ("Borrar"): an empty
  /// override, or nothing where the rotation is empty too. Notes stay.
  ScheduleChange? clearDays(Iterable<CivilDate> days) =>
      _paintDays(const PaintTool.erase(), days);

  /// «Cortar»: like [clearDays] and, for the days of [clip] that carried a
  /// note, a reminder, overtime or early leave, those go too, so cut + paste
  /// with notes MOVES them instead of duplicating them. ONE undo step; undoing
  /// brings everything back. What [clip] did not copy stays where it is.
  ScheduleChange? cutDays(DayClipboard clip, {bool withNotes = true}) {
    if (clip.sourceCalendarId != null &&
        clip.sourceCalendarId != state.calendarId) {
      return null;
    }
    final days = [for (final day in clip.days) clip.origin.addDays(day.offset)];
    if (!withNotes) return clearDays(days);
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final set = days.toSet();
    if (set.isEmpty) return null;
    final base = state.schedule;
    final painted = base.paint(const PaintTool.erase(), set);
    final changes = {...painted.changes};
    for (final day in clip.days) {
      if (!day.hasAnnotations) continue;
      final date = clip.origin.addDays(day.offset);
      final before = base.entries[date];
      final current = changes[date]?.after ?? before;
      if (current == null) continue;
      final stripped = current.copyWith(
        clearNote: day.note != null,
        clearNoteReminder: day.noteReminderMinute != null,
        clearOvertime: day.overtimeMinutes != null,
        clearEarlyLeave: day.earlyLeaveMinutes != null,
      );
      final after = stripped.isEmpty ? null : stripped;
      if (after == before) {
        changes.remove(date);
      } else {
        changes[date] = EntryChange(before, after);
      }
    }
    final plan = _withPostNight(
      base,
      ScheduleChange(patch: EntriesPatch(changes)),
      set,
    );
    if (plan.change.isEmpty) return null;
    final operation = clip.cutOperation;
    if (operation != null && operation.sourceCalendarId == state.calendarId) {
      _cutOperations[plan.change] = operation;
      operation.setApplied(true);
    }
    _undo.push(plan.change);
    _emit(plan.schedule, newTypes: plan.newTypes);
    _enqueueWrite(plan.change, newTypes: plan.newTypes);
    return plan.change;
  }

  /// Drops the manual override of every day in [days] so the rotation
  /// applies again ("Volver al patrón"). Notes stay.
  ScheduleChange? resetDaysToPattern(Iterable<CivilDate> days) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final entries = state.schedule.entries;
    return _editEntries({
      for (final date in days.toSet())
        if (entries[date] case final entry? when entry.shiftTypeIds != null)
          date: entry.copyWith(clearShiftTypeIds: true),
    });
  }

  /// The same [note] on every day in [days]; blank or `null` removes the
  /// notes. Shifts stay.
  ScheduleChange? setNoteOnDays(Iterable<CivilDate> days, String? note) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final entries = state.schedule.entries;
    return _editEntries({
      for (final date in days.toSet())
        date: _withNote(entries[date], date, note),
    });
  }

  /// Pastes [clip] so its first day lands on [start] and every other day
  /// keeps its distance from it ("Pegar"). Shifts replace the destination's;
  /// see [planPlacements] for [includeNotes]. A clip that was **cut**
  /// ([DayClipboard.isCut]) brings its notes, reminders and extras whatever
  /// [includeNotes] says, as long as they are really off the source
  /// ([pasteMovesAnnotations]): they left with the cut and would otherwise be
  /// lost. If the cut was undone they are back on the source and bringing them
  /// again would duplicate them, so [includeNotes] decides as for a copy.
  ScheduleChange? pasteDays(
    DayClipboard clip,
    CivilDate start, {
    bool includeNotes = false,
  }) {
    if (!ref.mounted || clip.isEmpty) return null;
    if (strokeActive) endStroke();
    final step = _editEntries(
      planPlacements(state.schedule, clip, [
        start,
      ], includeNotes: includeNotes || pasteMovesAnnotations(clip)),
    );
    if (step != null && clip.isCut) {
      _pasteOperations[step] = clip.cutOperation!;
    }
    return step;
  }

  /// Repeats the block of [days] [times] times forward ("Repetir"): copy `k`
  /// starts `k` blocks after the first day, a block being the span from the
  /// first to the last selected day. [times] goes from 1 to
  /// [maxRepeatTimes] (anything else is ignored).
  ScheduleChange? repeatDays(
    Iterable<CivilDate> days,
    int times, {
    bool includeNotes = false,
  }) {
    if (!ref.mounted || times < 1 || times > maxRepeatTimes) return null;
    if (strokeActive) endStroke();
    final schedule = state.schedule;
    final clip = DayClipboard.capture(schedule, days);
    if (clip.isEmpty) return null;
    return _editEntries(
      planPlacements(schedule, clip, [
        for (var k = 1; k <= times; k++) clip.origin.addDays(k * clip.span),
      ], includeNotes: includeNotes),
    );
  }

  /// Ends the rotation [runId] the day before [firstFreeDay] ("Terminar
  /// aquí"). Manual days stay. See [planEndRun] for when nothing happens.
  ScheduleChange? endRun(String runId, CivilDate firstFreeDay) =>
      _commitRunChange((schedule) => planEndRun(schedule, runId, firstFreeDay));

  /// Removes the rotation [runId] from the calendar ("Eliminar"). Manual days
  /// stay.
  ScheduleChange? deleteRun(String runId) =>
      _commitRunChange((schedule) => planDeleteRun(schedule, runId));

  /// [tool] over [days] as ONE step, with the automatic saliente like a
  /// stroke.
  ScheduleChange? _paintDays(PaintTool tool, Iterable<CivilDate> days) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final set = days.toSet();
    if (set.isEmpty) return null;
    final base = state.schedule;
    final plan = _withPostNight(
      base,
      ScheduleChange(patch: base.paint(tool, set)),
      set,
    );
    if (plan.change.isEmpty) return null;
    _undo.push(plan.change);
    _emit(plan.schedule, newTypes: plan.newTypes);
    _enqueueWrite(plan.change, newTypes: plan.newTypes);
    return plan.change;
  }

  ScheduleChange? _commitRunChange(
    ScheduleChange? Function(Schedule schedule) plan,
  ) {
    if (!ref.mounted) return null;
    if (strokeActive) endStroke();
    final change = plan(state.schedule);
    if (change == null) return null;
    _undo.push(change);
    _emit(state.schedule.apply(change));
    _enqueueWrite(change);
    return change;
  }
}

final scheduleControllerProvider =
    NotifierProvider<ScheduleController, ScheduleState>(ScheduleController.new);
