import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';
import '../application/open_day.dart';
import '../application/paint_controller.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import '../application/visible_month.dart';
import '../application/week_layout.dart';
import 'day_cell.dart';
import 'month_day_action.dart';
import '../application/month_presentation.dart';
import 'grid_geometry.dart';

const int _columns = 7;
const int _rows = 6;

/// Smallest row height before the screen scrolls instead of shrinking the
/// grid.
const double _minCellHeight = 52;

/// Rows are at most this many times taller than wide (phones are tall).
const double _maxCellAspect = 1.5;

/// Horizontal fling speed (dp/s) that changes the month.
const double _swipeVelocity = 300;

/// Only weeks containing stacked shifts grow. Gesture geometry and the outer
/// scroll extent use these same measured minima.
List<double> monthGridMinimumRowHeights(
  BuildContext context,
  List<ResolvedDay> days, {
  required double minCellHeight,
}) => [
  for (var row = 0; row < _rows; row++)
    days
        .skip(row * _columns)
        .take(_columns)
        .fold<double>(
          minCellHeight,
          (height, day) =>
              math.max(height, dayCellHeightForShifts(context, day.shifts)),
        ),
];

/// The 6 x 7 month grid and its single gesture layer.
///
/// One [GestureDetector] covers the whole grid and maps pointer positions to
/// cells with [GridGeometry]; the cells themselves have no gesture
/// recognizers. In paint mode a tap or a drag paints, and a drag is ONE
/// stroke (one undo step); outside paint mode a tap opens the day (or, in
/// selection mode, chooses it), a long press starts selection mode (and
/// dragging with the finger still down extends the range) and a horizontal
/// swipe changes month.
class MonthGrid extends ConsumerStatefulWidget {
  const MonthGrid({
    super.key,
    this.ringOpenDay = false,
    this.minCellHeight = _minCellHeight,
  });

  /// Smallest row height before the screen scrolls instead of shrinking the
  /// grid. The two-pane month asks for rows tall enough to show the time under
  /// the code ([dayCellHeightWithTime]).
  final double minCellHeight;

  static const double defaultMinCellHeight = _minCellHeight;

  /// Ring the day that is open (the two-pane month shows it in the right
  /// pane). On a phone the sheet covers the grid and nothing is ringed.
  final bool ringOpenDay;

  /// Height under which the grid does not shrink any more (six rows of the
  /// smallest cell); the screen scrolls instead.
  static const double minHeight = _minCellHeight * _rows;

  /// Width of the column of week numbers at the left of the grid (and of the
  /// gap it leaves in the weekday row) when the user turns it on.
  static const double weekNumberWidth = 24;

  @override
  ConsumerState<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends ConsumerState<MonthGrid> {
  GridGeometry _geometry = const GridGeometry(width: 1, height: 1);
  GridGeometry? _strokeGeometry;
  ScheduleController? _strokeController;
  CivilDate _gridStart = const CivilDate(2000, 1, 3);
  Offset? _lastPoint;
  final _dayFocus = List.generate(_columns * _rows, (_) => FocusNode());

  int _handledFocusRequest = 0;

  @override
  void initState() {
    super.initState();
    ref.listenManual(visibleMonthProvider, (previous, next) {
      if (previous != next) _endStroke();
    });
    for (var i = 0; i < _dayFocus.length; i++) {
      final index = i;
      _dayFocus[i].addListener(() {
        if (_dayFocus[index].hasFocus) {
          ref
              .read(monthDayFocusProvider.notifier)
              .remember(_gridStart.addDays(index));
        }
      });
    }
  }

  @override
  void dispose() {
    // Disposing an accepted drag need not call onPanEnd/onPanCancel. Detach
    // its owner now, but notify providers after Flutter unlocks the tree.
    final controller = _releaseStroke();
    if (controller != null) {
      scheduleMicrotask(controller.endStroke);
    }
    for (final node in _dayFocus) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int index, int delta) {
    final next = index + delta;
    if (next >= 0 && next < _dayFocus.length) {
      FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
        _dayFocus[next],
      );
    }
  }

  ScheduleController get _schedule =>
      ref.read(scheduleControllerProvider.notifier);

