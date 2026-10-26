import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/icons/settings_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/value_row.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/shift_badge.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/alarm_providers.dart';
import '../data/alarm_scheduler.dart';
import '../domain/alarm_planner.dart';
import '../domain/alarm_settings.dart';
import '../domain/alarm_strings.dart';
import 'alarm_pickers.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// Settings > Alarmas (`/ajustes/alarmas`): the global switch, the state of
/// the permissions the alarms need, the choices of every shift type with
/// times (switch, lead, reminder the evening before, own text), a button to
/// test a notification and the next alarm the planner will ring.
class AlarmsSettingsScreen extends ConsumerStatefulWidget {
  const AlarmsSettingsScreen({super.key});

  @override
  ConsumerState<AlarmsSettingsScreen> createState() =>
      _AlarmsSettingsScreenState();
}

class _AlarmsSettingsScreenState extends ConsumerState<AlarmsSettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from the system screens (notifications, "Alarmas y
    // recordatorios") the permissions may have changed.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(alarmPermissionsProvider);
        // Time passed while the app slept: "Próximo aviso" may be past.
        ref.invalidate(nextAlarmProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  AlarmSettingsController get _controller =>
      ref.read(alarmSettingsProvider.notifier);

  /// Asks for the notification permission when it is missing (the first time
  /// the user turns an alarm on, never at launch).
  Future<void> _ensurePermission() async {
    final scheduler = ref.read(alarmSchedulerProvider);
    if (await scheduler.permissionStatus() == AlarmPermission.denied) {
      await _controller.requestPermission();
    }
    ref.invalidate(alarmPermissionsProvider);
  }

  Future<void> _setMaster(bool on) => saveSetting(context, () async {
    await _controller.setEnabled(on);
    if (on) await _ensurePermission();
  });

  Future<void> _setType(
    String id,
    AlarmTypeSettings next, {
    bool askPermission = false,
  }) => saveSetting(context, () async {
    await _controller.setShiftType(id, next);
    if (askPermission) await _ensurePermission();
  });

  Future<void> _test() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    final strings = AlarmStrings.fromL10n(l10n);
    final ok = await _controller.scheduleTest(strings);
    ref.invalidate(alarmPermissionsProvider);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        appSnackBar(
          content: Text(ok ? l10n.alarmsTestScheduled : l10n.alarmsTestDenied),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(alarmSettingsProvider).value;
    final palette = ref.watch(
      scheduleControllerProvider.select((s) => s.palette),
    );
    // Shifts that can ring (they have times and are not absences), work
    // first; the palette order is kept inside each group.
    final types = [
      ...palette.where(
        (t) => canShiftTypeRing(t) && t.category == ShiftCategory.work,
      ),
      ...palette.where(
        (t) => canShiftTypeRing(t) && t.category != ShiftCategory.work,
      ),
    ];

    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.settingsAlarmsTitle),
      ),
      body: PageBody(
        child: settings == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Sp.page,
                  Sp.s,
                  Sp.page,
                  Sp.x3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsSection(
                      children: [
                        SettingsSwitchRow(
                          key: const ValueKey('alarms-master'),
                          switchKey: const ValueKey('alarms-master-switch'),
                          icon: SettingsIcons.alarms,
                          title: l10n.alarmsMasterTitle,
                          subtitle: l10n.alarmsMasterHelp,
                          value: settings.enabled,
                          onChanged: _setMaster,
                        ),
                      ],
                    ),
                    if (settings.enabled) ...[
                      const SizedBox(height: Sp.section),
                      _PermissionCard(
                        onChanged: () =>
                            ref.invalidate(alarmPermissionsProvider),
                      ),
                      const SizedBox(height: Sp.section),
                      if (types.isEmpty)
                        Text(
                          l10n.alarmsTypesEmpty,
                          key: const ValueKey('alarms-types-empty'),
                          style: context.type.body.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        )
                      else
                        SettingsSection(
                          title: l10n.alarmsSectionTypes,
                          children: [
                            for (final type in types)
                              _TypeTile(
                                key: ValueKey('alarms-type-${type.id}'),
                                shift: type,
                                settings: settings.forShiftType(type.id),
                                onChanged: (next, {askPermission = false}) =>
                                    _setType(
                                      type.id,
                                      next,
                                      askPermission: askPermission,
                                    ),
                              ),
                          ],
                        ),
                      const SizedBox(height: Sp.section),
                      SecondaryButton(
                        key: const ValueKey('alarms-test'),
                        icon: SettingsIcons.alarms,
                        label: l10n.alarmsTestButton,
                        onPressed: _test,
                      ),
                    ],
                    const SizedBox(height: Sp.l),
                    _NextAlarmLine(enabled: settings.enabled),
                  ],
                ),
              ),
      ),
    );
  }
}

