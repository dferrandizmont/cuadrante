import 'package:flutter/material.dart';

import '../../../core/format/text_measure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/backup_models.dart';
import 'backup_format.dart';

/// The rows of «Copias en este móvil»: date and kind on the left, «Restaurar
/// esta» on the same row as the trailing action (centred on the text, at the
/// x of the chevron of the other rows), or, when it does not fit beside the
/// text, under it with its text at the title's x.
///
/// All the rows of the list take the same layout: if one date is too long to
/// sit beside the button, every row stacks, so the list never mixes the two.
class BackupCopyList extends StatelessWidget {
  const BackupCopyList({
    super.key,
    required this.copies,
    required this.now,
    required this.onRestore,
  });

  final List<BackupCopy> copies;
  final DateTime now;
  final Future<void> Function(BackupCopy copy) onRestore;

  /// Horizontal padding of the button inside its pill; the button is moved
  /// out by as much so that its *text* sits on the edge it aligns with.
  static const double buttonPad = Sp.s;

  static String titleOf(AppLocalizations l10n, BackupCopy copy, DateTime now) =>
      sentenceCase(backupWhen(l10n, copy.entry.modifiedAt, now));

  /// «Copia del móvil · 0.5.0 · 2 KB»: the kind, the version of the app that
  /// wrote it (when the file says), and the size.
  static String metaOf(AppLocalizations l10n, BackupCopy copy) {
    final kind = copy.kind == BackupCopyKind.safety
        ? l10n.backupUiCopySafety
        : l10n.backupUiCopyLocal;
    final size = backupSize(copy.entry.sizeBytes, l10n.localeName);
    final version = copy.appVersion;
    return version == null
        ? l10n.backupUiCopyMeta(kind, size)
        : l10n.backupUiCopyMetaVersion(kind, version, size);
  }

  /// Whether every copy fits beside its button in a card [width] wide.
  bool _inline(BuildContext context, double width) {
    final l10n = context.l10n;
    final titleStyle = SettingsRow.titleStyle(context);
    final metaStyle = SettingsRow.subtitleStyle(context);
    final label = textWidth(
      context,
      l10n.backupUiCopyRestore,
      context.type.button,
    );
    final button = (label + 2 * buttonPad).clamp(64.0, double.infinity);
    final room = width - 2 * Sp.l - SettingsRow.leadingWidth - button - Sp.s;
    // Beside the button each text may wrap once, between words; with big
    // text both must fit on one line, as in `ValueRow`.
    final largeText = textScaleOf(context) >= 1.3 - 0.001;
    final maxLines = largeText ? 1 : 2;
    for (final copy in copies) {
      final title = titleOf(l10n, copy, now);
      final meta = metaOf(l10n, copy);
      if (longestWordWidth(context, title, titleStyle) > room ||
          longestWordWidth(context, meta, metaStyle) > room ||
          textLineCount(context, title, titleStyle, room) > maxLines ||
          textLineCount(context, meta, metaStyle, room) > maxLines) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final inline = _inline(context, box.maxWidth);
        return SettingsSection(
          title: l10n.backupUiSectionCopies,
          children: [
            for (final copy in copies)
              _CopyRow(
                key: ValueKey('backup-copy-${copy.id}'),
                copy: copy,
                title: titleOf(l10n, copy, now),
                meta: metaOf(l10n, copy),
                restoreLabel: l10n.backupUiCopyRestoreLabel(
                  backupWhen(l10n, copy.entry.modifiedAt, now),
                ),
                inline: inline,
                onRestore: () => onRestore(copy),
              ),
          ],
        );
      },
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    super.key,
    required this.copy,
    required this.title,
    required this.meta,
    required this.restoreLabel,
    required this.inline,
    required this.onRestore,
  });

  final BackupCopy copy;
  final String title;
  final String meta;
  final String restoreLabel;
  final bool inline;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final icon = copy.kind == BackupCopyKind.safety
        ? BackupIcons.restore
        : BackupIcons.save;
    // The pill is wider than its text by `buttonPad` on each side; moving it
    // out by that much puts the text on the edge: the right one beside the
    // chevron column, the left one on the title.
    Widget button({required bool stacked}) => Transform.translate(
      offset: Offset(
        stacked ? -BackupCopyList.buttonPad : BackupCopyList.buttonPad,
        0,
      ),
      child: Semantics(
        label: restoreLabel,
        button: true,
        excludeSemantics: true,
        child: TextButton(
          key: ValueKey('backup-restore-${copy.id}'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: BackupCopyList.buttonPad,
              vertical: Sp.s,
            ),
          ),
          onPressed: onRestore,
          child: Text(l10n.backupUiCopyRestore),
        ),
      ),
    );

    if (inline) {
      return SettingsRow(
        icon: icon,
        title: title,
        subtitle: meta,
        trailing: button(stacked: false),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(icon: icon, title: title, subtitle: meta),
        Padding(
          padding: const EdgeInsets.only(
            left: Sp.l + SettingsRow.leadingWidth,
            bottom: Sp.xs,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: button(stacked: true),
          ),
        ),
      ],
    );
  }
}
