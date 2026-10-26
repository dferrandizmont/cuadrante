import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../l10n/l10n.dart';
import 'empty_state.dart';

/// The one "could not load" state: a calm disc, the localized [message]
/// (defaults to the generic one) and a "Try again" button that runs [onRetry].
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.onRetry,
    this.message,
    this.compact = false,
  });

  final String? message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: AppIcons.error,
      title: message ?? l10n.errorGeneric,
      actionLabel: l10n.retry,
      onAction: onRetry,
      compact: compact,
    );
  }
}
