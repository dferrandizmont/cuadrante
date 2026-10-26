import 'package:flutter/material.dart';

import '../icons/app_icons.dart';

import '../theme/theme_context.dart';
import 'buttons.dart';
import 'app_card.dart';

/// The one callout card: a tinted panel with a tone disc, a title, an
/// optional line of body text and up to two actions (a quiet text button
/// and a filled primary), or a close button.
///
/// Every nudge and banner in the app uses it, so they read as one family.
class AppCallout extends StatelessWidget {
  const AppCallout({
    super.key,
    required this.icon,
    this.tone,
    required this.title,
    this.message,
    this.titleKey,
    this.primaryLabel,
    this.onPrimary,
    this.primaryKey,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryKey,
    this.onDismiss,
    this.dismissTooltip,
    this.dismissKey,
  });

  final IconData icon;

  /// Disc colours; defaults to the accent tone.
  final TonePair? tone;
  final String title;
  final String? message;
  final Key? titleKey;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final Key? primaryKey;
  final bool primaryLoading;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;

  /// Shows a close button in the top-right corner.
  final VoidCallback? onDismiss;
  final String? dismissTooltip;
  final Key? dismissKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final tone = this.tone ?? colors.accentTone;
    final hasActions = primaryLabel != null || secondaryLabel != null;
    final disc = ExcludeSemantics(
      child: Container(
        width: Disc.m,
        height: Disc.m,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
        child: Icon(icon, size: IconSize.button, fill: 1, color: tone.fg),
      ),
    );
    final dismiss = onDismiss == null
        ? null
        : IconButton(
            key: dismissKey,
            tooltip: dismissTooltip,
            icon: Icon(
              AppIcons.close,
              size: IconSize.button,
              color: colors.textSecondary,
            ),
            onPressed: onDismiss,
          );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, key: titleKey, style: type.bodyStrong),
        ),
        if (message != null) ...[
          const SizedBox(height: Sp.hair),
          Text(
            message!,
            style: type.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );

    return AppCard.tinted(
      padding: EdgeInsets.fromLTRB(
        Sp.m,
        Sp.m,
        onDismiss == null ? Sp.m : Sp.xs,
        Sp.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (context.largeText) ...[
            // The icon's column used to split long permission words at
            // 320 dp / text x2. Give the text the card's full width.
            Row(children: [disc, const Spacer(), ?dismiss]),
            const SizedBox(height: Sp.m),
            text,
          ] else
            Row(
              crossAxisAlignment: message == null
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                disc,
                const SizedBox(width: Sp.m),
                Expanded(child: text),
                ?dismiss,
              ],
            ),
          if (hasActions) ...[
            const SizedBox(height: Sp.m),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Sp.s,
              runSpacing: Sp.xs,
              children: [
                if (secondaryLabel != null)
                  TextButton(
                    key: secondaryKey,
                    onPressed: onSecondary,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                    child: Text(secondaryLabel!),
                  ),
                if (primaryLabel != null)
                  PrimaryButton(
                    key: primaryKey,
                    label: primaryLabel!,
                    onPressed: onPrimary,
                    loading: primaryLoading,
                    expand: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
