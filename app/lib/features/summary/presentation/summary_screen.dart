import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/money.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/value_row.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/visible_month.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../settings/application/preferences_controller.dart';
import '../../year/application/year_providers.dart';
import '../../year/presentation/year_image.dart';
import '../../calendar/presentation/shift_badge.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/summary_providers.dart';
import '../domain/month_summary.dart';
import '../domain/summary_range.dart';
import 'month_sharing.dart';
import 'summary_format.dart';
import 'year_table.dart';

/// "Resumen del mes" (free, `docs/roadmap.md`): per shift type the days, the
/// hours, the night hours and the estimated pay; the totals, the rest days,
/// the absences and the hours worked on holidays; the change in hours against
/// the previous month. A switch shows the year as a table of its twelve
/// months. It reads the ACTIVE calendar; the definitions are in
/// `month_summary.dart` and in the notes at the bottom of the screen.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, this.month, this.yearView = false});

  /// Month to open (any day of it); the month on the calendar when null.
  final CivilDate? month;

  /// Opens on the table of the year.
  final bool yearView;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

/// What the summary covers: one month, one year, or two dates of the user.
enum _Period { month, year, range }

DateTime _dateTime(CivilDate d) => DateTime(d.year, d.month, d.day);

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late CivilDate _month;
  late _Period _period;
  late SummaryRange _range;

  /// The user already chose the dates of the range (it is no longer just the
  /// month on screen).
  bool _rangeTouched = false;

  /// The last end date had to be shortened to the limit of 366 days.
  bool _rangeClamped = false;
  final _scroll = ScrollController();

  /// The picture of the year is being drawn and shared.
  bool _sharingYear = false;

  bool get _yearView => _period == _Period.year;

  @override
  void initState() {
    super.initState();
    final CivilDate start = widget.month ?? ref.read(visibleMonthProvider);
    _month = start.firstDayOfMonth;
    _period = widget.yearView ? _Period.year : _Period.month;
    _range = SummaryRange.month(_month);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// New period, new page: back to the top.
  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _setPeriod(_Period period) {
    _toTop();
    setState(() {
      _period = period;
      if (period == _Period.range && !_rangeTouched) {
        _range = SummaryRange.month(_month);
      }
    });
  }

  void _step(int direction) => setState(() {
    _toTop();
    switch (_period) {
      case _Period.year:
        _month = CivilDate(_month.year + direction, _month.month, 1);
      case _Period.month:
        _month = direction < 0
            ? _month.addDays(-1).firstDayOfMonth
            : _month.addDays(_month.daysInMonth);
      case _Period.range:
        _range = _range.shifted(direction);
        _rangeTouched = true;
        _rangeClamped = false;
    }
  });

  void _openMonth(CivilDate month) => setState(() {
    _toTop();
    _month = month.firstDayOfMonth;
    _period = _Period.month;
  });

  /// «Compartir como imagen» of Resumen › Año: draws the year picture of the
  /// annual view off-screen and hands it to the share sheet.
  Future<void> _shareYear(int year) async {
    if (_sharingYear) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharingYear = true);
    try {
      final share = ref.read(yearImageSharerProvider);
      final png = await renderYearImage(
        year: year,
        schedule: ref.read(scheduleControllerProvider).schedule,
        holidays: ref.read(holidaysProvider),
        today: CivilDate.fromDateTime(ref.read(minuteClockProvider)),
        weekStart: ref.read(preferencesProvider).weekStart,
        locale: Locale(l10n.localeName),
      );
      await share(png, 'cuadrante-$year.png', l10n.yearShareSubject(year));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(appSnackBar(content: Text(l10n.yearShareFailed)));
    } finally {
      if (mounted) setState(() => _sharingYear = false);
    }
  }

  /// Picks one end of the range with the system calendar. The last day can
  /// only be chosen between the first day and 366 days later.
  Future<void> _pickDate({required bool start}) async {
    final current = start ? _range.from : _range.to;
    final l10n = context.l10n;
    final first = start ? DateTime(2000) : _dateTime(_range.from);
    final limit = _dateTime(_range.from.addDays(maxSummaryRangeDays - 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime(current),
      firstDate: first,
      lastDate: start ? DateTime(2100) : limit,
      helpText: start ? l10n.summaryRangeFrom : l10n.summaryRangeTo,
    );
    if (picked == null || !mounted) return;
    final day = CivilDate.fromDateTime(picked);
    final result = start ? _range.withFrom(day) : _range.withTo(day);
    setState(() {
      _range = result.range;
      _rangeTouched = true;
      _rangeClamped = result.clamped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final sharing = ref.watch(monthSharingProvider);
    final periodLabel = switch (_period) {
      _Period.year => '${_month.year}',
      _Period.month => capitalize(
        format.monthYear(DateTime(_month.year, _month.month)),
      ),
      _Period.range => formatRange(format.locale, _range.from, _range.to),
    };

    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.summaryTitle),
        actions: [
          if (_period == _Period.month)
            IconButton(
              key: const ValueKey('summary-share'),
              tooltip: l10n.shareMonthTooltip,
              icon: Icon(AppIcons.share),
              onPressed: sharing
                  ? null
                  : () => shareMonthImage(context, ref, _month),
            ),
          // The same picture as the annual view's (H-T08-5). «Fechas…» has
          // none: a free range is not a calendar page.
          if (_period == _Period.year)
            IconButton(
              key: const ValueKey('summary-share'),
              tooltip: l10n.yearShare,
              icon: Icon(AppIcons.share),
              onPressed: sharing || _sharingYear
                  ? null
                  : () => _shareYear(_month.year),
            ),
        ],
      ),
      body: PageBody(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            Sp.page,
            Sp.xs,
            Sp.page,
            Sp.section,
          ),
          children: [
            Wrap(
              spacing: Sp.s,
              runSpacing: Sp.s,
              children: [
                ChoicePill(
                  key: const ValueKey('summary-mode-month'),
                  label: l10n.summaryModeMonth,
                  selected: _period == _Period.month,
                  onTap: () => _setPeriod(_Period.month),
                ),
                ChoicePill(
                  key: const ValueKey('summary-mode-year'),
                  label: l10n.summaryModeYear,
                  selected: _yearView,
                  onTap: () => _setPeriod(_Period.year),
                ),
                ChoicePill(
                  key: const ValueKey('summary-mode-range'),
                  label: l10n.summaryModeRange,
                  selected: _period == _Period.range,
                  onTap: () => _setPeriod(_Period.range),
                ),
              ],
            ),
            const SizedBox(height: Sp.s),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('summary-previous'),
                  tooltip: switch (_period) {
                    _Period.year => l10n.yearPrevious,
                    _Period.month => l10n.calendarPreviousMonth,
                    _Period.range => l10n.summaryRangePrevious,
                  },
                  icon: Icon(AppIcons.chevronLeft),
                  onPressed: () => _step(-1),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        periodLabel,
                        key: const ValueKey('summary-period'),
                        textAlign: TextAlign.center,
                        style: AppTypography.tabular(type.title),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('summary-next'),
                  tooltip: switch (_period) {
                    _Period.year => l10n.yearNext,
                    _Period.month => l10n.calendarNextMonth,
                    _Period.range => l10n.summaryRangeNext,
                  },
                  icon: Icon(AppIcons.chevronRight),
                  onPressed: () => _step(1),
                ),
              ],
            ),
            if (_period == _Period.range) ...[
              const SizedBox(height: Sp.s),
              _RangePicker(
                range: _range,
                clamped: _rangeClamped,
                onPickFrom: () => _pickDate(start: true),
                onPickTo: () => _pickDate(start: false),
              ),
            ],
            const SizedBox(height: Sp.s),
            switch (_period) {
              _Period.year => YearTable(
                year: _month.year,
                onOpenMonth: _openMonth,
              ),
              _Period.month => _MonthBody(month: _month),
              _Period.range => _RangeBody(range: _range),
            },
          ],
        ),
      ),
    );
  }
}

