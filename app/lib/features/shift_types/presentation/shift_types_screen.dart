import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/money.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/format/text_wrap.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/shift_badge.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';

/// "Ajustes > Mis turnos": the shift types of the palette in paint order.
/// Drag the handle to reorder, tap a row to edit it, archive to take it out
/// of the palette (days that already use it keep showing it) and add a new
/// one at the end. The archived ones wait in a collapsed «Archivados» section
/// at the end, each with «Recuperar» (H-T05-3).
class ShiftTypesScreen extends ConsumerWidget {
  const ShiftTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    // Archived = in the schedule, out of the palette (watching the schedule
    // too: restoring changes only the palette).
    ref.watch(scheduleControllerProvider.select((s) => s.schedule.shiftTypes));
    final controller = ref.read(scheduleControllerProvider.notifier);
    final archived = controller.archivedShiftTypes;

    Future<void> archive(ShiftType shift) async {
      final ok = await showConfirmDialog(
        context,
        title: l10n.shiftTypesArchiveTitle(shift.name),
        body: l10n.shiftTypesArchiveBody,
        confirmLabel: l10n.shiftTypesArchiveConfirm,
        destructive: true,
      );
      if (ok) controller.archiveShiftType(shift.id);
    }

    void restore(ShiftType shift) {
      controller.restoreShiftType(shift.id);
      // One undo step: archive it again.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          appSnackBar(
            context: context,
            content: Text(l10n.shiftTypesRestored(shift.name)),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => controller.archiveShiftType(shift.id),
            ),
          ),
        );
    }

    void reorder(int oldIndex, int newIndex) {
      final ids = [for (final t in palette) t.id];
      final moved = ids.removeAt(oldIndex);
      ids.insert(newIndex, moved);
      controller.reorderShiftTypes(ids);
    }

    // With every shift type archived the list is just the archived section:
    // that is where they come back from.
    final showList = palette.isNotEmpty || archived.isNotEmpty;

    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.shiftTypesTitle),
      ),
      // Pinned, so "Nuevo turno" never hides under a long list.
      bottomNavigationBar: !showList
          ? null
          : Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sp.maxContentWidth),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Sp.page,
                      Sp.s,
                      Sp.page,
                      Sp.l,
                    ),
                    child: PrimaryButton(
                      key: const ValueKey('shift-new'),
                      label: l10n.shiftTypesNew,
                      icon: AppIcons.add,
                      onPressed: () => context.push(AppRoutes.shiftTypeNew),
                    ),
                  ),
                ),
              ),
            ),
      body: PageBody(
        child: !showList
            ? EmptyState(
                icon: AppIcons.paint,
                title: l10n.shiftTypesEmptyTitle,
                message: l10n.shiftTypesEmptyMessage,
                primaryAction: true,
                actionLabel: l10n.shiftTypesNew,
                onAction: () => context.push(AppRoutes.shiftTypeNew),
              )
            : ReorderableListView.builder(
                key: const ValueKey('shift-list'),
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(
                  Sp.page,
                  Sp.s,
                  Sp.page,
                  Sp.section,
                ),
                itemCount: palette.length,
                onReorderItem: reorder,
                proxyDecorator: (child, _, _) =>
                    Material(color: Colors.transparent, child: child),
                footer: archived.isEmpty
                    ? null
                    : _ArchivedSection(shifts: archived, onRestore: restore),
                itemBuilder: (context, index) {
                  final shift = palette[index];
                  return Padding(
                    key: ValueKey('shift-row-${shift.id}'),
                    padding: const EdgeInsets.only(bottom: Sp.card),
                    child: _ShiftRow(
                      shift: shift,
                      index: index,
                      onEdit: () =>
                          context.push(AppRoutes.shiftTypeEdit(shift.id)),
                      onArchive: () => archive(shift),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Times, category and any hourly rate or fixed plus of a shift type.
({String semantic, String shown}) _details(
  BuildContext context,
  ShiftType shift,
) {
  final l10n = context.l10n;
  final format = AppDateFormat.of(context);
  final times = shift.timeRange(format) ?? l10n.shiftTypesNoTimes;
  final category = switch (shift.category) {
    ShiftCategory.work => l10n.shiftTypesCategoryWork,
    ShiftCategory.rest => l10n.shiftTypesCategoryRest,
    ShiftCategory.absence => l10n.shiftTypesCategoryAbsence,
  };
  final rate = shift.hourlyRateCents;
  final plus = shift.fixedPlusCents;
  final rest = [
    category,
    if (rate != null)
      l10n.shiftTypesRatePerHour(formatEuro(context, rate / 100)),
    if (plus != null)
      l10n.shiftTypesFixedPlusPerShift(formatEuroCents(context, plus)),
  ].join(' · ');
  // Two segments make a long line: the times get their own, so the category
  // never ends up alone on a second line by chance (H-T05-8).
  final split = shift.segment2StartMinute != null;
  final details = split ? '$times\n$rest' : '$times · $rest';
  // The time ranges are one word for the line breaker: «08:00–16:00 ·
  // 17:00–21:00» wrapped as «08:00– / 16:00 · 17:00– / 21:00» (H-T05-2).
  return (
    semantic: details.replaceAll('\n', ' · '),
    shown: keepTimeRangesTogether(details),
  );
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    required this.shift,
    required this.index,
    required this.onEdit,
    required this.onArchive,
  });

  final ShiftType shift;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  /// Left margin, badge and gap before the text.
  static const double _lead = Sp.m + Disc.l + Sp.m;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final details = _details(context, shift);
    final detailStyle = AppTypography.tabular(
      type.meta.copyWith(color: colors.textSecondary),
    );

    final archiveButton = IconButton(
      key: ValueKey('shift-archive-${shift.id}'),
      tooltip: l10n.shiftTypesArchive,
      icon: Icon(AppIcons.archive),
      onPressed: onArchive,
    );
    final handle = ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: l10n.shiftTypesDragHandle,
        child: SizedBox.square(
          dimension: Sp.touch,
          child: Icon(
            AppIcons.dragHandle,
            key: ValueKey('shift-handle-${shift.id}'),
            color: colors.textMuted,
          ),
        ),
      ),
    );
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shift.name, style: type.bodyStrong),
          Text(details.shown, style: detailStyle),
        ],
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      semanticLabel: '${shift.name}. ${details.semantic}',
      onTap: onEdit,
      child: LayoutBuilder(
        builder: (context, box) {
          // The two round buttons take 96 dp beside the text; when the
          // longest word of the name or of the details does not fit in what
          // is left (large text, a 320 dp phone) they go under it, and the
          // text keeps the whole row (H-T05-2).
          final word = math.max(
            longestWordWidth(context, shift.name, type.bodyStrong),
            longestWordWidth(context, details.shown, detailStyle),
          );
          final beside = word <= box.maxWidth - _lead - 2 * Sp.touch - Sp.xs;
          final lead = [
            const SizedBox(width: Sp.m),
            ShiftBadge(shift: shift),
            const SizedBox(width: Sp.m),
          ];
          if (beside) {
            return Row(
              children: [
                ...lead,
                Expanded(child: text),
                archiveButton,
                handle,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...lead.map(
                    (w) => w is ShiftBadge
                        ? Padding(
                            padding: const EdgeInsets.only(top: Sp.m),
                            child: w,
                          )
                        : w,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: Sp.m),
                      child: text,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [archiveButton, handle],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// «Archivados (2)»: collapsed by default; open, each archived shift type with
/// «Recuperar».
class _ArchivedSection extends StatefulWidget {
  const _ArchivedSection({required this.shifts, required this.onRestore});

  final List<ShiftType> shifts;
  final ValueChanged<ShiftType> onRestore;

  @override
  State<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _ArchivedSectionState extends State<_ArchivedSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    return Column(
      key: const ValueKey('shift-archived'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          expanded: _open,
          child: InkWell(
            key: const ValueKey('shift-archived-toggle'),
            borderRadius: Rad.chipSmallRadius,
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sp.touch),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.xs,
                  vertical: Sp.s,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.shiftTypesArchivedSection(widget.shifts.length),
                        style: type.label.copyWith(color: colors.textMuted),
                      ),
                    ),
                    Icon(
                      _open ? AppIcons.arrowUp : AppIcons.arrowDown,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.s),
            child: Text(
              l10n.shiftTypesArchivedHelp,
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          ),
          for (final shift in widget.shifts)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.card),
              child: _ArchivedRow(
                key: ValueKey('shift-archived-row-${shift.id}'),
                shift: shift,
                onRestore: () => widget.onRestore(shift),
              ),
            ),
        ],
      ],
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({super.key, required this.shift, required this.onRestore});

  final ShiftType shift;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final details = _details(context, shift);
    return AppCard(
      padding: const EdgeInsets.all(Sp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShiftBadge(shift: shift),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shift.name, style: type.bodyStrong),
                    Text(
                      details.shown,
                      style: AppTypography.tabular(
                        type.meta.copyWith(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.s),
          Semantics(
            label: l10n.shiftTypesRestoreSemantic(shift.name),
            excludeSemantics: true,
            button: true,
            onTap: onRestore,
            child: SecondaryButton(
              key: ValueKey('shift-restore-${shift.id}'),
              label: l10n.shiftTypesRestore,
              icon: AppIcons.undo,
              expand: false,
              onPressed: onRestore,
            ),
          ),
        ],
      ),
    );
  }
}
