import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/icons/parity_icons.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';

/// The colours a shift can take: the eight of the specification and a grid of
/// extra hues, as round swatches. The selected one gets the `todayRing` ring
/// and a check (never colour alone). What each colour looks like in the
/// calendar is shown by the preview; the swatch only needs to be recognisable.
class ShiftColorGrid extends StatelessWidget {
  const ShiftColorGrid({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onMore,
  });

  /// ARGB value of the current colour.
  final int selected;
  final ValueChanged<int> onChanged;

  /// «Más colores…»: opens the free colour picker. Without it the button is
  /// not shown.
  final VoidCallback? onMore;

  static const double _size = Disc.l;

  @override
  Widget build(BuildContext context) {
    final choices = ShiftPalette.editorChoices;
    final inChoices = choices.any((c) => c.toARGB32() == selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Sp.xs,
          runSpacing: Sp.xs,
          children: [
            for (final (index, color) in choices.indexed)
              _Swatch(
                key: ValueKey(
                  'shift-color-${color.toARGB32().toRadixString(16)}',
                ),
                color: color,
                label: context.l10n.shiftTypesColorOptionNamed(
                  shiftColorNames(context.l10n)[index],
                  index + 1,
                  choices.length,
                ),
                selected: color.toARGB32() == selected,
                onTap: () => onChanged(color.toARGB32()),
              ),
            // A colour from outside the grid: stored before, by a backup or
            // picked with «Más colores». Tapping it reopens the picker.
            if (!inChoices)
              _Swatch(
                key: const ValueKey('shift-color-current'),
                color: Color(selected),
                label: context.l10n.shiftTypesColorCurrent,
                selected: true,
                onTap: onMore ?? () {},
              ),
          ],
        ),
        if (onMore != null) ...[
          const SizedBox(height: Sp.s),
          SecondaryButton(
            key: const ValueKey('shift-color-more'),
            label: context.l10n.shiftTypesColorMore,
            icon: ParityIcons.palette,
            onPressed: onMore,
          ),
        ],
      ],
    );
  }
}

/// The name of each colour of [ShiftPalette.editorChoices], in the same
/// order, for whoever cannot see the swatch («Naranja, 1 de 24»).
List<String> shiftColorNames(AppLocalizations l10n) => [
  l10n.shiftColorNameOrange,
  l10n.shiftColorNameCoral,
  l10n.shiftColorNameIndigo,
  l10n.shiftColorNameLightGrey,
  l10n.shiftColorNameRed,
  l10n.shiftColorNameLilac,
  l10n.shiftColorNameGreen,
  l10n.shiftColorNameTeal,
  l10n.shiftColorNameRaspberry,
  l10n.shiftColorNamePink,
  l10n.shiftColorNameTangerine,
  l10n.shiftColorNameYellow,
  l10n.shiftColorNameLime,
  l10n.shiftColorNameForest,
  l10n.shiftColorNameMint,
  l10n.shiftColorNameCyan,
  l10n.shiftColorNameSkyBlue,
  l10n.shiftColorNameBlue,
  l10n.shiftColorNameCobalt,
  l10n.shiftColorNameViolet,
  l10n.shiftColorNamePurple,
  l10n.shiftColorNameBrown,
  l10n.shiftColorNameGrey,
  l10n.shiftColorNameGraphite,
];

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The swatch of the theme: Libre (grey) and the dark lift of Noche look
    // as they will in the calendar, not as the raw stored value.
    final swatch = ShiftSwatch.forColor(color.toARGB32(), colors.brightness);
    final fill = swatch.isRest ? swatch.disc : swatch.bar;
    final checkColor =
        contrastRatio(colors.textPrimary, fill) >=
            contrastRatio(colors.background, fill)
        ? colors.textPrimary
        : colors.background;
    const ringOutset = Sp.selectionGap + Sp.selectionRing / 2;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          // Room for the ring and a 48 dp target.
          dimension: Sp.touch,
          child: Center(
            child: SizedBox.square(
              dimension: ShiftColorGrid._size,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                      // Libre is grey on grey: it needs its outline.
                      border: swatch.isRest
                          ? Border.all(color: colors.borderStrong, width: 1.5)
                          : null,
                    ),
                    child: selected
                        ? Icon(AppIcons.check, color: checkColor, weight: 700)
                        : null,
                  ),
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
          ),
        ),
      ),
    );
  }
}
