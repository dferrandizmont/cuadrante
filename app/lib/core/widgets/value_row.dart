import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme_context.dart';

/// A line with a title that takes the free space and a value (and an
/// optional chevron) flush at the trailing edge.
///
/// `Expanded(title)` next to `Flexible(value)` is wrong: both are flex 1, so
/// the title is forced to half the width and the loose value sits at the left
/// of the other half, in the middle of the row. Here the value is a plain
/// child of the row and the title gets whatever is left. The chevron
/// ([trailing]) is at the same x with and without a value, in both layouts.
///
/// **Inline or stacked (H-T11-6).** Side by side is the default. The row
/// switches to a stacked layout, title on top and value under it (the
/// chevron stays at the trailing edge, centred), when side by side would
/// either cut the value (ellipsis) or break a word of the title in two. With
/// the text scaled to 1.3 or more it is stricter: it stacks as soon as title
/// and value do not both fit on one line. A title therefore only ever wraps
/// at spaces, and a value is only ellipsized when it is longer than the whole
/// row.
class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    this.leading,
    required this.title,
    this.value,
    this.detail,
    this.trailing,
    this.forceStacked = false,
    this.valueGap = Sp.s,
    this.trailingGap = Sp.xs,
    this.stackedGap = 2,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// Before the title (an icon disc, with its own gap).
  final Widget? leading;

  /// Takes the free space.
  final Widget title;

  /// Flush right inline; under the title, aligned with it, when stacked,
  /// where a long text wraps to up to three lines (see [ValueRowValue]).
  /// Pass a plain `Text`: its `maxLines`, `overflow` and `textAlign` come
  /// from the row.
  final Widget? value;

  /// A quiet second line of the value («+20,00 € en el estimado» under
  /// «+2 h»). Flush right under the value inline, and under it, aligned with
  /// the title, when stacked: a value and its detail always line up with each
  /// other, never one flush right and the other floating at the left of it
  /// (H-T08-1). Needs a [value].
  final Widget? detail;

  /// Always stacked (the value under the title), whatever the room. For rows
  /// that sit one under the other and must all look the same (H-T10-1: the
  /// community stacked while the municipality stayed inline).
  final bool forceStacked;

  /// After the value (a chevron): same x on every row.
  final Widget? trailing;

  final double valueGap;
  final double trailingGap;

  /// Space between the title and the value when they are stacked.
  final double stackedGap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    assert(detail == null || value != null, 'A detail needs a value.');
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return _ValueRowLayout(
      textDirection: Directionality.of(context),
      forceStacked: forceStacked,
      largeText: scale >= 1.3 - 0.001,
      valueGap: valueGap,
      trailingGap: trailingGap,
      stackedGap: stackedGap,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (leading != null) _Slot(_Role.leading, leading!),
        _Slot(_Role.title, title),
        if (value != null) _Slot(_Role.value, ValueRowValue(child: value!)),
        if (detail != null) _Slot(_Role.detail, ValueRowValue(child: detail!)),
        if (trailing != null) _Slot(_Role.trailing, trailing!),
      ],
    );
  }
}

/// The value of a [ValueRow], with the text rules of that slot: a `Text` that
/// sets none of its own wraps to up to three lines (the row stacks it under
/// the title when it does not fit beside it, H-T11-6), aligned with the
/// start of the title, and only then ends in an ellipsis. Side by side it is
/// as wide as its text, so it is always one line there.
class ValueRowValue extends StatelessWidget {
  const ValueRowValue({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.start,
    child: child,
  );
}

enum _Role { leading, title, value, detail, trailing }

class _Slot extends ParentDataWidget<_ValueRowParentData> {
  const _Slot(this.role, Widget child) : super(child: child);

  final _Role role;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _ValueRowParentData;
    if (data.role != role) {
      data.role = role;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ValueRow;
}

class _ValueRowParentData extends ContainerBoxParentData<RenderBox> {
  _Role role = _Role.title;
}

class _ValueRowLayout extends MultiChildRenderObjectWidget {
  const _ValueRowLayout({
    required super.children,
    required this.textDirection,
    required this.forceStacked,
    required this.largeText,
    required this.valueGap,
    required this.trailingGap,
    required this.stackedGap,
    required this.crossAxisAlignment,
  });

  final TextDirection textDirection;
  final bool forceStacked;
  final bool largeText;
  final double valueGap;
  final double trailingGap;
  final double stackedGap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderValueRow(
    textDirection: textDirection,
    forceStacked: forceStacked,
    largeText: largeText,
    valueGap: valueGap,
    trailingGap: trailingGap,
    stackedGap: stackedGap,
    crossAxisAlignment: crossAxisAlignment,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderValueRow renderObject) {
    renderObject
      ..textDirection = textDirection
      ..forceStacked = forceStacked
      ..largeText = largeText
      ..valueGap = valueGap
      ..trailingGap = trailingGap
      ..stackedGap = stackedGap
      ..crossAxisAlignment = crossAxisAlignment;
  }
}

/// The measured result of one layout pass.
class _Plan {
  const _Plan({
    required this.size,
    required this.stacked,
    required this.leadingSize,
    required this.titleSize,
    required this.valueSize,
    required this.detailSize,
    required this.trailingSize,
  });

