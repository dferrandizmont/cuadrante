import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'adaptive.dart';

/// App bar whose title (and back arrow / actions) line up with the page's
/// content column on tablets. On phones (no room to centre) it is a plain
/// [AppBar]. [ContentAppBar.adaptive] also reserves enough height for a title
/// that wraps at the reader's text size.
///
/// Pass the same [maxWidth] / [wideMaxWidth] as the screen's `PageBody`.
class ContentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContentAppBar({
    super.key,
    this.title,
    this.actions,
    this.titleSpacing,
    this.maxWidth = Sp.maxContentWidth,
    this.wideMaxWidth,
    this.wideFrom = Adaptive.twoColumnMin,
    this.toolbarHeight = height,
    this.titleBelowActions = false,
  });

  /// Measures the localized title at the reader's text size before Scaffold
  /// reserves the toolbar: wrapping a title alone would still clip its height.
  factory ContentAppBar.adaptive(
    BuildContext context, {
    Key? key,
    required Text title,
    List<Widget>? actions,
    double? titleSpacing,
    double maxWidth = Sp.maxContentWidth,
    double? wideMaxWidth,
    double wideFrom = Adaptive.twoColumnMin,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final cap = wideMaxWidth != null && width >= wideFrom
        ? wideMaxWidth
        : maxWidth;
    final centered = width > cap + 2 * Sp.xs;
    final canPop = Navigator.of(context).canPop();
    final spacing =
        titleSpacing ?? Theme.of(context).appBarTheme.titleSpacing ?? Sp.xs;
    final leading = canPop
        ? kToolbarHeight
        : centered
        ? Sp.page
        : 0.0;
    final available = math.max(
      1.0,
      math.min(width, cap) -
          leading -
          (actions?.length ?? 0) * Sp.touch -
          (centered ? Sp.s : 2 * spacing),
    );
    final style =
        Theme.of(context).appBarTheme.titleTextStyle ?? context.type.title;
    final painter = TextPainter(
      text: TextSpan(text: title.data, style: style.merge(title.style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
    )..layout(maxWidth: available);
    // Back and action buttons can leave less space than one complete word
    // (e.g. «calendarios» at 200%). Give the title its own full-width row
    // rather than splitting the word or reducing the chosen reading size.
    final titleBelowActions =
        painter.computeLineMetrics().length > 2 ||
        painter.minIntrinsicWidth > available;
    if (titleBelowActions) {
      painter.layout(maxWidth: math.max(1.0, math.min(width, cap) - 2 * Sp.l));
    }
    final toolbarHeight = math.max(
      height,
      painter.height + 2 * Sp.s + (titleBelowActions ? Sp.touch : 0),
    );
    painter.dispose();
    return ContentAppBar(
      key: key,
      // Material limits AppBar titles to 1.34 internally. Preserve the
      // reader's scaler used above when reserving the toolbar's height.
      title: MediaQuery(
        data: MediaQuery.of(context),
        child: DefaultTextStyle(
          style: style,
          softWrap: true,
          overflow: TextOverflow.visible,
          child: title,
        ),
      ),
      actions: actions,
      titleSpacing: titleSpacing,
      maxWidth: maxWidth,
      wideMaxWidth: wideMaxWidth,
      wideFrom: wideFrom,
      toolbarHeight: toolbarHeight,
      titleBelowActions: titleBelowActions,
    );
  }

  final Widget? title;
  final List<Widget>? actions;

  /// Phone only: passed to [AppBar.titleSpacing] (tab screens use `Sp.page`).
  final double? titleSpacing;
  final double maxWidth;
  final double? wideMaxWidth;
  final double wideFrom;
  final double toolbarHeight;
  final bool titleBelowActions;

  /// Matches `AppBarTheme.toolbarHeight` (app_theme.dart).
  static const double height = 64;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = wideMaxWidth;
        final cap = wide != null && box.maxWidth >= wideFrom ? wide : maxWidth;
        final canPop = Navigator.of(context).canPop();
        if (titleBelowActions) {
          return AppBar(
            toolbarHeight: toolbarHeight,
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 0,
            title: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cap),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: Sp.touch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Sp.s),
                        child: Row(
                          children: [
                            if (canPop) const BackButton(),
                            const Spacer(),
                            ...?actions,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.l,
                        vertical: Sp.s,
                      ),
                      child: title,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (box.maxWidth <= cap + 2 * Sp.xs) {
          return AppBar(
            toolbarHeight: toolbarHeight,
            titleSpacing: titleSpacing,
            title: title,
            actions: actions,
          );
        }
        return AppBar(
          toolbarHeight: toolbarHeight,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 0,
          title: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cap),
              child: Row(
                children: [
                  if (canPop)
                    const Padding(
                      padding: EdgeInsets.only(left: Sp.s),
                      child: BackButton(),
                    )
                  else
                    const SizedBox(width: Sp.page),
                  Expanded(child: title ?? const SizedBox.shrink()),
                  ...?actions,
                  const SizedBox(width: Sp.s),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
