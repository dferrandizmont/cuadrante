import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../calendar/presentation/day_cell.dart';
import '../../schedule/domain/schedule_domain.dart';

// Built once: a ThemeData is not cheap and the preview rebuilds per keystroke.
final ThemeData _lightTheme = AppTheme.light();
final ThemeData _darkTheme = AppTheme.dark();

/// Lowest contrast of the code ink over the cell tint and the disc of
/// [colorValue] in [brightness]: what the preview prints under each cell.
double shiftInkContrast(int colorValue, Brightness brightness) {
  final swatch = ShiftSwatch.forColor(colorValue, brightness);
  return math.min(
    contrastRatio(swatch.ink, swatch.tint),
    contrastRatio(swatch.ink, swatch.disc),
  );
}

/// The shift as a day cell of the month, in the light theme and in the dark
/// one side by side, so the user sees the contrast before saving. It draws
/// the real [DayCell] inside each theme (the cell derives its colours with
/// `ShiftSwatch`), and prints the contrast ratio of the code under each.
class ShiftTypePreview extends StatelessWidget {
  const ShiftTypePreview({super.key, required this.shift});

  /// The shift being edited (with a placeholder code while it is empty).
  final ShiftType shift;

  static const CivilDate _date = CivilDate(2026, 10, 19);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemedCell(
            key: const ValueKey('preview-light'),
            shift: shift,
            brightness: Brightness.light,
          ),
        ),
        const SizedBox(width: Sp.card),
        Expanded(
          child: _ThemedCell(
            key: const ValueKey('preview-dark'),
            shift: shift,
            brightness: Brightness.dark,
          ),
        ),
      ],
    );
  }
}

class _ThemedCell extends StatelessWidget {
  const _ThemedCell({super.key, required this.shift, required this.brightness});

  final ShiftType shift;
  final Brightness brightness;

  static const double _cellWidth = 76;
  static const double _cellHeight = 88;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final dark = brightness == Brightness.dark;
    final tokens = dark ? AppColors.dark : AppColors.light;
    final ratio = shiftInkContrast(shift.colorValue, brightness);
    final ratioText = ratio.toStringAsFixed(1).replaceAll('.', ',');
    final label = dark
        ? l10n.shiftTypesPreviewDark
        : l10n.shiftTypesPreviewLight;

    return Semantics(
      container: true,
      label: '$label, ${l10n.shiftTypesPreviewContrast(ratioText)}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.background,
          borderRadius: Rad.rowRadius,
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sp.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: type.caption.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: Sp.s),
              SizedBox(
                width: _cellWidth,
                height: math.max(_cellHeight, dayCellHeightWithTime(context)),
                child: Theme(
                  data: dark ? _darkTheme : _lightTheme,
                  child: DayCell(
                    day: ResolvedDay(
                      date: ShiftTypePreview._date,
                      shifts: [shift],
                      source: DaySource.override,
                    ),
                    holiday: null,
                    inMonth: true,
                    isToday: false,
                  ),
                ),
              ),
              const SizedBox(height: Sp.s),
              Text(
                l10n.shiftTypesPreviewContrast(ratioText),
                style: type.caption.copyWith(color: tokens.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
