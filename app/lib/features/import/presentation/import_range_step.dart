import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/icons/app_icons.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/import_wizard.dart';
import '../domain/import_models.dart';
import 'import_format.dart';
import 'import_step_layout.dart';
import 'import_date_row.dart';

/// Step 3: the days to look at. Starts with the last 12 months and the next
/// 6 (for a file, with the days it mentions).
class ImportRangeStep extends ConsumerStatefulWidget {
  const ImportRangeStep({super.key});

  @override
  ConsumerState<ImportRangeStep> createState() => _ImportRangeStepState();
}

class _ImportRangeStepState extends ConsumerState<ImportRangeStep> {
  bool _clamped = false;

  Future<void> _pick({required bool start}) async {
    final wizard = ref.read(importWizardProvider);
    final range = wizard.range;
    final current = start ? range.from : range.to;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: start
          ? context.l10n.importRangeFrom
          : context.l10n.importRangeTo,
    );
    if (picked == null || !mounted) return;
    final day = CivilDate.fromDateTime(picked);
    var next = start ? range.copyWith(from: day) : range.copyWith(to: day);
    // Moving "Desde" past "Hasta" (or the other way) drags the other end.
    if (!next.isValid) next = ImportRange(day, day);
    setState(() => _clamped = next.days > maxImportRangeDays);
    ref.read(importWizardProvider.notifier).setRange(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    final range = wizard.range;
    final doc = wizard.ics;
    final backup = wizard.lrhsoft;

    return ImportStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.importRangeTitle,
              key: const ValueKey('import-title'),
              style: type.headline,
            ),
          ),
          const SizedBox(height: Sp.s),
          Text(
            l10n.importRangeHelp,
            style: type.body.copyWith(color: colors.textSecondary),
          ),
          if (importFileLine(l10n, wizard) case final fileLine?) ...[
            const SizedBox(height: Sp.m),
            Text(
              fileLine,
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          ],
          if (doc != null) ...[
            const SizedBox(height: Sp.xs),
            Text(
              l10n.importRangeFileEvents(doc.events.length),
              key: const ValueKey('import-file-events'),
              style: type.meta.copyWith(color: colors.textMuted),
            ),
            if (doc.skippedEvents > 0)
              Text(
                l10n.importRangeFileSkipped(doc.skippedEvents),
                style: type.meta.copyWith(color: colors.textMuted),
              ),
            if (doc.unsupportedRules > 0)
              Text(
                l10n.importRangeFileRules(doc.unsupportedRules),
                style: type.meta.copyWith(color: colors.textMuted),
              ),
          ],
          if (backup != null) ...[
            const SizedBox(height: Sp.xs),
            Text(
              l10n.importRangeLrhsoftDays(backup.days.length),
              key: const ValueKey('import-file-days'),
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: Sp.l),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ImportDateRow(
                  key: const ValueKey('import-range-from'),
                  label: l10n.importRangeFrom,
                  value: importDateText(context, range.from),
                  onTap: () => _pick(start: true),
                ),
                Divider(height: 1, thickness: 1, color: colors.border),
                ImportDateRow(
                  key: const ValueKey('import-range-to'),
                  label: l10n.importRangeTo,
                  value: importDateText(context, range.to),
                  onTap: () => _pick(start: false),
                ),
              ],
            ),
          ),
          if (_clamped) ...[
            const SizedBox(height: Sp.m),
            Text(
              l10n.importRangeClamped,
              key: const ValueKey('import-range-clamped'),
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: Sp.m),
          Align(
            alignment: Alignment.centerLeft,
            child: SecondaryButton(
              key: const ValueKey('import-range-default'),
              expand: false,
              label: l10n.importRangeDefault,
              onPressed: () {
                final today = CivilDate.fromDateTime(ref.read(clockProvider)());
                setState(() => _clamped = false);
                notifier.setRange(ImportRange.around(today));
              },
            ),
          ),
          if (wizard.problem != null) ...[
            const SizedBox(height: Sp.l),
            AppCallout(
              titleKey: const ValueKey('import-problem'),
              icon: AppIcons.error,
              title: importProblemText(l10n, wizard.problem!),
            ),
          ],
          if (wizard.busy)
            Padding(
              padding: const EdgeInsets.only(top: Sp.l),
              child: Row(
                children: [
                  const ButtonSpinner(),
                  const SizedBox(width: Sp.m),
                  Text(l10n.importReading, style: type.body),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
