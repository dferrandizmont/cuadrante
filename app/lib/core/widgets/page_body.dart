import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import 'adaptive.dart';

/// Centres page content and caps its width (~640 dp) so cards do not stretch
/// edge to edge on tablets and landscape. Screens with a multi-column tablet
/// layout pass [wideMaxWidth]: it applies from [Adaptive.twoColumnMin].
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.maxWidth = Sp.maxContentWidth,
    this.wideMaxWidth,
    this.wideFrom = Adaptive.twoColumnMin,
  });

  final Widget child;
  final double maxWidth;
  final double? wideMaxWidth;

  /// Content width from which [wideMaxWidth] applies.
  final double wideFrom;

  @override
  Widget build(BuildContext context) {
    final wide = wideMaxWidth;
    if (wide == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: box.maxWidth >= wideFrom ? wide : maxWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}
