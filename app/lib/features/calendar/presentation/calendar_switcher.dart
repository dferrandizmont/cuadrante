import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/icons/parity_icons.dart';
import '../../../core/icons/settings_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../calendars/application/calendars_controller.dart';
import '../../calendars/domain/calendar.dart';
import '../../calendars/presentation/calendar_dot.dart';
import '../application/schedule_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';

/// The pill of the date line of the month screen: the colour dot and the name
/// of the calendar on screen. Only there when the user has two or more
/// calendars; a tap opens the sheet to switch (or to manage them).
class CalendarSwitcher extends ConsumerWidget {
  const CalendarSwitcher({super.key});

  /// The pill never grows past this; a longer name is cut with an ellipsis.
  static const double maxWidth = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendars =
        ref.watch(calendarsControllerProvider).value?.calendars ?? const [];
    if (calendars.length < 2) return const SizedBox.shrink();
    final activeId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );
    final active = calendars.firstWhere(
      (c) => c.id == activeId,
      orElse: () => calendars.first,
    );
    final colors = context.colors;
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Semantics(
        button: true,
        label: l10n.calendarsSwitcherLabel(active.name),
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('calendar-switcher'),
          borderRadius: Rad.pill,
          onTap: () => showCalendarSwitcherSheet(context),
          // The pill itself is about 36 dp tall; the touch target is 48.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sp.touch),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: Rad.pill,
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.m, Sp.s, Sp.s, Sp.s),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CalendarDot(colorValue: active.colorValue),
                      const SizedBox(width: Sp.s),
                      Flexible(
                        child: Text(
                          active.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.caption.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: Sp.xs),
                      Icon(
                        SettingsIcons.expand,
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
      ),
    );
  }
}

/// The sheet of the switcher: pick the calendar to show, or go to the list
/// to manage them.
Future<void> showCalendarSwitcherSheet(BuildContext context) {
  // Taken now: the sheet is closed before the switch runs.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.of(context);
  final failure = context.l10n.calendarsSwitchFailed;
  return showAppSheet<void>(
    context: context,
    padded: true,
    builder: (sheetContext) => _SwitcherSheet(
      onPick: (container, id) async {
        Navigator.pop(sheetContext);
        try {
          await container
              .read(scheduleControllerProvider.notifier)
              .switchCalendar(id);
        } on CalendarException {
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(appSnackBar(content: Text(failure)));
        }
      },
      onManage: () {
        Navigator.pop(sheetContext);
        router.push(AppRoutes.settingsCalendars);
      },
      onCompare: () {
        Navigator.pop(sheetContext);
        router.push(AppRoutes.compare);
      },
    ),
  );
}

class _SwitcherSheet extends ConsumerWidget {
  const _SwitcherSheet({
    required this.onPick,
    required this.onManage,
    required this.onCompare,
  });

  final Future<void> Function(ProviderContainer container, String id) onPick;
  final VoidCallback onManage;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final calendars =
        ref.watch(calendarsControllerProvider).value?.calendars ?? const [];
    final activeId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );
    final container = ProviderScope.containerOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.m),
          child: Semantics(
            header: true,
            child: Text(l10n.calendarsSwitcherTitle, style: type.headline),
          ),
        ),
        for (final calendar in calendars)
          Semantics(
            button: true,
            selected: calendar.id == activeId,
            excludeSemantics: true,
            label: calendar.name,
            child: InkWell(
              key: ValueKey('switch-calendar-${calendar.id}'),
              borderRadius: Rad.rowRadius,
              onTap: () => onPick(container, calendar.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.xs,
                    vertical: Sp.s,
                  ),
                  child: Row(
                    children: [
                      CalendarDot(colorValue: calendar.colorValue, size: 14),
                      const SizedBox(width: Sp.m),
                      Expanded(
                        child: Text(
                          calendar.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: calendar.id == activeId
                              ? type.bodyStrong
                              : type.body,
                        ),
                      ),
                      if (calendar.id == activeId)
                        Icon(
                          AppIcons.check,
                          color: colors.accentStrong,
                          weight: 600,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Divider(color: colors.border, height: Sp.l * 2),
        Semantics(
          button: true,
          excludeSemantics: true,
          label: l10n.compareOpen,
          child: InkWell(
            key: const ValueKey('calendar-switcher-compare'),
            borderRadius: Rad.rowRadius,
            onTap: onCompare,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.xs,
                  vertical: Sp.s,
                ),
                child: Row(
                  children: [
                    Icon(ParityIcons.compare, color: colors.accentText),
                    const SizedBox(width: Sp.m),
                    Expanded(
                      child: Text(
                        l10n.compareOpen,
                        style: type.body.copyWith(
                          color: colors.accentText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          excludeSemantics: true,
          label: l10n.calendarsManage,
          child: InkWell(
            key: const ValueKey('calendar-switcher-manage'),
            borderRadius: Rad.rowRadius,
            onTap: onManage,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.xs,
                  vertical: Sp.s,
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.settings, color: colors.accentText),
                    const SizedBox(width: Sp.m),
                    Expanded(
                      child: Text(
                        l10n.calendarsManage,
                        style: type.body.copyWith(
                          color: colors.accentText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
