import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';

/// The colour dot of a calendar (switcher pill, list rows, colour picker).
///
/// Decoration only: the name always sits next to it. In dark mode a colour
/// that would sink into the background (the indigo of the night shift) is
/// lifted the same way the shift bars are, so the dot stays visible.
class CalendarDot extends StatelessWidget {
  const CalendarDot({super.key, required this.colorValue, this.size = 12});

  /// ARGB, as stored with the calendar.
  final int colorValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = ShiftSwatch.forColor(
      colorValue,
      context.colors.brightness,
    ).bar;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
