import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import 'import_icons.dart';

/// A row with a label and a date at the right that opens a date picker
/// (the range of the import and of the export).
class ImportDateRow extends StatelessWidget {
  const ImportDateRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sp.touch + Sp.s),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.l,
              vertical: Sp.m,
            ),
            // Large text: the label above the date, so neither is cut.
            child: context.largeText
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: type.body),
                            Text(
                              value,
                              style: type.bodyStrong.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Sp.s),
                      Icon(
                        ImportIcons.pickDate,
                        size: IconSize.button,
                        color: colors.textMuted,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: Text(label, style: type.body)),
                      Text(
                        value,
                        style: type.bodyStrong.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: Sp.s),
                      Icon(
                        ImportIcons.pickDate,
                        size: IconSize.button,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
