import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/shift_badge.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/import_wizard.dart';
import '../domain/event_grouping.dart';
import '../domain/import_models.dart';
import '../domain/import_plan.dart';
import 'import_format.dart';
import 'import_step_layout.dart';
import 'new_type_sheet.dart';

/// Step 4: every title found, with how many days it covers and its usual
/// hours, and the shift it becomes (suggested when the name or the hours
/// match), a new shift type or nothing.
class ImportMappingStep extends ConsumerWidget {
  const ImportMappingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final groups = wizard.groups;

    final header = <Widget>[
      Semantics(
        header: true,
        child: Text(
          l10n.importMappingTitle,
          key: const ValueKey('import-title'),
          style: type.headline,
        ),
      ),
      const SizedBox(height: Sp.s),
      Text(
        l10n.importMappingHelp,
        style: type.body.copyWith(color: colors.textSecondary),
      ),
      const SizedBox(height: Sp.s),
      Text(
        groups.isEmpty && wizard.hasImportableNotes
            ? l10n.importNoteCount(wizard.notes.length)
            : l10n.importMappingSummary(wizard.coveredDays, groups.length),
        key: const ValueKey('import-mapping-summary'),
        style: type.meta.copyWith(color: colors.textMuted),
      ),
      if (wizard.truncated) ...[
        const SizedBox(height: Sp.m),
        AppCallout(
          titleKey: const ValueKey('import-truncated'),
          icon: AppIcons.error,
          title: l10n.importMappingTruncated(importLimitText(maxImportEvents)),
        ),
      ],
      if (wizard.skippedRows > 0) ...[
        const SizedBox(height: Sp.m),
        Text(
          wizard.source == ImportSourceKind.lrhsoftFile
              ? l10n.importMappingInvalidRows(wizard.skippedRows)
              : l10n.importMappingSkippedRows(
                  wizard.skippedRows,
                  wizard.skippedExamples.isEmpty
                      ? 0
                      : wizard.skippedExamples.first,
                ),
          key: const ValueKey('import-skipped-rows'),
          style: type.meta.copyWith(color: colors.textMuted),
        ),
      ],
      const SizedBox(height: Sp.l),
    ];

    final footer = <Widget>[
      if (!wizard.canContinueFromMapping)
        Padding(
          padding: const EdgeInsets.only(top: Sp.l),
          child: Text(
            l10n.importMappingNothing,
            key: const ValueKey('import-mapping-nothing'),
            style: type.meta.copyWith(color: colors.textMuted),
          ),
        ),
    ];