  final Size size;
  final bool stacked;
  final Size leadingSize;
  final Size titleSize;
  final Size valueSize;
  final Size detailSize;
  final Size trailingSize;

  /// The value and its detail, one over the other.
  double get valueBlockHeight => valueSize.height + detailSize.height;
}

// The setters below share their names with the constructor parameters.
// ignore_for_file: prefer_initializing_formals
class _RenderValueRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ValueRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ValueRowParentData> {
  _RenderValueRow({
    required TextDirection textDirection,
    required bool forceStacked,
    required bool largeText,
    required double valueGap,
    required double trailingGap,
    required double stackedGap,
    required CrossAxisAlignment crossAxisAlignment,
  }) : _textDirection = textDirection,
       _forceStacked = forceStacked,
       _largeText = largeText,
       _valueGap = valueGap,
       _trailingGap = trailingGap,
       _stackedGap = stackedGap,
       _crossAxisAlignment = crossAxisAlignment;

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  bool _forceStacked;
  set forceStacked(bool v) {
    if (v == _forceStacked) return;
    _forceStacked = v;
    markNeedsLayout();
  }

  bool _largeText;
  set largeText(bool v) {
    if (v == _largeText) return;
    _largeText = v;
    markNeedsLayout();
  }

  double _valueGap;
  set valueGap(double v) {
    if (v == _valueGap) return;
    _valueGap = v;
    markNeedsLayout();
  }

  double _trailingGap;
  set trailingGap(double v) {
    if (v == _trailingGap) return;
    _trailingGap = v;
    markNeedsLayout();
  }

  double _stackedGap;
  set stackedGap(double v) {
    if (v == _stackedGap) return;
    _stackedGap = v;
    markNeedsLayout();
  }

  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment v) {
    if (v == _crossAxisAlignment) return;
    _crossAxisAlignment = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ValueRowParentData) {
      child.parentData = _ValueRowParentData();
    }
  }

  RenderBox? _child(_Role role) {
    for (var c = firstChild; c != null; c = childAfter(c)) {
      if ((c.parentData! as _ValueRowParentData).role == role) return c;
    }
    return null;
  }

  // ---- Layout ---------------------------------------------------------------

