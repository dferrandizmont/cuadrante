import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/money.dart';
import '../../../core/format/text_wrap.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/month_summary.dart';
import 'summary_format.dart';

/// The year as a list of cards, for large text (see `YearTable`): a tappable
/// card per month with its figures in two short lines, and the total.
///
/// The five columns of the table do not fit a phone from text x1.3, and a
/// table that scrolls sideways hides the euros with no sign that there is
/// more and loses the month column (H-T08-2). Here nothing is hidden, the
/// name of the month is always next to its numbers, and every line wraps
/// between words like any other text.
class YearMonthCards extends StatelessWidget {
  const YearMonthCards({
    super.key,
    required this.totals,
    required this.onOpenMonth,
  });

  final YearTotals totals;
  final ValueChanged<CivilDate> onOpenMonth;

  /// Spaces that must not break a line: «176 h 30 min» stays together.
  static String _together(String text) => text.replaceAll(' ', noBreakSpace);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final format = AppDateFormat.of(context);

    String hours(int minutes) => _together(formatHours(l10n, minutes));

    /// «22 turnos · 176 h» and «56 h nocturnas · 2.180,00 € estimado».
    List<String> lines({
      required int shifts,
      required int workedMinutes,
      required int nightMinutes,
      required int? earningsCents,
    }) => [
      '${_together(l10n.summaryShifts(shifts))} · ${hours(workedMinutes)}',
      [
        _together(l10n.summaryNightOf(hours(nightMinutes))),
        if (earningsCents != null)
          l10n.summaryYearEstimated(
            _together(formatEuroCents(context, earningsCents)),
          ),
      ].join(' · '),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final month in totals.months) ...[
          Builder(
            builder: (context) {
              final name = capitalize(
                format.monthName(DateTime(month.month.year, month.month.month)),
              );
              return _MonthCard(
                key: ValueKey('summary-year-card-${month.month.month}'),
                title: name,
                semantics: l10n.summaryYearMonthSemantics(
                  name,
                  l10n.summaryShifts(month.shiftsWorked),
                  formatHours(l10n, month.workedMinutes),
                ),
                lines: month.isEmpty
                    ? [l10n.summaryYearMonthEmpty]
                    : lines(
                        shifts: month.shiftsWorked,
                        workedMinutes: month.workedMinutes,
                        nightMinutes: month.nightMinutes,
                        earningsCents: month.earningsCents,
                      ),
                muted: month.isEmpty,
                onTap: () => onOpenMonth(month.month),
              );
            },
          ),
          const SizedBox(height: Sp.card),
        ],
        _MonthCard(
          key: const ValueKey('summary-year-total'),
          title: l10n.summaryYearTotal,
          lines: lines(
            shifts: totals.shiftsWorked,
            workedMinutes: totals.workedMinutes,
            nightMinutes: totals.nightMinutes,
            earningsCents: totals.earningsCents,
          ),
          color: colors.surfaceMuted,
        ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    super.key,
    required this.title,
    required this.lines,
    this.semantics,
    this.onTap,
    this.muted = false,
    this.color,
  });

  final String title;
  final List<String> lines;
  final String? semantics;
  final VoidCallback? onTap;
  final bool muted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final card = AppCard(
      color: color,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: type.bodyStrong.copyWith(
                    color: muted ? colors.textMuted : colors.textPrimary,
                  ),
                ),
                for (final line in lines)
                  Text(
                    line,
                    style: AppTypography.tabular(
                      type.meta.copyWith(
                        color: muted ? colors.textMuted : colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: Sp.s),
            Icon(
              AppIcons.chevronRight,
              size: IconSize.inline,
              color: colors.textMuted,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: semantics ?? title,
      onTap: onTap,
      child: card,
    );
  }
}
