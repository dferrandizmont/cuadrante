import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../application/pattern_start_pick.dart';

/// Shown under the header of paint mode after a long press on a puck:
/// "Toca el día en que empieza el patrón". The next day tapped opens the
/// pattern wizard there; "Cancelar" (or leaving paint mode) drops it.
class PatternPickBanner extends ConsumerWidget {
  const PatternPickBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pick = ref.watch(patternStartPickProvider);
    if (pick == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, 0),
      child: AppCard.tinted(
        key: const ValueKey('pattern-pick-banner'),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            children: [
              Icon(AppIcons.pattern, color: colors.textPrimary),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Text(
                  l10n.patternPickBanner,
                  style: context.type.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('pattern-pick-cancel'),
                onPressed: ref.read(patternStartPickProvider.notifier).cancel,
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