/// What the OS allows: a green "all set" card, or the one thing missing with
/// the button that fixes it (the permission prompt, or the system screen
/// "Alarmas y recordatorios").
class _PermissionCard extends ConsumerWidget {
  const _PermissionCard({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final permissions = ref.watch(alarmPermissionsProvider).value;
    if (permissions == null) return const SizedBox.shrink();

    if (!permissions.notificationsGranted && permissions.notificationsBlocked) {
      // Denied for good: the prompt never comes back, so «Permitir» would do
      // nothing. The only way out is the system's notification settings; the
      // screen re-reads the state when the user comes back (H-T11-1).
      return AppCallout(
        key: const ValueKey('alarms-permission-notifications'),
        icon: AppIcons.error,
        tone: TonePair(colors.dangerContainer, colors.danger),
        title: l10n.alarmsPermNotifTitle,
        message: l10n.alarmsPermNotifBlockedBody,
        primaryKey: const ValueKey('alarms-permission-notifications-settings'),
        primaryLabel: l10n.alarmsPermNotifOpenSettings,
        onPrimary: () async {
          await ref.read(alarmSystemProvider).openNotificationSettings();
          onChanged();
        },
      );
    }
    if (!permissions.notificationsGranted) {
      return AppCallout(
        key: const ValueKey('alarms-permission-notifications'),
        icon: AppIcons.error,
        tone: TonePair(colors.dangerContainer, colors.danger),
        title: l10n.alarmsPermNotifTitle,
        message: l10n.alarmsPermNotifBody,
        primaryKey: const ValueKey('alarms-permission-allow'),
        primaryLabel: l10n.alarmsPermNotifAllow,
        onPrimary: () async {
          await ref.read(alarmSettingsProvider.notifier).requestPermission();
          onChanged();
        },
      );
    }
    if (!permissions.exact) {
      return AppCallout(
        key: const ValueKey('alarms-permission-exact'),
        icon: AppIcons.error,
        tone: TonePair(colors.dangerContainer, colors.danger),
        title: l10n.alarmsPermExactTitle,
        message: l10n.alarmsPermExactBody,
        primaryKey: const ValueKey('alarms-permission-open'),
        primaryLabel: l10n.alarmsPermExactOpen,
        onPrimary: () async {
          // Opens the system screen; the lifecycle listener of the screen
          // re-reads the state when the user comes back.
          await ref.read(alarmSchedulerProvider).requestExactAlarmPermission();
          onChanged();
        },
      );
    }
    return AppCallout(
      key: const ValueKey('alarms-permission-ok'),
      icon: AppIcons.check,
      tone: TonePair(colors.successContainer, colors.success),
      title: l10n.alarmsPermOkTitle,
      message: l10n.alarmsPermOkBody,
    );
  }
}

/// «Próximo aviso: mié 21 de octubre, 20:30 · Noche», computed by the same
/// planner that schedules the alarms.
class _NextAlarmLine extends ConsumerWidget {
  const _NextAlarmLine({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final String text;
    if (!enabled) {
      text = l10n.alarmsNextOff;
    } else {
      final next = ref.watch(nextAlarmProvider);
      if (next.isLoading && !next.hasValue) return const SizedBox.shrink();
      final alarm = next.value;
      if (alarm == null) {
        text = l10n.alarmsNextNone;
      } else {
        final format = AppDateFormat.of(context);
        final at = DateTime(
          alarm.fireDate.year,
          alarm.fireDate.month,
          alarm.fireDate.day,
          alarm.fireMinute ~/ 60,
          alarm.fireMinute % 60,
        );
        final when = l10n.alarmsNextWhen(
          format.weekdayShort(at),
          at.day,
          format.monthName(at),
          format.time(at),
        );
        text = alarm.kind == AlarmKind.dayBefore
            ? l10n.alarmsNextLineDayBefore(when, alarm.shiftName)
            : l10n.alarmsNextLine(when, alarm.shiftName);
      }
    }
    return Text(
      text,
      key: const ValueKey('alarms-next'),
      textAlign: TextAlign.center,
      style: context.type.meta.copyWith(color: context.colors.textSecondary),
    );
  }
}

typedef _TypeChanged = Future<void> Function(
  AlarmTypeSettings next, {
  bool askPermission,
});

/// One shift type: badge, name, times and the switch; when on, the lead, the
/// reminder the evening before and the own text.
class _TypeTile extends StatelessWidget {
  const _TypeTile({
    super.key,
    required this.shift,
    required this.settings,
    required this.onChanged,
  });

  final ShiftType shift;
  final AlarmTypeSettings settings;
  final _TypeChanged onChanged;

  /// Where the text of the inner rows starts: under the name of the header.
  static const double _inset = Sp.l + Disc.l + Sp.m;