  void _paintCell(int index) {
    final date = _gridStart.addDays(index);
    // The grey days of the neighbouring months are not painted: the stroke
    // stays inside the month that is being edited, so a drag with one hand
    // does not change days of another month by accident (H-T24-12).
    final month = ref.read(visibleMonthProvider);
    if (date.month != month.month || date.year != month.year) return;
    if (_schedule.paintDay(date)) {
      ref.read(monthDayFocusProvider.notifier).remember(date);
      // Haptics must never break painting (no vibrator, tests...).
      unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
    }
  }

  SelectionController get _selection =>
      ref.read(selectionControllerProvider.notifier);

  // Selection mode (range editing). Haptics never break the gesture.
  void _selectionHaptic(Future<void> Function() feedback) =>
      unawaited(feedback().catchError((Object _) {}));

  /// Long press: starts selection mode with this day chosen; the finger can
  /// then drag to extend the range.
  void _beginSelection(int index) {
    if (ref.read(paintControllerProvider).active) return;
    _selection.begin(_gridStart.addDays(index));
    _selectionHaptic(HapticFeedback.mediumImpact);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    final index = _geometry.cellAt(details.localPosition);
    if (index != null) _beginSelection(index);
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    final index = _geometry.cellAt(details.localPosition);
    if (index != null && _selection.extendTo(_gridStart.addDays(index))) {
      _selectionHaptic(HapticFeedback.selectionClick);
    }
  }

  void _tapCell(int index) {
    activateMonthDay(context, ref, _gridStart.addDays(index));
  }

  void _onTapUp(TapUpDetails details) {
    final index = _geometry.cellAt(details.localPosition);
    if (index != null) _tapCell(index);
  }

  void _onPanStart(DragStartDetails details) {
    // Keep the visible rows and hit testing on the same lattice until the
    // finger lifts, even when painting changes a week's required height.
    _strokeGeometry = _geometry;
    _strokeController = _schedule;
    _strokeController!.beginStroke(ref.read(paintControllerProvider).tool);
    _lastPoint = details.localPosition;
    final index = _geometry.cellAt(details.localPosition);
    if (index != null) _paintCell(index);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // A month change ends this gesture's stroke. Remaining moves/up belong
    // to the old grid and must not paint (or close a later stroke).
    if (_strokeController == null) return;
    final to = details.localPosition;
    for (final index in _geometry.cellsAlong(_lastPoint ?? to, to)) {
      _paintCell(index);
    }
    _lastPoint = to;
  }

  ScheduleController? _releaseStroke() {
    final controller = _strokeController;
    _strokeController = null;
    _lastPoint = null;
    _strokeGeometry = null;
    return controller;
  }

