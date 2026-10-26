import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../application/open_day.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../alarms/presentation/day_alarm_skip_row.dart';
import '../../alarms/presentation/day_reminder_row.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/schedule_controller.dart';
import '../../holidays/presentation/holiday_names.dart';
import 'day_extras_section.dart';
import 'holiday_label.dart';
import 'puck_label.dart';
import 'shift_badge.dart';
import 'shift_format.dart';
import 'shift_icon_glyph.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// The detail of [date] (`turnos-spec.md`, screen 4): its shifts (add, remove,
/// reorder, "volver al patrón"), the note, the user's own holiday and the
/// shortcuts to copy or clear the day. Every edit is ONE undoable step of the
/// schedule, so undo / redo in paint mode reverts it.
///
/// One widget, two places: the bottom sheet of a phone (`DayDetailSheet`) and
/// the right pane of the two-pane month ([inline]). [onClose] closes whichever
/// holds it; «Duplicar en otro día» and «Borrar día» call it.
class DayDetailBody extends ConsumerStatefulWidget {
  const DayDetailBody({
    super.key,
    required this.date,
    required this.onClose,
    this.inline = false,
    this.bottomRoom = 0,
  });

  final CivilDate date;
  final VoidCallback onClose;

  /// In a pane, not a sheet: it fills the room it is given (the sheet takes a
  /// share of the screen), has a close button in its header and leaves
  /// [bottomRoom] free at the end of the scroll (the floating button).
  final bool inline;
  final double bottomRoom;

  @override
  ConsumerState<DayDetailBody> createState() => DayDetailBodyState();
}

