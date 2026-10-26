import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../patterns/presentation/mini_month.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/import_wizard.dart';
import '../domain/import_plan.dart';
import 'import_format.dart';
import 'import_step_layout.dart';

/// Months drawn in the preview at most; the rest is only counted.
const int maxPreviewMonths = 24;

/// Step 5: what the calendar will look like, the choice for the days that
/// already have a shift, and the counts.
class ImportPreviewStep extends ConsumerWidget {
  const ImportPreviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final plan = ref.watch(importPlanProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    if (plan == null) return const SizedBox.shrink();
    final notesOnly = wizard.mappedDays == 0;

    final activeId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );
    final calendarName = ref
        .watch(calendarsControllerProvider)
        .value
        ?.calendars
        .where((c) => c.id == activeId)
        .map((c) => c.name)
        .firstOrNull;

    final months = <CivilDate>{
      for (final d in [...plan.changedDates, ...plan.conflictDates])
        d.firstDayOfMonth,
    }.toList()..sort();
    final shown = months.take(maxPreviewMonths).toList();

    final header = <Widget>[
      Semantics(
        header: true,
        child: Text(
          l10n.importPreviewTitle,
          key: const ValueKey('import-title'),
          style: type.headline,
        ),
      ),
      const SizedBox(height: Sp.s),
      Text(
        l10n.importPreviewHelp,
        style: type.body.copyWith(color: colors.textSecondary),
      ),
      if (calendarName != null) ...[
        const SizedBox(height: Sp.xs),
        Text(
          l10n.importPreviewTarget(calendarName),
          key: const ValueKey('import-preview-target'),
          style: type.meta.copyWith(color: colors.textMuted),
        ),
      ],
      const SizedBox(height: Sp.m),
      AppCard.tinted(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.isEmpty
                  ? l10n.importPreviewEmpty
                  : notesOnly
                  ? l10n.importPreviewNotes(plan.notesWritten)
                  : l10n.importPreviewDays(plan.written),
              key: const ValueKey('import-preview-days'),
              style: type.bodyStrong,
            ),
            if (plan.unchanged > 0)
              Text(
                l10n.importPreviewUnchanged(plan.unchanged),
                key: const ValueKey('import-preview-unchanged'),
                style: type.body.copyWith(color: colors.textSecondary),
              ),
            if (plan.newTypes.isNotEmpty)
              Text(
                l10n.importPreviewNewTypes(plan.newTypes.length),
                key: const ValueKey('import-preview-new-types'),
                style: type.body.copyWith(color: colors.textSecondary),
              ),
            if (plan.notesWritten > 0 && !notesOnly)
              Text(
                l10n.importPreviewNotes(plan.notesWritten),
                key: const ValueKey('import-preview-notes'),
                style: type.body.copyWith(color: colors.textSecondary),
              ),
            if (wizard.source == ImportSourceKind.lrhsoftFile) ...[
              if (wizard.skippedRows > 0)
                Text(
                  l10n.importMappingInvalidRows(wizard.skippedRows),
                  key: const ValueKey('import-preview-invalid-rows'),
                  style: type.body.copyWith(color: colors.textSecondary),
                ),
              Text(
                l10n.importLrhsoftNotImported,
                key: const ValueKey('import-preview-not-imported'),
                style: type.body.copyWith(color: colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      if (plan.conflicts > 0) ...[
        const SizedBox(height: Sp.l),
        Semantics(
          header: true,
          child: Text(
            l10n.importConflictsTitle(plan.conflicts),
            key: const ValueKey('import-conflicts'),
            style: type.bodyStrong,
          ),
        ),
        const SizedBox(height: Sp.hair),
        Text(
          l10n.importConflictsHelp,
          style: type.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: Sp.s),
        Wrap(
          spacing: Sp.s,
          runSpacing: Sp.s,
          children: [
            ChoicePill(
              key: const ValueKey('import-conflict-replace'),
              label: l10n.importConflictReplace,
              selected: wizard.policy == ConflictPolicy.replace,
              onTap: () => notifier.setPolicy(ConflictPolicy.replace),
            ),
            ChoicePill(
              key: const ValueKey('import-conflict-keep'),
              label: l10n.importConflictKeep,
              selected: wizard.policy == ConflictPolicy.keep,
              onTap: () => notifier.setPolicy(ConflictPolicy.keep),
            ),
          ],
        ),
        const SizedBox(height: Sp.s),
        Text(
          l10n.importConflictsExamples(
            importDateListText(context, plan.conflictDates.take(3)),
          ),
          style: type.meta.copyWith(color: colors.textMuted),
        ),
      ],
      const SizedBox(height: Sp.l),
    ];

    final footer = <Widget>[
      if (months.length > shown.length)
        Padding(
          padding: const EdgeInsets.only(top: Sp.s),
          child: Text(
            l10n.importPreviewMoreMonths(months.length - shown.length),
            key: const ValueKey('import-preview-more'),
            style: type.meta.copyWith(color: colors.textMuted),
          ),
        ),
    ];

    return ListView.builder(
      padding: importStepPadding,
      itemCount: header.length + shown.length + footer.length,
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final i = index - header.length;
        if (i < shown.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Sp.l),
            child: MiniMonth(
              month: shown[i],
              schedule: plan.result,
              keyPrefix: 'import-preview',
            ),
          );
        }
        return footer[i - shown.length];
      },
    );
  }
}
