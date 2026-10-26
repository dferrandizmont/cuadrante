import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/money.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/summary_providers.dart';
import '../domain/month_summary.dart';
import 'summary_format.dart';
import 'year_month_cards.dart';

/// The twelve months of a year in a compact table (shifts, hours, night
/// hours, estimated pay) with the totals at the bottom. A tap on a month
/// opens its summary.
///
/// **Large text (H-T08-2).** From text x1.3 the five columns do not fit a
/// phone, and a table that scrolls sideways hides the euros with no sign that
/// there is more, and loses the month column. There the table becomes a list
/// of cards, one per month, with the same figures in up to three short lines:
/// everything shows at once, nothing to discover, the month name is always
/// next to its numbers and it wraps between words like any other text.
class YearTable extends ConsumerWidget {
  const YearTable({super.key, required this.year, required this.onOpenMonth});

  final int year;
  final ValueChanged<CivilDate> onOpenMonth;

  /// From this text scale the table is a list of cards.
  static const double cardsFromScale = 1.3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final totals = ref.watch(yearTotalsProvider(year));
    if (totals.isEmpty) {
      return Padding(
        key: const ValueKey('summary-year-empty'),
        padding: const EdgeInsets.symmetric(vertical: Sp.x3),
        child: EmptyState(
          icon: AppIcons.summary,
          title: l10n.summaryYearEmpty,
          message: l10n.summaryEmptyBody,
        ),
      );
    }

    final cards = textScaleOf(context) >= cardsFromScale - 0.001;
    final table = cards
        ? YearMonthCards(totals: totals, onOpenMonth: onOpenMonth)
        : AppCard(
            padding: const EdgeInsets.symmetric(vertical: Sp.s),
            child: Column(
              children: [
                _Header(),
                Divider(height: 1, color: colors.border),
                for (final month in totals.months)
                  _MonthRow(
                    summary: month,
                    onTap: () => onOpenMonth(month.month),
                  ),
                Divider(height: 1, color: colors.border),
                _Cells(
                  key: const ValueKey('summary-year-total'),
                  bold: true,
                  month: l10n.summaryYearTotal,
                  shifts: '${totals.shiftsWorked}',
                  hours: formatHours(l10n, totals.workedMinutes),
                  night: formatHours(l10n, totals.nightMinutes),
                  estimate: totals.earningsCents == null
                      ? '–'
                      : formatEuroCents(context, totals.earningsCents!),
                ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        table,
        const SizedBox(height: Sp.m),
        Text(
          l10n.summaryYearHint,
          style: type.meta.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: Sp.section),
        AppCard.tinted(
          padding: const EdgeInsets.all(Sp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.summaryNotesTitle, style: type.bodyStrong),
              const SizedBox(height: Sp.s),
              Text(
                l10n.summaryNoteMidnight,
                style: type.meta.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: Sp.s),
              Text(
                l10n.summaryNoteDst,
                style: type.meta.copyWith(color: colors.textSecondary),
              ),
              if (totals.hasExtras) ...[
                const SizedBox(height: Sp.s),
                Text(
                  l10n.summaryNoteExtras,
                  key: const ValueKey('summary-year-extras-note'),
                  style: type.meta.copyWith(color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: Sp.s),
              Text(
                l10n.summaryEstimateNote,
                style: type.meta.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExcludeSemantics(
      child: _Cells(
        header: true,
        month: l10n.summaryYearHeaderMonth,
        shifts: l10n.summaryYearHeaderShifts,
        hours: l10n.summaryYearHeaderHours,
        night: l10n.summaryYearHeaderNight,
        estimate: l10n.summaryYearHeaderEstimate,
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.summary, required this.onTap});

  final MonthSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final month = summary.month;
    final empty = summary.isEmpty;
    const none = '–';
    final cells = _Cells(
      key: ValueKey('summary-year-row-${month.month}'),
      muted: empty,
      month: monthAbbreviation(format.locale, month),
      shifts: empty ? none : '${summary.shiftsWorked}',
      hours: empty ? none : formatHours(l10n, summary.workedMinutes),
      night: empty ? none : formatHours(l10n, summary.nightMinutes),
      estimate: summary.earningsCents == null
          ? none
          : formatEuroCents(context, summary.earningsCents!),
    );
    final name = capitalize(
      format.monthName(DateTime(month.year, month.month)),
    );
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.summaryYearMonthSemantics(
        name,
        l10n.summaryShifts(summary.shiftsWorked),
        formatHours(l10n, summary.workedMinutes),
      ),
      onTap: onTap,
      child: InkWell(onTap: onTap, child: cells),
    );
  }
}

/// One line of five columns; the figures shrink to fit their column.
class _Cells extends StatelessWidget {
  const _Cells({
    super.key,
    required this.month,
    required this.shifts,
    required this.hours,
    required this.night,
    required this.estimate,
    this.header = false,
    this.bold = false,
    this.muted = false,
  });

  final String month;
  final String shifts;
  final String hours;
  final String night;
  final String estimate;
  final bool header;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final base = header ? type.caption : type.meta;
    final style = AppTypography.tabular(
      base.copyWith(
        color: header || muted ? colors.textMuted : colors.textPrimary,
        fontWeight: header || bold ? FontWeight.w800 : FontWeight.w600,
      ),
    );
    Widget cell(String text, int flex, {bool end = true}) => Expanded(
      flex: flex,
      child: Align(
        alignment: end ? Alignment.centerRight : Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(text, maxLines: 1, style: style),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sp.touch - Sp.s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.xs),
        child: Row(
          children: [
            // The shares keep the widest header («Turnos», «Estimado») whole
            // on a 320 dp phone: they used to shrink on their own, each by
            // a different amount (H-T08-2).
            cell(month, 17, end: false),
            const SizedBox(width: Sp.xs),
            cell(shifts, 21),
            const SizedBox(width: Sp.xs),
            cell(hours, 26),
            const SizedBox(width: Sp.xs),
            cell(night, 26),
            const SizedBox(width: Sp.xs),
            cell(estimate, 36),
          ],
        ),
      ),
    );
  }
}
