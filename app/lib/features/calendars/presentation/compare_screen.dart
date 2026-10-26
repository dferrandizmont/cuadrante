import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/icons/parity_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/week_layout.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';
import '../application/calendars_controller.dart';
import '../application/compare_providers.dart';
import '../domain/calendar.dart';
import '../domain/calendar_comparison.dart';
import 'calendar_dot.dart';
import 'compare_cell.dart';

/// Horizontal fling speed (dp/s) that changes the month (as in the month
/// grid).
const double _swipeVelocity = 300;

/// Smallest height of a day of the grid: the day number and two bands.
const double _minCellHeight = 76;

/// «Comparar calendarios» (`/comparar`, `docs/paridad.md` A4): two calendars
/// of the user side by side on a month grid, each day showing the shifts of
/// both, with the days on which both are free marked, how many they are and
/// the list of those dates. Read-only: it uses [Schedule] of each calendar
/// and never changes the one on screen. Free for everyone.
///
/// Opens on the calendar on screen and the next one; [firstId], [secondId]
/// and [month] come from the link (`?a=&b=&mes=2026-10`).
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key, this.firstId, this.secondId, this.month});

  final String? firstId;
  final String? secondId;

  /// Month to open (any day of it); the current month when null.
  final CivilDate? month;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  String? _firstId;
  String? _secondId;
  late CivilDate _month;

  @override
  void initState() {
    super.initState();
    _firstId = widget.firstId;
    _secondId = widget.secondId;
    final CivilDate start =
        widget.month ?? CivilDate.fromDateTime(ref.read(clockProvider)());
    _month = start.firstDayOfMonth;
  }

  void _step(int direction) => setState(() {
    _month = direction < 0
        ? _month.addDays(-1).firstDayOfMonth
        : _month.addDays(_month.daysInMonth);
  });

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocity) {
      _step(1);
    } else if (velocity >= _swipeVelocity) {
      _step(-1);
    }
  }

  /// Picks a calendar for one of the two places. Choosing the one the other
  /// place has swaps them, so the two are always different.
  Future<void> _pick({
    required bool forFirst,
    required List<Calendar> calendars,
    required Calendar first,
    required Calendar second,
  }) async {
    final current = forFirst ? first : second;
    final other = forFirst ? second : first;
    final id = await showChoiceSheet<String>(
      context: context,
      title: context.l10n.comparePickTitle,
      options: [for (final c in calendars) ChoiceOption(c.id, c.name)],
      selected: current.id,
    );
    if (id == null || !mounted || id == current.id) return;
    setState(() {
      if (forFirst) {
        _firstId = id;
        _secondId = id == other.id ? current.id : other.id;
      } else {
        _secondId = id;
        _firstId = id == other.id ? current.id : other.id;
      }
    });
  }

  /// Puts the second calendar first and the first one second (H-T07-4).
  void _swap(Calendar first, Calendar second) => setState(() {
    _firstId = second.id;
    _secondId = first.id;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calendarsState = ref.watch(calendarsControllerProvider);
    final activeId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );
    final shown = calendarsState.value == null
        ? null
        : resolveComparePair(
            calendarsState.value!.calendars,
            activeId: activeId,
            firstId: _firstId,
            secondId: _secondId,
          );
    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.compareTitle),
        actions: [
          // Swapping used to happen only by picking in one place the
          // calendar the other one had, with nothing to say so.
          if (shown != null)
            IconButton(
              key: const ValueKey('compare-swap'),
              tooltip: l10n.compareSwap,
              icon: Icon(ParityIcons.swap),
              onPressed: () => _swap(shown.first, shown.second),
            ),
        ],
      ),
      body: PageBody(
        child: calendarsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorState(
            message: l10n.compareLoadFailed,
            onRetry: () => ref.invalidate(calendarsControllerProvider),
          ),
          data: (data) {
            final pair = resolveComparePair(
              data.calendars,
              activeId: activeId,
              firstId: _firstId,
              secondId: _secondId,
            );
            if (pair == null) return const _NeedTwoCalendars();
            return _Comparison(
              calendars: data.calendars,
              first: pair.first,
              second: pair.second,
              month: _month,
              onStep: _step,
              onSwipe: _onHorizontalDragEnd,
              onPick: ({required bool forFirst}) => _pick(
                forFirst: forFirst,
                calendars: data.calendars,
                first: pair.first,
                second: pair.second,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fewer than two calendars: nothing to compare, and the way to make one.
class _NeedTwoCalendars extends StatelessWidget {
  const _NeedTwoCalendars();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      key: const ValueKey('compare-need-two'),
      icon: ParityIcons.compare,
      title: l10n.compareNeedTwoTitle,
      message: l10n.compareNeedTwoBody,
      actionLabel: l10n.calendarsAdd,
      primaryAction: true,
      onAction: () => context.pushReplacement(AppRoutes.settingsCalendars),
    );
  }
}

class _Comparison extends ConsumerWidget {
  const _Comparison({
    required this.calendars,
    required this.first,
    required this.second,
    required this.month,
    required this.onStep,
    required this.onSwipe,
    required this.onPick,
  });

  final List<Calendar> calendars;
  final Calendar first;
  final Calendar second;
  final CivilDate month;
  final void Function(int direction) onStep;
  final GestureDragEndCallback onSwipe;
  final Future<void> Function({required bool forFirst}) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final format = AppDateFormat.of(context);
    final scheduleA = ref.watch(compareScheduleProvider(first.id));
    final scheduleB = ref.watch(compareScheduleProvider(second.id));
    final title = capitalize(
      format.monthYear(DateTime(month.year, month.month)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.page, Sp.section),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.m),
          child: Text(
            l10n.compareIntro,
            style: type.meta.copyWith(color: colors.textMuted),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _CalendarRow(
                rowKey: 'compare-first',
                label: l10n.compareFirstLabel,
                calendar: first,
                onTap: () => onPick(forFirst: true),
              ),
              Divider(height: 1, thickness: 1, color: colors.border),
              _CalendarRow(
                rowKey: 'compare-second',
                label: l10n.compareSecondLabel,
                calendar: second,
                onTap: () => onPick(forFirst: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.s),
        Row(
          children: [
            IconButton(
              key: const ValueKey('compare-previous'),
              tooltip: l10n.calendarPreviousMonth,
              icon: Icon(AppIcons.chevronLeft),
              onPressed: () => onStep(-1),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  key: const ValueKey('compare-month'),
                  textAlign: TextAlign.center,
                  style: AppTypography.tabular(type.title),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('compare-next'),
              tooltip: l10n.calendarNextMonth,
              icon: Icon(AppIcons.chevronRight),
              onPressed: () => onStep(1),
            ),
          ],
        ),
        if (scheduleA.hasError || scheduleB.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.x3),
            child: ErrorState(
              compact: true,
              message: l10n.compareLoadFailed,
              onRetry: () {
                ref.invalidate(compareScheduleProvider(first.id));
                ref.invalidate(compareScheduleProvider(second.id));
              },
            ),
          )
        else if (scheduleA.value == null || scheduleB.value == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Sp.x3),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _WeekdayRow(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: onSwipe,
            child: _CompareGrid(
              month: month,
              first: first,
              second: second,
              scheduleA: scheduleA.requireValue,
              scheduleB: scheduleB.requireValue,
            ),
          ),
          const SizedBox(height: Sp.l),
          _Summary(
            comparison: compareMonth(
              scheduleA.requireValue,
              scheduleB.requireValue,
              month,
            ),
          ),
        ],
      ],
    );
  }
}

