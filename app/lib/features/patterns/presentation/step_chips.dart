import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/pattern_catalog.dart';

/// One day of a pattern as a small chip: the `disc` and `ink` of its shift
/// with the code (several shifts: one band each; no shift: a dash). The
/// selected one is ringed in `todayRing`, with [caption] (the day number)
/// below when given. Never colour alone: the code is always drawn.
class StepChip extends StatelessWidget {
  const StepChip({
    super.key,
    required this.shifts,
    this.size = Disc.s,
    this.selected = false,
    this.caption,
    this.onTap,
    this.semanticsLabel,
  });

  final List<ShiftType> shifts;

  /// Side of the chip (a [Disc] size).
  final double size;
  final bool selected;

  /// Small text under the chip (the day of the cycle).
  final String? caption;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final brightness = colors.brightness;

    final chip = ClipRRect(
      borderRadius: Rad.chipSmallRadius,
      child: SizedBox.square(
        dimension: size,
        child: shifts.isEmpty
            ? ColoredBox(
                color: colors.surfaceMuted,
                child: Center(
                  child: Text(
                    '–',
                    style: type.caption.copyWith(color: colors.textMuted),
                  ),
                ),
              )
            : Column(
                children: [
                  for (final shift in shifts)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final swatch = shift.swatch(brightness);
                          return ColoredBox(
                            color: swatch.disc,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(Sp.hair),
                                  child: Text(
                                    shift.code,
                                    maxLines: 1,
                                    style: type.caption.copyWith(
                                      color: swatch.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );

    // The ring takes its room even when off, so selecting never moves things.
    final ringed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Rad.chipSmall + Sp.selectionGap + Sp.selectionRing,
        ),
        border: Border.all(
          color: selected ? colors.todayRing : Colors.transparent,
          width: Sp.selectionRing,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.selectionGap),
        child: chip,
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ringed,
        if (caption != null)
          Text(
            caption!,
            style: AppTypography.tabular(
              type.caption.copyWith(
                color: selected ? colors.textPrimary : colors.textMuted,
                fontWeight: selected ? FontWeight.w800 : null,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return semanticsLabel == null
          ? content
          : Semantics(
              container: true,
              label: semanticsLabel,
              excludeSemantics: true,
              child: content,
            );
    }
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
        onTap: onTap,
        // The chip keeps its look; the touch area reaches 48 x 48 dp
        // (H-T18-1: it was 42 wide).
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Sp.touch,
            minHeight: Sp.touch,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        ),
      ),
    );
  }
}

/// All the days of a pattern as [StepChip]s, wrapping onto several lines.
class SequenceChips extends StatelessWidget {
  const SequenceChips({
    super.key,
    required this.steps,
    required this.schedule,
    this.size = Disc.s,
    this.keyPrefix,
  });

  final List<List<String>> steps;
  final Schedule schedule;
  final double size;

  /// Gives each chip the key `<prefix>-<index>`.
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Sp.xs,
      runSpacing: Sp.xs,
      children: [
        for (final (i, step) in steps.indexed)
          StepChip(
            key: keyPrefix == null ? null : ValueKey('$keyPrefix-$i'),
            size: size,
            shifts: [for (final id in step) ?shiftTypeForDisplay(schedule, id)],
          ),
      ],
    );
  }
}
