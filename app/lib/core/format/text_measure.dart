import 'package:flutter/widgets.dart';

/// The style a `Text` draws [style] with in [context]: [style] over the
/// default text style of the tree (the theme's family, letter spacing...).
///
/// Measure with this, not with the bare [style]: a `TextPainter` given only
/// [style] uses the engine's default font, and on a phone that is not always
/// the one the `Text` ends up in, so the measure came out a few dp short and
/// «Mañana» wrapped as «Mañan / a» (H-T02-6).
TextStyle effectiveTextStyle(BuildContext context, TextStyle style) =>
    DefaultTextStyle.of(context).style.merge(style);

/// Width of the longest word of [text] in [style], with the text size the
/// user chose: the narrowest a box can be and still show [text] wrapped
/// between words, never in the middle of one.
///
/// Used to size things that must not split a word (the labels under the
/// round tools of the selection bar, the buttons of a row) instead of
/// guessing a width that large text then breaks.
double longestWordWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: effectiveTextStyle(context, style)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.minIntrinsicWidth;
  painter.dispose();
  return width;
}

/// Lines [text] takes in [style] inside a box [maxWidth] wide, with the text
/// size the user chose. To decide a layout (beside or under) before building
/// it.
int textLineCount(
  BuildContext context,
  String text,
  TextStyle style,
  double maxWidth,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: effectiveTextStyle(context, style)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth < 0 ? 0 : maxWidth);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

/// Width of [text] on one line in [style], with the text size the user chose.
double textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: effectiveTextStyle(context, style)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// How much the user scaled the text (1.0 = normal).
double textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14;

/// From this text scale on, the bars of the app that carry a label under each
/// tool show only the tool (its name stays as tooltip and for screen
/// readers): at x2.0 two lines of caption under every round button, plus the
/// hint above, take most of a 320 dp phone.
const double kCompactTextScale = 1.6;