  void _endStroke() {
    final controller = _releaseStroke();
    if (controller == null) return;
    setState(() {});
    controller.endStroke();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final month = ref.read(visibleMonthProvider.notifier);
    if (velocity <= -_swipeVelocity) {
      month.next();
    } else if (velocity >= _swipeVelocity) {
      month.previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(visibleMonthProvider);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final holidays = ref.watch(holidaysProvider);
    final painting = ref.watch(paintControllerProvider.select((p) => p.active));
    final strokeDays = ref.watch(
      scheduleControllerProvider.select((s) => s.strokeDays),
    );
    final selectedDays = ref.watch(
      selectionControllerProvider.select((s) => s.days),
    );
    final openDay = widget.ringOpenDay ? ref.watch(openDayProvider) : null;
    // The minute clock, so the ring moves to the next day at midnight.
    final today = CivilDate.fromDateTime(ref.watch(minuteClockProvider));

    final weekStart = ref.watch(preferencesProvider.select((p) => p.weekStart));
    final weekNumbers = ref.watch(
      preferencesProvider.select((p) => p.weekNumbers),
    );

    _gridStart = monthGridStart(month, weekStart);
    final focus = ref.watch(monthDayFocusProvider);
    if (focus.request != _handledFocusRequest) {
      _handledFocusRequest = focus.request;
      final index = focus.date?.differenceInDays(_gridStart);
      if (index != null && index >= 0 && index < _dayFocus.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
              _dayFocus[index],
            );
          }
        });
      }
    }
    final days = schedule.resolveRange(
      _gridStart,
      _gridStart.addDays(_columns * _rows - 1),
    );

    return LayoutBuilder(
      builder: (context, box) {
        final gutter = weekNumbers ? MonthGrid.weekNumberWidth : 0.0;
        final cellWidth = (box.maxWidth - gutter) / _columns;
        // The upper bound never goes under the lower one: in a very narrow
        // window (split screen) the width limit would fall below the minimum
        // height and `clamp` would throw.
        final minima = monthGridMinimumRowHeights(
          context,
          days,
          minCellHeight: widget.minCellHeight,
        );
        final extra =
            math.max(0.0, box.maxHeight - minima.reduce((a, b) => a + b)) /
            _rows;
        final rowHeights = [
          for (final minimum in minima)
            minimum +
                math.min(
                  extra,
                  math.max(0.0, cellWidth * _maxCellAspect - minimum),
                ),
        ];
        final geometry =
            _strokeGeometry ??
            GridGeometry(
              width: box.maxWidth,
              height: rowHeights.reduce((a, b) => a + b),
              gutter: gutter,
              rowHeights: rowHeights,
            );
        _geometry = geometry;

        final grid = FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The drag starts where the finger went down, so the first cell
            // of a stroke is never skipped.
            dragStartBehavior: DragStartBehavior.down,
            excludeFromSemantics: true,
            onTapUp: _onTapUp,
            onPanStart: painting ? _onPanStart : null,
            onPanUpdate: painting ? _onPanUpdate : null,
            onPanEnd: painting ? (_) => _endStroke() : null,
            onPanCancel: painting ? _endStroke : null,
            onHorizontalDragEnd: painting ? null : _onHorizontalDragEnd,
            // Long press (then drag) chooses days; it never competes with
            // paint mode, where a drag already means paint.
            onLongPressStart: painting ? null : _onLongPressStart,
            onLongPressMoveUpdate: painting ? null : _onLongPressMove,
            onLongPressEnd: painting ? null : (_) => _selection.endDrag(),
            onLongPressCancel: painting ? null : _selection.endDrag,
            child: SizedBox(
              width: geometry.width,
              height: geometry.height,
              child: Column(
                children: [
                  for (var r = 0; r < _rows; r++)
                    Row(
                      children: [
                        if (weekNumbers)
                          _WeekNumber(
                            rowStart: _gridStart.addDays(r * _columns),
                            width: gutter,
                            height: geometry.rowHeight(r),
                          ),
                        for (var c = 0; c < _columns; c++)
                          _cell(
                            r * _columns + c,
                            days,
                            holidays,
                            month,
                            today,
                            strokeDays,
                            selectedDays,
                            openDay,
                            geometry,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );

        if (geometry.height <= box.maxHeight) {
          return Align(alignment: Alignment.topCenter, child: grid);
        }
        // Too little room (landscape, very large text): scroll the grid,
        // but never while painting, where a drag means paint.
        return SingleChildScrollView(
          physics: painting ? const NeverScrollableScrollPhysics() : null,
          child: grid,
        );
      },
    );
  }

  Widget _cell(
    int index,
    List<ResolvedDay> days,
    Map<CivilDate, Holiday> holidays,
    CivilDate month,
    CivilDate today,
    Set<CivilDate> strokeDays,
    Set<CivilDate> selectedDays,
    CivilDate? openDay,
    GridGeometry geometry,
  ) {
    final day = days[index];
    return SizedBox(
      width: geometry.cellWidth,
      height: geometry.rowHeight(index ~/ _columns),
      child: FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: DayCell(
          key: ValueKey('day-${day.date.toIso()}'),
          day: day,
          holiday: holidays[day.date],
          inMonth: day.date.month == month.month && day.date.year == month.year,
          isToday: day.date == today,
          painted: strokeDays.contains(day.date),
          selected: selectedDays.contains(day.date),
          focused: day.date == openDay,
          focusNode: _dayFocus[index],
          onMoveFocus: (delta) => _moveFocus(index, delta),
          onTap: () => _tapCell(index),
          onLongPress: () {
            // The accessibility action has no finger to wait for.
            _beginSelection(index);
            _selection.endDrag();
          },
        ),
      ),
    );
  }
}

/// The ISO week number at the left of a row of the grid. It is not part of
/// the gesture layer's cells (see [GridGeometry.gutter]).
class _WeekNumber extends StatelessWidget {
  const _WeekNumber({
    required this.rowStart,
    required this.width,
    required this.height,
  });

  final CivilDate rowStart;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final number = rowWeekNumber(rowStart);
    return SizedBox(
      key: ValueKey('week-${rowStart.toIso()}'),
      width: width,
      height: height,
      child: Semantics(
        label: context.l10n.calendarWeekNumberSemantics(number),
        excludeSemantics: true,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$number',
              style: context.type.caption.copyWith(
                color: context.colors.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
