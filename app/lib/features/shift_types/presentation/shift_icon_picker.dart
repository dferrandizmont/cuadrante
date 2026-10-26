import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../calendar/presentation/shift_icon_glyph.dart';
import '../../schedule/domain/schedule_domain.dart';

/// The name of [icon] in words, for the picker and for screen readers.
String shiftIconName(AppLocalizations l10n, ShiftIcon icon) => switch (icon) {
  ShiftIcon.sun => l10n.shiftIconNameSun,
  ShiftIcon.moon => l10n.shiftIconNameMoon,
  ShiftIcon.sunrise => l10n.shiftIconNameSunrise,
  ShiftIcon.hospital => l10n.shiftIconNameHospital,
  ShiftIcon.ambulance => l10n.shiftIconNameAmbulance,
  ShiftIcon.police => l10n.shiftIconNamePolice,
  ShiftIcon.fire => l10n.shiftIconNameFire,
  ShiftIcon.factory => l10n.shiftIconNameFactory,
  ShiftIcon.truck => l10n.shiftIconNameTruck,
  ShiftIcon.plane => l10n.shiftIconNamePlane,
  ShiftIcon.school => l10n.shiftIconNameSchool,
  ShiftIcon.home => l10n.shiftIconNameHome,
  ShiftIcon.beach => l10n.shiftIconNameBeach,
  ShiftIcon.bed => l10n.shiftIconNameBed,
  ShiftIcon.star => l10n.shiftIconNameStar,
  ShiftIcon.heart => l10n.shiftIconNameHeart,
  ShiftIcon.coffee => l10n.shiftIconNameCoffee,
  ShiftIcon.book => l10n.shiftIconNameBook,
  ShiftIcon.money => l10n.shiftIconNameMoney,
  ShiftIcon.alert => l10n.shiftIconNameAlert,
  ShiftIcon.phone => l10n.shiftIconNamePhone,
  ShiftIcon.car => l10n.shiftIconNameCar,
  ShiftIcon.train => l10n.shiftIconNameTrain,
  ShiftIcon.bus => l10n.shiftIconNameBus,
  ShiftIcon.shop => l10n.shiftIconNameShop,
  ShiftIcon.tool => l10n.shiftIconNameTool,
  ShiftIcon.baby => l10n.shiftIconNameBaby,
  ShiftIcon.sport => l10n.shiftIconNameSport,
  ShiftIcon.party => l10n.shiftIconNameParty,
  ShiftIcon.medical => l10n.shiftIconNameMedical,
};

/// «Icono» of the shift type form (docs/paridad.md, A8): a button that shows
/// the current icon (or «Sin icono») and opens a grid with the whole set
/// ([ShiftIcon.values]) plus «Sin icono». Self-contained: the form only gives
/// it the [selected] icon and gets the new one back through [onChanged]
/// (`null` = no icon).
class ShiftIconField extends StatelessWidget {
  const ShiftIconField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ShiftIcon? selected;
  final ValueChanged<ShiftIcon?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showAppSheet<({ShiftIcon? icon})>(
      context: context,
      padded: true,
      builder: (_) => _ShiftIconSheet(selected: selected),
    );
    // Dismissing the sheet changes nothing; «Sin icono» answers with null.
    if (picked != null) onChanged(picked.icon);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = selected;
    return LabeledField(
      label: l10n.shiftTypesIconLabel,
      helper: l10n.shiftTypesIconHelper,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SecondaryButton(
          key: const ValueKey('shift-icon'),
          icon: current?.data ?? AppIcons.noIcon,
          label: current == null
              ? l10n.shiftTypesIconNone
              : l10n.shiftTypesIconCurrent(shiftIconName(l10n, current)),
          expand: false,
          onPressed: () => _open(context),
        ),
      ),
    );
  }
}

class _ShiftIconSheet extends StatelessWidget {
  const _ShiftIconSheet({required this.selected});

  final ShiftIcon? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.shiftTypesIconChoose, style: type.headline),
        ),
        const SizedBox(height: Sp.m),
        Wrap(
          key: const ValueKey('shift-icon-grid'),
          spacing: Sp.xs,
          runSpacing: Sp.xs,
          children: [
            _IconTile(
              key: const ValueKey('shift-icon-none'),
              icon: AppIcons.noIcon,
              label: l10n.shiftTypesIconNone,
              selected: selected == null,
              onTap: () => Navigator.of(context).pop((icon: null)),
            ),
            for (final icon in ShiftIcon.values)
              _IconTile(
                key: ValueKey('shift-icon-${icon.key}'),
                icon: icon.data,
                label: shiftIconName(l10n, icon),
                selected: icon == selected,
                onTap: () => Navigator.of(context).pop((icon: icon)),
              ),
          ],
        ),
      ],
    );
  }
}

/// One cell of the grid: a 48 dp target with the glyph; the chosen one gets
/// the `todayRing` ring and a check, so it is never colour alone.
class _IconTile extends StatelessWidget {
  const _IconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: Rad.inputRadius),
          child: SizedBox.square(
            dimension: Sp.touch,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: Rad.inputRadius,
                color: selected ? colors.surfaceRaised : null,
                border: selected
                    ? Border.all(color: colors.todayRing, width: Sp.ring)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: colors.textPrimary),
                  if (selected)
                    // A filled disc, like the mark of a chosen day: the bare
                    // 12 dp check was too small to see (H-T05-6).
                    Positioned(
                      right: Sp.hair,
                      bottom: Sp.hair,
                      child: DecoratedBox(
                        key: const ValueKey('shift-icon-selected-mark'),
                        decoration: BoxDecoration(
                          color: colors.isDark
                              ? colors.highlight
                              : colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.hair),
                          child: Icon(
                            AppIcons.check,
                            size: 14,
                            color: colors.isDark
                                ? colors.onHighlight
                                : colors.onAccent,
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
