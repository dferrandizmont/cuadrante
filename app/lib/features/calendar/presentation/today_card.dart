import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../application/schedule_controller.dart';
import '../application/today_status.dart';
import 'shift_format.dart';

/// The card at the top of the month (`docs/diseno.md`, "Tarjeta de hoy"): the
/// shift that matters now, with a badge, a countdown chip that refreshes every
/// minute and the line for tomorrow. Its label says the moment: AHORA (shift
/// in progress), ESTA NOCHE (starts from 20:00), HOY (starts earlier), HOY
/// LIBRE (nothing left today: shows the next shift), HOY TERMINADO (today's
/// shift is over: says which one and shows the next).
class TodayCard extends ConsumerStatefulWidget {
  const TodayCard({super.key});

  @override
  ConsumerState<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends ConsumerState<TodayCard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background the timer may be late: read the clock again.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(minuteClockProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final now = ref.watch(minuteClockProvider);
    final status = todayStatus(schedule, now);

    final main = status.main;
    final swatch = main?.swatch(colors.brightness);
    final restSwatch = status.restShift?.swatch(colors.brightness);
    final timed = status.timed;

    final label = switch (status.phase) {
      TodayPhase.now => l10n.todayLabelNow,
      TodayPhase.tonight => l10n.todayLabelTonight,
      TodayPhase.today => l10n.todayLabelToday,
      TodayPhase.free => l10n.todayLabelFree,
      TodayPhase.done => l10n.todayLabelDone,
      TodayPhase.gap => l10n.todayLabelGap,
    }.toUpperCase();
    final labelColor = swatch?.ink ?? colors.textMuted;

    final title = main?.name ?? l10n.todayFreeTitle;

    // Second line: hours, "until" for a shift in progress, when it ended, or
    // the next shift when today is free.
    final String? detail = switch (status.phase) {
      TodayPhase.done => l10n.todayFinishedAt(
        format.time(status.finished!.end),
      ),
      TodayPhase.now => l10n.todayUntil(format.time(timed!.end)),
      TodayPhase.tonight || TodayPhase.today => main?.timeRange(format),
      TodayPhase.gap => l10n.todayBackAt(format.time(timed!.start)),
      TodayPhase.free =>
        timed == null
            ? l10n.todayNoNext
            : l10n.todayNext(
                timed.shift.name,
                format.weekdayShort(timed.start),
                format.time(timed.start),
              ),
    };

    final countdown = status.minutes == null
        ? null
        : switch (status.phase) {
            TodayPhase.now => l10n.todayEndsIn(
              durationText(l10n, status.minutes!),
            ),
            TodayPhase.gap => l10n.todayBackIn(
              durationText(l10n, status.minutes!),
            ),
            _ => l10n.todayStartsIn(durationText(l10n, status.minutes!)),
          };

    // Once today's shift is over, the next one is a line of its own.
    final nextShift = status.phase == TodayPhase.done && status.timed != null
        ? l10n.todayNext(
            status.timed!.shift.name,
            format.weekdayShort(status.timed!.start),
            format.time(status.timed!.start),
          )
        : null;
    final also = status.others.isEmpty
        ? null
        : status.others
              .map((s) => l10n.todayAlso(s.nameWithTimes(l10n, format)))
              .join('  ');

    // With the date, so that "mañana" (the next day) is never read as a shift
    // called Mañana.
    final tomorrowDate = format.weekdayDay(
      DateTime(now.year, now.month, now.day + 1),
    );
    final tomorrowText = status.tomorrow.isEmpty
        ? l10n.calendarHeaderTomorrowNone(tomorrowDate)
        : l10n.calendarHeaderTomorrow(
            tomorrowDate,
            status.tomorrow.map((s) => s.name).join(' + '),
          );

    final badgeSwatch = swatch ?? restSwatch;
    final badgeCode = main?.code ?? status.restShift?.code;
    final barColor = swatch?.bar ?? restSwatch?.bar ?? colors.borderStrong;

    final spoken = [
      label.toLowerCase(),
      title,
      ?detail,
      ?nextShift,
      ?also,
      ?countdown,
      tomorrowText,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.xs, Sp.l, 0),
      child: Semantics(
        container: true,
        label: spoken,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Rad.cardRadius,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: Rad.cardRadius,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Sp.xl - Sp.hair,
                    Sp.xl - Sp.hair,
                    Sp.xl - Sp.hair,
                    Sp.l + Sp.cardBar,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: type.label.copyWith(color: labelColor),
                                ),
                                const SizedBox(height: Sp.hair),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: type.display,
                                ),
                                if (detail != null)
                                  Text(
                                    detail,
                                    style: type.bodyStrong.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                if (nextShift != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: Sp.xs),
                                    child: Text(
                                      nextShift,
                                      style: AppTypography.tabular(type.meta),
                                    ),
                                  ),
                                if (also != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: Sp.xs),
                                    child: Text(
                                      also,
                                      style: AppTypography.tabular(type.meta),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (badgeSwatch != null && badgeCode != null) ...[
                            const SizedBox(width: Sp.m),
                            _Badge(code: badgeCode, swatch: badgeSwatch),
                          ],
                        ],
                      ),
                      const SizedBox(height: Sp.m),
                      Wrap(
                        spacing: Sp.m,
                        runSpacing: Sp.s,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (countdown != null)
                            _CountdownChip(text: countdown),
                          Text(
                            tomorrowText,
                            style: AppTypography.tabular(
                              type.body.copyWith(color: colors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: Sp.cardBar,
                  child: ColoredBox(color: barColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 56 dp badge with the shift code: `disc` background, `ink` code.
class _Badge extends StatelessWidget {
  const _Badge({required this.code, required this.swatch});

  final String code;
  final ShiftSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: swatch.disc,
        borderRadius: Rad.badgeRadius,
      ),
      child: SizedBox.square(
        dimension: Disc.badge,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(Sp.xs),
              child: Text(
                code,
                maxLines: 1,
                style: context.type.headline.copyWith(color: swatch.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Empieza en 3 h 40 min" on `highlight`.
class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.highlight,
        borderRadius: Rad.countdownRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.xs),
        child: Text(
          text,
          style: AppTypography.tabular(
            context.type.body.copyWith(
              color: colors.onHighlight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
