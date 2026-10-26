import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../import/presentation/import_date_row.dart';
import '../../import/presentation/import_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/export_controller.dart';
import '../data/calendar_exporter.dart';
import 'calendar_permission_card.dart';
import 'export_texts.dart';

/// Exportar al calendario del móvil (`/ajustes/exportar`): a one-off copy of
/// the shifts as events of a calendar of the phone. Running it again replaces
/// the events of the previous export in those dates instead of duplicating
/// them (docs/importar.md).
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final state = ref.watch(exportControllerProvider);
    final controller = ref.read(exportControllerProvider.notifier);
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

    final Widget body;
    if (state.loading && state.access == null) {
      body = const Padding(
        padding: EdgeInsets.all(Sp.x3),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!state.hasAccess) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CalendarPermissionCard(
            access: state.access,
            purpose: CalendarPermissionPurpose.write,
            busy: state.loading,
            declined: state.declined,
            onRequest: controller.requestAccess,
            onOpenSettings: controller.openAppSettings,
            onRecheck: controller.refresh,
          ),
          if (state.problem != null) ...[
            const SizedBox(height: Sp.l),
            _ProblemCallout(problem: state.problem!),
          ],
        ],
      );
    } else {
      body = _Options(state: state);
    }

    return Scaffold(
      appBar: ContentAppBar.adaptive(context, title: Text(l10n.calExportTitle)),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.x4 * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.calExportHelp,
                style: type.body.copyWith(color: colors.textSecondary),
              ),
              if (calendarName != null) ...[
                const SizedBox(height: Sp.s),
                Text(
                  l10n.calExportSource(calendarName),
                  key: const ValueKey('export-source'),
                  style: type.meta.copyWith(color: colors.textMuted),
                ),
              ],
              const SizedBox(height: Sp.l),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemCallout extends StatelessWidget {
  const _ProblemCallout({required this.problem});

  final ExportProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCallout(
      titleKey: const ValueKey('export-problem'),
      icon: AppIcons.error,
      title: switch (problem) {
        ExportProblem.permissionDenied => l10n.calExportProblemPermission,
        ExportProblem.permissionRestricted =>
          l10n.calExportPermissionRestrictedTitle,
        ExportProblem.calendarUnavailable => l10n.calExportProblemUnavailable,
        ExportProblem.failed => l10n.calExportProblemFailed,
      },
    );
  }
}

class _Options extends ConsumerWidget {
  const _Options({required this.state});

  final ExportState state;

