import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_context.dart';
import 'adaptive.dart';

/// Keeps wide-window notices compact. A split screen can exclude its tools
/// pane with [endInset], so even a tall notice cannot cover the tools.
/// Narrow phones inherit their existing SnackBar theme unchanged.
class AppSnackBarLayout extends StatelessWidget {
  const AppSnackBarLayout({super.key, required this.child, this.endInset = 0});

  final Widget child;
  final double endInset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < Adaptive.splitLandscapeMin) {
      return child;
    }
    return LayoutBuilder(
      builder: (context, box) {
        final available = box.maxWidth - endInset;
        final side = ((available - Sp.snackBarMaxWidth) / 2).clamp(
          Sp.l,
          double.infinity,
        );
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            snackBarTheme: theme.snackBarTheme.copyWith(
              behavior: SnackBarBehavior.floating,
              insetPadding: EdgeInsets.fromLTRB(
                side,
                Sp.l,
                side + endInset,
                Sp.l,
              ),
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// How long a [SnackBar] of the app stays up before it goes away by itself.
const Duration kSnackBarDuration = Duration(seconds: 6);

/// Action notices remain available with accessible navigation. Otherwise they
/// keep the six-second timeout and the existing clearance below the grid.
SnackBar appSnackBar({
  BuildContext? context,
  required Widget content,
  SnackBarAction? action,
  Duration duration = kSnackBarDuration,
}) {
  assert(
    action == null || context != null,
    'Action notices need their display context',
  );
  return SnackBar(
    content: content,
    action: action,
    duration: duration,
    persist:
        action != null &&
        (context != null && MediaQuery.accessibleNavigationOf(context)),
    showCloseIcon:
        action != null &&
        (context != null && MediaQuery.accessibleNavigationOf(context)),
  );
}

/// How much room the SnackBar shown with [showTrackedSnackBar] takes at the
/// bottom of the screen, or `null` when there is none. The month screen
/// watches it to leave that room under the grid, so the last row can be
/// scrolled clear of the notice (it floats over the body).
final snackBarCoverProvider = NotifierProvider<SnackBarCover, double?>(
  SnackBarCover.new,
);

class SnackBarCover extends Notifier<double?> {
  Object? _current;

  @override
  double? build() {
    _current = null;
    return null;
  }

  /// [token] is up; until it is measured, [estimate] dp are reserved.
  void shown(Object token, double estimate) {
    _current = token;
    state = estimate;
  }

  /// The real height of the notice, once laid out.
  void measured(Object token, double height) {
    if (!ref.mounted || _current != token || state == height) return;
    state = height;
  }

  /// [token] is gone; a newer SnackBar that replaced it keeps the cover.
  void gone(Object token) {
    if (!ref.mounted || _current != token) return;
    _current = null;
    state = null;
  }
}

/// A guess of the room a notice needs before it is measured: its text (more
/// lines as the text grows), the action button, which Material puts under the
/// text when it does not fit beside it, and the margins.
double snackBarClearance(BuildContext context) =>
    104 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 6;

/// Shows an [appSnackBar] with [content] and [action] on the nearest
/// messenger (the one on screen goes first) and tells [snackBarCoverProvider]
/// how tall it is while it is up.
void showTrackedSnackBar(
  WidgetRef ref,
  BuildContext context, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = kSnackBarDuration,
}) {
  _showTracked(
    ref.read(snackBarCoverProvider.notifier),
    ScaffoldMessenger.of(context),
    snackBarClearance(context),
    content: content,
    action: action,
    duration: duration,
  );
}

/// The same notice for a screen that is already gone (the "Deshacer" of an
/// import, said from the calendar): the [messenger], the [cover] and the
/// [clearance] are the ones that screen had.
void showTrackedSnackBarAfter(
  SnackBarCover cover, {
  required ScaffoldMessengerState messenger,
  required double clearance,
  required Widget content,
  Duration duration = kSnackBarDuration,
}) => _showTracked(
  cover,
  messenger,
  clearance,
  content: content,
  duration: duration,
);

void _showTracked(
  SnackBarCover cover,
  ScaffoldMessengerState messenger,
  double clearance, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = kSnackBarDuration,
}) {
  final token = Object();
  final bar = appSnackBar(
    context: messenger.context,
    content: _HeightProbe(
      onHeight: (height) => cover.measured(token, height + Sp.l),
      child: content,
    ),
    action: action,
    duration: duration,
  );
  // The one on screen goes first: the new notice takes its place.
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(bar);
  cover.shown(token, clearance);
  // `closed` ends when the bar leaves: by timeout, by its action or because
  // another one replaced it (which has already taken the cover over).
  controller.closed.then((_) => cover.gone(token));
}

/// Reports the height of the [SnackBar] that holds [child]. The bar grows to
/// its full height as it comes in, so the probe looks at every frame of the
/// entrance and reports the tallest it sees.
class _HeightProbe extends StatefulWidget {
  const _HeightProbe({required this.child, required this.onHeight});

  final Widget child;
  final ValueChanged<double> onHeight;

  @override
  State<_HeightProbe> createState() => _HeightProbeState();
}

class _HeightProbeState extends State<_HeightProbe> {
  static const _watch = Duration(milliseconds: 800);

  Duration? _since;
  double _tallest = 0;

  @override
  void initState() {
    super.initState();
    _look();
  }

  void _look() {
    WidgetsBinding.instance.addPostFrameCallback((frame) {
      if (!mounted) return;
      _since ??= frame;
      RenderBox? box;
      context.visitAncestorElements((element) {
        if (element.widget is! SnackBar) return true;
        final render = element.renderObject;
        if (render is RenderBox && render.hasSize) box = render;
        return false;
      });
      final height = box?.size.height ?? 0;
      if (height > _tallest) {
        _tallest = height;
        widget.onHeight(height);
      }
      if (frame - _since! < _watch) _look();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
