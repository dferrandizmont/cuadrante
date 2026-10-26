import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/text_wrap.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/value_row.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/visible_month.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/pattern_wizard.dart';
import '../domain/pattern_catalog.dart';
import 'mini_month.dart';
import 'pattern_builder.dart';
import 'step_chips.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// "Asistente de patrón" (turnos-spec.md section 4, screen 3): 1) choose a
/// preset or build your own, 2) start day and the day of the cycle you are
/// on, 3) the end and what to do with the days changed by hand. The result
/// is previewed live (two months, the same cell as the month screen) and
/// applied as ONE undoable step.
class PatternWizardScreen extends ConsumerWidget {
  const PatternWizardScreen({super.key, this.start, this.shiftId});

  /// Day to start on (the one tapped after a long press on a puck).
  final CivilDate? start;

  /// Shift of the puck that was long-pressed: its typical patterns go first.
  final String? shiftId;

  PatternWizardArgs get _args => (start: start, shiftId: shiftId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = patternWizardProvider(_args);
    final wizard = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final last = wizard.step == WizardStep.end;

    return Scaffold(
      appBar: ContentAppBar.adaptive(context, title: Text(l10n.patternTitle)),
      body: PageBody(
        child: Column(
          children: [
            _StepIndicator(step: wizard.step),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey('pattern-step-${wizard.step.name}'),
                padding: const EdgeInsets.fromLTRB(
                  Sp.page,
                  Sp.s,
                  Sp.page,
                  Sp.section,
                ),
                child: switch (wizard.step) {
                  WizardStep.choose => _ChooseStep(args: _args),
                  WizardStep.start => _StartStep(args: _args),
                  WizardStep.end => _EndStep(args: _args),
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Sp.page,
                  Sp.s,
                  Sp.page,
                  Sp.m,
                ),
                // «Atrás» next to «Siguiente», or one under the other when
                // the words do not fit side by side («Atr / ás» at x2.0 on
                // 320 dp, H-T06-3); then the main action is on top.
                child: AdaptiveButtonRow(
                  gap: Sp.m,
                  primaryFirstWhenStacked: true,
                  items: [
                    if (wizard.step != WizardStep.choose)
                      ButtonRowItem(
                        label: l10n.patternBack,
                        child: SecondaryButton(
                          key: const ValueKey('pattern-back'),
                          label: l10n.patternBack,
                          onPressed: wizard.applying ? null : controller.back,
                        ),
                      ),
                    ButtonRowItem(
                      flex: 2,
                      label: last ? l10n.patternApply : l10n.patternNext,
                      child: PrimaryButton(
                        key: ValueKey(last ? 'pattern-apply' : 'pattern-next'),
                        label: last ? l10n.patternApply : l10n.patternNext,
                        loading: wizard.applying,
                        onPressed: !wizard.hasChoice
                            ? null
                            : last
                            ? () => _apply(context, ref)
                            : controller.next,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final provider = patternWizardProvider(_args);
    final day = ref.read(provider).start;
    final schedule = ref.read(scheduleControllerProvider.notifier);
    final month = ref.read(visibleMonthProvider.notifier);
    final step = await ref
        .read(provider.notifier)
        .apply(fallbackName: l10n.patternBuilderDefaultName);
    if (!context.mounted) return;
    if (step == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(appSnackBar(content: Text(l10n.patternApplyFailed)));
      return;
    }
    month.goTo(day);
    router.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          context: context,
          content: Text(l10n.patternApplied),
          action: SnackBarAction(
            label: l10n.undo,
            // Only while the pattern is still the latest thing done.
            onPressed: () => schedule.undoIfLast(step),
          ),
        ),
      );
  }
}

/// "Paso 2 de 3" with three segments.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final WizardStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final title = switch (step) {
      WizardStep.choose => l10n.patternStepChoose,
      WizardStep.start => l10n.patternStepStart,
      WizardStep.end => l10n.patternStepEnd,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final s in WizardStep.values) ...[
                Expanded(
                  child: SizedBox(
                    height: Sp.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: s.index <= step.index
                            ? colors.accent
                            : colors.border,
                        borderRadius: Rad.pill,
                      ),
                    ),
                  ),
                ),
                if (s != WizardStep.values.last) const SizedBox(width: Sp.xs),
              ],
            ],
          ),
          const SizedBox(height: Sp.s),
          Semantics(
            header: true,
            child: Text(
              l10n.patternStepOf(step.index + 1, WizardStep.values.length),
              style: context.type.label.copyWith(color: colors.textMuted),
            ),
          ),
          Text(
            title,
            key: const ValueKey('pattern-step-title'),
            style: context.type.headline,
          ),
        ],
      ),
    );
  }
}

