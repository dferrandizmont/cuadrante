import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../calendar/application/week_layout.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../holidays/domain/holiday.dart';
import '../../schedule/domain/schedule_domain.dart';

/// One month of the annual view: its name (tap to open it) over a small grid
/// with a coloured square per day, starting on the week start the user chose
/// (Monday by default; no weekday header). A square takes the `bar`
/// colour of the day's shift (side by side when there are several); a day
/// without shift is `surfaceMuted`; a holiday carries a red dot; today has a
/// ring. Days outside the month are left blank. The month reads aloud as its
/// shift counts, since colour alone says nothing.
class YearMonth extends StatelessWidget {
  const YearMonth({
    super.key,
    required this.month,
    required this.schedule,
    required this.holidays,
    required this.today,
    required this.weekStart,
    required this.width,
    this.onTap,
  });

  /// First day of the month.
  final CivilDate month;
  final Schedule schedule;
  final Map<CivilDate, Holiday> holidays;
  final CivilDate today;

  /// 1 (Monday) or 7 (Sunday), like the month screen.
  final int weekStart;

  /// Known by the annual grid, including its off-screen image renderer.
  final double width;

  /// Opens the month; null in the picture that is shared (nothing to tap).
  final ValueChanged<CivilDate>? onTap;

  static const double _dot = Sp.xs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final first = month.firstDayOfMonth;
    // Blank squares before the 1st: the same week start as the month grid.
    final lead = first.differenceInDays(monthGridStart(first, weekStart));
    final days = schedule.resolveRange(
      first,
      first.addDays(first.daysInMonth - 1),
    );
    final rows = ((lead + days.length) / 7).ceil();
    final title = capitalize(
      format.monthName(DateTime(first.year, first.month)),
    );
    final titleStyle = type.caption.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w800,
    );
    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final visibleTitle = titlePainter.width <= width
        ? title
        : format.monthShort(DateTime(first.year, first.month));
    titlePainter.dispose();

    // "5 Noche, 4 Libre": what the colours mean, for TalkBack.
    final counts = <String, int>{};
    for (final d in days) {
      for (final s in d.shifts) {
        counts[s.name] = (counts[s.name] ?? 0) + 1;
      }
    }
    final summary = counts.isEmpty
        ? l10n.yearMonthEmpty
        : counts.entries.map((e) => '${e.value} ${e.key}').join(', ');

    return Semantics(
      container: true,
      button: true,
      label: '$title ${first.year}: $summary',
      excludeSemantics: true,
      onTap: onTap == null ? null : () => onTap!(first),
      child: InkWell(
        borderRadius: Rad.chipSmallRadius,
        onTap: onTap == null ? null : () => onTap!(first),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.xs),
              child: Text(
                visibleTitle,
                key: const ValueKey('year-month-title'),
                maxLines: 1,
                style: titleStyle,
              ),
            ),
            for (var r = 0; r < rows; r++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: _cell(context, r * 7 + c - lead, days)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int index, List<ResolvedDay> days) {
    if (index < 0 || index >= days.length) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }
    final colors = context.colors;
    final day = days[index];
    final swatches = [for (final s in day.shifts) s.swatch(colors.brightness)];
    final holiday = holidays.containsKey(day.date);
    final radius = BorderRadius.circular(Sp.hair);
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(Sp.hair / 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: swatches.isEmpty
                  ? ColoredBox(
                      key: ValueKey('year-day-${day.date.toIso()}'),
                      color: colors.surfaceMuted,
                    )
                  : Row(
                      key: ValueKey('year-day-${day.date.toIso()}'),
                      // The squares have no child: without this they would
                      // be 0 dp tall and draw nothing.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < swatches.length; i++)
                          Expanded(
                            child: ColoredBox(
                              color: swatches[i].bar,
                              child: Padding(
                                padding: const EdgeInsets.all(Sp.hair),
                                child: ColoredBox(
                                  color: swatches[i].tint,
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        day.shifts[i].code,
                                        key: ValueKey(
                                          'year-code-${day.date.toIso()}-${day.shifts[i].id}',
                                        ),
                                        style: context.type.cellTime.copyWith(
                                          color: swatches[i].ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (day.date == today)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: colors.todayRing, width: 1),
                  ),
                ),
              ),
            if (holiday)
              Align(
                alignment: Alignment.topRight,
                child: DecoratedBox(
                  key: ValueKey('year-holiday-${day.date.toIso()}'),
                  decoration: BoxDecoration(
                    color: colors.holiday,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 0.5),
                  ),
                  child: const SizedBox.square(dimension: _dot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
