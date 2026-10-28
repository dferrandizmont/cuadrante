import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../holidays/domain/holiday.dart';
import '../../holidays/presentation/holiday_names.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';
import '../application/month_presentation.dart';
import '../application/open_day.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import '../application/visible_month.dart';
import '../application/week_layout.dart';
import 'day_cell.dart';
import 'holiday_label.dart';
import 'month_day_action.dart';
import 'shift_format.dart';

/// All days of the visible month, grouped using the same week arithmetic as
/// MonthGrid. No gesture recognizer claims drags: even while painting they scroll.
class MonthList extends ConsumerStatefulWidget {
  const MonthList({super.key});

  @override
  ConsumerState<MonthList> createState() => _MonthListState();
}

class _MonthListState extends ConsumerState<MonthList> {
  final _nodes = List.generate(31, (_) => FocusNode());
  int _handledFocusRequest = 0;

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _focus(int index) {
    if (index < 0 || index >= _nodes.length || _nodes[index].context == null) {
      return;
    }
    // Centred, not at the bottom edge (the default): the floating «Pintar»
    // button would cover the day there.
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      _nodes[index],
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(visibleMonthProvider);
    final end = month.lastDayOfMonth;
    final preferences = ref.watch(preferencesProvider);
    final format = AppDateFormat.of(context);
    ref.listen(monthDayFocusProvider.select((focus) => focus.request), (
      _,
      request,
    ) {
      if (request == _handledFocusRequest) return;
      _handledFocusRequest = request;
      final date = ref.read(monthDayFocusProvider).date;
      if (date != null && date.firstDayOfMonth == month) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus(date.day - 1);
        });
      }
    });
    // A new presentation mounts after the request was sent.
    final focus = ref.read(monthDayFocusProvider);
    if (focus.request != _handledFocusRequest) {
      _handledFocusRequest = focus.request;
      final date = focus.date;
      if (date != null && date.firstDayOfMonth == month) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus(date.day - 1);
        });
      }
    }
    final children = <Widget>[];
    for (
      var start = monthGridStart(month, preferences.weekStart);
      !start.isAfter(end);
      start = start.addDays(7)
    ) {
      final first = start.isBefore(month) ? month : start;
      final last = start.addDays(6).isAfter(end) ? end : start.addDays(6);
      final range = format.shortDateRange(
        DateTime(first.year, first.month, first.day),
        DateTime(last.year, last.month, last.day),
      );
      children.add(
        Padding(
          key: ValueKey('list-week-${start.toIso()}'),
          padding: const EdgeInsets.symmetric(vertical: Sp.m),
          child: Semantics(
            header: true,
            child: Text(
              preferences.weekNumbers
                  ? '${context.l10n.calendarWeekNumberSemantics(rowWeekNumber(start))}\n$range'
                  : range,
              style: context.type.body.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
      );
      for (var date = first; !date.isAfter(last); date = date.addDays(1)) {
        children.add(
          _ConnectedMonthListDay(
            key: ValueKey('connected-list-day-${date.toIso()}'),
            date: date,
            focusNode: _nodes[date.day - 1],
            onMove: (delta) => _focus(date.day - 1 + delta),
          ),
        );
      }
    }
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Subscriptions belong to a date, so a stroke, selection toggle or focus
/// move cannot rebuild the other thirty rows.
class _ConnectedMonthListDay extends ConsumerWidget {
  const _ConnectedMonthListDay({
    super.key,
    required this.date,
    required this.focusNode,
    required this.onMove,
  });

  final CivilDate date;
  final FocusNode focusNode;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      scheduleControllerProvider.select(
        (state) => _ListDaySnapshot(state.schedule.resolve(date)),
      ),
    );
    final selection = ref.watch(
      selectionControllerProvider.select(
        (state) => (active: state.active, selected: state.contains(date)),
      ),
    );
    final holiday = ref.watch(holidaysProvider.select((days) => days[date]));
    final additional = ref
        .watch(holidayControllerProvider)
        .calendar
        .list(date, date);
    final opened = ref.watch(openDayProvider.select((open) => open == date));
    final today = ref.watch(
      minuteClockProvider.select((now) => CivilDate.fromDateTime(now) == date),
    );
    return MonthListDay(
      key: ValueKey('list-day-${date.toIso()}'),
      day: snapshot.day,
      holiday: holiday,
      additionalHolidays: [
        for (final item in additional)
          if (item.name != holiday?.name) item,
      ],
      isToday: today,
      selected: selection.selected,
      selectionActive: selection.active,
      opened: opened,
      focusNode: focusNode,
      onMove: onMove,
      onFocus: () => ref.read(monthDayFocusProvider.notifier).remember(date),
      onTap: () => activateMonthDay(context, ref, date),
    );
  }
}

/// Resolve returns fresh lists even for unchanged days. Compare their values,
/// including shift definitions, rather than their identities.
class _ListDaySnapshot {
  const _ListDaySnapshot(this.day);
  final ResolvedDay day;
  static const _shifts = ListEquality<ShiftType>();

  @override
  bool operator ==(Object other) =>
      other is _ListDaySnapshot &&
      day.date == other.day.date &&
      _shifts.equals(day.shifts, other.day.shifts) &&
      day.source == other.day.source &&
      day.runId == other.day.runId &&
      day.stepIndex == other.day.stepIndex &&
      day.note == other.day.note &&
      day.overtimeMinutes == other.day.overtimeMinutes &&
      day.earlyLeaveMinutes == other.day.earlyLeaveMinutes;

  @override
  int get hashCode => Object.hash(
    day.date,
    _shifts.hash(day.shifts),
    day.source,
    day.runId,
    day.stepIndex,
    day.note,
    day.overtimeMinutes,
    day.earlyLeaveMinutes,
  );
}

/// One accessible target per day. Date, codes and each exact time segment have
/// their own lines and grow with TextScaler, without fitted boxes or ellipses.
class MonthListDay extends StatefulWidget {
  const MonthListDay({
    super.key,
    required this.day,
    required this.holiday,
    this.additionalHolidays = const [],
    required this.isToday,
    required this.selected,
    required this.selectionActive,
    required this.opened,
    required this.focusNode,
    required this.onMove,
    required this.onFocus,
    required this.onTap,
  });

  final ResolvedDay day;
  final Holiday? holiday;
  final List<Holiday> additionalHolidays;
  final bool isToday, selected, selectionActive, opened;
  final FocusNode focusNode;
  final ValueChanged<int> onMove;
  final VoidCallback onFocus, onTap;

  @override
  State<MonthListDay> createState() => _MonthListDayState();
}

class _MonthListDayState extends State<MonthListDay> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) widget.onTap();
      return KeyEventResult.handled;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowRight => 1,
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent || event is KeyRepeatEvent) widget.onMove(delta);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final day = widget.day;
    final date = day.date;
    final holiday = widget.holiday;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Rad.row),
      side: BorderSide(
        color: widget.selected || widget.opened || _focused || widget.isToday
            ? colors.todayRing
            : colors.border,
        width: widget.selected ? Sp.selectedBorder : Sp.ring,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s),
      child: FocusTraversalOrder(
        order: NumericFocusOrder(date.day.toDouble()),
        child: Focus(
          focusNode: widget.focusNode,
          includeSemantics: false,
          onFocusChange: (focused) {
            setState(() => _focused = focused);
            if (focused) widget.onFocus();
          },
          onKeyEvent: _key,
          child: Semantics(
            key: ValueKey('list-day-target-${date.toIso()}'),
            container: true,
            button: true,
            selected: widget.selected,
            focusable: true,
            focused: _focused,
            excludeSemantics: true,
            label: [
              daySemanticsLabel(
                context,
                day: day,
                holiday: holiday,
                isToday: widget.isToday,
                selected: widget.selected,
              ),
              for (final holiday in widget.additionalHolidays)
                holidaySpoken(l10n, holidayDisplayName(l10n, holiday)),
            ].join(', '),
            onTap: widget.onTap,
            child: Material(
              color: widget.selected ? colors.surfaceRaised : colors.surface,
              shape: shape,
              child: InkWell(
                onTap: widget.onTap,
                canRequestFocus: false,
                customBorder: shape,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: Sp.touch,
                    minHeight: Sp.touch,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Sp.m),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          capitalize(
                            format.longDate(
                              DateTime(date.year, date.month, date.day),
                            ),
                          ),
                          style: type.bodyStrong.copyWith(
                            color: holiday == null
                                ? colors.textPrimary
                                : colors.holiday,
                          ),
                        ),
                        if (widget.isToday)
                          Text(l10n.calendarToday, style: type.body),
                        if (widget.selectionActive)
                          Text(
                            widget.selected
                                ? l10n.selectionCellSelected
                                : l10n.monthSelectDay,
                            style: type.body,
                          ),
                        if (day.shifts.isEmpty)
                          Text(l10n.calendarNoShift, style: type.body),
                        for (final shift in day.shifts)
                          _shift(context, shift, format),
                        for (final holiday in [
                          ?holiday,
                          ...widget.additionalHolidays,
                        ])
                          Text(
                            holidayLine(
                              l10n,
                              holidayDisplayName(l10n, holiday),
                            ),
                            style: type.body.copyWith(color: colors.holiday),
                          ),
                        if (day.note?.isNotEmpty ?? false)
                          Text(l10n.daySemanticsNote, style: type.body),
                        if (day.overtimeMinutes > 0)
                          Text(
                            l10n.daySemanticsOvertime(
                              durationText(l10n, day.overtimeMinutes),
                            ),
                            style: type.body,
                          ),
                        if (day.earlyLeaveMinutes > 0)
                          Text(
                            l10n.daySemanticsEarlyLeave(
                              durationText(l10n, day.earlyLeaveMinutes),
                            ),
                            style: type.body,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shift(BuildContext context, ShiftType shift, AppDateFormat format) {
    final swatch = shift.swatch(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: swatch.tint,
          borderRadius: BorderRadius.circular(Rad.inner),
          border: Border(
            left: BorderSide(color: swatch.bar, width: Sp.bar),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                shift.code,
                style: context.type.bodyStrong.copyWith(color: swatch.ink),
              ),
              Text(
                shift.name,
                style: context.type.body.copyWith(color: swatch.ink),
              ),
              // One intact range per line, including minutes and both segments.
              for (final range
                  in shift.timeRange(format)?.split(' · ') ?? <String>[])
                Text(
                  range,
                  style: context.type.body.copyWith(
                    color: swatch.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
