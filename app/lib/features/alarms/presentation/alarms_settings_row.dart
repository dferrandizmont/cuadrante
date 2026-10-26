import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/settings_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../../calendar/application/schedule_controller.dart';
import '../application/alarm_providers.dart';
import '../domain/alarm_planner.dart';

/// The "Alarmas" row of the main Settings screen: Activadas / Desactivadas,
/// opening `/ajustes/alarmas`.
class AlarmsSettingsRow extends ConsumerWidget {
  const AlarmsSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(alarmSettingsProvider).value;
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    return SettingsRow(
      key: const ValueKey('settings-alarms'),
      icon: SettingsIcons.alarms,
      title: l10n.settingsAlarmsTitle,
      value: settings == null
          ? null
          : (alarmsCanRing(settings, palette)
                ? l10n.alarmsRowOn
                : l10n.alarmsRowOff),
      onTap: () => context.push(AppRoutes.settingsAlarms),
    );
  }
}