/// Everything under the month switcher.
class _MonthBody extends ConsumerWidget {
  const _MonthBody({required this.month});

  final CivilDate month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(monthSummaryProvider(month));
    if (summary.isEmpty) {
      return _EmptyPeriod(
        title: l10n.summaryEmptyTitle,
        message: l10n.summaryEmptyBody,
      );
    }
    final previous = ref.watch(
      monthSummaryProvider(month.addDays(-1).firstDayOfMonth),
    );
    final previousName = AppDateFormat.of(context)
        .monthName(DateTime(previous.month.year, previous.month.month));
    return _PeriodBody(
      summary: summary,
      previous: previous,
      previousName: previousName,
    );
  }
}

/// Everything under the dates of a free range (`docs/paridad.md` A7): the
/// same cards as a month, compared with the same number of days before.
class _RangeBody extends ConsumerWidget {
  const _RangeBody({required this.range});

  final SummaryRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(rangeSummaryProvider(range));
    if (summary.isEmpty) {
      return _EmptyPeriod(
        title: l10n.summaryRangeEmptyTitle,
        message: l10n.summaryRangeEmptyBody,
      );
    }
    final previous = ref.watch(rangeSummaryProvider(range.previous));
    return _PeriodBody(
      summary: summary,
      previous: previous,
      previousName: l10n.summaryRangePreviousName(range.days),
      range: true,
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('summary-empty'),
    padding: const EdgeInsets.symmetric(vertical: Sp.x3),
    child: EmptyState(icon: AppIcons.summary, title: title, message: message),
  );
}

