import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// `surface` card on `background` with a hairline border and no shadow.
///
/// Radius is [Rad.row] (16) everywhere; [Rad.card] (24) is kept for the few
/// hero cards (the "today" card).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = defaultPadding,
    this.onTap,
    this.radius = Rad.row,
    this.color,
    this.borderColor,
    this.clip = true,
    this.semanticLabel,
    this.selected,
  }) : tinted = false;

  /// Soft `surfaceMuted` card without outline: callouts, hints, banners.
  const AppCard.tinted({
    super.key,
    required this.child,
    this.padding = compactPadding,
    this.onTap,
    this.radius = Rad.row,
    this.clip = true,
    this.semanticLabel,
  }) : tinted = true,
       color = null,
       borderColor = null,
       selected = null;

  /// Default card padding.
  static const EdgeInsets defaultPadding = EdgeInsets.all(Sp.l);

  /// Compact padding (dense rows, callouts).
  static const EdgeInsets compactPadding = EdgeInsets.all(Sp.m);

  final bool tinted;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  /// Defaults to `surface`.
  final Color? color;

  /// Defaults to the `border` hairline; pass transparent for no outline.
  final Color? borderColor;
  final bool clip;
  final String? semanticLabel;

  /// A card that is one of several choices says whether it is the chosen
  /// one («seleccionado» in TalkBack); `null` = not a choice. It needs a
  /// [semanticLabel]: the state lives on the node that label makes.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: tinted
          ? BorderSide.none
          : BorderSide(color: borderColor ?? colors.border),
    );
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: tinted ? colors.surfaceMuted : (color ?? colors.surface),
      shape: shape,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, customBorder: shape, child: content),
    );
    if (semanticLabel == null) return card;
    return Semantics(
      container: true,
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      child: card,
    );
  }
}
