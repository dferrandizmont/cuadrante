import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'app_sheet.dart';
import 'choice_row.dart';

class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label);
  final T value;
  final String label;
}

/// Calm bottom sheet with a single-choice list (language, appearance …).
/// Returns the picked value, or null when dismissed.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<ChoiceOption<T>> options,
  required T selected,
}) {
  return showAppSheet<T>(
    context: context,
    padded: true,
    builder: (ctx) {
      final type = ctx.type;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.m),
            child: Semantics(
              header: true,
              child: Text(title, style: type.headline),
            ),
          ),
          for (final o in options)
            ChoiceRow(
              label: o.label,
              selected: o.value == selected,
              onTap: () => Navigator.pop(ctx, o.value),
            ),
        ],
      );
    },
  );
}
