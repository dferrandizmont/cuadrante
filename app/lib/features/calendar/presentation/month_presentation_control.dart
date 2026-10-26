import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../schedule/domain/civil_date.dart';
import '../../settings/application/preferences_controller.dart';
import '../application/month_presentation.dart';
import '../application/open_day.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import '../application/visible_month.dart';
import 'day_cell.dart';
import 'month_grid.dart';
import 'shift_format.dart';

/// Available in every editing mode and layout, beside the month navigation.
class MonthPresentationControl extends ConsumerWidget {
  const MonthPresentationControl({super.key});

  void _choose(BuildContext context, WidgetRef ref, MonthPresentation value) {
    if (ref.read(monthPresentationProvider) == value) return;
    final month = ref.read(visibleMonthProvider);
    final today = CivilDate.fromDateTime(ref.read(clockProvider)());
    final remembered =
        ref.read(monthDayFocusProvider).date ??
        ref.read(openDayProvider) ??
        ref.read(selectionControllerProvider).first;
    final date = remembered != null && remembered.firstDayOfMonth == month
        ? remembered
        : today.firstDayOfMonth == month
        ? today
        : month;
    ref.read(monthDayFocusProvider.notifier).request(date);
    ref.read(monthPresentationProvider.notifier).choose(value);
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        value == MonthPresentation.list
            ? context.l10n.monthListSelected
            : context.l10n.monthGridSelected,
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(monthPresentationProvider);
    final preferences = ref.watch(preferencesProvider);
    final month = ref.watch(visibleMonthProvider);
    final schedule = ref.watch(scheduleControllerProvider).schedule;
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final width =
            (box.maxWidth -
                2 * (Sp.l - Sp.cellGap / 2) -
                (preferences.weekNumbers ? MonthGrid.weekNumberWidth : 0)) /
            7;
        final scaler = MediaQuery.textScalerOf(context);
        final codeStyle = context.type.cellCode;
        final timeStyle = context.type.cellTime;
        final contentWidth = width - Sp.cellGap - 2 * cellContentInset;
        var reduced = false;
        for (final day in schedule.resolveRange(month, month.lastDayOfMonth)) {
          for (final shift in day.shifts) {
            final time = shift.compactTimeRange;
            if (day.shifts.length > 1 ||
                textWidth(shift.code, codeStyle, scaler) > contentWidth ||
                (time != null &&
                    textWidth(time, timeStyle, scaler) > contentWidth)) {
              reduced = true;
              break;
            }
          }
          if (reduced) break;
        }
        final recommended =
            width < Sp.touch ||
            reduced ||
            scaler.scale(codeStyle.fontSize!) / codeStyle.fontSize! >= 1.5 ||
            scaler.scale(timeStyle.fontSize!) / timeStyle.fontSize! >= 1.5;
        return Padding(
          padding: const EdgeInsets.all(Sp.xs),
          child: Wrap(
            spacing: Sp.s,
            runSpacing: Sp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoicePill(
                key: const ValueKey('month-presentation-grid'),
                label: l10n.monthPresentationGrid,
                selected: presentation == MonthPresentation.grid,
                onTap: () => _choose(context, ref, MonthPresentation.grid),
              ),
              DecoratedBox(
                key: recommended
                    ? const ValueKey('month-list-recommendation')
                    : null,
                decoration: BoxDecoration(
                  color: recommended ? context.colors.surfaceRaised : null,
                  borderRadius: BorderRadius.circular(Rad.chip),
                  border: recommended
                      ? Border.all(color: context.colors.accent, width: Sp.ring)
                      : null,
                ),
                child: Tooltip(
                  message: recommended
                      ? l10n.monthListRecommended
                      : l10n.monthPresentationList,
                  child: ChoicePill(
                    key: const ValueKey('month-presentation-list'),
                    label: l10n.monthPresentationList,
                    selected: presentation == MonthPresentation.list,
                    onTap: () => _choose(context, ref, MonthPresentation.list),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Selection shares the fixed navigation row with the paint scroll buttons,
/// leaving only the two presentation choices above the days.
class MonthSelectDaysControl extends ConsumerWidget {
  const MonthSelectDaysControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
      child: TextButton(
        key: const ValueKey('month-select-days'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
        ),
        onPressed: ref.read(selectionControllerProvider.notifier).enter,
        child: Text(context.l10n.monthSelectDays),
      ),
    ),
  );
}