  Future<void> _pick(
    BuildContext context,
    ExportController controller, {
    required bool start,
  }) async {
    final current = start ? state.from : state.to;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: start ? context.l10n.calExportFrom : context.l10n.calExportTo,
    );
    if (picked == null) return;
    final day = CivilDate.fromDateTime(picked);
    var from = start ? day : state.from;
    var to = start ? state.to : day;
    if (to.isBefore(from)) {
      from = day;
      to = day;
    }
    controller.setRange(from, to);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final controller = ref.read(exportControllerProvider.notifier);
    final plan = state.plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(l10n.calExportCalendarLabel),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _CalendarChoice(
                key: const ValueKey('export-calendar-new'),
                title: l10n.calExportNewCalendar,
                subtitle: l10n.calExportNewCalendarHelp,
                color: null,
                selected: state.targetId == null,
                enabled: !state.running,
                onTap: () => controller.selectCalendar(null),
              ),
              for (final c in state.calendars) ...[
                Divider(height: 1, thickness: 1, color: colors.border),
                _CalendarChoice(
                  key: ValueKey('export-calendar-${c.id}'),
                  title: c.name,
                  subtitle: c.accountName,
                  color: c.colorValue,
                  selected: state.targetId == c.id,
                  enabled: !state.running,
                  onTap: () => controller.selectCalendar(c.id),
                ),
              ],
            ],
          ),
        ),
        if (state.target?.isSynced ?? false)
          Padding(
            padding: const EdgeInsets.only(top: Sp.s),
            child: Text(
              state.target!.accountName == null ||
                      state.target!.accountName!.trim().isEmpty
                  ? l10n.calExportSyncedUnnamed
                  : l10n.calExportSynced(state.target!.accountName!),
              key: const ValueKey('export-synced'),
              style: type.meta.copyWith(color: colors.textSecondary),
            ),
          ),
        const SizedBox(height: Sp.section),
        _SectionLabel(l10n.calExportRangeLabel),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ImportDateRow(
                key: const ValueKey('export-from'),
                label: l10n.calExportFrom,
                value: importDateText(context, state.from),
                onTap: state.running
                    ? null
                    : () => _pick(context, controller, start: true),
              ),
              Divider(height: 1, thickness: 1, color: colors.border),
              ImportDateRow(
                key: const ValueKey('export-to'),
                label: l10n.calExportTo,
                value: importDateText(context, state.to),
                onTap: state.running
                    ? null
                    : () => _pick(context, controller, start: false),
              ),
            ],
          ),
        ),
        if (state.rangeCut)
          Padding(
            padding: const EdgeInsets.only(top: Sp.s),
            child: Text(
              l10n.calExportRangeClamped,
              key: const ValueKey('export-clamped'),
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          ),
        const SizedBox(height: Sp.section),
        AppCard(
          padding: EdgeInsets.zero,
          child: SettingsSwitchRow(
            key: const ValueKey('export-include-rest'),
            switchKey: const ValueKey('export-include-rest-switch'),
            icon: AppIcons.calendar,
            title: l10n.calExportIncludeRest,
            subtitle: l10n.calExportIncludeRestHelp,
            value: state.includeRest,
            onChanged: state.running ? (_) {} : controller.setIncludeRest,
          ),
        ),
        const SizedBox(height: Sp.card),
        AppCard(
          padding: EdgeInsets.zero,
          child: SettingsSwitchRow(
            key: const ValueKey('export-include-absences'),
            switchKey: const ValueKey('export-include-absences-switch'),
            icon: AppIcons.calendar,
            title: l10n.calExportIncludeAbsences,
            subtitle: l10n.calExportIncludeAbsencesHelp,
            value: state.includeAbsences,
            onChanged: state.running ? (_) {} : controller.setIncludeAbsences,
          ),
        ),
        const SizedBox(height: Sp.l),
        if (plan != null)
          AppCard.tinted(
            key: const ValueKey('export-plan'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in exportPlanLines(l10n, plan))
                  Text(
                    line.text,
                    key: ValueKey('export-plan-${line.key}'),
                    style: line.strong
                        ? type.bodyStrong
                        : type.body.copyWith(color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        const SizedBox(height: Sp.l),
        PrimaryButton(
          key: const ValueKey('export-start'),
          label: state.running
              ? l10n.calExportRunning(state.done, state.total)
              : l10n.calExportButton,
          loading: state.running,
          onPressed: state.loading || plan == null || plan.isNoop
              ? null
              : controller.start,
        ),
        if (state.problem != null) ...[
          const SizedBox(height: Sp.l),
          _ProblemCallout(problem: state.problem!),
        ],
        if (state.result != null) ...[
          const SizedBox(height: Sp.l),
          _ResultCard(result: state.result!),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.s),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: context.type.label.copyWith(color: context.colors.textMuted),
        ),
      ),
    );
  }
}

/// A calendar of the phone to export to: a coloured dot, its name and
/// account, and a check when chosen (never colour alone).
class _CalendarChoice extends StatelessWidget {
  const _CalendarChoice({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final int? color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: subtitle == null ? title : '$title, $subtitle',
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.l,
              vertical: Sp.m,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color == null ? colors.accent : Color(color!),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: Sp.xxl),
                ),
                const SizedBox(width: Sp.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: type.body.copyWith(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
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
  }
}

/// What an export did, in plain counts. It appears under the «Exportar»
/// button, often below the fold, so it scrolls itself into view when it shows
/// up (H-T14-4), and says so to a screen reader (a live region).
class _ResultCard extends StatefulWidget {
  const _ResultCard({required this.result});

  final ExportResult result;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The Scrollable above is the screen's; nothing to do without one.
      if (Scrollable.maybeOf(context) == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: Motion.of(context, const Duration(milliseconds: 250)),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      liveRegion: true,
      child: AppCard.tinted(
        key: const ValueKey('export-result'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.calExportDoneTitle, style: type.bodyStrong),
            ),
            for (final line in exportResultLines(l10n, widget.result))
              Text(
                line.text,
                key: ValueKey('export-result-${line.key}'),
                style: type.body.copyWith(
                  color: line.key == 'failed'
                      ? colors.textPrimary
                      : colors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
