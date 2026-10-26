import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/alarm_providers.dart';
import '../domain/alarm_planner.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// «Sin alarma este día» in the day detail: a switch that stops every alarm
/// of the shifts starting on [date] (the setting lives in the alarm settings,
/// `skippedDates`, so it survives repainting the day).
///
/// Shown only when it can matter: the alarms are on, the calendar on screen
/// is the one the alarms follow (the primary one) and one of the day's shifts
/// has its alarm on. A day that is already skipped keeps the switch even if
/// the shift changed meanwhile, so it can always be undone.
class DayAlarmSkipRow extends ConsumerWidget {
  const DayAlarmSkipRow({super.key, required this.date});

  final CivilDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(alarmSettingsProvider).value;
    final primaryId = ref.watch(
      calendarsControllerProvider.select((c) => c.value?.primaryId),
    );
    final viewing = ref.watch(
      scheduleControllerProvider.select((s) => (s.calendarId, s.schedule)),
    );
    if (settings == null || !settings.enabled || primaryId != viewing.$1) {
      return const SizedBox.shrink();
    }
    final skipped = settings.isSkipped(date);
    final rings = viewing.$2
        .resolve(date)
        .shifts
        .any((s) => canShiftTypeRing(s) && settings.forShiftType(s.id).enabled);
    if (!rings && !skipped) return const SizedBox.shrink();

    return SwitchListTile(
      key: const ValueKey('day-alarm-skip-switch'),
      contentPadding: EdgeInsets.zero,
      title: Text(context.l10n.alarmsSkipDay),
      value: skipped,
      onChanged: (on) async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final failed = context.l10n.saveFailed;
        try {
          await ref
              .read(alarmSettingsProvider.notifier)
              .setSkipped(date, skipped: on);
        } catch (_) {
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(appSnackBar(content: Text(failed)));
        }
      },
    );
  }
}
