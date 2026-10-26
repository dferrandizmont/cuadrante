import 'package:flutter/material.dart';

import '../../../core/format/text_measure.dart';
import '../../../core/theme/theme_context.dart';

/// Width of a round tool ("puck") of a row of shifts, such that its name below
/// is never cut and never touches the next puck's name.
///
/// [minWidth] is the width of the puck at normal text. The name stays on one
/// line while that line is not much wider than a puck; a longer name wraps
/// between words (never inside one), and the puck grows to hold its longest
/// word plus [PuckLabel.gap] on each side. Measured with the user's text size
/// and the style the `Text` really draws with (see [effectiveTextStyle]), so
/// large text widens the pucks instead of abbreviating the names.
double puckWidth(
  BuildContext context, {
  required String label,
  required TextStyle style,
  required double minWidth,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final drawn = effectiveTextStyle(context, style);
  double widthOf(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: drawn),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  final single = widthOf(label) + 2 * PuckLabel.gap;
  // One line is fine up to a puck and a half at normal size; beyond that the
  // name wraps.
  final oneLineCap = minWidth * 1.5 * scaler.scale(1);
  if (single <= oneLineCap) return single < minWidth ? minWidth : single;
  var longest = 0.0;
  for (final word in label.split(RegExp(r'\s+'))) {
    final w = widthOf(word);
    if (w > longest) longest = w;
  }
  final wrapped = longest + 2 * PuckLabel.gap;
  return wrapped < minWidth ? minWidth : wrapped;
}

/// The name under a puck: centered, up to three lines, wrapping between words.
///
/// **A word is never split** (H-T02-6). The puck is sized to hold its longest
/// word ([puckWidth]); if that still comes out a few dp short on some phone
/// (another font than the measured one), the name is drawn smaller, down to
/// [minScale] of its size, instead of breaking «Mañana» into «Mañan / a».
class PuckLabel extends StatelessWidget {
  const PuckLabel({super.key, required this.label, required this.style});

  /// Space kept at each side of the name inside its puck, so the names of two
  /// neighbours are never stuck together.
  static const double gap = Sp.xs;

  /// The smallest the name is drawn, as a share of its size.
  static const double minScale = 0.7;

  final String label;
  final TextStyle style;

  /// The share of [style]'s size at which the longest word of [label] fits
  /// in [width] (1 when it already does, never below [minScale]).
  @visibleForTesting
  static double scaleToFit(
    BuildContext context,
    String label,
    TextStyle style,
    double width,
  ) {
    final size = style.fontSize;
    if (size == null || !width.isFinite) return 1;
    final drawn = effectiveTextStyle(context, style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double longestAt(double scale) {
      var widest = 0.0;
      for (final word in label.split(RegExp(r'\s+'))) {
        final painter = TextPainter(
          text: TextSpan(
            text: word,
            style: drawn.copyWith(fontSize: size * scale),
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
      return widest;
    }

    var scale = 1.0;
    while (scale > minScale && longestAt(scale) > width) {
      scale = (scale - 0.05).clamp(minScale, 1.0);
    }
    return scale;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: gap),
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = scaleToFit(context, label, style, box.maxWidth);
          return Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: scale == 1
                ? style
                : style.copyWith(fontSize: style.fontSize! * scale),
          );
        },
      ),
    );
  }
}
