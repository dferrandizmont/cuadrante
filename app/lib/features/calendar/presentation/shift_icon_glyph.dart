import 'package:flutter/widgets.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/theme_context.dart';
import '../../schedule/domain/schedule_domain.dart';

/// The symbol that draws each [ShiftIcon] (docs/paridad.md, A8). The domain
/// only knows the key; the glyph set (SF-style on iOS, Material Symbols
/// rounded on Android) lives in [AppIcons]. An exhaustive `switch`: a new key
/// does not compile until it has a symbol.
extension ShiftIconData on ShiftIcon {
  IconData get data => switch (this) {
    ShiftIcon.sun => AppIcons.shiftSun,
    ShiftIcon.moon => AppIcons.shiftMoon,
    ShiftIcon.sunrise => AppIcons.shiftSunrise,
    ShiftIcon.hospital => AppIcons.shiftHospital,
    ShiftIcon.ambulance => AppIcons.shiftAmbulance,
    ShiftIcon.police => AppIcons.shiftPolice,
    ShiftIcon.fire => AppIcons.shiftFire,
    ShiftIcon.factory => AppIcons.shiftFactory,
    ShiftIcon.truck => AppIcons.shiftTruck,
    ShiftIcon.plane => AppIcons.shiftPlane,
    ShiftIcon.school => AppIcons.shiftSchool,
    ShiftIcon.home => AppIcons.shiftHome,
    ShiftIcon.beach => AppIcons.shiftBeach,
    ShiftIcon.bed => AppIcons.shiftBed,
    ShiftIcon.star => AppIcons.shiftStar,
    ShiftIcon.heart => AppIcons.shiftHeart,
    ShiftIcon.coffee => AppIcons.shiftCoffee,
    ShiftIcon.book => AppIcons.shiftBook,
    ShiftIcon.money => AppIcons.shiftMoney,
    ShiftIcon.alert => AppIcons.shiftAlert,
    ShiftIcon.phone => AppIcons.shiftPhone,
    ShiftIcon.car => AppIcons.shiftCar,
    ShiftIcon.train => AppIcons.shiftTrain,
    ShiftIcon.bus => AppIcons.shiftBus,
    ShiftIcon.shop => AppIcons.shiftShop,
    ShiftIcon.tool => AppIcons.shiftTool,
    ShiftIcon.baby => AppIcons.shiftBaby,
    ShiftIcon.sport => AppIcons.shiftSport,
    ShiftIcon.party => AppIcons.shiftParty,
    ShiftIcon.medical => AppIcons.shiftMedical,
  };
}

/// [icon] drawn at [size] in [color]. Decorative: the name of the shift
/// already says everything, so it carries no semantics of its own.
class ShiftIconGlyph extends StatelessWidget {
  const ShiftIconGlyph({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  final ShiftIcon icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(icon.data, size: size, color: color),
  );
}

/// The code of [shift] in [style] with its icon (if it has one) above it, for
/// the round pucks of the paint tools and the day detail. Put it inside a
/// `FittedBox(fit: BoxFit.scaleDown)`: the code is never dropped, the pair
/// just shrinks to fit.
class ShiftCodeWithIcon extends StatelessWidget {
  const ShiftCodeWithIcon({
    super.key,
    required this.shift,
    required this.style,
    this.iconSize = 12,
  });

  final ShiftType shift;
  final TextStyle style;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final code = Text(shift.code, maxLines: 1, style: style);
    final icon = shift.icon;
    if (icon == null) return code;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShiftIconGlyph(
          key: const ValueKey('puck-icon'),
          icon: icon,
          size: iconSize,
          color: style.color ?? context.colors.textPrimary,
        ),
        code,
      ],
    );
  }
}