/// The two dates of a free range: «Desde» and «Hasta», each a row that opens
/// the system calendar, the number of days and, when the end had to be
/// shortened, why.
class _RangePicker extends StatelessWidget {
  const _RangePicker({
    required this.range,
    required this.clamped,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final SummaryRange range;
  final bool clamped;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final locale = AppDateFormat.of(context).locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _DateRow(
                key: const ValueKey('summary-range-from'),
                label: l10n.summaryRangeFrom,
                value: formatRangeDate(locale, range.from),
                onTap: onPickFrom,
              ),
              Divider(height: 1, thickness: 1, color: colors.border),
              _DateRow(
                key: const ValueKey('summary-range-to'),
                label: l10n.summaryRangeTo,
                value: formatRangeDate(locale, range.to),
                onTap: onPickTo,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.s, Sp.xs, 0),
          child: Text(
            clamped
                ? l10n.summaryRangeClamped(maxSummaryRangeDays)
                : l10n.summaryRangeDays(range.days, maxSummaryRangeDays),
            key: const ValueKey('summary-range-days'),
            style: type.meta.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final valueStyle = AppTypography.tabular(
      type.body.copyWith(fontWeight: FontWeight.w700),
    );
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$label: $value',
      onTap: onTap,
      child: InkWell(
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
                // With large text there is no room side by side: the date
                // goes under its label.
                Expanded(
                  child: context.largeText
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: type.body),
                            Text(value, style: valueStyle),
                          ],
                        )
                      : ValueRow(
                          title: Text(label, style: type.body),
                          value: Text(
                            value,
                            textAlign: TextAlign.end,
                            style: valueStyle,
                          ),
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

/// The cards of a period that has shifts.
class _PeriodBody extends StatelessWidget {
  const _PeriodBody({
    required this.summary,
    required this.previous,
    required this.previousName,
    this.range = false,
  });

  final MonthSummary summary;
  final MonthSummary previous;

  /// How the period before is named in the comparison ("septiembre", "los 7
  /// días anteriores").
  final String previousName;

  /// A free range: the notes do not talk about months.
  final bool range;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // «Horas en festivo: 0 h / 0 turnos en festivo» says nothing: like the
    // overtime lines, it is left out when both are 0 (H-T08-6 / H-T10-4).
    final showHolidays =
        summary.holidayMinutes > 0 || summary.holidayShifts > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HoursCard(
          summary: summary,
          previous: previous,
          previousName: previousName,
          showHolidays: showHolidays,
        ),
        if (summary.workedMinutes > 0 || summary.hasEarnings) ...[
          const SizedBox(height: Sp.card),
          _EstimateCard(summary: summary),
        ],
        for (final group in [
          (l10n.summaryGroupWork, summary.workTypes),
          (l10n.summaryGroupRest, summary.restTypes),
          (l10n.summaryAbsences, summary.absenceTypes),
        ])
          if (group.$2.isNotEmpty) ...[
            const SizedBox(height: Sp.section),
            _TypeGroup(title: group.$1, rows: group.$2),
          ],
        const SizedBox(height: Sp.section),
        _Notes(summary: summary, range: range, holidays: showHolidays),
      ],
    );
  }
}

/// Hours worked, the change against the previous period and the other
/// totals.
class _HoursCard extends StatelessWidget {
  const _HoursCard({
    required this.summary,
    required this.previous,
    required this.previousName,
    required this.showHolidays,
  });

  final MonthSummary summary;
  final MonthSummary previous;
  final String previousName;

  /// Whether the line of the hours on holidays shows.
  final bool showHolidays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final delta = summary.workedMinutes - previous.workedMinutes;
    final comparison = previous.isEmpty
        ? l10n.summaryDeltaNone(previousName)
        : delta == 0
        ? l10n.summaryDeltaSame(previousName)
        : l10n.summaryDelta(formatSignedHours(l10n, delta), previousName);

