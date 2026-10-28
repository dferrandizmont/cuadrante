import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/icons/app_icons.dart';
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
        // The icons only repeat the labels: they go first when large text
        // would otherwise wrap a label and push the month down.
        final labelStyle = context.type.body.copyWith(
          fontWeight: FontWeight.w800,
        );
        double segment(String label, {required bool icon}) =>
            textWidth(label, labelStyle, scaler) +
            2 * Sp.l +
            (icon ? IconSize.inline + Sp.s : 0);
        double both({required bool icons}) =>
            segment(l10n.monthPresentationGrid, icon: icons) +
            segment(l10n.monthPresentationList, icon: icons) +
            2 * (Sp.xs + Sp.hair + 1) +
            (recommended ? Sp.xs + Sp.cellSegmentDot : 0);
        final showIcons = both(icons: true) <= box.maxWidth;
        // Each half keeps its natural width; when even the bare labels do
        // not fit side by side (very large text), they stack.
        final inOneRow = both(icons: false) <= box.maxWidth;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(Rad.button),
                border: Border.all(color: context.colors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Sp.hair),
                child: Flex(
                  direction: inOneRow ? Axis.horizontal : Axis.vertical,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Segment(
                      key: const ValueKey('month-presentation-grid'),
                      icon: showIcons ? AppIcons.gridView : null,
                      label: l10n.monthPresentationGrid,
                      selected: presentation == MonthPresentation.grid,
                      onTap: () =>
                          _choose(context, ref, MonthPresentation.grid),
                    ),
                    Tooltip(
                      message: recommended
                          ? l10n.monthListRecommended
                          : l10n.monthPresentationList,
                      child: _Segment(
                        key: const ValueKey('month-presentation-list'),
                        icon: showIcons ? AppIcons.listView : null,
                        label: l10n.monthPresentationList,
                        selected: presentation == MonthPresentation.list,
                        // A dot, not a colour change of the whole control:
                        // the list is suggested, never imposed.
                        badge: recommended
                            ? Container(
                                key: const ValueKey(
                                  'month-list-recommendation',
                                ),
                                width: Sp.cellSegmentDot,
                                height: Sp.cellSegmentDot,
                                decoration: BoxDecoration(
                                  color: context.colors.accent,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () =>
                            _choose(context, ref, MonthPresentation.list),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One half of the grid/list switch: the selected half sits on a raised
/// thumb with a bolder label (never colour alone), like a native segmented
/// control on iOS and Android.
class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = selected ? colors.textPrimary : colors.textSecondary;
    final radius = BorderRadius.circular(Rad.inner);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.state,
        constraints: const BoxConstraints(minHeight: Sp.touch),
        decoration: BoxDecoration(
          // The soft accent, not `surface`: in dark mode `surface` and the
          // track are almost the same colour.
          color: selected ? colors.accentSoft : Colors.transparent,
          borderRadius: radius,
          border: Border.all(
            color: selected ? colors.borderStrong : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.l),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: IconSize.inline, color: ink),
                    const SizedBox(width: Sp.s),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: context.type.body.copyWith(
                        color: ink,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: Sp.xs), badge!],
                ],
              ),
            ),
          ),
        ),
      ),
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
