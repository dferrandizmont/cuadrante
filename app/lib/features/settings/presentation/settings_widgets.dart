import 'package:flutter/material.dart';

import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/value_row.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// A group of rows on one `surface` card, with an optional small heading
/// above it. Every area of the Settings screen is one section widget built
/// on this, so a new row goes in its section without touching the others.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});

  /// Heading above the card (shown in capitals, `label` style).
  final String? title;

  /// Usually [SettingsRow]s; separated by hairlines.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.s),
            child: Semantics(
              header: true,
              child: Text(
                title!.toUpperCase(),
                style: context.type.label.copyWith(color: colors.textMuted),
              ),
            ),
          ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: Sp.l + Disc.m + Sp.m,
                    color: colors.border,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row of a [SettingsSection]: icon disc, title with an optional
/// subtitle, an optional value at the right and a chevron when it opens
/// something. Without [onTap] the row is information only.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.forceStacked = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// The value goes under the title whatever the room. For rows that sit one
  /// under the other and must all look the same (H-T10-1).
  final bool forceStacked;

  /// Current value, in `textMuted` before the chevron.
  final String? value;
  final VoidCallback? onTap;

  /// Replaces the value and the chevron (a switch).
  final Widget? trailing;

  static const double minHeight = 56;

  /// Style of the title and of the subtitle, to measure them from outside.
  static TextStyle titleStyle(BuildContext context) => context.type.body
      .copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary);
  static TextStyle subtitleStyle(BuildContext context) =>
      context.type.meta.copyWith(color: context.colors.textMuted);

  /// Space the icon disc and its gap take before the title.
  static const double leadingWidth = Disc.m + Sp.m;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final tone = colors.accentTone;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m),
        child: ValueRow(
          forceStacked: forceStacked,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Disc.m,
                height: Disc.m,
                decoration: BoxDecoration(
                  color: tone.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: IconSize.button, color: tone.fg),
              ),
              const SizedBox(width: Sp.m),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle(context)),
              if (subtitle != null)
                Text(subtitle!, style: subtitleStyle(context)),
            ],
          ),
          // The value and the chevron sit flush at the trailing edge; the
          // chevron is at the same x on every row, with or without a value.
          value: trailing == null && value != null
              ? Text(value!, style: type.body.copyWith(color: colors.textMuted))
              : null,
          trailing:
              trailing ??
              (onTap != null
                  ? Icon(
                      AppIcons.chevronRight,
                      size: IconSize.inline,
                      color: colors.textMuted,
                    )
                  : null),
          trailingGap: trailing != null ? 0 : Sp.xs,
        ),
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// A [SettingsRow] whose whole width toggles a switch.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.switchKey,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Key of the [Switch] itself (tests).
  final Key? switchKey;

  /// Width the switch takes beside the text (the track plus a margin).
  static const double _switchWidth = 56;

  @override
  Widget build(BuildContext context) {
    final toggle = Switch(key: switchKey, value: value, onChanged: onChanged);
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: LayoutBuilder(
          builder: (context, box) {
            // The switch takes its width off the text. When the longest word
            // of the title or of the subtitle no longer fits beside it, the
            // switch goes under the text, at the trailing edge, and the text
            // keeps the whole row: «Copias automáticas» came out as «Copias /
            // automática / s» at x2.0 on a 320 dp phone (H-T13-2).
            final room =
                box.maxWidth -
                2 * Sp.l -
                SettingsRow.leadingWidth -
                _switchWidth;
            final titleFits =
                longestWordWidth(
                  context,
                  title,
                  SettingsRow.titleStyle(context),
                ) <=
                room;
            final subtitleFits =
                subtitle == null ||
                longestWordWidth(
                      context,
                      subtitle!,
                      SettingsRow.subtitleStyle(context),
                    ) <=
                    room;
            if (titleFits && subtitleFits) {
              return SettingsRow(
                icon: icon,
                title: title,
                subtitle: subtitle,
                trailing: toggle,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsRow(icon: icon, title: title, subtitle: subtitle),
                Padding(
                  padding: const EdgeInsets.only(right: Sp.l, bottom: Sp.m),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: toggle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Runs a settings write; if it fails, tells the user in a SnackBar (the
/// controller has already put the previous value back).
Future<void> saveSetting(
  BuildContext context,
  Future<void> Function() write,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = context.l10n.settingsSaveFailed;
  try {
    await write();
  } catch (_) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(content: Text(message)));
  }
}