    Widget stat(String id, String label, String value, [String? detail]) =>
        _StatRow(id: id, label: label, value: value, detail: detail);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.summaryHoursWorked.toUpperCase(),
            style: type.label.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: Sp.xs),
          Semantics(
            label:
                '${l10n.summaryHoursWorked}: '
                '${formatHours(l10n, summary.workedMinutes)}',
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatHours(l10n, summary.workedMinutes),
                key: const ValueKey('summary-hours'),
                style: AppTypography.tabular(type.display),
              ),
            ),
          ),
          const SizedBox(height: Sp.xs),
          Text(
            comparison,
            key: const ValueKey('summary-delta'),
            style: type.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: Sp.m),
          Divider(height: 1, color: colors.border),
          stat(
            'summary-shifts',
            l10n.summaryShiftsWorked,
            '${summary.shiftsWorked}',
            summary.workedDays != summary.shiftsWorked
                ? l10n.summaryDays(summary.workedDays)
                : null,
          ),
          if (summary.overtimeMinutes > 0)
            stat(
              'summary-overtime',
              l10n.summaryOvertime,
              formatSignedHours(l10n, summary.overtimeMinutes),
              summary.overtimeCents > 0
                  ? l10n.summaryExtrasPay(
                      '+${formatEuroCents(context, summary.overtimeCents)}',
                    )
                  : null,
            ),
          if (summary.earlyLeaveMinutes > 0)
            stat(
              'summary-early-leave',
              l10n.summaryEarlyLeave,
              formatSignedHours(l10n, -summary.earlyLeaveMinutes),
              summary.earlyLeaveCents > 0
                  ? l10n.summaryExtrasPay(
                      '−${formatEuroCents(context, summary.earlyLeaveCents)}',
                    )
                  : null,
            ),
          stat(
            'summary-night',
            l10n.summaryNightHours,
            formatHours(l10n, summary.nightMinutes),
          ),
          stat('summary-rest', l10n.summaryRestDays, '${summary.restDays}'),
          stat(
            'summary-absences',
            l10n.summaryAbsences,
            '${summary.absenceDays}',
          ),
          if (showHolidays)
            stat(
              'summary-holiday',
              l10n.summaryHolidayHours,
              formatHours(l10n, summary.holidayMinutes),
              l10n.summaryHolidayDetail(summary.holidayShifts),
            ),
        ],
      ),
    );
  }
}

/// One "label ... value" line of the totals, with an optional quiet detail.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.id,
    required this.label,
    required this.value,
    this.detail,
  });

  /// Key prefix: `<id>` for the row, `<id>-value` for the figure.
  final String id;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return MergeSemantics(
      key: ValueKey(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.s),
        child: ValueRow(
          crossAxisAlignment: CrossAxisAlignment.start,
          valueGap: Sp.m,
          title: Text(label, style: type.body),
          // The figure flush right, or under the label when the row does not
          // fit; the detail travels with it, in the same column (H-T08-1).
          value: Text(
            value,
            key: ValueKey('$id-value'),
            style: AppTypography.tabular(
              type.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          detail: detail == null
              ? null
              : Text(
                  detail!,
                  key: ValueKey('$id-detail'),
                  style: type.meta.copyWith(color: colors.textSecondary),
                ),
        ),
      ),
    );
  }
}