// ---- step 1 -----------------------------------------------------------------

class _ChooseStep extends ConsumerWidget {
  const _ChooseStep({required this.args});

  final PatternWizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final provider = patternWizardProvider(args);
    final wizard = ref.watch(provider);
    if (wizard.building) return PatternBuilder(args: args);
    final controller = ref.read(provider.notifier);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );

    final shiftId = args.shiftId;
    final shiftName = shiftId == null
        ? null
        : schedule.shiftTypeById(shiftId)?.name;
    // Patterns that begin with the shift of the puck; when none does, the
    // ones that at least include it.
    final startsWith = <PatternPreset>[
      if (shiftId != null)
        for (final p in patternPresets)
          if (startsWithShift(p.steps, shiftId)) p,
    ];
    final includes = <PatternPreset>[
      if (shiftId != null && startsWith.isEmpty)
        for (final p in patternPresets)
          if (containsShift(p.steps, shiftId)) p,
    ];
    final typical = startsWith.isNotEmpty ? startsWith : includes;
    final typicalIds = {for (final p in typical) p.id};
    final saved = [
      for (final p in schedule.patterns)
        if (!presetPatternIds.contains(p.id)) p,
    ];
    final byStart = startsWith.isNotEmpty || includes.isEmpty;
    final typicalSaved = [
      if (shiftId != null)
        for (final p in saved)
          if (byStart
              ? startsWithShift(p.steps, shiftId)
              : containsShift(p.steps, shiftId))
            p,
    ];
    final restSaved = [
      for (final p in saved)
        if (!typicalSaved.contains(p)) p,
    ];

    Widget presetCard(PatternPreset p) => PatternCard(
      key: ValueKey('pattern-card-${p.id}'),
      name: p.name,
      description: p.description,
      steps: p.steps,
      schedule: schedule,
      selected: wizard.presetId == p.id,
      onTap: () => controller.selectPreset(p.id),
    );

    Widget savedCard(Pattern p) => PatternCard(
      key: ValueKey('pattern-card-${p.id}'),
      name: p.name,
      description: null,
      steps: p.steps,
      schedule: schedule,
      selected: wizard.customId == p.id,
      onTap: () => controller.selectCustom(p.id),
    );

    final groupLabels = {
      PatternGroup.health: l10n.patternGroupHealth,
      PatternGroup.police: l10n.patternGroupPolice,
      PatternGroup.firefighters: l10n.patternGroupFirefighters,
      PatternGroup.industry: l10n.patternGroupIndustry,
      PatternGroup.security: l10n.patternGroupSecurity,
    };

    final sections = <Widget>[];
    void section(String label, List<Widget> cards, {Key? key}) {
      if (cards.isEmpty) return;
      sections
        ..add(
          Padding(
            padding: const EdgeInsets.only(top: Sp.section, bottom: Sp.s),
            child: Semantics(
              header: true,
              child: Text(
                label.toUpperCase(),
                key: key,
                style: type.label.copyWith(color: colors.textMuted),
              ),
            ),
          ),
        )
        ..addAll([
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.card),
              child: card,
            ),
        ]);
    }

    if (typical.isNotEmpty || typicalSaved.isNotEmpty) {
      final label = byStart
          ? l10n.patternGroupTypical(shiftName ?? '')
          : l10n.patternGroupIncluding(shiftName ?? '');
      section(label, [
        for (final p in typical) presetCard(p),
        for (final p in typicalSaved) savedCard(p),
      ], key: const ValueKey('pattern-group-typical'));
    }
    for (final entry in patternGroupPresets.entries) {
      section(groupLabels[entry.key]!, [
        for (final id in entry.value)
          if (!typicalIds.contains(id)) presetCard(patternPresetById(id)),
      ]);
    }
    section(l10n.patternGroupOther, [
      for (final p in ungroupedPresets())
        if (!typicalIds.contains(p.id)) presetCard(p),
    ]);
    section(l10n.patternGroupMine, [for (final p in restSaved) savedCard(p)]);

    final from = args.start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (from != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.m),
            child: Text(
              key: const ValueKey('pattern-from-day'),
              l10n.patternFromDay(
                format.weekdayDayMonth(
                  DateTime(from.year, from.month, from.day),
                ),
              ),
              style: type.body.copyWith(color: colors.textSecondary),
            ),
          ),
        AppCard(
          key: const ValueKey('pattern-create-own'),
          onTap: controller.startBuilding,
          semanticLabel: l10n.patternCreateOwn,
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: Disc.m,
                  child: Icon(AppIcons.add, color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.patternCreateOwn, style: type.bodyStrong),
                    Text(l10n.patternCreateOwnHint, style: type.meta),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...sections,
      ],
    );
  }
}

