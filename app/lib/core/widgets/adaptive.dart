import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Tablet layout rules shared by screens, page bodies and app bars.
///
/// Widths are the width available to the content (the window minus the
/// navigation rail), so a 800 dp portrait tablet stays single column while a
/// 1280 dp landscape one (about 1200 dp of content) goes multi-column.
class Adaptive {
  const Adaptive._();

  /// Content width from which screens switch to their multi-column layout.
  static const double twoColumnMin = 900;

  /// Single-column cap on tablets in portrait (Today, Inbox, Week list).
  static const double portraitMax = 680;

  /// Cap of the multi-column layouts: keeps lines readable on large tablets.
  static const double wideMax = 1120;

  /// Gap between two columns.
  static const double gutter = Sp.xxl;

  static bool isWide(double contentWidth) => contentWidth >= twoColumnMin;

  /// Window width (dp) from which the month screen shows two panes whatever
  /// the orientation: Material's "expanded" window class.
  static const double splitWideMin = 840;

  /// Window width (dp) from which it shows two panes when the window is also
  /// wider than tall (landscape): a landscape phone is 800-930 dp wide but
  /// only ~400 dp tall, a 7" tablet 960 x 600.
  static const double splitLandscapeMin = 600;

  /// The two panes never spread wider than this (desktop-like windows).
  static const double splitMaxWidth = 1280;

  /// Two panes (month | day) or one column? Decided on the size of the whole
  /// window (`MediaQuery.sizeOf`), which the keyboard does not change: an
  /// 800 x 1280 tablet in portrait with the keyboard up is still portrait.
  ///
  /// - 412 x 915 phone portrait: one column.
  /// - 915 x 412 phone landscape: two panes (>= 600 and landscape).
  /// - 1280 x 800 tablet landscape: two panes.
  /// - 800 x 1280 tablet portrait: one column (800 < 840, not landscape);
  ///   the month already has room there and a modal sheet is a better use of
  ///   a tall screen than a 320 dp strip.
  static bool useSplit(Size window) =>
      window.width >= splitWideMin ||
      (window.width >= splitLandscapeMin && window.width > window.height);
}

/// Reads the content width and hands it to [builder] with the wide flag.
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool wide) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => builder(context, Adaptive.isWide(box.maxWidth)),
  );
}
