import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../patterns/domain/pattern_catalog.dart';
import '../../patterns/presentation/pattern_wizard_screen.dart'
    show PatternCard, PatternDateTile, patternFullDate, pickPatternDate;
import '../../patterns/presentation/step_chips.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/onboarding_controller.dart';
import '../domain/profession.dart';
import 'onboarding_widgets.dart';

/// Step 3a, «¿Cómo es tu rotación?»: the catalogue patterns of the job first
/// (the same cards as the pattern wizard), then the rest, or «Lo pinto a
/// mano».
class RotationStep extends ConsumerWidget {
  const RotationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );

    final typicalIds = state.profession?.presetIds ?? const <String>[];
    final typical = [for (final id in typicalIds) patternPresetById(id)];
    final others = [
      for (final p in patternPresets)
        if (!typicalIds.contains(p.id)) p,
    ];

    Widget card(PatternPreset p) => Padding(
      padding: const EdgeInsets.only(bottom: Sp.card),
      child: PatternCard(
        key: ValueKey('onboarding-pattern-${p.id}'),
        name: p.name,
        description: p.description,
        steps: p.steps,
        schedule: schedule,
        selected: state.presetId == p.id,
        onTap: () => controller.selectPreset(p.id),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: l10n.onboardingRotationTitle,
          titleKey: const ValueKey('onboarding-title'),
          help: l10n.onboardingRotationHelp,
        ),
        if (typical.isNotEmpty) ...[
          GroupLabel(l10n.onboardingRotationTypical),
          for (final p in typical) card(p),
        ],
        const SizedBox(height: Sp.s),
        AppCard(
          key: const ValueKey('onboarding-by-hand'),
          onTap: controller.paintByHand,
          semanticLabel: l10n.onboardingByHand,
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: Disc.m,
                  child: Icon(
                    AppIcons.paint,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.onboardingByHand, style: context.type.bodyStrong),
                    Text(l10n.onboardingByHandHint, style: context.type.meta),
                  ],
                ),
              ),
            ],
          ),
        ),
        GroupLabel(
          typical.isEmpty
              ? l10n.onboardingRotationAll
              : l10n.onboardingRotationOthers,
        ),
        for (final p in others) card(p),
      ],
    );
  }
}

/// Step 3b: the day the rotation starts and the day of the cycle that is
/// that day (the start step of the pattern wizard).
class StartStep extends ConsumerWidget {
  const StartStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final format = AppDateFormat.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    // The shift types as `finish` will leave them for the chosen job, so the
    // hours of "that day" are the ones the calendar will show.
    final schedule = scheduleWithProfession(
      ref.watch(scheduleControllerProvider.select((s) => s.schedule)),
      state.profession,
    );
    final id = state.presetId;
    if (id == null) return const SizedBox.shrink();
    final preset = patternPresetById(id);
    final pattern = presetPattern(schedule, preset);
    final offset = state.stepOffset % pattern.lengthDays;
    final start = state.start;

    List<ShiftType> shiftsOf(List<String> ids) => [
      for (final shiftId in ids) ?shiftTypeForDisplay(schedule, shiftId),
    ];

    final suggested = preset.suggestedStart;
    final weekdays = {
      DateTime.monday: l10n.patternWeekdayMonday,
      DateTime.tuesday: l10n.patternWeekdayTuesday,
      DateTime.wednesday: l10n.patternWeekdayWednesday,
      DateTime.thursday: l10n.patternWeekdayThursday,
      DateTime.friday: l10n.patternWeekdayFriday,
      DateTime.saturday: l10n.patternWeekdaySaturday,
      DateTime.sunday: l10n.patternWeekdaySunday,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: l10n.onboardingStartTitle,
          titleKey: const ValueKey('onboarding-title'),
          help: l10n.onboardingStartHelp,
        ),
        PatternDateTile(
          key: const ValueKey('onboarding-start-date'),
          label: l10n.patternStartLabel,
          value: patternFullDate(format, start),
          onTap: () async {
            final picked = await pickPatternDate(context, start);
            if (picked != null) controller.setStart(picked);
          },
        ),
        if (suggested != null && start.weekday != suggested)
          Padding(
            padding: const EdgeInsets.only(top: Sp.s),
            child: Text(
              l10n.patternSuggestedStart(weekdays[suggested]!),
              style: type.meta,
            ),
          ),
        const SizedBox(height: Sp.section),
        Semantics(
          header: true,
          child: Text(l10n.patternOffsetTitle, style: type.bodyStrong),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          l10n.patternOffsetHelp(
            format.weekdayDayMonth(
              DateTime(start.year, start.month, start.day),
            ),
          ),
          style: type.meta,
        ),
        const SizedBox(height: Sp.m),
        Wrap(
          // The cells are 48 dp wide to the touch: their own margin is the gap.
          runSpacing: Sp.xs,
          children: [
            for (final (i, step) in pattern.steps.indexed)
              StepChip(
                key: ValueKey('onboarding-offset-$i'),
                size: Disc.m,
                shifts: shiftsOf(step),
                selected: i == offset,
                caption: '${i + 1}',
                semanticsLabel: l10n.patternChipDay(
                  i + 1,
                  shiftsLine(l10n, format, shiftsOf(step)),
                ),
                onTap: () => controller.setStepOffset(i),
              ),
          ],
        ),
        const SizedBox(height: Sp.m),
        Text(
          l10n.patternOffsetThatDay(
            shiftsLine(l10n, format, shiftsOf(pattern.steps[offset])),
          ),
          key: const ValueKey('onboarding-offset-result'),
          style: type.body.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
