import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../holidays/domain/holiday.dart';
import '../../onboarding/presentation/onboarding_tip.dart';
import '../../patterns/presentation/pattern_pick_banner.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/open_day.dart';
import '../application/paint_controller.dart';
import '../application/schedule_controller.dart';
import '../application/selection_controller.dart';
import 'day_cell.dart';
import 'day_detail_body.dart';
import 'paint_bar.dart';
import 'selection_bar.dart';
import 'shift_badge.dart';
import 'shift_format.dart';
import 'today_card.dart';

/// How many days follow today in the list under the "today" card.
const int upcomingDayCount = 7;

/// The right pane of the two-pane month (`docs/diseno.md`, «Pantallas
/// anchas»), under the [header] with the date and the buttons:
///
/// - paint and selection mode: their own header at the top and their tools at
///   the bottom, in the pane (the month keeps the whole height);
/// - a day open ([openDayProvider]): its detail, the same content and actions
///   as the bottom sheet, with a button that goes back;
/// - otherwise the "today" card and the next [upcomingDayCount] days.
///
/// [bottomRoom] is kept outside the scrolling viewport, above the floating
/// button, so controls cannot pass behind it at any scroll position.
class DayPane extends ConsumerWidget {
  const DayPane({super.key, required this.header, required this.bottomRoom});

  final Widget header;
  final double bottomRoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final painting = ref.watch(paintControllerProvider.select((p) => p.active));
    final selecting = ref.watch(
      selectionControllerProvider.select((s) => s.settled),
    );
    if (painting) {
      return const _ToolsPane(
        key: ValueKey('pane-paint'),
        top: [PaintHeader(), PatternPickBanner()],
        bar: PaintBar(card: true),
      );
    }
    if (selecting) {
      return const _ToolsPane(
        key: ValueKey('pane-selection'),
        top: [SelectionHeader()],
        bar: SelectionBar(card: true),
      );
    }

    final open = ref.watch(openDayProvider);
    return Column(
      children: [
        header,
        Expanded(
          // Keep the viewport above the floating button, rather than only
          // adding trailing scroll padding: no scroll position puts a
          // control behind the button (including the first-use tip).
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomRoom),
            child: open == null
                ? const _TodayView()
                : DayDetailBody(
                    // Another day starts over (its own note field).
                    key: ValueKey('pane-day-${open.toIso()}'),
                    date: open,
                    inline: true,
                    onClose: ref.read(openDayProvider.notifier).close,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Paint fills the pane between its header and fixed history actions. The
/// selection card grows with its complete labels and scrolls with its header
/// if both no longer fit (a landscape phone with big text).
class _ToolsPane extends StatelessWidget {
  const _ToolsPane({super.key, required this.top, required this.bar});

  final List<Widget> top;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (bar is PaintBar) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...top,
              const SizedBox(height: Sp.s),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
                  child: bar,
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(children: top),
                // The margin of the other cards of the pane.
                Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
                  child: bar,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The "today" card, the first-use tip and the next days.
class _TodayView extends StatelessWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('pane-today'),
      padding: const EdgeInsets.only(bottom: Sp.l),
      children: const [TodayCard(), OnboardingTipCard(), UpcomingDays()],
    );
  }
}

/// The next [upcomingDayCount] days after today as a compact list: the day,
/// code, name and hours of its shifts and a clip when it has a note. A tap
/// opens the day in the pane.
class UpcomingDays extends ConsumerWidget {
  const UpcomingDays({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final holidays = ref.watch(holidaysProvider);
    final now = ref.watch(minuteClockProvider);
    final tomorrow = CivilDate.fromDateTime(now).addDays(1);
    final days = schedule.resolveRange(
      tomorrow,
      tomorrow.addDays(upcomingDayCount - 1),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.section, Sp.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.upcomingTitle.toUpperCase(),
              style: context.type.label.copyWith(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: Sp.s),
          AppCard(
            key: const ValueKey('upcoming-days'),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, day) in days.indexed) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: colors.border),
                  _UpcomingRow(
                    day: day,
                    holiday: holidays[day.date],
                    onTap: () =>
                        ref.read(openDayProvider.notifier).open(day.date),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends ConsumerWidget {
  const _UpcomingRow({
    required this.day,
    required this.holiday,
    required this.onTap,
  });

  final ResolvedDay day;
  final Holiday? holiday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final date = DateTime(day.date.year, day.date.month, day.date.day);
    final isHoliday = holiday != null;
    final dayColor = isHoliday ? colors.holiday : colors.textPrimary;

    final shifts = day.shifts.isEmpty
        ? Text(
            l10n.calendarNoShift,
            style: type.body.copyWith(color: colors.textMuted),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final shift in day.shifts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.hair),
                  child: Row(
                    children: [
                      ShiftBadge(shift: shift, size: Disc.s),
                      const SizedBox(width: Sp.s),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: shift.name,
                                style: type.bodyStrong,
                              ),
                              if (shift.timeRange(format) case final times?)
                                TextSpan(
                                  text: '  $times',
                                  style: AppTypography.tabular(
                                    type.body.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: daySemanticsLabel(
        context,
        day: day,
        holiday: holiday,
        isToday: false,
      ),
      onTap: onTap,
      child: InkWell(
        key: ValueKey('upcoming-${day.date.toIso()}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sp.touch),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.m,
              vertical: Sp.s,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: Disc.l,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        capitalize(format.weekdayShort(date))
                            .replaceAll('.', ''),
                        maxLines: 1,
                        style: type.caption.copyWith(color: dayColor),
                      ),
                      Text(
                        '${day.date.day}',
                        style: AppTypography.tabular(
                          type.bodyStrong.copyWith(color: dayColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.m),
                Expanded(child: shifts),
                if (day.note != null && day.note!.isNotEmpty) ...[
                  const SizedBox(width: Sp.s),
                  Icon(
                    AppIcons.note,
                    size: IconSize.inline,
                    color: colors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
