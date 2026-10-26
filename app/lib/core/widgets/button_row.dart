import 'package:flutter/material.dart';

import '../format/text_measure.dart';
import '../theme/theme_context.dart';

/// One button of an [AdaptiveButtonRow]: the button itself, the [label] it
/// shows (to know how wide it needs to be) and its share of the row.
class ButtonRowItem {
  const ButtonRowItem({
    required this.label,
    required this.child,
    this.flex = 1,
    this.hasIcon = false,
  });

  final String label;
  final Widget child;

  /// Share of the row when the buttons are side by side.
  final int flex;

  /// The button carries an icon before its label.
  final bool hasIcon;
}

/// Buttons side by side while the longest word of every label fits in its
/// button; one under the other (full width) when it does not. At x2.0 on a
/// 320 dp phone «Atrás» next to «Siguiente» came out as «Atr / ás», and the
/// two time buttons of the shift form as «Empi / eza 17:0 / 0»
/// (H-T06-3, H-T05-2): a label may wrap between words, never inside one.
///
/// With [primaryFirstWhenStacked] the last item (the main action) goes on
/// top when they stack, where the thumb finds it first.
class AdaptiveButtonRow extends StatelessWidget {
  const AdaptiveButtonRow({
    super.key,
    required this.items,
    this.gap = Sp.s,
    this.primaryFirstWhenStacked = false,
  });

  final List<ButtonRowItem> items;
  final double gap;
  final bool primaryFirstWhenStacked;

  /// Horizontal padding of the buttons of the theme (`app_theme.dart`).
  static const double _padding = Sp.xl;

  /// Icon (20 dp) and the gap Material leaves between it and the label.
  static const double _iconAndGap = IconSize.button + 8;

  @override
  Widget build(BuildContext context) {
    final style = context.type.button;
    return LayoutBuilder(
      builder: (context, box) {
        final totalFlex = items.fold<int>(0, (sum, item) => sum + item.flex);
        final free = box.maxWidth - gap * (items.length - 1);
        var sideBySide = true;
        for (final item in items) {
          final share = free * item.flex / totalFlex;
          final need =
              longestWordWidth(context, item.label, style) +
              2 * _padding +
              (item.hasIcon ? _iconAndGap : 0);
          if (need > share) sideBySide = false;
        }
        if (sideBySide) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(flex: items[i].flex, child: items[i].child),
              ],
            ],
          );
        }
        final stacked = primaryFirstWhenStacked
            ? items.reversed.toList()
            : items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < stacked.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              stacked[i].child,
            ],
          ],
        );
      },
    );
  }
}
