import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../calendar_export/domain/device_calendar_api.dart';
import '../../calendar_export/presentation/calendar_permission_card.dart';
import '../application/import_wizard.dart';
import 'import_format.dart';
import 'import_step_layout.dart';

/// Step 2 (phone calendar only): the permission, then the calendars to read,
/// each with its account, name and colour.
class ImportCalendarsStep extends ConsumerWidget {
  const ImportCalendarsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);

    final Widget body;
    if (wizard.access == null) {
      body = wizard.problem == null
          ? const Padding(
              padding: EdgeInsets.all(Sp.x3),
              child: Center(child: CircularProgressIndicator()),
            )
          : AppCallout(
              titleKey: const ValueKey('import-problem'),
              icon: AppIcons.error,
              title: importProblemText(l10n, wizard.problem!),
              primaryLabel: l10n.retry,
              onPrimary: notifier.recheckAccess,
            );
    } else if (wizard.access != CalendarAccess.granted) {
      body = CalendarPermissionCard(
        access: wizard.access,
        purpose: CalendarPermissionPurpose.read,
        busy: wizard.busy,
        declined: wizard.declined,
        onRequest: notifier.requestAccess,
        onOpenSettings: notifier.openAppSettings,
        onRecheck: notifier.recheckAccess,
      );
    } else if (wizard.calendars.isEmpty) {
      body = EmptyState(
        icon: AppIcons.calendar,
        title: l10n.importCalendarsEmpty,
        compact: true,
      );
    } else {
      final sorted = [...wizard.calendars]
        ..sort((a, b) {
          final byAccount = (a.accountName ?? '').toLowerCase().compareTo(
            (b.accountName ?? '').toLowerCase(),
          );
          return byAccount != 0
              ? byAccount
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      body = AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, c) in sorted.indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: colors.border),
              _CalendarRow(
                calendar: c,
                selected: wizard.selectedCalendars.contains(c.id),
                onChanged: () => notifier.toggleCalendar(c.id),
              ),
            ],
          ],
        ),
      );
    }

    return ImportStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.importCalendarsTitle,
              key: const ValueKey('import-title'),
              style: type.headline,
            ),
          ),
          const SizedBox(height: Sp.s),
          Text(
            l10n.importCalendarsHelp,
            style: type.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: Sp.l),
          body,
        ],
      ),
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.calendar,
    required this.selected,
    required this.onChanged,
  });

  final DeviceCalendarInfo calendar;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final account = calendar.accountName?.trim().isNotEmpty == true
        ? calendar.accountName!.trim()
        : l10n.importCalendarsNoAccount;
    final subtitle = calendar.readOnly
        ? '$account · ${l10n.importCalendarsReadOnly}'
        : account;
    return MergeSemantics(
      child: Semantics(
        label: l10n.importCalendarSemantics(calendar.name, account),
        child: CheckboxListTile(
          key: ValueKey('import-calendar-${calendar.id}'),
          value: selected,
          onChanged: (_) => onChanged(),
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l),
          secondary: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: calendar.colorValue == null
                    ? colors.borderStrong
                    : Color(calendar.colorValue!),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: Sp.xxl),
            ),
          ),
          title: Text(
            calendar.name,
            style: type.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: type.meta.copyWith(color: colors.textMuted),
          ),
        ),
      ),
    );
  }
}
