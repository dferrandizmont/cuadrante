import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../onboarding/application/onboarding_providers.dart';

/// The first-use tip of the month screen, compact: one line that says how to
/// paint the month and the cross that closes it (H-T18-6, punto 3 de
/// docs/propuestas-diseno.md).
///
/// It is compact on purpose: the rows of the month keep the height they need
/// for the code and the time of every day (see `dayCellHeightWithTime`), and
/// the tip only takes the line it needs. With large text the line wraps (it
/// is never cut) and the user can close it. The wide screen keeps the whole
/// tip in the day pane ([OnboardingTipCard]).
class MonthTipCard extends ConsumerWidget {
  const MonthTipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(onboardingTipProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.colors;
    final dismiss = ref.read(onboardingTipProvider.notifier).dismiss;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 0),
      child: AppCard.tinted(
        key: const ValueKey('onboarding-tip'),
        radius: Rad.inner,
        padding: const EdgeInsets.fromLTRB(Sp.m, Sp.xs, Sp.xs, Sp.xs),
        child: Row(
          children: [
            Icon(
              AppIcons.paint,
              size: IconSize.inline,
              color: colors.accentText,
            ),
            const SizedBox(width: Sp.s),
            Expanded(
              child: Semantics(
                // The visible line is short; a screen reader hears the whole
                // tip (the title and what it explains).
                label: '${l10n.onboardingTipTitle}. ${l10n.onboardingTipBody}',
                excludeSemantics: true,
                child: Text(
                  l10n.monthTipPaint,
                  style: context.type.meta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('onboarding-tip-close'),
              tooltip: l10n.onboardingTipClose,
              icon: Icon(
                AppIcons.close,
                size: IconSize.button,
                color: colors.textSecondary,
              ),
              onPressed: dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