/// A pattern to pick: name, length, a line about it and its days as chips.
class PatternCard extends StatelessWidget {
  const PatternCard({
    super.key,
    required this.name,
    required this.description,
    required this.steps,
    required this.schedule,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String? description;
  final List<List<String>> steps;
  final Schedule schedule;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    return AppCard(
      onTap: onTap,
      borderColor: selected ? colors.todayRing : null,
      semanticLabel: '$name, ${l10n.patternCycleDays(steps.length)}',
      selected: selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and length on one line while the name's words fit beside
          // it, the length under the name when they do not («Correturno /
          // s» next to «21 días» at x2.0 on 320 dp, H-T06-3).
          ValueRow(
            title: Text(name, style: type.bodyStrong),
            value: Text(l10n.patternCycleDays(steps.length), style: type.meta),
            trailing: selected
                ? Icon(AppIcons.check, color: colors.textPrimary)
                : null,
          ),
          if (description != null) ...[
            const SizedBox(height: Sp.xs),
            Text(description!, style: type.meta),
          ],
          const SizedBox(height: Sp.m),
          SequenceChips(steps: steps, schedule: schedule),
        ],
      ),
    );
  }
}

// ---- step 2 -----------------------------------------------------------------

String patternFullDate(AppDateFormat format, CivilDate d) => capitalize(
  '${format.weekdayDayMonth(DateTime(d.year, d.month, d.day))} ${d.year}',
);

Future<CivilDate?> pickPatternDate(
  BuildContext context,
  CivilDate initial, {
  CivilDate? first,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: first == null
        ? DateTime(2000)
        : DateTime(first.year, first.month, first.day),
    lastDate: DateTime(2100),
  );
  return picked == null ? null : CivilDate.fromDateTime(picked);
}

/// A tappable date with its calendar icon.
class PatternDateTile extends StatelessWidget {
  const PatternDateTile({
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
    final type = context.type;
    return AppCard(
      onTap: onTap,
      semanticLabel: '$label: $value',
      child: Row(
        children: [
          Icon(AppIcons.calendar),
          const SizedBox(width: Sp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: type.meta),
                Text(value, style: type.bodyStrong),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight),
        ],
      ),
    );
  }
}

class _StartStep extends ConsumerWidget {
  const _StartStep({required this.args});

  final PatternWizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final provider = patternWizardProvider(args);
    final wizard = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final pattern = controller.chosenPattern(
      schedule,
      fallbackName: l10n.patternBuilderDefaultName,
    );
    if (pattern == null) return const SizedBox.shrink();
    final preset = wizard.presetId == null
        ? null
        : patternPresetById(wizard.presetId!);
    final offset = wizard.stepOffset % pattern.lengthDays;
    final shiftsThatDay = [
      for (final id in pattern.steps[offset])
        ?shiftTypeForDisplay(schedule, id),
    ];

    final suggested = preset?.suggestedStart;
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
        PatternDateTile(
          key: const ValueKey('pattern-start-date'),
          label: l10n.patternStartLabel,
          value: patternFullDate(format, wizard.start),
          onTap: () async {
            final picked = await pickPatternDate(context, wizard.start);
            if (picked != null) controller.setStart(picked);
          },
        ),
        if (suggested != null && wizard.start.weekday != suggested)
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
              DateTime(wizard.start.year, wizard.start.month, wizard.start.day),
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
              Builder(
                builder: (context) {
                  final shifts = [
                    for (final id in step) ?shiftTypeForDisplay(schedule, id),
                  ];
                  return StepChip(
                    key: ValueKey('offset-$i'),
                    size: Disc.m,
                    shifts: shifts,
                    selected: i == offset,
                    caption: '${i + 1}',
                    semanticsLabel: l10n.patternChipDay(
                      i + 1,
                      shiftsLine(l10n, format, shifts),
                    ),
                    onTap: () => controller.setStepOffset(i),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: Sp.m),
        Text(
          // «Mañana 06:00–14:00» wrapped between the hours at the dash.
          keepTimeRangesTogether(
            l10n.patternOffsetThatDay(shiftsLine(l10n, format, shiftsThatDay)),
          ),
          key: const ValueKey('pattern-offset-result'),
          style: type.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: Sp.section),
        _Preview(args: args),
      ],
    );
  }
}

