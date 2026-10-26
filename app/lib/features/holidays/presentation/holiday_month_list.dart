import 'package:flutter/material.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/holiday.dart';
import '../domain/substituted_holidays.dart';
import 'holiday_names.dart';
import 'holidays_icons.dart';

/// One row of the year list: a holiday and, when another holiday falls on
/// the same day, the note that says how they relate.
class HolidayRowData {
  const HolidayRowData(this.holiday, [this.note]);

  final Holiday holiday;
  final String? note;
}

/// The rows of [holidays] (one year, in calendar order). A holiday the
/// person added on a day that already has an official one says it replaces
/// it; the official one says what covers it in the calendar.
List<HolidayRowData> holidayRows(
  BuildContext context,
  Iterable<Holiday> holidays,
) {
  final l10n = context.l10n;
  final byDate = <Holiday>[...holidays];
  String joined(Iterable<Holiday> of) =>
      of.map((h) => holidayDisplayName(l10n, h)).toSet().join(' / ');
  return [
    for (final h in byDate)
      HolidayRowData(
        h,
        h.isUserAdded
            ? _noteFor(
                byDate.where((o) => o.date == h.date && !o.isUserAdded),
                (others) => l10n.holidaysSettingsNoteReplaces(joined(others)),
              )
            : _noteFor(
                byDate.where((o) => o.date == h.date && o.isUserAdded),
                (others) => l10n.holidaysSettingsNoteCovered(joined(others)),
              ),
      ),
  ];
}

String? _noteFor(
  Iterable<Holiday> others,
  String Function(List<Holiday> others) note,
) {
  final list = others.toList();
  return list.isEmpty ? null : note(list);
}

/// The year's holidays grouped by month: a small heading per month and one
/// card of rows under it. Each row shows the day, the name, a chip with its
/// scope (Nacional / the community / Local / Tuyo) and its note. The ones the
/// person added carry a remove button and can be swiped away; [onRemove] does
/// the work (the screen hides the row at once and offers to undo).
///
/// Keys: `holiday-row-<yyyy-mm-dd>-<n>`, `holiday-remove-<yyyy-mm-dd>`,
/// `holiday-dismiss-<yyyy-mm-dd>-<n>`.
class HolidayMonthList extends StatelessWidget {
  const HolidayMonthList({
    super.key,
    required this.rows,
    required this.regionName,
    required this.onRemove,
  });

  final List<HolidayRowData> rows;

  /// Name of the chosen community: the label of regional holidays.
  final String? regionName;
  final void Function(Holiday holiday) onRemove;

  @override
  Widget build(BuildContext context) {
    final format = AppDateFormat.of(context);
    final colors = context.colors;
    final byMonth = <int, List<HolidayRowData>>{};
    for (final row in rows) {
      byMonth.putIfAbsent(row.holiday.date.month, () => []).add(row);
    }
    final occurrences = <String, int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: month, value: monthRows)
            in byMonth.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.l, Sp.xs, Sp.s),
            child: Semantics(
              header: true,
              child: Text(
                format
                    .monthName(
                      DateTime(monthRows.first.holiday.date.year, month),
                    )
                    .toUpperCase(),
                style: context.type.label.copyWith(color: colors.textMuted),
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < monthRows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: colors.border),
                  _row(context, monthRows[i], occurrences),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    HolidayRowData data,
    Map<String, int> occurrences,
  ) {
    final iso = data.holiday.date.toIso();
    final n = occurrences.update(iso, (v) => v + 1, ifAbsent: () => 0);
    final row = _HolidayRow(
      key: ValueKey('holiday-row-$iso-$n'),
      data: data,
      regionName: regionName,
      onRemove: data.holiday.isUserAdded ? () => onRemove(data.holiday) : null,
    );
    if (!data.holiday.isUserAdded) return row;
    final colors = context.colors;
    return Dismissible(
      key: ValueKey('holiday-dismiss-$iso-$n'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(data.holiday),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Sp.l),
        color: colors.dangerContainer,
        child: Icon(HolidaysIcons.delete, color: colors.danger),
      ),
      child: row,
    );
  }
}

class _HolidayRow extends StatelessWidget {
  const _HolidayRow({
    super.key,
    required this.data,
    required this.regionName,
    required this.onRemove,
  });

  final HolidayRowData data;
  final String? regionName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final holiday = data.holiday;
    final date = holiday.date;
    final dateTime = DateTime(date.year, date.month, date.day);
    final scope = _scopeLabel(l10n, holiday);
    final note = data.note;

    return Material(
      color: colors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Sp.l,
            Sp.m,
            onRemove == null ? Sp.l : Sp.xs,
            Sp.m,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  label: l10n.holidaysSettingsRowSemantics(
                    format.weekdayDayMonth(dateTime),
                    holidayDisplayName(l10n, holiday),
                    scope,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            Text(
                              '${date.day}',
                              style: type.bodyStrong.copyWith(
                                color: colors.holiday,
                              ),
                            ),
                            Text(
                              format.weekdayShort(dateTime),
                              style: type.caption.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Sp.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holidayDisplayName(l10n, holiday),
                              style: type.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: Sp.xs),
                            _ScopeChip(
                              label: scope,
                              emphasized: holiday.isUserAdded,
                            ),
                            if (note != null) ...[
                              const SizedBox(height: Sp.xs),
                              Text(
                                note,
                                style: type.meta.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  key: ValueKey('holiday-remove-${date.toIso()}'),
                  tooltip: l10n.holidaysSettingsRemove,
                  icon: Icon(
                    HolidaysIcons.delete,
                    size: IconSize.button,
                    color: colors.textSecondary,
                  ),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _scopeLabel(AppLocalizations l10n, Holiday holiday) {
    if (holiday.isUserAdded) return l10n.holidaysSettingsScopeUser;
    return switch (holiday.scope) {
      HolidayScope.national => l10n.holidaysSettingsScopeNational,
      HolidayScope.regional => regionName ?? l10n.holidaysSettingsScopeNational,
      HolidayScope.local => l10n.holidaysSettingsScopeLocal,
    };
  }
}

/// Small pill with the scope in words (never colour alone); the person's own
/// holidays get the accent tone.
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = colors.accentTone;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? tone.bg : colors.surfaceRaised,
        borderRadius: Rad.chipSmallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s,
          vertical: Sp.hair,
        ),
        child: Text(
          label,
          style: context.type.caption.copyWith(
            color: emphasized ? tone.fg : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// «No son festivo en…» (with the community name): the replaceable national days the chosen
/// region does not apply, with a line on why.
class SubstitutedHolidaysNote extends StatelessWidget {
  const SubstitutedHolidaysNote({
    super.key,
    required this.regionName,
    required this.days,
  });

  final String regionName;
  final List<SubstitutedHoliday> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    return AppCard.tinted(
      padding: const EdgeInsets.all(Sp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.holidaysSettingsSubstitutedTitle(regionName),
              style: type.bodyStrong,
            ),
          ),
          const SizedBox(height: Sp.xs),
          Text(
            l10n.holidaysSettingsSubstitutedBody,
            style: type.meta.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: Sp.s),
          for (final day in days)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs),
              child: Text(
                '${localizedHolidayName(l10n, day.name) ?? day.name} · ${format.shortDate(DateTime(day.date.year, day.date.month, day.date.day))}',
                style: type.body.copyWith(color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
