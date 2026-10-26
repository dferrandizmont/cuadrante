import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/domain/schedule_domain.dart';
import '../domain/range_editing.dart';
import 'paint_controller.dart';
import 'schedule_controller.dart';

/// State of selection mode (range editing): the days chosen, in any month.
class SelectionState {
  const SelectionState({
    this.active = false,
    this.days = const {},
    this.dragging = false,
  });

  /// Selection mode on: taps toggle days instead of opening them.
  final bool active;
  final Set<CivilDate> days;

  /// The long press that started the mode still has the finger down. The
  /// screen waits for it to end before it changes its layout (bar, header),
  /// so the cells do not move under the finger while it drags.
  final bool dragging;

  /// The mode is on and its screen layout (action bar, no today card) is in
  /// place.
  bool get settled => active && !dragging;

  int get count => days.length;
  bool get isEmpty => days.isEmpty;

  /// The chosen days in date order.
  List<CivilDate> get sorted => days.toList()..sort();

  /// First (earliest) chosen day, or `null`.
  CivilDate? get first => days.isEmpty ? null : sorted.first;

  bool contains(CivilDate day) => days.contains(day);
}

/// Selection mode, outside paint mode. The two never run together: entering
/// one leaves the other. Each calendar retains its own selection for this session.
///
/// Gestures: a long press on a day starts the mode with that day chosen and,
/// while the finger stays down, dragging extends a linear range (every day
/// from the one pressed to the one under the finger, in date order; the
/// days chosen before stay). A tap toggles a day. The state lives here, not in
/// the grid, so it survives changing month.
class SelectionController extends Notifier<SelectionState> {
  // Days chosen before the drag in progress, and where it started.
  Set<CivilDate> _base = const {};
  CivilDate? _anchor;
  final Map<String, SelectionState> _calendarSelections = {};

  @override
  SelectionState build() {
    _base = const {};
    _anchor = null;
    ref.listen(paintControllerProvider.select((p) => p.active), (_, painting) {
      if (painting) exit();
    });
    ref.listen(scheduleControllerProvider.select((s) => s.calendarId), (
      previous,
      next,
    ) {
      if (previous != null) {
        _calendarSelections[previous] = SelectionState(
          active: state.active,
          days: state.days,
        );
      }
      _base = const {};
      _anchor = null;
      final restored = _calendarSelections[next] ?? const SelectionState();
      // Restoring a selection must keep the two editing modes exclusive.
      if (restored.active && ref.read(paintControllerProvider).active) {
        ref.read(paintControllerProvider.notifier).exit();
      }
      state = restored;
    });
    return const SelectionState();
  }

  bool get active => state.active;

  /// Starts the mode with nothing chosen (paint mode is left).
  void enter() {
    if (state.active) return;
    final paint = ref.read(paintControllerProvider.notifier);
    if (ref.read(paintControllerProvider).active) paint.exit();
    state = const SelectionState(active: true);
  }

  /// Long press on [day]: starts the mode if needed, chooses [day] and opens
  /// a drag whose range grows from it ([extendTo]).
  void begin(CivilDate day) {
    // Starting the mode changes the layout of the screen: that waits for the
    // finger to come up ([endDrag]).
    final starting = !state.active;
    enter();
    _base = state.days;
    _anchor = day;
    state = SelectionState(
      active: true,
      days: {..._base, day},
      dragging: starting || state.dragging,
    );
  }

  /// The finger of a drag started with [begin] is now over [day]. Returns
  /// whether the selection changed.
  bool extendTo(CivilDate day) {
    final anchor = _anchor;
    if (anchor == null || !state.active) return false;
    final from = anchor.isBefore(day) ? anchor : day;
    final to = anchor.isBefore(day) ? day : anchor;
    final days = {..._base};
    for (var d = from; !d.isAfter(to); d = d.addDays(1)) {
      days.add(d);
    }
    if (days.length == state.days.length && days.containsAll(state.days)) {
      return false;
    }
    state = SelectionState(active: true, days: days, dragging: state.dragging);
    return true;
  }

