import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../patterns/application/pattern_start_pick.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/paint_controller.dart';
import '../application/schedule_controller.dart';
import 'history_feedback.dart';
import 'puck_label.dart';
import 'shift_format.dart';
import 'shift_icon_glyph.dart';

/// Header of paint mode (`docs/diseno.md`, "Modo pintar"): "PINTANDO" in the
/// ink of the chosen shift, its name and hours, and the "Listo" button.
///
/// The header has the same height whichever shift is chosen, so the month
/// below it never moves when the user switches tools: the title is always ONE
/// line (the name gets the ellipsis, never the hours) and the label is never
/// broken. The title goes beside the buttons only when EVERY title of the
/// palette fits there whole; otherwise it goes under them, full width, for
/// every tool alike, so a name is only ever cut when it does not fit even in
/// the full width (H-T02-11: «Mañana» came out as «Mañ…» beside the buttons
/// because it was 8 dp short, with the gap next to the icon unused).
class PaintHeader extends ConsumerWidget {
  const PaintHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final paint = ref.watch(paintControllerProvider);
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );

    final shift = paint.shiftTypeId == null
        ? null
        : palette.where((t) => t.id == paint.shiftTypeId).firstOrNull;
    final labelColor = shift?.swatch(colors.brightness).ink ?? colors.textMuted;

    // Name and hours of the chosen tool and of every possible one. The hours
    // come with their separator (" · 08:00–15:00"), from the same template as
    // the full title.
    _TitleParts partsOf(ShiftType? s) {
      if (s == null) return _TitleParts(l10n.paintEraser, null);
      final times = s.timeRange(format);
      return _TitleParts(
        s.name,
        times == null ? null : l10n.paintHeaderShift('', times),
        times == null ? s.name : l10n.paintHeaderShift(s.name, times),
      );
    }

    final title = partsOf(shift);
    final all = [partsOf(null), for (final s in palette) partsOf(s)];

    final titleStyle = AppTypography.tabular(type.headline);
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: effectiveTextStyle(context, style)),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final lineHeight = scaler.scale(titleStyle.fontSize! * titleStyle.height!);
    final doneWidth = math.max(
      64.0,
      widthOf(l10n.paintDone, type.button) + 2 * Sp.xl,
    );
    final buttonsWidth = Sp.s + Sp.touch + Sp.xs + doneWidth;

    final label = Align(
      alignment: Alignment.centerLeft,
      // One line, whatever the size: it shrinks before it breaks.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.paintHeader.toUpperCase(),
          key: const ValueKey('paint-label'),
          maxLines: 1,
          softWrap: false,
          style: type.label.copyWith(color: labelColor),
        ),
      ),
    );

    final buttons = [
      const SizedBox(width: Sp.s),
      IconButton(
        key: const ValueKey('paint-pattern'),
        tooltip: l10n.patternButton,
        icon: Icon(AppIcons.pattern),
        onPressed: () =>
            context.push(patternWizardLocation(shiftTypeId: paint.shiftTypeId)),
      ),
      const SizedBox(width: Sp.xs),
      FilledButton(
        key: const ValueKey('paint-done'),
        onPressed: ref.read(paintControllerProvider.notifier).exit,
        child: Text(l10n.paintDone),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, 0),
      child: LayoutBuilder(
        builder: (context, box) {
          final beside = box.maxWidth - buttonsWidth;
          // Does every title fit on one line beside the buttons, name and
          // hours whole? If one does not, none goes there: they all take the
          // full width under the buttons.
          final fitsBeside = all.every(
            (t) => widthOf(t.full, titleStyle) <= beside,
          );
          final titleLine = _PaintTitle(
            key: const ValueKey('paint-title'),
            parts: title,
            style: titleStyle,
            height: lineHeight,
          );
          return Semantics(
            header: true,
            child: fitsBeside
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [label, titleLine],
                        ),
                      ),
                      ...buttons,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: label),
                          ...buttons,
                        ],
                      ),
                      titleLine,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// Name and hours of the tool shown in the paint header.
class _TitleParts {
  const _TitleParts(this.name, this.suffix, [String? full])
    : full = full ?? name;

  final String name;

  /// " · 08:00–15:00", or null when the tool has no hours.
  final String? suffix;

  /// The whole title: "Mañana · 08:00–15:00".
  final String full;

