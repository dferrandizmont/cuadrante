import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/calendar.dart';
import '../domain/calendar_comparison.dart';

/// Spoken description of a compared day: "lunes 19 de octubre, hoy. Mi
/// cuadrante: Noche. Pareja: Libre. libres los dos".
String compareCellSemantics(
  BuildContext context, {
  required ComparedDay day,
  required Calendar first,
  required Calendar second,
  required bool isToday,
}) {
  final l10n = context.l10n;
  final date = day.date;
  String shifts(ResolvedDay d) => d.shifts.isEmpty
      ? l10n.calendarNoShift
      : d.shifts.map((s) => s.name).join(' + ');
  return [
    AppDateFormat.of(context)
        .weekdayDayMonth(DateTime(date.year, date.month, date.day)),
    if (isToday) l10n.daySemanticsToday,
    l10n.compareCellCalendar(first.name, shifts(day.a)),
    l10n.compareCellCalendar(second.name, shifts(day.b)),
    if (day.bothFree) l10n.compareBothFree,
  ].join('. ');
}

/// One day of the comparison grid (`docs/diseno.md`, "Celda del día", with
/// two bands instead of one): the day number, and below it the shifts of the
/// first calendar and of the second, stacked. Each band has a strip in the
/// colour of its calendar and, in the shift's tint, the code of every shift
/// of that calendar that day (a dash when there is none). The days on which
/// both are free get a ring and a check, so it is never colour
/// alone; days of the neighbouring months are muted and never marked.
class CompareCell extends StatelessWidget {
  const CompareCell({
    super.key,
    required this.day,
    required this.first,
    required this.second,
    required this.inMonth,
    required this.isToday,
  });

  final ComparedDay day;
  final Calendar first;
  final Calendar second;
  final bool inMonth;
  final bool isToday;

  static const double _stripWidth = 3;
  static const double _markSize = 11;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final scaler = MediaQuery.textScalerOf(context);
    final free = inMonth && day.bothFree;
    // Dark mode selects in amber, light mode in the accent, like the
    // selection of the month grid.
    final markColor = colors.isDark ? colors.highlight : colors.accent;
    final onMarkColor = colors.isDark ? colors.onHighlight : colors.onAccent;
    final background = inMonth ? colors.surface : colors.surfaceMuted;
    final numberLine =
        scaler.scale(type.cellDay.fontSize! * type.cellDay.height!) + Sp.xs;

    final ringColor = free
        ? markColor
        : isToday
        ? colors.todayRing
        : null;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: compareCellSemantics(
        context,
        day: day,
        first: first,
        second: second,
        isToday: isToday,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.cellGap / 2),
        child: ClipRRect(
          borderRadius: Rad.cellRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: background),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Sp.hair,
                  Sp.hair,
                  Sp.hair,
                  Sp.hair,
                ),
                child: Column(
                  children: [
                    SizedBox(height: numberLine),
                    Expanded(
                      child: _Band(
                        key: ValueKey('compare-a-${day.date.toIso()}'),
                        shifts: day.a.shifts,
                        calendar: first,
                        inMonth: inMonth,
                      ),
                    ),
                    const SizedBox(height: Sp.hair),
                    Expanded(
                      child: _Band(
                        key: ValueKey('compare-b-${day.date.toIso()}'),
                        shifts: day.b.shifts,
                        calendar: second,
                        inMonth: inMonth,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: Sp.xs,
                left: Sp.s,
                right: Sp.xs,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${day.date.day}',
                      maxLines: 1,
                      style: type.cellDay.copyWith(
                        color: inMonth
                            ? colors.textSecondary
                            : colors.textMuted,
                        fontWeight: isToday ? FontWeight.w900 : null,
                      ),
                    ),
                  ),
                ),
              ),
              // No fill over the bands: the codes keep their contrast; the
              // ring and the check say "free in both".
              if (free)
                Positioned(
                  top: Sp.xs,
                  right: Sp.xs,
                  child: DecoratedBox(
                    key: ValueKey('compare-free-${day.date.toIso()}'),
                    decoration: BoxDecoration(
                      color: markColor,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.hair),
                      child: Icon(
                        AppIcons.check,
                        size: _markSize,
                        color: onMarkColor,
                      ),
                    ),
                  ),
                ),
              if (ringColor != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: Rad.cellRadius,
                        border: Border.all(color: ringColor, width: Sp.ring),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shifts of ONE calendar on a day: a strip in the colour of the
/// calendar, then the tint of the first shift with every code ("M+T").
class _Band extends StatelessWidget {
  const _Band({
    super.key,
    required this.shifts,
    required this.calendar,
    required this.inMonth,
  });

  final List<ShiftType> shifts;
  final Calendar calendar;
  final bool inMonth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final brightness = colors.brightness;
    final stripColor = ShiftSwatch.forColor(
      calendar.colorValue,
      brightness,
      outOfMonth: !inMonth,
    ).bar;
    final swatches = [
      for (final s in shifts) s.swatch(brightness, outOfMonth: !inMonth),
    ];
    final lead = swatches.isEmpty ? null : swatches.first;
    final label = shifts.isEmpty
        ? context.l10n.compareNoShiftMark
        : shifts.map((s) => s.code).join('+');

    return ClipRRect(
      borderRadius: BorderRadius.circular(Rad.swatch),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: CompareCell._stripWidth,
            child: ColoredBox(color: stripColor),
          ),
          Expanded(
            child: ColoredBox(
              color:
                  lead?.tint ??
                  (inMonth ? colors.surfaceRaised : colors.surfaceMuted),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: type.cellCodeMulti.copyWith(
                      color: lead == null ? colors.textMuted : lead.ink,
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
