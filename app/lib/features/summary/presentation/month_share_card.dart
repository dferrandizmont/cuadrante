import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../calendar/application/week_layout.dart';
import '../../calendar/presentation/day_cell.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../year/application/year_summary.dart';
import '../../year/presentation/year_legend.dart';
import '../domain/month_summary.dart';

/// The picture that "Compartir el mes como imagen" sends: the title, the
/// month in the grid of design B (the real [DayCell]s, without today's ring,
/// notes or the days of the neighbouring months), the legend with the days of
/// each shift and a small "Cuadrante" at the bottom. Nothing private goes
/// in: no notes, no hours, no pay.
///
/// It reads the theme and the texts from its context; the image is drawn
/// with the light theme whatever the app is showing (see `renderMonthImage`).
/// No `LayoutBuilder` (it is laid out in one pass off-screen): the width
/// comes from the parent, the cells have a fixed height.
class MonthShareCard extends StatelessWidget {
  const MonthShareCard({
    super.key,
    required this.month,
    required this.schedule,
    required this.holidays,
    required this.weekStart,
  });

  /// A day of the month to draw.
  final CivilDate month;
  final Schedule schedule;
  final Map<CivilDate, Holiday> holidays;

  /// 1 (Monday) or 7 (Sunday).
  final int weekStart;

  /// Width of the picture in logical pixels (1200 px at 3x).
  static const double width = 400;

  /// Smallest height of a row of days: the tokens reserve 14 + 6 + 22 + 12 +
  /// 6 + 4 = 64 dp for the number of the day, the code, the time, the bar
  /// and the gap between cells.
  static const double minCellHeight = 64;

  /// Height of a row of days: the room the cell needs for its code and its
  /// time ([dayCellHeightWithTime]), never less than [minCellHeight]. The
  /// picture is drawn with the normal text size (it ignores the text size of
  /// the phone), so it is measured once, here.
  static double cellHeightOf(BuildContext context) =>
      math.max(minCellHeight, dayCellHeightWithTime(context));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final cellHeight = cellHeightOf(context);
    final first = month.firstDayOfMonth;
    final gridStart = monthGridStart(first, weekStart);
    final lead = first.differenceInDays(gridStart);
    final rows = ((lead + first.daysInMonth) / 7).ceil();
    final days = schedule.resolveRange(first, first.lastDayOfMonth);
    final summary = summarizeMonth(schedule, first);
    final legend = YearSummary({
      for (final t in summary.types) t.type.id: t.days,
    });
    final title = capitalize(
      format.monthYear(DateTime(first.year, first.month)),
    );
    final weekdayInitials = [
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
      l10n.calendarWeekdaySun,
    ];
    final hasHoliday = days.any((d) => holidays.containsKey(d.date));

    Widget cell(int index) {
      final day = index < 0 || index >= days.length ? null : days[index];
      if (day == null) return SizedBox(height: cellHeight);
      return SizedBox(
        key: ValueKey('share-day-${day.date.toIso()}'),
        height: cellHeight,
        child: DayCell(
          // The note is private: the picture only needs the shifts.
          day: ResolvedDay(
            date: day.date,
            shifts: day.shifts,
            source: day.source,
          ),
          holiday: holidays[day.date],
          inMonth: true,
          isToday: false,
        ),
      );
    }

    return ColoredBox(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, Sp.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: type.headline),
            const SizedBox(height: Sp.l),
            Row(
              children: [
                for (final weekday in weekdayOrder(weekStart))
                  Expanded(
                    key: ValueKey('share-weekday-$weekday'),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: Sp.xs),
                      child: Center(
                        child: Text(
                          weekdayInitials[weekday - 1],
                          style: type.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (var r = 0; r < rows; r++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: cell(r * 7 + c - lead)),
                ],
              ),
            const SizedBox(height: Sp.xl),
            YearLegend(
              schedule: schedule,
              summary: legend,
              title: l10n.shareMonthLegendTitle,
              emptyText: l10n.shareMonthLegendEmpty,
              showHoliday: hasHoliday,
            ),
            const SizedBox(height: Sp.l),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.appName,
                key: const ValueKey('share-footer'),
                style: type.caption.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