  /// The least the title can be on one line without shrinking: the first
  /// letter of the name, the ellipsis and the hours.
  String get shortest {
    if (suffix == null) return full;
    final first = name.isEmpty ? '' : name.substring(0, 1);
    return '$first…$suffix';
  }
}

/// The title of the paint header: "Mañana · 08:00–15:00" on ONE line of a
/// fixed [height]. If it does not fit, the name is cut with an ellipsis and
/// the hours stay whole; if not even that fits, the whole line shrinks.
class _PaintTitle extends StatelessWidget {
  const _PaintTitle({
    super.key,
    required this.parts,
    required this.style,
    required this.height,
  });

  final _TitleParts parts;
  final TextStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: effectiveTextStyle(context, style)),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final suffix = parts.suffix;
          if (widthOf(parts.full) <= box.maxWidth) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                parts.full,
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            );
          }
          if (suffix != null && widthOf(parts.shortest) <= box.maxWidth) {
            return Row(
              children: [
                Flexible(
                  child: Text(
                    parts.name,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
                Text(suffix, maxLines: 1, softWrap: false, style: style),
              ],
            );
          }
          // Not even the hours fit: the whole line shrinks.
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(parts.full, maxLines: 1, softWrap: false, style: style),
          );
        },
      ),
    );
  }
}

/// Bottom sheet of paint mode: a round puck per shift (disc + ink code, name
/// below, the selected one ringed), the eraser, "Doblar" and round
/// undo / redo. Long-pressing a puck starts "aplicar patrón desde este día":
/// the next day tapped is where the pattern wizard begins.
class PaintBar extends ConsumerWidget {
  const PaintBar({super.key, this.card = false});

  /// In the pane of the two-pane month: a rounded card with the margin of the
  /// other cards of the pane, not a bar stuck to the bottom of the screen.
  final bool card;

  /// The most of the screen height the tools may take before they scroll.
  static const double _toolsMaxHeightShare = 0.25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final paint = ref.watch(paintControllerProvider);
    final history = ref.watch(scheduleControllerProvider);
    final paintController = ref.read(paintControllerProvider.notifier);
    final scheduleController = ref.read(scheduleControllerProvider.notifier);
    final shiftTypes = history.palette;

    void patternFrom(String? shiftTypeId) =>
        ref.read(patternStartPickProvider.notifier).begin(shiftTypeId);

    ButtonStyle roundStyle() => IconButton.styleFrom(
      fixedSize: const Size.square(Disc.round),
      backgroundColor: colors.surfaceRaised,
      disabledBackgroundColor: colors.surfaceRaised,
      foregroundColor: colors.textPrimary,
      disabledForegroundColor: colors.textMuted,
      shape: const CircleBorder(),
    );

