import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/icons/selection_icons.dart';
import '../../../../core/icons/settings_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router.dart';
import '../../../calendar/application/schedule_controller.dart';
import '../../../calendars/application/calendars_controller.dart';
import '../../../patterns/application/post_night_provider.dart';
import '../settings_widgets.dart';

/// "Tu cuadrante": the shift types editor and the calendars.
class ScheduleSection extends ConsumerWidget {
  const ScheduleSection({super.key});

  /// The editor of the shift types (`/ajustes/turnos`) is a screen of its
  /// own; the path is pushed as a string so this section does not depend on
  /// how that route is registered.
  static const String shiftsPath = AppRoutes.shiftTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final calendars = ref.watch(calendarsControllerProvider).value?.calendars;
    final activeId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );
    final activeName = calendars
        ?.where((c) => c.id == activeId)
        .map((c) => c.name)
        .firstOrNull;

    return SettingsSection(
      title: l10n.settingsSectionSchedule,
      children: [
        SettingsRow(
          key: const ValueKey('settings-shifts'),
          icon: SettingsIcons.shifts,
          title: l10n.settingsShiftsTitle,
          subtitle: l10n.settingsShiftsSubtitle,
          onTap: () => context.push(shiftsPath),
        ),
        SettingsRow(
          key: const ValueKey('settings-runs'),
          icon: SelectionIcons.rotations,
          title: l10n.selectionRunsTitle,
          subtitle: l10n.selectionRunsSubtitle,
          onTap: () => context.push(AppRoutes.settingsRuns),
        ),
        SettingsRow(
          key: const ValueKey('settings-calendars'),
          icon: AppIcons.calendar,
          title: l10n.settingsCalendarsTitle,
          value: activeName,
          onTap: () => context.push(AppRoutes.settingsCalendars),
        ),
        SettingsSwitchRow(
          key: const ValueKey('settings-post-night'),
          switchKey: const ValueKey('settings-post-night-switch'),
          icon: AppIcons.pattern,
          title: l10n.postNightAutoTitle,
          subtitle: l10n.postNightAutoHelp,
          value: ref.watch(postNightAutoProvider),
          // Same path as every other setting: a write that fails says so.
          onChanged: (value) => saveSetting(
            context,
            () => ref.read(postNightAutoProvider.notifier).set(value),
          ),
        ),
      ],
    );
  }
}
