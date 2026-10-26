import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/icons/selection_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// "Ajustes > Mis rotaciones": the patterns running on the calendar, each
/// with its dates, to end it on a day you choose («Terminar aquí») or to
/// remove it altogether («Eliminar»). Either is ONE undoable step; the days
/// you changed by hand and the notes stay.
class RunsScreen extends ConsumerWidget {
  const RunsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final today = CivilDate.fromDateTime(ref.watch(minuteClockProvider));
    final runs = [...schedule.runs]
      ..sort((a, b) {
        final byStart = a.startDate.compareTo(b.startDate);
        return byStart != 0 ? byStart : a.seq.compareTo(b.seq);
      });

    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.selectionRunsTitle),
      ),
      body: PageBody(
        child: runs.isEmpty
            ? EmptyState(
                icon: SelectionIcons.rotations,
                title: l10n.selectionRunsEmptyTitle,
                message: l10n.selectionRunsEmptyMessage,
              )
            : ListView.separated(
                key: const ValueKey('runs-list'),
                padding: const EdgeInsets.fromLTRB(
                  Sp.page,
                  Sp.s,
                  Sp.page,
                  Sp.section,
                ),
                itemCount: runs.length,
                separatorBuilder: (_, _) => const SizedBox(height: Sp.card),
                itemBuilder: (context, index) {
                  final run = runs[index];
                  return _RunCard(
                    key: ValueKey('run-${run.id}'),
                    run: run,
                    patternName:
                        schedule.patternById(run.patternId)?.name ??
                        run.patternId,
                    today: today,
                  );
                },
              ),
      ),
    );
  }
}

class _RunCard extends ConsumerWidget {
  const _RunCard({
    super.key,
    required this.run,
    required this.patternName,
    required this.today,
  });

  final PatternRun run;
  final String patternName;
  final CivilDate today;

  bool get _ended => run.endDate != null && run.endDate!.isBefore(today);

  /// The earliest "first day without it" that shortens the run, and the
  /// latest the date picker offers. `null` when it cannot be shortened (one
  /// day long, or already ended).
  (CivilDate, CivilDate)? get _endRange {
    final first = run.startDate.addDays(1);
    final last = run.endDate ?? _later(today, first).addDays(366 * 3);
    return last.isBefore(first) || _ended ? null : (first, last);
  }

  static CivilDate _later(CivilDate a, CivilDate b) => a.isAfter(b) ? a : b;

  DateTime _date(CivilDate d) => DateTime(d.year, d.month, d.day);

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final range = _endRange;
    if (range == null) return;
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final (first, last) = range;
    final initial = _later(today, first);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date(initial.isAfter(last) ? last : initial),
      firstDate: _date(first),
      lastDate: _date(last),
      helpText: l10n.selectionRunsEndHelp,
    );
    if (picked == null || !context.mounted) return;
    final firstFree = CivilDate.fromDateTime(picked);
    final step = controller.endRun(run.id, firstFree);
    if (step == null) return;
    // `endDate` is inclusive (docs/motor-de-turnos.md): the run ends the day
    // BEFORE the one picked, and that is the day the card shows. The notice
    // used to name the picked day, which contradicted the card (H-T06-1).
    final lastDay = firstFree.addDays(-1);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          context: context,
          content: Text(
            l10n.selectionRunsEndDone(format.longDate(_date(lastDay))),
          ),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => controller.undoIfLast(step),
          ),
        ),
      );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final ok = await showConfirmDialog(
      context,
      title: l10n.selectionRunsDeleteTitle(patternName),
      body: l10n.selectionRunsDeleteBody,
      confirmLabel: l10n.selectionRunsDelete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final step = controller.deleteRun(run.id);
    if (step == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          context: context,
          content: Text(l10n.selectionRunsDeleted),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => controller.undoIfLast(step),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final from = format.longDate(_date(run.startDate));
    final range = run.endDate == null
        ? l10n.selectionRunsOpenEnded(from)
        : l10n.selectionRunsRange(from, format.longDate(_date(run.endDate!)));
    final status = _ended
        ? l10n.selectionRunsEnded
        : run.startDate.isAfter(today)
        ? l10n.selectionRunsFuture
        : l10n.selectionRunsActive;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(patternName, style: type.bodyStrong),
          ),
          const SizedBox(height: Sp.xs),
          Text(range, style: type.body.copyWith(color: colors.textSecondary)),
          // Several runs of the same pattern are told apart by where in the
          // cycle each one starts (H-T06-2).
          Text(
            l10n.selectionRunsStep(run.stepOffset + 1),
            key: ValueKey('run-step-${run.id}'),
            style: type.meta,
          ),
          Text(
            status,
            key: ValueKey('run-status-${run.id}'),
            style: type.meta.copyWith(
              color: _ended ? colors.textMuted : colors.accentText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Sp.m),
          Wrap(
            spacing: Sp.s,
            runSpacing: Sp.s,
            children: [
              SecondaryButton(
                key: ValueKey('run-end-${run.id}'),
                icon: SelectionIcons.endRun,
                label: l10n.selectionRunsEnd,
                expand: false,
                onPressed: _endRange == null ? null : () => _end(context, ref),
              ),
              SecondaryButton(
                key: ValueKey('run-delete-${run.id}'),
                icon: AppIcons.remove,
                label: l10n.selectionRunsDelete,
                expand: false,
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
