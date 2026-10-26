import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/import_wizard.dart';
import '../data/import_file_picker.dart';
import 'import_format.dart';
import 'import_step_layout.dart';
import 'import_icons.dart';

/// Step 1: where do the shifts come from?
class ImportSourceStep extends ConsumerWidget {
  const ImportSourceStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    final busy = wizard.busy;

    return ImportStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.importSourceTitle,
              key: const ValueKey('import-title'),
              style: type.headline,
            ),
          ),
          const SizedBox(height: Sp.s),
          Text(
            l10n.importSourceHelp,
            style: type.body.copyWith(color: colors.textSecondary),
          ),
          if (wizard.problem != null) ...[
            const SizedBox(height: Sp.l),
            AppCallout(
              titleKey: const ValueKey('import-problem'),
              icon: AppIcons.error,
              title: importProblemText(l10n, wizard.problem!),
            ),
          ],
          const SizedBox(height: Sp.l),
          SettingsSection(
            children: [
              SettingsRow(
                key: const ValueKey('import-source-lrhsoft'),
                icon: ImportIcons.backupFile,
                title: l10n.importSourceLrhsoft,
                subtitle: l10n.importSourceLrhsoftHelp,
                onTap: busy
                    ? null
                    : () => notifier.chooseFile(ImportFileKind.lrhsoft),
              ),
              SettingsRow(
                key: const ValueKey('import-source-device'),
                icon: AppIcons.calendar,
                title: l10n.importSourceDevice,
                subtitle: l10n.importSourceDeviceHelp,
                onTap: busy ? null : notifier.chooseDeviceCalendar,
              ),
              SettingsRow(
                key: const ValueKey('import-source-ics'),
                icon: ImportIcons.icsFile,
                title: l10n.importSourceIcs,
                subtitle: l10n.importSourceIcsHelp,
                onTap: busy
                    ? null
                    : () => notifier.chooseFile(ImportFileKind.ics),
              ),
              SettingsRow(
                key: const ValueKey('import-source-csv'),
                icon: ImportIcons.csvFile,
                title: l10n.importSourceCsv,
                subtitle: l10n.importSourceCsvHelp,
                onTap: busy
                    ? null
                    : () => notifier.chooseFile(ImportFileKind.csv),
              ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: Sp.l),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: Sp.section),
          AppCallout(
            icon: ImportIcons.lock,
            title: l10n.importHowToTitle,
            message: l10n.importHowToBody,
          ),
        ],
      ),
    );
  }
}
