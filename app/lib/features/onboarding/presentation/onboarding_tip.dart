import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../application/onboarding_providers.dart';

/// The one-time tip under the "today" card after the first-use flow: how to
/// paint and what the pattern button does. Closed for good with «Entendido»
/// or the cross (remembered in `onboarding.tipPending`).
class OnboardingTipCard extends ConsumerWidget {
  const OnboardingTipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(onboardingTipProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final dismiss = ref.read(onboardingTipProvider.notifier).dismiss;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 0),
      child: AppCallout(
        key: const ValueKey('onboarding-tip'),
        icon: AppIcons.paint,
        title: l10n.onboardingTipTitle,
        message: l10n.onboardingTipBody,
        primaryLabel: l10n.onboardingTipDismiss,
        primaryKey: const ValueKey('onboarding-tip-dismiss'),
        onPrimary: dismiss,
        onDismiss: dismiss,
        dismissTooltip: l10n.onboardingTipClose,
        dismissKey: const ValueKey('onboarding-tip-close'),
      ),
    );
  }
}
