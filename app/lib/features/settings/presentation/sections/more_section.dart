import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/icons/settings_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router.dart';
import '../../../alarms/presentation/alarms_settings_row.dart';
import '../../../holidays/presentation/holidays_settings_row.dart';
import '../../../widget/presentation/add_widget_row.dart';
import '../settings_widgets.dart';

/// Holidays, alarms, backup and the widget: the rows of "Avisos y datos",
/// each opening the screen of its feature.
class MoreSection extends StatelessWidget {
  const MoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSection(
      title: l10n.settingsSectionMore,
      children: [
        const HolidaysSettingsRow(),
        const AlarmsSettingsRow(),
        SettingsRow(
          key: const ValueKey('settings-backup'),
          icon: SettingsIcons.backup,
          title: l10n.settingsBackupTitle,
          subtitle: l10n.backupUiRowSubtitle,
          onTap: () => context.push(AppRoutes.settingsBackup),
        ),
        const AddWidgetSettingsRow(),
      ],
    );
  }
}
