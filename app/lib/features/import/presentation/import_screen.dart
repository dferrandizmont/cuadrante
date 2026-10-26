import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/application/visible_month.dart';
import '../application/import_wizard.dart';
import '../data/import_file_picker.dart';
import 'import_calendars_step.dart';
import 'import_columns_step.dart';
import 'import_mapping_step.dart';
import 'import_preview_step.dart';
import 'import_range_step.dart';
import 'import_source_step.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Importar turnos (`/ajustes/importar`): bring the shifts of a calendar of
/// the phone, an `.ics` or a CSV. Source, (calendars | columns), dates,
/// titles to shifts and a preview; the result is applied as ONE undoable step
/// on the calendar being shown (docs/importar.md).
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.initialFile, this.initialPick});

  /// A file the system handed to the app: the wizard starts reading it.
  final PickedImportFile? initialFile;

  /// A kind of file to ask for as soon as the screen opens (the first use
  /// offers the LRHSoft backup directly).
  final ImportFileKind? initialPick;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  void initState() {
    super.initState();
    final file = widget.initialFile;
    final pick = widget.initialPick;
    if (file != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(importWizardProvider.notifier).loadFile(file);
      });
    } else if (pick != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(importWizardProvider.notifier).chooseFile(pick);
      });
    }
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // The notice outlives this screen (the app goes to the calendar), so
    // what it needs to show the undo message is taken now.
    final cover = ref.read(snackBarCoverProvider.notifier);
    final clearance = snackBarClearance(context);
    final router = GoRouter.of(context);
    final schedule = ref.read(scheduleControllerProvider.notifier);
    final month = ref.read(visibleMonthProvider.notifier);
    final fromLrhsoft =
        ref.read(importWizardProvider).source == ImportSourceKind.lrhsoftFile;
    final invalidRows = ref.read(importWizardProvider).skippedRows;
    final outcome = ref.read(importWizardProvider.notifier).apply();
    if (outcome == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(appSnackBar(content: Text(l10n.importApplyFailed)));
      return;
    }
    month.goTo(outcome.firstDay);
    // The calendar, on the first month imported, with the notice and its
    // «Deshacer» over it: the way to check what the import did, instead of
    // going back to Ajustes (H-T14-7). The notice is shown first, from this
    // screen, and survives the navigation (it lives in the app's messenger).
    showTrackedSnackBar(
      ref,
      context,
      content: Text(
        [
          outcome.notesOnly
              ? l10n.importAppliedNotes(outcome.notes)
              : outcome.newTypes == 0
              ? l10n.importApplied(outcome.days)
              : l10n.importAppliedWithTypes(outcome.days, outcome.newTypes),
          // What a backup of another app leaves behind is said, not lost
          // in silence.
          if (fromLrhsoft && invalidRows > 0)
            l10n.importMappingInvalidRows(invalidRows),
          if (fromLrhsoft) l10n.importLrhsoftNotImported,
        ].join(' '),
      ),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: l10n.undo,
        // Only while the import is still the latest thing done.
        onPressed: () => _undo(
          outcome,
          schedule: schedule,
          l10n: l10n,
          messenger: messenger,
          cover: cover,
          clearance: clearance,
        ),
      ),
    );
    router.go(AppRoutes.home);
  }

  /// The «Deshacer» of the import: the days and the notes go back, and the
  /// shift types the import created go too, unless something uses them by
  /// then (H-T22-8). The ones that stay are said.
  Future<void> _undo(
    ImportOutcome outcome, {
    required ScheduleController schedule,
    required AppLocalizations l10n,
    required ScaffoldMessengerState messenger,
    required SnackBarCover cover,
    required double clearance,
  }) async {
    final result = await schedule.undoImport(outcome.step, outcome.newTypeIds);
    // The import was not the latest thing done: nothing was undone, so
    // there is nothing to say.
    if (!result.undone) return;
    showTrackedSnackBarAfter(
      cover,
      messenger: messenger,
      clearance: clearance,
      content: Text(
        [
          l10n.importUndoDone,
          if (result.keptTypes.isNotEmpty)
            l10n.importUndoKeptTypes(
              result.keptTypes.length,
              result.keptTypes.join(', '),
            ),
        ].join(' '),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wizard = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    final steps = wizard.steps;
    final index = steps.indexOf(wizard.step);

    return PopScope(
      canPop: wizard.step == ImportStep.source,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.back();
      },
      child: Scaffold(
        appBar: ContentAppBar.adaptive(context, title: Text(l10n.importTitle)),
        body: PageBody(
          child: Column(
            children: [
              if (steps.length > 1)
                _StepIndicator(index: index, total: steps.length),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey('import-step-${wizard.step.name}'),
                  child: switch (wizard.step) {
                    ImportStep.source => const ImportSourceStep(),
                    ImportStep.calendars => const ImportCalendarsStep(),
                    ImportStep.range => const ImportRangeStep(),
                    ImportStep.columns => const ImportColumnsStep(),
                    ImportStep.mapping => const ImportMappingStep(),
                    ImportStep.preview => const ImportPreviewStep(),
                  },
                ),
              ),
              if (wizard.step != ImportStep.source) _BottomBar(onApply: _apply),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Paso 2 de 4» with one segment per step.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                Expanded(
                  child: SizedBox(
                    height: Sp.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i <= index ? colors.accent : colors.border,
                        borderRadius: Rad.pill,
                      ),
                    ),
                  ),
                ),
                if (i < total - 1) const SizedBox(width: Sp.xs),
              ],
            ],
          ),
          const SizedBox(height: Sp.s),
          Semantics(
            header: true,
            child: Text(
              context.l10n.importStepOf(index + 1, total),
              key: const ValueKey('import-step-of'),
              style: context.type.label.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Atrás» and the primary action of the step.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wizard = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    final busy = wizard.busy || wizard.applying;
    final preview = wizard.step == ImportStep.preview;
    final plan = preview ? ref.watch(importPlanProvider) : null;
    final mainLabel = preview
        ? wizard.mappedDays == 0
              ? l10n.importApplyNotes(plan?.notesWritten ?? 0)
              : l10n.importApply(plan?.written ?? 0)
        : l10n.importNext;

    final bool canGoOn = switch (wizard.step) {
      ImportStep.calendars =>
        wizard.selectedCalendars.isNotEmpty && wizard.access != null,
      ImportStep.range => wizard.range.isValid,
      ImportStep.columns => wizard.columns != null,
      ImportStep.mapping => wizard.canContinueFromMapping,
      ImportStep.preview => plan != null && !plan.isEmpty,
      ImportStep.source => false,
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.m),
        // «Atrás» next to the main action, or one under the other when the
        // words do not fit side by side: «Atrá / s» at x2.0 on 360 dp and a
        // bar a third of the screen tall (H-T14-1). Stacked, the main action
        // is on top.
        child: AdaptiveButtonRow(
          gap: Sp.m,
          primaryFirstWhenStacked: true,
          items: [
            ButtonRowItem(
              label: l10n.back,
              child: SecondaryButton(
                key: const ValueKey('import-back'),
                label: l10n.back,
                onPressed: busy ? null : notifier.back,
              ),
            ),
            ButtonRowItem(
              flex: 2,
              label: mainLabel,
              child: PrimaryButton(
                key: ValueKey(preview ? 'import-apply' : 'import-next'),
                label: mainLabel,
                loading: busy,
                onPressed: !canGoOn
                    ? null
                    : preview
                    ? onApply
                    : notifier.next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
