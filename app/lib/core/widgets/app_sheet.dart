import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme_context.dart';

/// The one way to open a bottom sheet: root navigator, scroll-controlled
/// (tall content and the keyboard never clip it), safe area, max content
/// width, and the theme's radius and drag handle.
///
/// With [padded] the builder's content is wrapped in [AppSheetBody]
/// (scroll view, page gutter, keyboard inset), the layout most sheets want.
/// Without it the builder owns its layout (lists with their own scroll,
/// search sheets) and the keyboard inset.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool padded = false,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    // The dimmed area is a button for TalkBack: it says what it does (it
    // read «Sombreado», H-T18-3).
    barrierLabel: context.l10n.close,
    constraints: const BoxConstraints(maxWidth: Sp.maxContentWidth),
    builder: padded ? (ctx) => AppSheetBody(child: builder(ctx)) : builder,
  );
}

/// Standard sheet body: bottom safe area, page gutter, keyboard inset.
class AppSheetBody extends StatelessWidget {
  const AppSheetBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Sp.page,
          0,
          Sp.page,
          Sp.l + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}