  /// The finger came up (or the gesture was cancelled).
  void endDrag() {
    _base = const {};
    _anchor = null;
    if (state.dragging) {
      state = SelectionState(active: true, days: state.days);
    }
  }

  /// Tap on [day]: chosen becomes not chosen and the other way round.
  void toggle(CivilDate day) {
    enter();
    final days = {...state.days};
    if (!days.remove(day)) days.add(day);
    state = SelectionState(active: true, days: days);
  }

  /// Chooses exactly [days] (mode on).
  void select(Iterable<CivilDate> days) {
    enter();
    state = SelectionState(active: true, days: days.toSet());
  }

  /// «Cortar»: copies the chosen days to the clipboard and moves them out of
  /// the calendar: their shifts are cleared ("Borrar") and, with [withNotes]
  /// (the default), so are the note, its reminder and the overtime and
  /// early-leave minutes the copy carries, because they travel with the days
  /// when pasted (cut + paste with notes is a move, never a duplicate). With
  /// `withNotes: false` they stay on the source. ONE undo step of the
  /// schedule. The clipboard is outside the undo history, so undoing brings
  /// the days back and the pasteable copy stays. The choice is cleared (the
  /// mode stays) so the next tap picks where to paste. `null` when nothing
  /// was chosen; `step` is `null` when there was nothing to clear (the copy
  /// is made anyway).
  ({DayClipboard clip, ScheduleChange? step})? cut({bool withNotes = true}) {
    if (!state.active || state.isEmpty) return null;
    final days = state.sorted;
    final schedule = ref.read(scheduleControllerProvider.notifier);
    // With notes the annotations leave the source, so the clipboard is a cut
    // one and its paste always brings them (no way to lose them); without
    // notes they stay on the source and it behaves as a copy.
    final current = ref.read(scheduleControllerProvider);
    final clip = DayClipboard.capture(
      current.schedule,
      days,
      sourceCalendarId: current.calendarId,
      cutOperation: withNotes
          ? ClipboardCut(sourceCalendarId: current.calendarId)
          : null,
    );
    ref.read(dayClipboardProvider.notifier).set(clip);
    final step = schedule.cutDays(clip, withNotes: withNotes);
    clear();
    return (clip: clip, step: step);
  }

  /// Nothing chosen, mode still on.
  void clear() {
    if (!state.active) return;
    state = const SelectionState(active: true);
  }

  /// Leaves the mode.
  void exit() {
    _base = const {};
    _anchor = null;
    if (state.active || state.days.isNotEmpty) state = const SelectionState();
  }
}

final selectionControllerProvider =
    NotifierProvider<SelectionController, SelectionState>(
      SelectionController.new,
    );

/// The days copied with «Copiar» (`null` = nothing copied). It survives
/// leaving selection mode, so a week can be copied, the mode closed and the
/// paste made later.
class DayClipboardController extends Notifier<DayClipboard?> {
  @override
  DayClipboard? build() => null;

  void set(DayClipboard? clip) =>
      state = clip == null || clip.isEmpty ? null : clip;

  /// A paste of [clip] went through. A cut clip has done its move (the
  /// annotations now live on the destination), so the clipboard becomes the
  /// same days as a plain copy: pasting again elsewhere duplicates the shifts
  /// but offers «Incluir notas» instead of dragging the notes along a second
  /// time. Does nothing if the clipboard is no longer [clip].
  void pasted(DayClipboard clip) {
    if (!identical(state, clip) || !clip.isCut) return;
    clip.cutOperation?.setMoved(true);
    state = clip.afterPaste();
  }
}

final dayClipboardProvider =
    NotifierProvider<DayClipboardController, DayClipboard?>(
      DayClipboardController.new,
    );
