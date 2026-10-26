import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'shift_format.dart';
import 'shift_icon_glyph.dart';

/// The rounded square with a shift's code in its `ink` on its `disc`
/// (`docs/diseno.md`): the badge of the day detail and of the shift list.
///
/// A shift with an icon (docs/paridad.md, A8) shows it above the code when the
/// badge is big enough ([iconMinSize]); the code stays, so the badge never
/// depends on the icon.
class ShiftBadge extends StatelessWidget {
  const ShiftBadge({super.key, required this.shift, this.size = Disc.l});

  final ShiftType shift;
  final double size;

  /// Smallest badge that also draws the icon.
  static const double iconMinSize = Disc.m;

  /// Size of the icon above the code.
  static const double iconSize = 14;

  @override
  Widget build(BuildContext context) {
    final swatch = shift.swatch(context.colors.brightness);
    final icon = size >= iconMinSize ? shift.icon : null;
    final code = Text(
      shift.code,
      maxLines: 1,
      style: context.type.cellCode.copyWith(color: swatch.ink),
    );
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: swatch.disc,
          borderRadius: Rad.inputRadius,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(Sp.xs),
                child: icon == null
                    ? code
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShiftIconGlyph(
                            key: const ValueKey('badge-icon'),
                            icon: icon,
                            size: iconSize,
                            color: swatch.ink,
                          ),
                          code,
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
