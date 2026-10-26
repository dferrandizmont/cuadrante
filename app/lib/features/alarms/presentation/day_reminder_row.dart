import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/buttons.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/alarm_providers.dart';
import '../data/alarm_scheduler.dart';
import 'alarm_pickers.dart';

/// Hour a new reminder starts at in the time picker.
const int _defaultReminderMinute = 9 * 60;

/// «Avisarme» in the day detail, under the note (docs/paridad.md, A1): a
/// reminder at a time of day, stored in `DayEntry.noteReminderMinute`. With a
/// reminder it shows the time (tap to change it) and «Quitar aviso»; removing
/// it offers «Deshacer» in place, as long as nothing else was done to the
/// schedule since.
///
/// Asking for a reminder asks the OS for the notification permission when it
/// is missing (the one place besides the alarm settings that does), and a
/// reminder that cannot ring says so right under itself.
class DayReminderRow extends ConsumerStatefulWidget {
  const DayReminderRow({super.key, required this.date});

  final CivilDate date;

  @override
  ConsumerState<DayReminderRow> createState() => _DayReminderRowState();
}

class _DayReminderRowState extends ConsumerState<DayReminderRow> {
  /// The undo step of the last «Quitar aviso», while its «Deshacer» shows.
  ScheduleChange? _removed;

  CivilDate get _date => widget.date;

  ScheduleController get _schedule =>
      ref.read(scheduleControllerProvider.notifier);

  /// 09:00, or the next full hour when it is today and 09:00 has gone by.
  int _suggestedMinute() {
    final now = ref.read(clockProvider)();
    final isToday = CivilDate.fromDateTime(now) == _date;
    final nowMinute = now.hour * 60 + now.minute;
    if (!isToday || nowMinute < _defaultReminderMinute) {
      return _defaultReminderMinute;
    }
    return ((nowMinute ~/ 60 + 1) * 60).clamp(0, 1439);
  }

  Future<void> _pick({required int initial}) async {
    final minute = await pickMinuteOfDay(
      context,
      current: initial,
      help: context.l10n.dayReminderPickHelp,
    );
    if (minute == null || !mounted) return;
    // The permission first: the reminder is saved either way, but the system
    // prompt belongs to this tap, not to a later sync.
    try {
      await ref
          .read(alarmSettingsProvider.notifier)
          .ensureNotificationPermission();
    } catch (_) {
      // The reminder is still saved; the warning below says it cannot ring.
    }
    if (!mounted) return;
    setState(() => _removed = null);
    _schedule.setNoteReminder(_date, minute);
  }

  void _remove() {
    final step = _schedule.setNoteReminder(_date, null);
    setState(() => _removed = step);
  }

  void _undo() {
    final step = _removed;
    setState(() => _removed = null);
    if (step != null) _schedule.undoIfLast(step);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final format = AppDateFormat.of(context);
    final minute = ref.watch(
      scheduleControllerProvider.select(
        (s) => s.schedule.entries[_date]?.noteReminderMinute,
      ),
    );
    // The «Deshacer» offer is only good while nothing else happens to this
    // day: any other change to its entry (typing in the note...) drops it,
    // and «Avisarme» is all that is left.
    ref.listen(
      scheduleControllerProvider.select((s) => s.schedule.entries[_date]),
      (previous, next) {
        if (_removed == null) return;
        if (previous?.noteReminderMinute != null ||
            next?.noteReminderMinute != null) {
          return;
        }
        if (previous != next) setState(() => _removed = null);
      },
    );
    final now = ref.watch(clockProvider)();
    final today = CivilDate.fromDateTime(now);

    String clock(int m) => format.time(DateTime(2000, 1, 1, m ~/ 60, m % 60));

    if (minute == null) {
      // A reminder for a day that has gone by could never ring.
      final canAdd = !_date.isBefore(today);
      final add = Align(
        alignment: AlignmentDirectional.centerStart,
        child: SecondaryButton(
          key: const ValueKey('day-reminder-add'),
          icon: AppIcons.bell,
          label: l10n.dayReminderAdd,
          expand: false,
          onPressed: () => _pick(initial: _suggestedMinute()),
        ),
      );
      if (_removed != null) {
        // H-T11-5: «Avisarme» stays available next to the «Deshacer» offer,
        // so a new reminder does not need the sheet to be reopened.
        return Padding(
          padding: const EdgeInsets.only(top: Sp.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dayReminderRemoved,
                      key: const ValueKey('day-reminder-removed'),
                      style: type.body,
                    ),
                  ),
                  SecondaryButton(
                    key: const ValueKey('day-reminder-undo'),
                    icon: AppIcons.undo,
                    label: l10n.undo,
                    expand: false,
                    onPressed: _undo,
                  ),
                ],
              ),
              if (canAdd) ...[const SizedBox(height: Sp.s), add],
            ],
          ),
        );
      }
      if (!canAdd) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: Sp.s),
        child: add,
      );
    }

    final nowWall = today.epochDay * 1440 + now.hour * 60 + now.minute;
    final passed = _date.epochDay * 1440 + minute <= nowWall;
    final primaryId = ref.watch(
      calendarsControllerProvider.select((c) => c.value?.primaryId),
    );
    final viewingId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );
    final permission = ref.watch(alarmPermissionsProvider).value;
    final denied =
        permission != null &&
        permission.notifications == AlarmPermission.denied;

    return Padding(
      padding: const EdgeInsets.only(top: Sp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Sp.s,
            runSpacing: Sp.s,
            children: [
              Semantics(
                button: true,
                hint: l10n.dayReminderChange,
                child: SecondaryButton(
                  key: const ValueKey('day-reminder-time'),
                  icon: AppIcons.bell,
                  label: l10n.dayReminderAt(clock(minute)),
                  expand: false,
                  onPressed: () => _pick(initial: minute),
                ),
              ),
              SecondaryButton(
                key: const ValueKey('day-reminder-remove'),
                icon: AppIcons.close,
                label: l10n.dayReminderRemove,
                expand: false,
                onPressed: _remove,
              ),
            ],
          ),
          if (passed)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs),
              child: Text(
                l10n.dayReminderPast,
                key: const ValueKey('day-reminder-past'),
                style: type.meta.copyWith(color: colors.textMuted),
              ),
            )
          else if (denied)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs),
              child: Text(
                l10n.dayReminderNoPermission,
                key: const ValueKey('day-reminder-denied'),
                style: type.meta.copyWith(color: colors.textMuted),
              ),
            ),
          if (primaryId != null && primaryId != viewingId)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs),
              child: Text(
                l10n.dayReminderOnlyPrimary,
                key: const ValueKey('day-reminder-primary-only'),
                style: type.meta.copyWith(color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
