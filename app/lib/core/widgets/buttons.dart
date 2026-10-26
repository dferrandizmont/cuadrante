import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// The one in-button / inline progress spinner (18 dp, 2.4 stroke). Takes
/// the surrounding icon colour unless [color] is given.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.color, this.size = IconSize.inline});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      color: color ?? IconTheme.of(context).color,
    ),
  );
}

Widget _spinner(Color color) => ButtonSpinner(color: color);

/// Filled `accent` button with an optional icon and a loading state.
/// At most one per view.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onAccent = context.colors.onAccent;
    final handler = loading ? null : onPressed;
    final Widget button = (icon == null && !loading)
        ? FilledButton(onPressed: handler, child: Text(label))
        : FilledButton.icon(
            onPressed: handler,
            icon: loading
                ? _spinner(onAccent)
                : Icon(icon, size: IconSize.button),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Outlined button on `surface` (secondary action).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = icon == null
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: IconSize.button),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