class DayDetailBodyState extends ConsumerState<DayDetailBody>
    with WidgetsBindingObserver {
  /// How long after the last keystroke the note is saved on its own.
  static const noteAutosaveDelay = Duration(milliseconds: 800);

  late final ScheduleController _schedule;
  late final NoteDraftController _draft;
  final _note = TextEditingController();
  final _noteFocus = FocusNode();
  final _holidayName = TextEditingController();
  final _holidayFocus = FocusNode();
  final _extras = GlobalKey<DayExtrasSectionState>();

  // The note is saved when the field loses focus, when the sheet closes, a
  // moment after the last keystroke and when the app leaves the foreground
  // (the system may kill it there, H-T19-1); a field the user never typed in
  // writes nothing.
  bool _noteDirty = false;
  Timer? _autosave;

  /// A save of this typing session was already made: the next ones join its
  /// undo step. Ends when the field loses focus.
  bool _noteSaved = false;
  bool _holidayNameShown = false;

  /// The note field has some text (typed or stored): «Borrar día» has
  /// something to clear.
  bool _noteHasText = false;

  CivilDate get _date => widget.date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule = ref.read(scheduleControllerProvider.notifier);
    _draft = ref.read(noteDraftProvider.notifier);
    _note.text =
        ref.read(scheduleControllerProvider).schedule.entries[_date]?.note ??
        '';
    // The same day was being typed in the other face (sheet <-> pane on a
    // rotation): carry on from where it was.
    final draft = ref.read(noteDraftProvider);
    if (draft != null && draft.date == _date) {
      _note.text = draft.text;
      _noteDirty = true;
    }
    _noteHasText = _note.text.trim().isNotEmpty;
    final holiday = ref.read(holidaysProvider)[_date];
    if (holiday != null && holiday.isUserAdded) {
      _holidayName.text = holiday.name;
      _holidayNameShown = true;
    }
    _noteFocus.addListener(() {
      if (!_noteFocus.hasFocus) _commitNote();
    });
    _holidayFocus.addListener(() {
      if (!_holidayFocus.hasFocus) _commitHolidayName();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosave?.cancel();
    // Closing by any route (scrim, drag, back) ends here at the latest. The
    // write waits for the end of the frame: the tree is locked right now.
    if (_noteDirty) {
      final text = _note.text;
      final date = _date;
      final schedule = _schedule;
      final draft = _draft;
      final continues = _noteSaved;
      scheduleMicrotask(() {
        schedule.setNote(date, text, continuesTyping: continues);
        draft.clear(date);
      });
    }
    _note.dispose();
    _noteFocus.dispose();
    _holidayName.dispose();
    _holidayFocus.dispose();
    super.dispose();
  }

  void _commitNote({bool endsTyping = true}) {
    _autosave?.cancel();
    if (!_noteDirty) {
      if (endsTyping) _noteSaved = false;
      return;
    }
    _noteDirty = false;
    _schedule.setNote(_date, _note.text, continuesTyping: _noteSaved);
    _draft.clear(_date);
    _noteSaved = !endsTyping;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Going to the background (a call, the home button): the system may kill
    // the app from here without any further notice.
    if (state != AppLifecycleState.resumed) _commitNote(endsTyping: false);
  }

  /// Saves what is typed now (a sheet that is about to give its day to the
  /// pane, so the old field cannot overwrite what the new one will type).
  void commitPending() {
    _extras.currentState?.commitPending();
    _commitNote();
    _commitHolidayName();
  }

  void _commitHolidayName() {
    final holiday = ref.read(holidaysProvider)[_date];
    if (holiday == null || !holiday.isUserAdded) return;
    final text = _holidayName.text.trim();
    if (text.isEmpty) {
      _holidayName.text = holiday.name;
    } else if (text != holiday.name) {
      unawaited(_guard(() => _addHoliday(text)));
    }
  }

  Future<void> _addHoliday(String name) => ref
      .read(holidayControllerProvider.notifier)
      .addUserHoliday(date: _date, name: name);

  /// Runs a holiday write; a failure is told to the user, never thrown.
  Future<void> _guard(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.saveFailed;
    try {
      await action();
    } catch (_) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(appSnackBar(content: Text(failed)));
    }
  }

  Future<void> _setUserHoliday(bool on) async {
    _commitNote();
    final defaultName = context.l10n.dayDetailUserHolidayDefault;
    await _guard(
      on
          ? () => _addHoliday(defaultName)
          : () => ref
                .read(holidayControllerProvider.notifier)
                .removeUserHoliday(_date),
    );
  }

  void _setShifts(List<String> ids) {
    _commitNote();
    _schedule.setDayShifts(_date, ids);
  }

  void _move(List<String> ids, int index, int by) {
    final target = index + by;
    if (target < 0 || target >= ids.length) return;
    final next = [...ids];
    final moved = next.removeAt(index);
    next.insert(target, moved);
    _setShifts(next);
  }

  Future<void> _duplicate() async {
    _commitNote();
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final close = widget.onClose;
    final from = DateTime(_date.year, _date.month, _date.day);
    // Calendar arithmetic, not `from + 24 h`: the day the clocks go back is
    // 25 h long and would propose the same day again.
    final next = _date.addDays(1);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(next.year, next.month, next.day),
      firstDate: DateTime(from.year - 1),
      lastDate: DateTime(from.year + 3, 12, 31),
      helpText: l10n.dayDetailDuplicateHelp,
    );
    if (picked == null || !mounted) return;
    final to = CivilDate.fromDateTime(picked);
    if (to == _date) return;
    final schedule = _schedule;
    final step = schedule.copyDay(_date, to);
    close();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          context: context,
          content: Text(l10n.dayDetailDuplicated(format.longDate(picked))),
          // Nothing to undo when the day already was like that. Otherwise
          // only while the copy is still the latest thing done.
          action: step == null
              ? null
              : SnackBarAction(
                  label: l10n.undo,
                  onPressed: () => schedule.undoIfLast(step),
                ),
        ),
      );
  }

  /// "Borrar día": leaves the day with nothing of its own (shifts, note,
  /// reminder, extra and missing minutes, own holiday), closes the sheet (the
  /// notice would hide behind it) and offers to undo it all, like "Duplicar
  /// en otro día".
  void _clear() {
    _extras.currentState?.commitPending();
    _commitNote();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final close = widget.onClose;
    final schedule = _schedule;
    final holidays = ref.read(holidayControllerProvider.notifier);
    final holiday = ref.read(holidaysProvider)[_date];
    final own = holiday != null && holiday.isUserAdded ? holiday : null;
    final date = _date;
    final step = schedule.clearDayCompletely(date);
    if (own != null) {
      unawaited(_guard(() => holidays.removeUserHoliday(date)));
    }
    close();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          context: context,
          content: Text(l10n.dayDetailCleared),
          action: step == null && own == null
              ? null
              : SnackBarAction(
                  label: l10n.undo,
                  onPressed: () {
                    // Only while nothing else was done to the day; the own
                    // holiday comes back with the rest.
                    final undone = step == null || schedule.undoIfLast(step);
                    if (undone && own != null) {
                      unawaited(
                        holidays.addUserHoliday(
                          date: date,
                          name: own.name,
                          scope: own.scope,
                        ),
                      );
                    }
                  },
                ),
        ),
      );
  }

  /// Share of the available height the sheet takes. The height depends on
  /// nothing the user does inside (typing, the holiday name field, adding or
  /// removing shifts), so the sheet never jumps; what does not fit scrolls.
  static const double _heightFactor = 0.88;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    final holiday = ref.watch(holidaysProvider.select((m) => m[_date]));
    final userHoliday = holiday != null && holiday.isUserAdded ? holiday : null;
    if (userHoliday == null) {
      _holidayNameShown = false;
    } else if (!_holidayNameShown) {
      _holidayName.text = userHoliday.name;
      _holidayNameShown = true;
    }

    final day = schedule.resolve(_date);
    final entry = schedule.entries[_date];
    // Anything «Borrar día» would remove: a shift, the note, its reminder,
    // the extra or missing minutes or the own holiday (H-T09-2).
    final hasContent =
        day.shifts.isNotEmpty ||
        _noteHasText ||
        entry?.noteReminderMinute != null ||
        (entry?.overtimeMinutes ?? 0) > 0 ||
        (entry?.earlyLeaveMinutes ?? 0) > 0 ||
        userHoliday != null;
    final ids = day.shiftIds;
    final isOverride = day.source == DaySource.override;
    final date = DateTime(_date.year, _date.month, _date.day);

    const gutter = EdgeInsets.symmetric(horizontal: Sp.page);

    // The date and the holiday stay put above the scrolling part: nothing in
    // it takes the vertical drag, so dragging them closes the sheet like
    // dragging the handle does.
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.inline)
          Semantics(
            header: true,
            child: Text(
              capitalize(format.longDate(date)),
              style: type.headline,
            ),
          ),
        if (holiday != null) ...[
          const SizedBox(height: Sp.xs),
          Text(
            holidayLine(l10n, holidayDisplayName(l10n, holiday)),
            key: const ValueKey('day-holiday-line'),
            style: type.bodyStrong.copyWith(color: colors.holiday),
          ),
        ],
      ],
    );
    final header = widget.inline
        // In the pane the way back to the "today" view is a button.
        ? Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.xs, Sp.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Sp.s),
                    child: title,
                  ),
                ),
                IconButton(
                  key: const ValueKey('day-pane-close'),
                  tooltip: l10n.dayPaneClose,
                  icon: Icon(AppIcons.close, color: colors.textMuted),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.m),
            child: title,
          );

    final shifts = Padding(
      padding: gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (day.shifts.isEmpty)
            Text(l10n.daySheetEmpty, style: type.body)
          else ...[
            for (final (index, shift) in day.shifts.indexed)
              _ShiftRow(
                key: ValueKey('day-shift-$index'),
                index: index,
                shift: shift,
                format: format,
                isFirst: index == 0,
                isLast: index == day.shifts.length - 1,
                onMoveUp: () => _move(ids, index, -1),
                onMoveDown: () => _move(ids, index, 1),
                onRemove: () => _setShifts([
                  for (final (i, id) in ids.indexed)
                    if (i != index) id,
                ]),
              ),
            Text(
              isOverride
                  ? l10n.dayDetailSourceOverride
                  : l10n.dayDetailSourcePattern,
              style: type.meta,
            ),
          ],
          if (palette.isNotEmpty) ...[
            const SizedBox(height: Sp.l),
            Text(
              (day.shifts.isEmpty ? l10n.dayDetailAdd : l10n.dayDetailDouble)
                  .toUpperCase(),
              style: type.label.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: Sp.s),
          ],
        ],
      ),
    );

    // The pucks wrap onto as many lines as they need (H-T17-3, H-T21-9): a
    // single scrolling row cut the last name at large text, in landscape or
    // in Basque, with nothing to say it scrolled. The sheet already scrolls
    // vertically, so any number of shift types is reachable. The first puck
    // still lines up with the text above.
    final pucks = palette.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.page - Sp.m),
            child: Wrap(
              key: const ValueKey('day-add-wrap'),
              spacing: Sp.xs,
              runSpacing: Sp.xs,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                for (final shift in palette)
                  _AddPuck(
                    key: ValueKey('day-add-${shift.id}'),
                    shift: shift,
                    onTap: ids.contains(shift.id)
                        ? null
                        : () => _setShifts([...ids, shift.id]),
                  ),
              ],
            ),
          );

    final rest = Padding(
      padding: gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOverride) ...[
            const SizedBox(height: Sp.l),
            SecondaryButton(
              key: const ValueKey('day-reset'),
              icon: AppIcons.undo,
              label: l10n.dayDetailReset,
              onPressed: () {
                _commitNote();
                _schedule.resetToPattern(_date);
              },
            ),
            const SizedBox(height: Sp.xs),
            Text(
              l10n.dayDetailPatternGives(
                shiftsLine(l10n, format, schedule.resolvePattern(_date).shifts),
              ),
              key: const ValueKey('day-pattern-gives'),
              style: type.meta,
            ),
          ],
          const SizedBox(height: Sp.section),
          LabeledField(
            label: l10n.daySheetNote,
            child: TextField(
              key: const ValueKey('day-note'),
              controller: _note,
              focusNode: _noteFocus,
              minLines: 2,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.dayDetailNoteHint),
              onChanged: (text) {
                _noteDirty = true;
                _draft.set(_date, text);
                _autosave?.cancel();
                _autosave = Timer(
                  noteAutosaveDelay,
                  () => _commitNote(endsTyping: false),
                );
                final has = text.trim().isNotEmpty;
                if (has != _noteHasText) setState(() => _noteHasText = has);
              },
            ),
          ),
          DayReminderRow(date: _date),
          const SizedBox(height: Sp.l),
          SwitchListTile(
            key: const ValueKey('day-holiday-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.dayDetailUserHoliday),
            value: userHoliday != null,
            onChanged: _setUserHoliday,
          ),
          if (userHoliday != null) ...[
            const SizedBox(height: Sp.xs),
            TextField(
              key: const ValueKey('day-holiday-name'),
              controller: _holidayName,
              focusNode: _holidayFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.dayDetailUserHolidayNameHint,
              ),
              onSubmitted: (_) => _commitHolidayName(),
            ),
          ],
          DayAlarmSkipRow(date: _date),
          DayExtrasSection(key: _extras, date: _date),
          const SizedBox(height: Sp.l),
          Wrap(
            spacing: Sp.s,
            runSpacing: Sp.s,
            children: [
              SecondaryButton(
                key: const ValueKey('day-duplicate'),
                icon: AppIcons.copy,
                label: l10n.dayDetailDuplicate,
                expand: false,
                onPressed: _duplicate,
              ),
              SecondaryButton(
                key: const ValueKey('day-clear'),
                icon: AppIcons.erase,
                label: l10n.dayDetailClear,
                expand: false,
                onPressed: hasContent ? _clear : null,
              ),
            ],
          ),
        ],
      ),
    );

    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (widget.inline) {
      // The pane gives the height (the screen already sits above the
      // keyboard) and scrolls what does not fit.
      return PopScope(
        onPopInvokedWithResult: (_, _) => commitPending(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('day-pane-scroll'),
                padding: EdgeInsets.only(bottom: Sp.l + widget.bottomRoom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [shifts, ?pucks, rest],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return PopScope(
      onPopInvokedWithResult: (_, _) => commitPending(),
      child: LayoutBuilder(
        builder: (context, box) {
          final room = box.hasBoundedHeight
              ? box.maxHeight
              : MediaQuery.sizeOf(context).height;
          // A share of the room, whatever the content; with the keyboard up
          // the sheet sits above it and only shrinks if it would not fit.
          final height = math.min(room * _heightFactor, room - keyboard);
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: SizedBox(
              height: height,
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: Sp.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [shifts, ?pucks, rest],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One shift of the day: badge, name, times, up / down and remove.
class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    super.key,
    required this.index,
    required this.shift,
    required this.format,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final ShiftType shift;
  final AppDateFormat format;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final times = shift.timeRange(format);
    final several = !(isFirst && isLast);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s),
      child: Row(
        children: [
          ShiftBadge(shift: shift),
          const SizedBox(width: Sp.m),
          Expanded(
            child: Semantics(
              container: true,
              label: shift.spoken(l10n, format),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.name, style: type.bodyStrong),
                  if (times != null)
                    Text(
                      times,
                      style: AppTypography.tabular(
                        type.body.copyWith(color: colors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (several) ...[
            IconButton(
              key: ValueKey('day-up-$index'),
              tooltip: l10n.dayDetailMoveUp,
              icon: Icon(AppIcons.arrowUp),
              onPressed: isFirst ? null : onMoveUp,
            ),
            IconButton(
              key: ValueKey('day-down-$index'),
              tooltip: l10n.dayDetailMoveDown,
              icon: Icon(AppIcons.arrowDown),
              onPressed: isLast ? null : onMoveDown,
            ),
          ],
          IconButton(
            key: ValueKey('day-remove-$index'),
            tooltip: l10n.dayDetailRemove(shift.name),
            icon: Icon(AppIcons.remove),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// A shift of the palette as a round puck (disc + ink code, name below) that
/// adds it to the day. Greyed out and not tappable when the day has it.
class _AddPuck extends StatelessWidget {
  const _AddPuck({super.key, required this.shift, required this.onTap});

  final ShiftType shift;
  final VoidCallback? onTap;

  static const double _minWidth = Disc.l + 2 * Sp.m;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final swatch = shift.swatch(colors.brightness);
    final labelStyle = type.caption.copyWith(color: colors.textMuted);
    // Grows with the text size and the name: never abbreviated.
    final width = puckWidth(
      context,
      label: shift.name,
      style: labelStyle,
      minWidth: _minWidth,
    );
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      label: shift.name,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
          onTap: onTap,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: Sp.xs),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: swatch.disc,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: Disc.l,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.xs),
                          child: ShiftCodeWithIcon(
                            shift: shift,
                            iconSize: 11,
                            style: type.bodyStrong.copyWith(
                              color: swatch.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.xs),
                PuckLabel(label: shift.name, style: labelStyle),
                const SizedBox(height: Sp.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