// ---- step 3 -----------------------------------------------------------------

class _EndStep extends ConsumerWidget {
  const _EndStep({required this.args});

  final PatternWizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final provider = patternWizardProvider(args);
    final wizard = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final endless = wizard.until == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionTile(
          key: const ValueKey('pattern-end-never'),
          selected: endless,
          title: l10n.patternEndNever,
          subtitle: l10n.patternEndNeverHint,
          onTap: controller.setEndless,
        ),
        const SizedBox(height: Sp.card),
        _OptionTile(
          key: const ValueKey('pattern-end-until'),
          selected: !endless,
          title: l10n.patternEndUntil,
          subtitle: l10n.patternEndUntilHint,
          onTap: () {
            if (endless) controller.setUntil(wizard.start.addDays(89));
          },
        ),
        if (!endless) ...[
          const SizedBox(height: Sp.card),
          PatternDateTile(
            key: const ValueKey('pattern-until-date'),
            label: l10n.patternUntilLabel,
            value: patternFullDate(format, wizard.until!),
            onTap: () async {
              final picked = await pickPatternDate(
                context,
                wizard.until!,
                first: wizard.start,
              );
              if (picked != null) controller.setUntil(picked);
            },
          ),
        ],
        const SizedBox(height: Sp.section),
        Semantics(
          header: true,
          child: Text(l10n.patternOverridesTitle, style: type.bodyStrong),
        ),
        const SizedBox(height: Sp.s),
        _OptionTile(
          key: const ValueKey('pattern-keep-overrides'),
          selected: !wizard.clearOverrides,
          title: l10n.patternOverridesKeep,
          subtitle: l10n.patternOverridesKeepHint,
          onTap: () => controller.setClearOverrides(false),
        ),
        const SizedBox(height: Sp.card),
        _OptionTile(
          key: const ValueKey('pattern-replace-overrides'),
          selected: wizard.clearOverrides,
          title: l10n.patternOverridesReplace,
          subtitle: l10n.patternOverridesReplaceHint,
          onTap: () => controller.setClearOverrides(true),
        ),
        const SizedBox(height: Sp.section),
        _Preview(args: args),
      ],
    );
  }
}

/// A choice between a few options: selected, it gets the ring border and a
/// check (not colour alone).
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? colors.todayRing : null,
        semanticLabel: '$title. $subtitle',
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.bodyStrong),
                  const SizedBox(height: Sp.hair),
                  Text(subtitle, style: type.meta),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: Sp.s),
              Icon(AppIcons.check, color: colors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- preview ----------------------------------------------------------------

/// The result before applying: the start month and the next one.
class _Preview extends ConsumerWidget {
  const _Preview({required this.args});

  final PatternWizardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final wizard = ref.watch(patternWizardProvider(args));
    final plan = ref.watch(patternPreviewProvider(args));
    final first = wizard.start.firstDayOfMonth;
    final second = first.addDays(first.daysInMonth);

    return Column(
      key: const ValueKey('pattern-preview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.patternPreviewTitle, style: type.bodyStrong),
        ),
        const SizedBox(height: Sp.s),
        if (plan == null)
          Text(
            l10n.patternPreviewNone,
            style: type.body.copyWith(color: colors.textMuted),
          )
        else ...[
          if (plan.postNightDays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: Text(
                l10n.patternPreviewPostNight(plan.postNightDays.length),
                key: const ValueKey('pattern-preview-post-night'),
                style: type.meta,
              ),
            ),
          MiniMonth(month: first, schedule: plan.schedule),
          const SizedBox(height: Sp.l),
          MiniMonth(month: second, schedule: plan.schedule),
        ],
      ],
    );
  }
}
