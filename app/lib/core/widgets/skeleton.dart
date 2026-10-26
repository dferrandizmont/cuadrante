import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme_context.dart';
import 'app_card.dart';

/// Calm loading placeholder for list screens (Today, Week, Agenda): a few
/// still card shapes in the layout's own rhythm instead of a bare spinner.
/// Static on purpose: no shimmer, nothing moves, and screen readers hear a
/// single "Loading".
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.cards = 3, this.header = true});

  final int cards;

  /// Draws a short title bar above the cards.
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('skeleton-loading'),
      label: context.l10n.loadingLabel,
      liveRegion: true,
      excludeSemantics: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.l, Sp.page, Sp.l),
        children: [
          if (header) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBar(widthFactor: 0.45, height: 22),
            ),
            const SizedBox(height: Sp.l),
          ],
          for (var i = 0; i < cards; i++) ...[
            const SkeletonCard(),
            const SizedBox(height: Sp.card),
          ],
        ],
      ),
    );
  }
}

/// One placeholder row card: a disc and two text bars.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final fill = context.colors.skeleton;
    return AppCard(
      padding: AppCard.compactPadding,
      child: Row(
        children: [
          Container(
            width: Disc.m,
            height: Disc.m,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          ),
          const SizedBox(width: Sp.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBar(widthFactor: 0.7),
                SizedBox(height: Sp.s),
                SkeletonBar(widthFactor: 0.4, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded placeholder bar of [height], [widthFactor] of the line.
class SkeletonBar extends StatelessWidget {
  const SkeletonBar({super.key, this.widthFactor = 1, this.height = 14});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.colors.skeleton,
          borderRadius: Rad.pill,
        ),
      ),
    );
  }
}
