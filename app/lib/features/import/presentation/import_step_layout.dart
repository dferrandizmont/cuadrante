import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';

/// Padding of every step of the wizard.
const EdgeInsets importStepPadding = EdgeInsets.fromLTRB(
  Sp.page,
  Sp.s,
  Sp.page,
  Sp.section,
);

/// A step whose content is short: it scrolls as a whole.
class ImportStepScroll extends StatelessWidget {
  const ImportStepScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: importStepPadding, child: child);
  }
}
