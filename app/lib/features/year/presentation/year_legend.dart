import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/value_row.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../calendar/presentation/shift_icon_glyph.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/year_summary.dart';

/// "Turnos del año": a row per shift type that appears, with its colour, its
/// code, its name and the days it takes; and the holiday dot. The image of a
/// month reuses it with its own [title] and [emptyText] and shows the holiday
/// row only when the month has one ([showHoliday]).
class YearLegend extends StatelessWidget {
  const YearLegend({
    super.key,
    required this.schedule,
    required this.summary,
    this.title,
    this.emptyText,
    this.showHoliday = true,
  });

  final Schedule schedule;
  final YearSummary summary;
  final String? title;
  final String? emptyText;
  final bool showHoliday;

  /// Legend swatches are small squares (docs/diseno.md: 10-14 dp).
  static const double _swatch = 14;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;

    Widget row({
      required Key key,
      required Widget mark,
      required String code,
      required String name,
      required String count,
      ShiftIcon? icon,
    }) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: Sp.xs),
      // The name wraps between words and the count goes under it when the
      // two do not fit side by side: «Vacacion…» was cut at x2.0 on 320 dp
      // (H-T08-4). A name is never cut and a word never broken.
      child: ValueRow(
        valueGap: Sp.s,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: Sp.s),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: Sp.x4),
              child: Text(
                code,
                maxLines: 1,
                style: type.body.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (icon != null) ...[
              ShiftIconGlyph(
                key: const ValueKey('legend-icon'),
                icon: icon,
                size: _swatch,
                color: colors.textSecondary,
              ),
              const SizedBox(width: Sp.xs),
            ],
          ],
        ),
        title: Text(name, style: type.body),
        value: Text(count, style: AppTypography.tabular(type.bodyStrong)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title ?? l10n.yearLegendTitle, style: type.bodyStrong),
        ),
        const SizedBox(height: Sp.s),
        if (summary.isEmpty)
          Text(
            emptyText ?? l10n.yearLegendEmpty,
            style: type.body.copyWith(color: colors.textMuted),
          )
        else
          for (final entry in summary.counts.entries)
            Builder(
              builder: (context) {
                final shift = schedule.shiftTypeById(entry.key)!;
                final swatch = shift.swatch(colors.brightness);
                return row(
                  key: ValueKey('year-legend-${shift.id}'),
                  mark: SizedBox.square(
                    dimension: _swatch,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: swatch.bar,
                        borderRadius: Rad.swatchRadius,
                      ),
                    ),
                  ),
                  code: shift.code,
                  icon: shift.icon,
                  name: shift.name,
                  count: l10n.yearLegendDays(entry.value),
                );
              },
            ),
        if (showHoliday) ...[
          const SizedBox(height: Sp.s),
          Row(
            children: [
              SizedBox.square(
                dimension: _swatch,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.holiday,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: Sp.s),
                  ),
                ),
              ),
              const SizedBox(width: Sp.s),
              Expanded(
                child: Text(
                  l10n.yearLegendHoliday,
                  style: type.body.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