  /// Measures with [layoutChild] (a real layout, or a dry one) and decides
  /// the layout.
  _Plan _plan(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints c) layoutChild,
  ) {
    final leading = _child(_Role.leading);
    final title = _child(_Role.title)!;
    final value = _child(_Role.value);
    final detail = _child(_Role.detail);
    final trailing = _child(_Role.trailing);

    const unbounded = BoxConstraints();
    final leadingSize = leading == null
        ? Size.zero
        : layoutChild(leading, unbounded);
    final trailingSize = trailing == null
        ? Size.zero
        : layoutChild(trailing, unbounded);
    final trailingSpace = trailing == null
        ? 0.0
        : trailingSize.width + _trailingGap;
    final available = math.max(
      0.0,
      constraints.maxWidth - leadingSize.width - trailingSpace,
    );

    var stacked = false;
    Size titleSize;
    Size valueSize = Size.zero;
    Size detailSize = Size.zero;
    if (value == null) {
      titleSize = layoutChild(title, BoxConstraints.tightFor(width: available));
    } else {
      final titleFull = title.getMaxIntrinsicWidth(double.infinity);
      final titleWord = title.getMinIntrinsicWidth(double.infinity);
      // The value and its detail share the column at the trailing edge.
      final valueFull = math.max(
        value.getMaxIntrinsicWidth(double.infinity),
        detail?.getMaxIntrinsicWidth(double.infinity) ?? 0,
      );
      // Small slack: intrinsic widths are exact, but layout rounds to pixels.
      const eps = 0.5;
      final sideBySide = titleFull + _valueGap + valueFull <= available - eps;
      final wordsFit = titleWord + _valueGap + valueFull <= available - eps;
      stacked = _forceStacked || (_largeText ? !sideBySide : !wordsFit);
      if (stacked) {
        titleSize = layoutChild(
          title,
          BoxConstraints.tightFor(width: available),
        );
        valueSize = layoutChild(value, BoxConstraints(maxWidth: available));
        if (detail != null) {
          detailSize = layoutChild(detail, BoxConstraints(maxWidth: available));
        }
      } else {
        valueSize = layoutChild(value, BoxConstraints(maxWidth: valueFull));
        if (detail != null) {
          detailSize = layoutChild(detail, BoxConstraints(maxWidth: valueFull));
        }
        titleSize = layoutChild(
          title,
          BoxConstraints.tightFor(
            width: math.max(
              0.0,
              available -
                  _valueGap -
                  math.max(valueSize.width, detailSize.width),
            ),
          ),
        );
      }
    }

    final valueBlock = valueSize.height + detailSize.height;
    final blockHeight = stacked
        ? titleSize.height + _stackedGap + valueBlock
        : math.max(titleSize.height, valueBlock);
    final height = constraints.constrainHeight(
      math.max(blockHeight, math.max(leadingSize.height, trailingSize.height)),
    );
    return _Plan(
      size: Size(constraints.maxWidth, height),
      stacked: stacked,
      leadingSize: leadingSize,
      titleSize: titleSize,
      valueSize: valueSize,
      detailSize: detailSize,
      trailingSize: trailingSize,
    );
  }

  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth,
      'ValueRow needs a bounded width (it is a row that fills its parent).',
    );
    final plan = _plan(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = plan.size;

    final ltr = _textDirection == TextDirection.ltr;
    double yFor(double childHeight) => switch (_crossAxisAlignment) {
      CrossAxisAlignment.start => 0.0,
      CrossAxisAlignment.end => size.height - childHeight,
      _ => (size.height - childHeight) / 2,
    };
    double xFor(double start, double width) =>
        ltr ? start : size.width - start - width;

    var start = 0.0;
    final leading = _child(_Role.leading);
    if (leading != null) {
      (leading.parentData! as _ValueRowParentData).offset = Offset(
        xFor(0, plan.leadingSize.width),
        yFor(plan.leadingSize.height),
      );
      start += plan.leadingSize.width;
    }
    final title = _child(_Role.title)!;
    final value = _child(_Role.value);
    final detail = _child(_Role.detail);
    final blockHeight = plan.stacked
        ? plan.titleSize.height + _stackedGap + plan.valueBlockHeight
        : math.max(plan.titleSize.height, plan.valueBlockHeight);
    final blockTop = yFor(blockHeight);
    if (plan.stacked) {
      (title.parentData! as _ValueRowParentData).offset = Offset(
        xFor(start, plan.titleSize.width),
        blockTop,
      );
      final valueTop = blockTop + plan.titleSize.height + _stackedGap;
      if (value != null) {
        (value.parentData! as _ValueRowParentData).offset = Offset(
          xFor(start, plan.valueSize.width),
          valueTop,
        );
      }
      if (detail != null) {
        (detail.parentData! as _ValueRowParentData).offset = Offset(
          xFor(start, plan.detailSize.width),
          valueTop + plan.valueSize.height,
        );
      }
    } else {
      (title.parentData! as _ValueRowParentData).offset = Offset(
        xFor(start, plan.titleSize.width),
        yFor(plan.titleSize.height),
      );
      if (value != null) {
        // Flush at the trailing edge, before the chevron; the detail under
        // it, flush too.
        final trailingSpace = _child(_Role.trailing) == null
            ? 0.0
            : plan.trailingSize.width + _trailingGap;
        final valueTop = yFor(plan.valueBlockHeight);
        double xAt(double width) {
          final from = size.width - trailingSpace - width;
          return ltr ? from : size.width - from - width;
        }

        (value.parentData! as _ValueRowParentData).offset = Offset(
          xAt(plan.valueSize.width),
          valueTop,
        );
        if (detail != null) {
          (detail.parentData! as _ValueRowParentData).offset = Offset(
            xAt(plan.detailSize.width),
            valueTop + plan.valueSize.height,
          );
        }
      }
    }
    final trailing = _child(_Role.trailing);
    if (trailing != null) {
      (trailing.parentData! as _ValueRowParentData).offset = Offset(
        ltr ? size.width - plan.trailingSize.width : 0,
        yFor(plan.trailingSize.height),
      );
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _plan(constraints, (child, c) => child.getDryLayout(c)).size;

  @override
  double computeMinIntrinsicWidth(double height) {
    final leading = _child(_Role.leading)?.getMinIntrinsicWidth(height) ?? 0;
    final trailing = _child(_Role.trailing);
    return leading +
        _child(_Role.title)!.getMinIntrinsicWidth(height) +
        (trailing == null
            ? 0
            : trailing.getMinIntrinsicWidth(height) + _trailingGap);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final leading = _child(_Role.leading)?.getMaxIntrinsicWidth(height) ?? 0;
    final value = _child(_Role.value);
    final detail = _child(_Role.detail);
    final trailing = _child(_Role.trailing);
    return leading +
        _child(_Role.title)!.getMaxIntrinsicWidth(height) +
        (value == null
            ? 0
            : math.max(
                    value.getMaxIntrinsicWidth(height),
                    detail?.getMaxIntrinsicWidth(height) ?? 0,
                  ) +
                  _valueGap) +
        (trailing == null
            ? 0
            : trailing.getMaxIntrinsicWidth(height) + _trailingGap);
  }

  double _heightFor(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMinIntrinsicHeight(double width) => _heightFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _heightFor(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
