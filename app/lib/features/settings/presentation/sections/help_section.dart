import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/icons/parity_icons.dart';
import '../../../../core/icons/settings_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers.dart';
import '../../../../core/router.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/buttons.dart';
import '../settings_widgets.dart';
import '../../../../core/widgets/app_snack_bar.dart';

/// Always delegates to another app; Cuadrante needs no network permission.
final privacyPolicyLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// "Ayuda": the frequently asked questions, contact and the "about" sheet
/// with the version and the licences.
class HelpSection extends ConsumerWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = _versionLabel(context, ref);
    final hasEmail = ref.watch(appConfigProvider).supportEmail.isNotEmpty;
    return SettingsSection(
      title: l10n.settingsSectionHelp,
      children: [
        SettingsRow(
          key: const ValueKey('settings-faq'),
          icon: ParityIcons.faq,
          title: l10n.settingsFaqTitle,
          subtitle: l10n.settingsFaqSubtitle,
          onTap: () => context.push(AppRoutes.settingsFaq),
        ),
        SettingsRow(
          key: const ValueKey('settings-help'),
          icon: SettingsIcons.help,
          title: l10n.settingsHelpTitle,
          // Without an address the row does not promise a reply (H-T15-2).
          subtitle: hasEmail
              ? l10n.settingsHelpSubtitle
              : l10n.settingsHelpSubtitleSoon,
          onTap: () => showContactSheet(context, ref),
        ),
        SettingsRow(
          key: const ValueKey('settings-privacy'),
          icon: SettingsIcons.privacy,
          title: l10n.settingsPrivacyTitle,
          subtitle: l10n.settingsPrivacySubtitle,
          onTap: () => _openPrivacyPolicy(context, ref),
        ),
        SettingsRow(
          key: const ValueKey('settings-about'),
          icon: SettingsIcons.about,
          title: l10n.settingsAboutTitle,
          value: version,
          onTap: () => _showAbout(context, ref),
        ),
      ],
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context, WidgetRef ref) async {
    final url = ref
        .read(appConfigProvider)
        .privacyUrlFor(Localizations.localeOf(context).languageCode);
    final uri = Uri.tryParse(url);
    var opened = false;
    try {
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        opened = await ref.read(privacyPolicyLauncherProvider)(uri);
      }
    } on Exception {
      // A missing browser or a platform failure must leave Settings usable.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        appSnackBar(content: Text(context.l10n.settingsPrivacyOpenFailed)),
      );
    }
  }

  /// "Versión 0.3.0", or "Versión de desarrollo" in a build without
  /// `--dart-define=APP_VERSION`.
  static String _versionLabel(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.read(appConfigProvider).appVersion;
    return version.isEmpty
        ? l10n.settingsAboutVersionDev
        : l10n.settingsAboutVersion(version);
  }

  /// Contact details. The app has no mail launcher yet, so the address (when
  /// the build sets one) and the version are offered to copy. Also opened
  /// from the frequently asked questions.
  static Future<void> showContactSheet(BuildContext context, WidgetRef ref) {
    final config = ref.read(appConfigProvider);
    final version = _versionLabel(context, ref);
    return showAppSheet<void>(
      context: context,
      padded: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final colors = sheetContext.colors;
        final type = sheetContext.type;

        // Copies and closes the sheet, then says so in a SnackBar: a SnackBar
        // shown while the sheet is open sits under its barrier and is not
        // seen (H-T15-3).
        Future<void> copy(String text, String done) async {
          final messenger = ScaffoldMessenger.maybeOf(sheetContext);
          await Clipboard.setData(ClipboardData(text: text));
          if (sheetContext.mounted) Navigator.pop(sheetContext);
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(appSnackBar(content: Text(done)));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: Semantics(
                header: true,
                child: Text(l10n.settingsHelpTitle, style: type.headline),
              ),
            ),
            Text(
              config.supportEmail.isEmpty
                  ? l10n.settingsHelpBodySoon
                  : l10n.settingsHelpBody,
              style: type.body,
            ),
            const SizedBox(height: Sp.m),
            Text(
              '${l10n.appName} · $version',
              style: type.meta.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: Sp.l),
            if (config.supportEmail.isEmpty)
              // A sentence of support, not a title: the body style, quiet
              // (H-T15-7).
              Text(
                l10n.settingsHelpNoEmail,
                key: const ValueKey('help-no-email'),
                style: type.body.copyWith(color: colors.textSecondary),
              )
            else ...[
              SelectableText(config.supportEmail, style: type.bodyStrong),
              const SizedBox(height: Sp.m),
              PrimaryButton(
                key: const ValueKey('help-copy-email'),
                label: l10n.settingsHelpCopyEmail,
                icon: SettingsIcons.copy,
                onPressed: () =>
                    copy(config.supportEmail, l10n.settingsEmailCopied),
              ),
            ],
            const SizedBox(height: Sp.s),
            SecondaryButton(
              key: const ValueKey('help-copy-version'),
              label: l10n.settingsHelpCopyVersion,
              icon: SettingsIcons.copy,
              onPressed: () => copy(
                '${l10n.appName} · $version',
                l10n.settingsVersionCopied,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAbout(BuildContext context, WidgetRef ref) {
    final label = _versionLabel(context, ref);
    return showAppSheet<void>(
      context: context,
      padded: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final colors = sheetContext.colors;
        final type = sheetContext.type;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.xs),
              child: Semantics(
                header: true,
                child: Text(l10n.appName, style: type.headline),
              ),
            ),
            Text(label, style: type.meta.copyWith(color: colors.textMuted)),
            const SizedBox(height: Sp.m),
            Text(l10n.settingsAboutTagline, style: type.body),
            const SizedBox(height: Sp.l),
            SecondaryButton(
              key: const ValueKey('about-licenses'),
              label: l10n.settingsAboutLicenses,
              onPressed: () {
                Navigator.pop(sheetContext);
                // The page takes its labels («Licencias», «1 licencia») from
                // the Spanish Material strings; these three are ours. Flutter
                // writes «Powered by Flutter» in the header itself, in English
                // and not through a localization, so it cannot be translated.
                showLicensePage(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: label,
                  applicationLegalese: l10n.settingsAboutTagline,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