/// The estimated pay, or what is missing to see it.
class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final earnings = summary.earningsCents;
    final unpriced = summary.unpricedTypes;
    return AppCard(
      key: const ValueKey('summary-estimate'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.summaryEstimateTitle.toUpperCase(),
            style: type.label.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: Sp.xs),
          if (earnings != null) ...[
            Semantics(
              label:
                  '${l10n.summaryEstimateTitle}: '
                  '${formatEuroCents(context, earnings)}. '
                  '${l10n.summaryEstimateNote}',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatEuroCents(context, earnings),
                  key: const ValueKey('summary-earnings'),
                  style: AppTypography.tabular(type.display),
                ),
              ),
            ),
            const SizedBox(height: Sp.xs),
            Text(
              l10n.summaryEstimateNote,
              style: type.body.copyWith(color: colors.textSecondary),
            ),
          ] else
            Text(
              l10n.summaryEstimateNone,
              key: const ValueKey('summary-earnings-none'),
              style: type.body.copyWith(color: colors.textSecondary),
            ),
          if (summary.fixedPlusCount > 0)
            _StatRow(
              id: 'summary-fixed-plus',
              label: l10n.summaryFixedPluses,
              value: formatEuroCents(context, summary.fixedPlusCents),
              detail: l10n.summaryFixedPlusCount(summary.fixedPlusCount),
            ),
          if (summary.extrasWithoutRateMinutes > 0) ...[
            const SizedBox(height: Sp.s),
            Text(
              l10n.summaryExtrasNoRate,
              key: const ValueKey('summary-extras-no-rate'),
              style: type.meta.copyWith(color: colors.textSecondary),
            ),
          ],
          if (earnings != null && unpriced.isNotEmpty) ...[
            const SizedBox(height: Sp.s),
            Text(
              l10n.summaryEstimateMissing(
                unpriced.map((t) => t.name).join(', '),
              ),
              key: const ValueKey('summary-earnings-missing'),
              style: type.meta.copyWith(color: colors.textSecondary),
            ),
          ],
          if (unpriced.isNotEmpty) ...[
            const SizedBox(height: Sp.m),
            SecondaryButton(
              key: const ValueKey('summary-rate-action'),
              label: l10n.summaryRateAction,
              onPressed: () => context.push(AppRoutes.shiftTypes),
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled card with a row per shift type.
class _TypeGroup extends StatelessWidget {
  const _TypeGroup({required this.title, required this.rows});

  final String title;
  final List<ShiftTypeMonth> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.s),
          child: Semantics(
            header: true,
            child: Text(title, style: context.type.bodyStrong),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                _TypeRow(row: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.row});

  final ShiftTypeMonth row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final shift = row.type;

    final counts = [
      l10n.summaryDays(row.days),
      if (row.count != row.days) l10n.summaryShifts(row.count),
    ].join(' · ');
    final hours = !row.isWork
        ? null
        : !shift.hasTimes
        ? l10n.summaryNoTimes
        : [
            formatHours(l10n, row.paidMinutes),
            if (row.nightMinutes > 0)
              l10n.summaryNightOf(formatHours(l10n, row.nightMinutes)),
          ].join(' · ');
    final pay = row.earningsCents;
    final Widget? payText = pay != null
        ? Text(
            formatEuroCents(context, pay),
            key: ValueKey('summary-type-pay-${shift.id}'),
            style: AppTypography.tabular(type.bodyStrong),
          )
        : row.missingRate
        ? Text(
            l10n.summaryNoRate,
            key: ValueKey('summary-type-norate-${shift.id}'),
            style: type.meta.copyWith(color: colors.textMuted),
          )
        : null;

    return MergeSemantics(
      child: Padding(
        key: ValueKey('summary-type-${shift.id}'),
        padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.m),
        child: Row(
          children: [
            ShiftBadge(shift: shift),
            const SizedBox(width: Sp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.name, style: type.bodyStrong),
                  Text(
                    counts,
                    style: AppTypography.tabular(
                      type.meta.copyWith(color: colors.textSecondary),
                    ),
                  ),
                  if (hours != null)
                    Text(
                      hours,
                      key: ValueKey('summary-type-hours-${shift.id}'),
                      style: AppTypography.tabular(
                        type.meta.copyWith(color: colors.textSecondary),
                      ),
                    ),
                  // With large text there is no room at the side.
                  if (context.largeText && payText != null) payText,
                ],
              ),
            ),
            if (!context.largeText && payText != null) ...[
              const SizedBox(width: Sp.s),
              payText,
            ],
          ],
        ),
      ),
    );
  }
}

/// How the numbers are counted, in plain words.
class _Notes extends StatelessWidget {
  const _Notes({
    required this.summary,
    required this.holidays,
    this.range = false,
  });

  final MonthSummary summary;

  /// The line of the holiday hours shows, so its note does too.
  final bool holidays;

  /// A free range: the first note speaks of days, not of months.
  final bool range;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final notes = [
      range ? l10n.summaryRangeNoteMidnight : l10n.summaryNoteMidnight,
      l10n.summaryNoteNight,
      l10n.summaryNoteDst,
      if (summary.shiftsWithoutTimes > 0) l10n.summaryNoteNoTimes,
      if (summary.hasExtras) l10n.summaryNoteExtras,
      if (holidays) l10n.summaryNoteHoliday,
    ];
    return AppCard.tinted(
      key: const ValueKey('summary-notes'),
      padding: const EdgeInsets.all(Sp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.summaryNotesTitle, style: type.bodyStrong),
          ),
          for (final note in notes) ...[
            const SizedBox(height: Sp.s),
            Text(note, style: type.meta.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
