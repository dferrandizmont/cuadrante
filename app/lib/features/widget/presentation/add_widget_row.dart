import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/settings_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/widget_providers.dart';
import '../data/widget_publisher.dart';

/// Settings row "Añadir widget": opens the sheet that pins a widget (Android
/// launchers that support it) or explains how to add one by hand.
class AddWidgetSettingsRow extends ConsumerWidget {
  const AddWidgetSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SettingsRow(
      key: const ValueKey('settings-widget'),
      icon: SettingsIcons.widget,
      title: l10n.widgetAddTitle,
      subtitle: l10n.widgetAddSubtitle,
      onTap: () =>
          showAddWidgetSheet(context, ref.read(widgetPublisherProvider)),
    );
  }
}

/// The "Añadir widget" sheet. With [publisher] able to pin, it offers the five
/// layouts; otherwise it explains the manual steps of the platform.
Future<void> showAddWidgetSheet(
  BuildContext context,
  WidgetPublisher publisher,
) {
  return showAppSheet<void>(
    context: context,
    padded: true,
    builder: (sheetContext) => _AddWidgetSheet(publisher: publisher),
  );
}

class _AddWidgetSheet extends StatelessWidget {
  const _AddWidgetSheet({required this.publisher});

  final WidgetPublisher publisher;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return FutureBuilder<bool>(
      future: publisher.canPin(),
      builder: (context, snapshot) {
        final canPin = snapshot.data ?? false;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.s),
              child: Semantics(
                header: true,
                child: Text(l10n.widgetAddTitle, style: type.headline),
              ),
            ),
            Text(l10n.widgetAddBody, style: type.body),
            const SizedBox(height: Sp.m),
            if (canPin) ...[
              PrimaryButton(
                key: const ValueKey('widget-pin-small'),
                label: l10n.widgetAddSmall,
                onPressed: () {
                  Navigator.pop(context);
                  publisher.requestPin(WidgetSize.small);
                },
              ),
              const SizedBox(height: Sp.s),
              SecondaryButton(
                key: const ValueKey('widget-pin-medium'),
                label: l10n.widgetAddMedium,
                onPressed: () {
                  Navigator.pop(context);
                  publisher.requestPin(WidgetSize.medium);
                },
              ),
              const SizedBox(height: Sp.s),
              SecondaryButton(
                key: const ValueKey('widget-pin-large'),
                label: l10n.widgetAddLarge,
                onPressed: () {
                  Navigator.pop(context);
                  publisher.requestPin(WidgetSize.large);
                },
              ),
              const SizedBox(height: Sp.s),
              SecondaryButton(
                key: const ValueKey('widget-pin-agenda'),
                label: l10n.widgetAddAgenda,
                onPressed: () {
                  Navigator.pop(context);
                  publisher.requestPin(WidgetSize.agenda);
                },
              ),
              const SizedBox(height: Sp.s),
              SecondaryButton(
                key: const ValueKey('widget-pin-two-weeks'),
                label: l10n.widgetAddTwoWeeks,
                onPressed: () {
                  Navigator.pop(context);
                  publisher.requestPin(WidgetSize.twoWeeks);
                },
              ),
            ] else
              Text(
                key: const ValueKey('widget-add-manual'),
                ios ? l10n.widgetAddManualIos : l10n.widgetAddManualAndroid,
                style: type.body.copyWith(color: colors.textSecondary),
              ),
          ],
        );
      },
    );
  }
}