    // Lazy: a calendar can hold hundreds of different titles.
    return ListView.builder(
      padding: importStepPadding,
      itemCount: header.length + groups.length + footer.length,
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final i = index - header.length;
        if (i < groups.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Sp.s),
            child: _GroupCard(group: groups[i]),
          );
        }
        return footer[i - groups.length];
      },
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group});

  final EventGroup group;

  String _meta(BuildContext context) {
    final l10n = context.l10n;
    final times = group.hasTimes
        ? importTimesText(context, group.startMinute!, group.endMinute)
        : l10n.importGroupAllDay;
    final examples = importDateListText(context, group.sampleDates);
    return '${l10n.importGroupDays(group.count)} · $times · '
        '${l10n.importGroupExamples(examples)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final mapping = wizard.mappings[group.key] ?? const IgnoreGroup();
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    final title = importGroupTitle(context, group);

    final ShiftType? shift = switch (mapping) {
      MapToType(:final typeId) =>
        palette.where((t) => t.id == typeId).firstOrNull,
      CreateType() when mapping.isCreatable => mapping.draft.toShiftType(
        mapping.id,
      ),
      _ => null,
    };
    final choice = switch (mapping) {
      IgnoreGroup() => l10n.importMapIgnore,
      CreateType() => l10n.importMapNew(mapping.draft.name),
      MapToType() => shift?.name ?? l10n.importMapIgnore,
    };
    final suggested = wizard.suggested.contains(group.key);

    return AppCard(
      key: ValueKey('import-group-${group.key}'),
      padding: const EdgeInsets.all(Sp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: type.bodyStrong,
          ),
          const SizedBox(height: Sp.hair),
          Text(
            _meta(context),
            style: type.meta.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: Sp.m),
          Semantics(
            button: true,
            label: l10n.importMapSemantics(title, choice),
            excludeSemantics: true,
            child: Material(
              color: mapping is IgnoreGroup
                  ? Colors.transparent
                  : colors.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: Rad.rowRadius,
                side: BorderSide(color: colors.borderStrong),
              ),
              child: InkWell(
                key: ValueKey('import-map-${group.key}'),
                customBorder: RoundedRectangleBorder(
                  borderRadius: Rad.rowRadius,
                ),
                onTap: () => _choose(context, ref, palette, mapping),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Sp.touch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.m,
                      vertical: Sp.s,
                    ),
                    child: Row(
                      children: [
                        if (shift != null) ...[
                          ShiftBadge(shift: shift, size: Disc.s),
                          const SizedBox(width: Sp.m),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                choice,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: type.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: mapping is IgnoreGroup
                                      ? colors.textMuted
                                      : colors.textPrimary,
                                ),
                              ),
                              if (suggested)
                                Text(
                                  l10n.importMapSuggested,
                                  key: ValueKey(
                                    'import-suggested-${group.key}',
                                  ),
                                  style: type.caption.copyWith(
                                    color: colors.accentText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Sp.xs),
                        Icon(
                          AppIcons.chevronRight,
                          size: IconSize.inline,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    List<ShiftType> palette,
    GroupMapping current,
  ) async {
    final notifier = ref.read(importWizardProvider.notifier);
    final fallback = context.l10n.importNewTypeTitle;
    final picked = await showAppSheet<_Pick>(
      context: context,
      padded: true,
      builder: (ctx) => _PickSheet(
        title: importGroupTitle(ctx, group),
        palette: palette,
        current: current,
      ),
    );
    if (picked == null || !context.mounted) return;
    switch (picked) {
      case _PickIgnore():
        notifier.setMapping(group.key, const IgnoreGroup());
      case _PickType(:final typeId):
        notifier.setMapping(group.key, MapToType(typeId));
      case _PickNew():
        final draft = await showNewTypeSheet(
          context: context,
          draft: notifier.proposeDraft(group.key, fallbackName: fallback),
          taken: notifier.typesToAvoid(group.key),
        );
        if (draft != null) notifier.useDraft(group.key, draft);
    }
  }
}

sealed class _Pick {
  const _Pick();
}

class _PickIgnore extends _Pick {
  const _PickIgnore();
}

class _PickNew extends _Pick {
  const _PickNew();
}

class _PickType extends _Pick {
  const _PickType(this.typeId);

  final String typeId;
}

/// The sheet with the shift types, «Crear tipo nuevo» and «Ignorar».
class _PickSheet extends StatelessWidget {
  const _PickSheet({
    required this.title,
    required this.palette,
    required this.current,
  });

  final String title;
  final List<ShiftType> palette;
  final GroupMapping current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final selectedId = switch (current) {
      MapToType(:final typeId) => typeId,
      _ => null,
    };

    Widget row({
      required Key key,
      required Widget leading,
      required String label,
      String? detail,
      required bool selected,
      required _Pick value,
    }) => Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: detail == null ? label : '$label, $detail',
      child: InkWell(
        key: key,
        borderRadius: Rad.rowRadius,
        onTap: () => Navigator.pop(context, value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.xs,
              vertical: Sp.s,
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: Sp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: type.body.copyWith(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail,
                          style: type.meta.copyWith(color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    AppIcons.check,
                    size: IconSize.button,
                    color: colors.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    Widget plainIcon(IconData icon) => SizedBox.square(
      dimension: Disc.s,
      child: Icon(icon, size: IconSize.button, color: colors.textSecondary),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.m),
          child: Semantics(
            header: true,
            child: Text(l10n.importMapPickTitle(title), style: type.headline),
          ),
        ),
        for (final shift in palette)
          row(
            key: ValueKey('import-pick-${shift.id}'),
            leading: ShiftBadge(shift: shift, size: Disc.s),
            label: shift.name,
            detail: shift.timeRange(format),
            selected: selectedId == shift.id,
            value: _PickType(shift.id),
          ),
        row(
          key: const ValueKey('import-pick-new'),
          leading: plainIcon(AppIcons.add),
          label: l10n.importMapCreate,
          selected: current is CreateType,
          value: const _PickNew(),
        ),
        row(
          key: const ValueKey('import-pick-ignore'),
          leading: plainIcon(AppIcons.remove),
          label: l10n.importMapIgnore,
          selected: current is IgnoreGroup,
          value: const _PickIgnore(),
        ),
      ],
    );
  }
}
