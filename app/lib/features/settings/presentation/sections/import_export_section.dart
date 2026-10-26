import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router.dart';
import '../../../import/presentation/import_icons.dart';
import '../settings_widgets.dart';

/// «Importar y exportar»: bring the shifts from the calendar of the phone or
/// a file, and copy them out once to the calendar of the phone.
class ImportExportSection extends StatelessWidget {
  const ImportExportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSection(
      title: l10n.importSectionTitle,
      children: [
        SettingsRow(
          key: const ValueKey('settings-import'),
          icon: ImportIcons.importData,
          title: l10n.importRowTitle,
          subtitle: l10n.importRowSubtitle,
          onTap: () => context.push(AppRoutes.settingsImport),
        ),
        SettingsRow(
          key: const ValueKey('settings-export-calendar'),
          icon: ImportIcons.exportData,
          title: l10n.calExportRowTitle,
          subtitle: l10n.calExportRowSubtitle,
          onTap: () => context.push(AppRoutes.settingsExport),
        ),
      ],
    );
  }
}
