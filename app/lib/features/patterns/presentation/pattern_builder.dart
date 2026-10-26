import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/section_header.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/pattern_wizard.dart';
import '../domain/pattern_catalog.dart';
import 'step_chips.dart';

/// "Crear el mío": the sequence builder. Tapping a shift adds a day to the
/// cycle (or, with "Varios turnos en un día", one more shift to the last
/// day); the chips show the cycle so far.
class PatternBuilder extends ConsumerStatefulWidget {
  const PatternBuilder({super.key, required this.args});

  final PatternWizardArgs args;

  @override
  ConsumerState<PatternBuilder> createState() => _PatternBuilderState();
}

class _PatternBuilderState extends ConsumerState<PatternBuilder> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(patternWizardProvider(widget.args)).draftName,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final provider = patternWizardProvider(widget.args);
    final wizard = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    // Names wrap between words under the puck, so each puck is as wide as the
    // longest word of any name.
    final puckWidth = palette.fold<double>(
      _BuilderPuck.minWidth,
      (widest, shift) => math.max(
        widest,
        longestWordWidth(context, shift.name, type.caption) + 2 * Sp.xs,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('builder-back'),
            onPressed: controller.stopBuilding,
            icon: Icon(AppIcons.back, size: IconSize.button),
            label: Text(l10n.patternBuilderBack),
          ),
        ),
        LabeledField(
          label: l10n.patternBuilderName,
          child: TextField(
            key: const ValueKey('builder-name'),
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: l10n.patternBuilderDefaultName,
              counterText: '',
            ),
            onChanged: controller.setName,
          ),
        ),
        const SizedBox(height: Sp.section),
        SectionHeader(
          l10n.patternBuilderSequence,
          trailing: Text(
            l10n.patternCycleDays(wizard.draft.length),
            key: const ValueKey('builder-length'),
            style: type.meta,
          ),
        ),
        if (wizard.draft.isEmpty)
          Text(
            l10n.patternBuilderEmpty,
            style: type.body.copyWith(color: colors.textMuted),
          )
        else
          Wrap(
            key: const ValueKey('builder-sequence'),
            spacing: Sp.xs,
            runSpacing: Sp.xs,
            children: [
              for (final (i, step) in wizard.draft.indexed)
                StepChip(
                  key: ValueKey('builder-step-$i'),
                  size: Disc.m,
                  shifts: [
                    for (final id in step) ?shiftTypeForDisplay(schedule, id),
                  ],
                  caption: '${i + 1}',
                ),
            ],
          ),
        const SizedBox(height: Sp.l),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _BuilderChip(
                    key: const ValueKey('builder-same-day'),
                    label: l10n.patternBuilderSameDay,
                    selected: wizard.sameDay,
                    onTap: () => controller.setSameDay(!wizard.sameDay),
                  ),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('builder-remove-last'),
              tooltip: l10n.patternBuilderRemoveLast,
              icon: Icon(AppIcons.undo),
              onPressed: wizard.draft.isEmpty ? null : controller.removeLast,
            ),
            IconButton(
              key: const ValueKey('builder-clear'),
              tooltip: l10n.patternBuilderClear,
              icon: Icon(AppIcons.erase),
              onPressed: wizard.draft.isEmpty ? null : controller.clearDraft,
            ),
          ],
        ),
        // What the chip does is not obvious: a tap adds a day, except with
        // the chip on, when it adds to the last one (H-T06-4).
        if (wizard.sameDay)
          Padding(
            padding: const EdgeInsets.only(top: Sp.xs),
            child: Text(
              l10n.patternBuilderSameDayHint,
              key: const ValueKey('builder-same-day-hint'),
              style: type.meta,
            ),
          ),
        const SizedBox(height: Sp.s),
        // All the shifts in sight, wrapping onto as many lines as needed: a
        // row that scrolled sideways cut «Vac» at the edge with nothing to
        // say there was more (H-T06-5).
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            for (final shift in palette)
              _BuilderPuck(
                key: ValueKey('builder-add-${shift.id}'),
                shift: shift,
                width: puckWidth,
                onTap: () => controller.appendShift(shift.id),
              ),
          ],
        ),
      ],
    );
  }
}

/// A round shift to tap, like the pucks of paint mode.
class _BuilderPuck extends StatelessWidget {
  const _BuilderPuck({
    super.key,
    required this.shift,
    required this.width,
    required this.onTap,
  });

  final ShiftType shift;
  final double width;
  final VoidCallback onTap;

  static const double minWidth = Disc.puck + 2 * Sp.s;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final swatch = shift.swatch(colors.brightness);
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: l10n.patternBuilderAdd(shift.name),
      onTap: onTap,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Sp.s),
              SizedBox.square(
                dimension: Disc.puck,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: swatch.disc,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(Sp.s),
                        child: Text(
                          shift.code,
                          maxLines: 1,
                          style: context.type.headline.copyWith(
                            color: swatch.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.s),
              Text(
                shift.name,
                textAlign: TextAlign.center,
                style: context.type.caption.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: Sp.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bordered toggle chip ("Varios turnos en un día"): on, it gets a check
/// and the ring border (not colour alone).
class _BuilderChip extends StatelessWidget {
  const _BuilderChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected ? colors.todayRing : colors.borderStrong,
        width: selected ? Sp.ring : 1,
      ),
    );
    return Semantics(
      container: true,
      button: true,
      toggled: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: Material(
        color: selected ? colors.surfaceRaised : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sp.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.l),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? AppIcons.check : AppIcons.add,
                    size: IconSize.inline,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: Sp.s),
                  Text(
                    label,
                    style: context.type.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
