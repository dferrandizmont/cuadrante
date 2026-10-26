import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Label (`meta`) above a field, optional helper below. The field itself is a
/// borderless `surfaceMuted` input from the theme.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
    this.gap = Sp.s,
  });

  final String label;
  final String? helper;
  final Widget child;

  /// Space between the label and the field.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    // A single input owns its visible label. Groups keep their heading and
    // their independently named choices instead of merging their actions.
    final input = child is TextField || child is TextFormField;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: ExcludeSemantics(
            excluding: input,
            child: Text(label, style: type.meta),
          ),
        ),
        if (input) Semantics(label: label, child: child) else child,
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: Sp.xs),
            child: Text(helper!, style: type.meta),
          ),
      ],
    );
  }
}
