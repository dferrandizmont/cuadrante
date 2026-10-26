import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'value_row.dart';

/// Section heading (`headline`) with an optional quiet trailing text/widget.
/// Callers leave 24 dp between sections; the header adds 12 below itself.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.text, {
    super.key,
    this.trailing,
    this.eyebrow,
    this.padding = const EdgeInsets.only(bottom: Sp.m),
  });

  final String text;
  final Widget? trailing;

  /// Small line above the heading (e.g. a date).
  final String? eyebrow;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final heading = Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) Text(eyebrow!, style: type.caption),
          Text(text, style: type.headline),
        ],
      ),
    );
    // The trailing text goes under the heading when the heading's words and
    // it do not fit on one line («Tu secuenci / a» next to «7 días» at x2.0
    // on 320 dp, H-T06-3).
    return Padding(
      padding: padding,
      child: trailing == null
          ? SizedBox(width: double.infinity, child: heading)
          : ValueRow(
              crossAxisAlignment: CrossAxisAlignment.end,
              title: heading,
              value: trailing,
            ),
    );
  }
}