  String _clock(AppDateFormat format, int minute) =>
      format.time(DateTime(2000, 1, 1, minute ~/ 60, minute % 60));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final times = shift.timeRange(format);
    final divider = Divider(
      height: 1,
      thickness: 1,
      indent: _inset,
      color: colors.border,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: InkWell(
            onTap: () => onChanged(
              settings.copyWith(enabled: !settings.enabled),
              askPermission: !settings.enabled,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: SettingsRow.minHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.l,
                  vertical: Sp.m,
                ),
                child: Row(
                  children: [
                    ShiftBadge(shift: shift),
                    const SizedBox(width: Sp.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift.name,
                            style: type.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (times != null)
                            Text(
                              times,
                              style: AppTypography.tabular(
                                type.meta.copyWith(color: colors.textMuted),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      key: ValueKey('alarms-type-switch-${shift.id}'),
                      value: settings.enabled,
                      onChanged: (on) => onChanged(
                        settings.copyWith(enabled: on),
                        askPermission: on,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (settings.enabled) ...[
          divider,
          _ValueRow(
            key: ValueKey('alarms-before-${shift.id}'),
            inset: _inset,
            title: l10n.alarmsBeforeTitle,
            value: alarmLeadText(l10n, settings.minutesBefore),
            onTap: () async {
              final picked = await pickAlarmLead(
                context,
                current: settings.minutesBefore,
              );
              if (picked != null) {
                await onChanged(settings.copyWith(minutesBefore: picked));
              }
            },
          ),
          if (shift.hasSegment2) ...[
            divider,
            MergeSemantics(
              child: InkWell(
                onTap: () => onChanged(
                  settings.copyWith(secondSegment: !settings.secondSegment),
                ),
                child: _RowFrame(
                  inset: _inset,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.alarmsSecondSegmentTitle,
                              style: type.body,
                            ),
                            Text(
                              l10n.alarmsSecondSegmentHelper,
                              style: type.meta.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        key: ValueKey('alarms-second-switch-${shift.id}'),
                        value: settings.secondSegment,
                        onChanged: (on) =>
                            onChanged(settings.copyWith(secondSegment: on)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          divider,
          MergeSemantics(
            child: InkWell(
              onTap: () =>
                  onChanged(settings.copyWith(dayBefore: !settings.dayBefore)),
              child: _RowFrame(
                inset: _inset,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.alarmsDayBeforeTitle, style: type.body),
                          if (settings.dayBefore)
                            Text(
                              l10n.alarmsDayBeforeAt(
                                _clock(format, settings.dayBeforeMinute),
                              ),
                              style: type.meta.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      key: ValueKey('alarms-daybefore-switch-${shift.id}'),
                      value: settings.dayBefore,
                      onChanged: (on) =>
                          onChanged(settings.copyWith(dayBefore: on)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (settings.dayBefore) ...[
            divider,
            _ValueRow(
              key: ValueKey('alarms-daybefore-time-${shift.id}'),
              inset: _inset,
              title: l10n.alarmsDayBeforeTimeTitle,
              value: _clock(format, settings.dayBeforeMinute),
              onTap: () async {
                final picked = await pickDayBeforeTime(
                  context,
                  current: settings.dayBeforeMinute,
                );
                if (picked != null) {
                  await onChanged(settings.copyWith(dayBeforeMinute: picked));
                }
              },
            ),
          ],
          divider,
          _ValueRow(
            key: ValueKey('alarms-label-${shift.id}'),
            inset: _inset,
            title: l10n.alarmsLabelTitle,
            value: settings.cleanLabel ?? l10n.alarmsLabelDefault,
            onTap: () async {
              final picked = await pickAlarmLabel(
                context,
                current: settings.cleanLabel,
              );
              if (picked == null) return;
              final text = picked.trim();
              await onChanged(
                text.isEmpty
                    ? settings.copyWith(clearLabel: true)
                    : settings.copyWith(label: text),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Padding and minimum height shared by the inner rows of a type.
class _RowFrame extends StatelessWidget {
  const _RowFrame({required this.inset, required this.child});

  final double inset;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: Sp.touch),
    child: Padding(
      padding: EdgeInsets.fromLTRB(inset, Sp.xs, Sp.l, Sp.xs),
      child: Align(alignment: Alignment.centerLeft, child: child),
    ),
  );
}

/// A row with a title, its current value and a chevron.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    super.key,
    required this.inset,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final double inset;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: _RowFrame(
          inset: inset,
          child: ValueRow(
            title: Text(title, style: type.body),
            value: Text(
              value,
              style: type.body.copyWith(color: colors.textMuted),
            ),
            trailing: Icon(
              AppIcons.chevronRight,
              size: IconSize.inline,
              color: colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
