import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The repaint boundary of the last [renderWidgetToPng] call, so a test can
/// check it was disposed.
@visibleForTesting
RenderObject? debugLastOffscreenBoundary;

/// Draws [widget] outside the screen and returns it as a PNG.
///
/// The widget gets its own small render tree (a [PipelineOwner] and a
/// [BuildOwner] that nothing else uses), laid out [width] logical pixels
/// wide and as tall as it needs (at most [maxHeight]), so the image does not
/// depend on the phone's screen, on what is open or on the light/dark theme
/// of the app: [widget] must bring its own `Theme`, `MediaQuery`,
/// `Directionality` and `Localizations`. It must not need a second layout
/// pass to build (no `LayoutBuilder`).
///
/// The PNG is [width] x [pixelRatio] pixels wide. `toImage` needs real time:
/// widget tests wrap the call in `tester.runAsync`.
Future<Uint8List> renderWidgetToPng(
  Widget widget, {
  required double width,
  double maxHeight = 4000,
  double pixelRatio = 3,
}) async {
  final constraints = BoxConstraints(
    minWidth: width,
    maxWidth: width,
    maxHeight: maxHeight,
  );
  final boundary = RenderRepaintBoundary();
  debugLastOffscreenBoundary = boundary;
  final renderView = RenderView(
    view: WidgetsBinding.instance.platformDispatcher.views.first,
    configuration: ViewConfiguration(
      logicalConstraints: constraints,
      physicalConstraints: constraints,
    ),
    child: boundary,
  );
  final pipelineOwner = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focusManager = FocusManager();
  final buildOwner = BuildOwner(focusManager: focusManager);
  RenderObjectToWidgetElement<RenderBox>? root;
  try {
    root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: widget,
    ).attachToRenderTree(buildOwner);
    buildOwner.buildScope(root);
    buildOwner.finalizeTree();
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    // Unmount the tree and let go of the render objects.
    if (root != null) {
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
          .attachToRenderTree(buildOwner, root);
      buildOwner.buildScope(root);
      buildOwner.finalizeTree();
    }
    pipelineOwner.rootNode = null;
    // The boundary is ours: let it go from the view first, then dispose it
    // (the view does not dispose a child it is detached from).
    renderView.child = null;
    boundary.dispose();
    renderView.dispose();
    focusManager.dispose();
  }
}