    return Semantics(
      container: true,
      label: l10n.paintToolsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: card
              ? const BorderRadius.all(Radius.circular(Rad.sheet))
              : const BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: card ? null : 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sp.maxContentWidth),
              child: Column(
                mainAxisSize: card ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  // The tools wrap onto as many lines as they need, never a
                  // single row cut mid-word (H-T17-3, H-T21-9); with many
                  // shift types the area scrolls vertically, at most a
                  // share of the screen, so the month keeps its room.
                  _PaletteArea(
                    expanded: card,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: card
                            ? double.infinity
                            : MediaQuery.sizeOf(context).height *
                                  _toolsMaxHeightShare,
                      ),
                      child: SingleChildScrollView(
                        key: const ValueKey('paint-tools-scroll'),
                        padding: const EdgeInsets.fromLTRB(
                          Sp.page - Sp.s,
                          Sp.l,
                          Sp.page - Sp.s,
                          Sp.s,
                        ),
                        child: Wrap(
                          key: const ValueKey('paint-tools-wrap'),
                          alignment: card
                              ? WrapAlignment.spaceEvenly
                              : WrapAlignment.start,
                          runSpacing: card ? Sp.l : 0,
                          spacing: Sp.xs,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            _Puck(
                              key: const ValueKey('tool-eraser'),
                              label: l10n.paintEraser,
                              selected: paint.erasing,
                              disc: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.surfaceMuted,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.borderStrong,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    AppIcons.erase,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              onTap: paintController.selectEraser,
                              onLongPress: () => patternFrom(null),
                            ),
                            for (final shift in shiftTypes)
                              _Puck(
                                key: ValueKey('tool-${shift.id}'),
                                label: shift.name,
                                selected: paint.shiftTypeId == shift.id,
                                disc: _ShiftDisc(shift: shift),
                                onTap: () =>
                                    paintController.selectShift(shift.id),
                                onLongPress: () {
                                  paintController.selectShift(shift.id);
                                  patternFrom(shift.id);
                                },
                              ),
                            _Puck(
                              key: const ValueKey('tool-edit-types'),
                              label: l10n.shiftTypesEditEntry,
                              selected: false,
                              disc: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.borderStrong,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    AppIcons.edit,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              onTap: () => context.push(AppRoutes.shiftTypes),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Sp.page,
                      Sp.xs,
                      Sp.page,
                      Sp.l,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: _DoubleChip(
                                key: const ValueKey('tool-double'),
                                label: l10n.paintDouble,
                                selected: paint.doubling && !paint.erasing,
                                enabled: !paint.erasing,
                                onTap: paintController.toggleDoubling,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('undo'),
                          tooltip: l10n.undo,
                          style: roundStyle(),
                          icon: Icon(AppIcons.undo),
                          onPressed: history.canUndo
                              ? () => undoWithFeedback(
                                  context,
                                  scheduleController,
                                )
                              : null,
                        ),
                        const SizedBox(width: Sp.s),
                        IconButton(
                          key: const ValueKey('redo'),
                          tooltip: l10n.redo,
                          style: roundStyle(),
                          icon: Icon(AppIcons.redo),
                          onPressed: history.canRedo
                              ? () => redoWithFeedback(
                                  context,
                                  scheduleController,
                                )
                              : null,
                        ),
                      ],
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

/// The pane gives the palette all the room between header and actions.
class _PaletteArea extends StatelessWidget {
  const _PaletteArea({required this.expanded, required this.child});
  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      expanded ? Expanded(child: child) : child;
}

/// A round 54 dp tool with its name below. The selected one gets a 2.5 dp
/// ring in `todayRing`, 3 dp away, and a bolder name (not colour alone).
class _Puck extends StatelessWidget {
  const _Puck({
    super.key,
    required this.label,
    required this.selected,
    required this.disc,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;

  /// Content of the 54 dp circle.
  final Widget disc;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const double _minWidth = Disc.puck + 2 * Sp.s;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final labelStyle = type.caption.copyWith(
      color: selected ? colors.textPrimary : colors.textMuted,
      fontWeight: selected ? FontWeight.w800 : null,
    );
    // Grows with the text size and the name: never abbreviated, never stuck
    // to the next puck.
    final width = puckWidth(
      context,
      label: label,
      style: labelStyle.copyWith(fontWeight: FontWeight.w800),
      minWidth: _minWidth,
    );
    const ringOutset = Sp.selectionGap + Sp.selectionRing / 2;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Sp.s),
              SizedBox.square(
                dimension: Disc.puck,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    disc,
                    if (selected)
                      Positioned(
                        left: -ringOutset,
                        top: -ringOutset,
                        right: -ringOutset,
                        bottom: -ringOutset,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.todayRing,
                                width: Sp.selectionRing,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.s),
              PuckLabel(label: label, style: labelStyle),
              const SizedBox(height: Sp.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shift's `disc` with its code in the `ink`.
class _ShiftDisc extends StatelessWidget {
  const _ShiftDisc({required this.shift});

  final ShiftType shift;

  @override
  Widget build(BuildContext context) {
    final swatch = shift.swatch(context.colors.brightness);
    return DecoratedBox(
      decoration: BoxDecoration(color: swatch.disc, shape: BoxShape.circle),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(Sp.s),
            child: ShiftCodeWithIcon(
              shift: shift,
              style: context.type.headline.copyWith(color: swatch.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Doblar": a bordered chip that toggles adding instead of replacing. On, it
/// gets a check instead of the plus and the border of the selection ring.
class _DoubleChip extends StatelessWidget {
  const _DoubleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
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
      enabled: enabled,
      toggled: selected,
      excludeSemantics: true,
      label: label,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: selected ? colors.surfaceRaised : Colors.transparent,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: enabled ? onTap : null,
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
      ),
    );
  }
}
