import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Calm yes/no dialog. Returns true only when the user confirms.
///
/// Pass [body] for a plain message, or [content] for a richer body (it wins
/// over [body]). [destructive] tints the confirm button with the danger pair.
Future<bool> showConfirmDialog(
  BuildContext context, {
  String? title,
  String? body,
  Widget? content,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  bool scrollable = false,
  Key? confirmKey,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: scrollable,
      title: title == null ? null : Text(title),
      content: content ?? (body == null ? null : Text(body)),
      actions: [
        _cancelButton(ctx, cancelLabel, false),
        _confirmButton(ctx, confirmLabel, destructive, confirmKey, true),
      ],
    ),
  );
  return ok == true;
}

/// Three-way variant: returns true (confirm), false ([alternativeLabel]) or
/// null when cancelled or dismissed.
Future<bool?> showConfirmDialogWithAlternative(
  BuildContext context, {
  String? title,
  String? body,
  required String confirmLabel,
  required String alternativeLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: body == null ? null : Text(body),
      actions: [
        _cancelButton(ctx, cancelLabel, null),
        TextButton(
          key: const ValueKey('confirm-alt'),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(alternativeLabel),
        ),
        _confirmButton(ctx, confirmLabel, destructive, null, true),
      ],
    ),
  );
}

Widget _cancelButton(BuildContext ctx, String? label, bool? result) =>
    TextButton(
      key: const ValueKey('confirm-cancel'),
      onPressed: () => Navigator.pop(ctx, result),
      child: Text(label ?? ctx.l10n.cancel),
    );

Widget _confirmButton(
  BuildContext ctx,
  String label,
  bool destructive,
  Key? key,
  bool result,
) {
  final colors = ctx.colors;
  return FilledButton(
    key: key ?? const ValueKey('confirm-ok'),
    style: destructive
        ? FilledButton.styleFrom(
            backgroundColor: colors.dangerContainer,
            foregroundColor: colors.danger,
          )
        : null,
    onPressed: () => Navigator.pop(ctx, result),
    child: Text(label),
  );
}