/// One of the two chosen calendars: its colour, its name and a chevron.
class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.rowKey,
    required this.label,
    required this.calendar,
    required this.onTap,
  });

  final String rowKey;
  final String label;
  final Calendar calendar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$label: ${calendar.name}',
      onTap: onTap,
      child: InkWell(
        key: ValueKey(rowKey),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sp.touch),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.l,
              vertical: Sp.s,
            ),
            child: Row(
              children: [
                CalendarDot(colorValue: calendar.colorValue, size: 14),
                const SizedBox(width: Sp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: type.caption.copyWith(color: colors.textMuted),
                      ),
                      Text(
                        calendar.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: type.bodyStrong,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.s),
                Icon(
                  AppIcons.chevronRight,
                  size: IconSize.inline,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L M X J V S D (or D L M X J V S by preference), aligned with the grid.
class _WeekdayRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final weekStart = ref.watch(preferencesProvider.select((p) => p.weekStart));
    // Indexed by DateTime.weekday - 1.
    final initials = [
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
      l10n.calendarWeekdaySun,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: Sp.xs),
      child: Row(
        children: [
          for (final weekday in weekdayOrder(weekStart))
            Expanded(
              key: ValueKey('compare-weekday-$weekday'),
              child: Semantics(
                label: format.weekdayLong(
                  // 5 Jan 2026 is a Monday.
                  DateTime(2026, 1, 4 + weekday),
                ),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Sp.xs),
                  child: Center(
                    child: Text(
                      initials[weekday - 1],
                      style: context.type.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 6 x 7 grid of the month with both calendars in every day.
class _CompareGrid extends ConsumerWidget {
  const _CompareGrid({
    required this.month,
    required this.first,
    required this.second,
    required this.scheduleA,
    required this.scheduleB,
  });

  final CivilDate month;
  final Calendar first;
  final Calendar second;
  final Schedule scheduleA;
  final Schedule scheduleB;

  static const int _columns = 7;
  static const int _rows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(preferencesProvider.select((p) => p.weekStart));
    final today = CivilDate.fromDateTime(ref.watch(minuteClockProvider));
    final start = monthGridStart(month, weekStart);
    final days = compareDays(
      scheduleA,
      scheduleB,
      start,
      start.addDays(_columns * _rows - 1),
    );
    final scaler = MediaQuery.textScalerOf(context);
    // Room for the number, two bands of a code each and their gaps.
    final cellHeight = _minCellHeight * scaler.scale(1).clamp(1.0, 1.6);

    return Column(
      key: const ValueKey('compare-grid'),
      children: [
        for (var r = 0; r < _rows; r++)
          SizedBox(
            height: cellHeight,
            child: Row(
              children: [
                for (var c = 0; c < _columns; c++)
                  Expanded(
                    child: CompareCell(
                      key: ValueKey(
                        'compare-day-${days[r * _columns + c].date.toIso()}',
                      ),
                      day: days[r * _columns + c],
                      first: first,
                      second: second,
                      inMonth:
                          days[r * _columns + c].date.month == month.month &&
                          days[r * _columns + c].date.year == month.year,
                      isToday: days[r * _columns + c].date == today,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// «X días libres en común este mes», what the marks mean and the list of
/// those dates.
class _Summary extends StatelessWidget {
  const _Summary({required this.comparison});

  final MonthComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final count = comparison.commonFreeCount;
    final markColor = colors.isDark ? colors.highlight : colors.accent;
    final onMarkColor = colors.isDark ? colors.onHighlight : colors.onAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          key: const ValueKey('compare-summary'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: markColor,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.hair),
                      child: Icon(
                        AppIcons.check,
                        size: IconSize.inline,
                        color: onMarkColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.s),
                  Expanded(
                    child: Text(
                      l10n.compareLegendFree.toUpperCase(),
                      style: type.label.copyWith(color: colors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.s),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.compareCount(count),
                  key: const ValueKey('compare-count'),
                  style: type.title,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: Sp.m),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.compareFreeListTitle,
                    style: type.bodyStrong,
                  ),
                ),
                const SizedBox(height: Sp.s),
                Wrap(
                  key: const ValueKey('compare-free-list'),
                  spacing: Sp.s,
                  runSpacing: Sp.s,
                  children: [
                    for (final date in comparison.commonFreeDays)
                      _DatePill(
                        key: ValueKey('compare-free-date-${date.toIso()}'),
                        label: format.shortDate(
                          DateTime(date.year, date.month, date.day),
                        ),
                        spoken: format.weekdayDayMonth(
                          DateTime(date.year, date.month, date.day),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Sp.card),
        AppCard.tinted(
          child: Text(
            l10n.compareNote,
            style: type.meta.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({super.key, required this.label, required this.spoken});

  final String label;
  final String spoken;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: Rad.pill,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Sp.m,
            vertical: Sp.xs + Sp.hair,
          ),
          child: Text(
            label,
            style: AppTypography.tabular(
              context.type.caption.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
