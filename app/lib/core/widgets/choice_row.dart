import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/theme_context.dart';

/// One row of a list of choices in a bottom sheet: the label, and a check
/// when it is the current one. The communities, the municipalities and every
/// other single-choice sheet use this row, so they share the same indent,
/// height and trailing mark (H-T01-4: the two onboarding sheets used to
/// differ, one with a chevron and another indent, the other without).
///
/// The text starts [Sp.xs] inside the gutter of the sheet; in a sheet whose
/// list owns the whole width, wrap the row in a `Padding` of
/// [Sp.page] so the text lands at the same x.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.subtitle,
  });

  final String label;

  /// A second, quieter line (the province of a municipality whose name
  /// repeats).
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Minimum height of a row (a comfortable touch target).
  static const double minHeight = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: subtitle == null ? label : '$label, $subtitle',
      child: InkWell(
        borderRadius: Rad.rowRadius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.xs,
              vertical: Sp.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: selected ? type.bodyStrong : type.body,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: type.meta.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(AppIcons.check, color: colors.accentStrong, weight: 600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
