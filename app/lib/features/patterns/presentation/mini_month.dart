import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../calendar/application/week_layout.dart';
import '../../calendar/presentation/day_cell.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';

/// A whole month drawn with the same [DayCell] as the month screen, for the
/// live preview of the wizard: [schedule] is the schedule AFTER the pattern.
/// Days of the neighbouring months are left blank. Cells are keyed
/// `<keyPrefix>-<yyyy-MM-dd>`.
class MiniMonth extends ConsumerWidget {
  const MiniMonth({
    super.key,
    required this.month,
    required this.schedule,
    this.keyPrefix = 'preview',
  });

  /// Any day of the month to draw.
  final CivilDate month;
  final Schedule schedule;
  final String keyPrefix;

  /// Height of a row (the smallest the month screen lets a cell shrink to).
  static const double cellHeight = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = AppDateFormat.of(context);
    final holidays = ref.watch(holidaysProvider);
    final today = CivilDate.fromDateTime(ref.watch(minuteClockProvider));
    final first = month.firstDayOfMonth;
    // Blank cells before the 1st: the same week start as the month grid.
    final weekStart = ref.watch(preferencesProvider.select((p) => p.weekStart));
    final lead = first.differenceInDays(monthGridStart(first, weekStart));
    final rows = ((lead + first.daysInMonth) / 7).ceil();
    final days = schedule.resolveRange(
      first,
      first.addDays(first.daysInMonth - 1),
    );
    // The height of a row is the same for every row: it is measured once,
    // not once per cell.
    final rowHeight = math.max(
      cellHeight,
      dayCellHeightWithTime(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.xs),
          child: Semantics(
            header: true,
            child: Text(
              capitalize(format.monthYear(DateTime(first.year, first.month))),
              style: context.type.bodyStrong,
            ),
          ),
        ),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: SizedBox(
                    height: rowHeight,
                    child: _cell(r * 7 + c - lead, days, holidays, today),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    int dayIndex,
    List<ResolvedDay> days,
    Map<CivilDate, Holiday> holidays,
    CivilDate today,
  ) {
    if (dayIndex < 0 || dayIndex >= days.length) return const SizedBox();
    final day = days[dayIndex];
    return DayCell(
      key: ValueKey('$keyPrefix-${day.date.toIso()}'),
      day: day,
      holiday: holidays[day.date],
      inMonth: true,
      isToday: day.date == today,
    );
  }
}
