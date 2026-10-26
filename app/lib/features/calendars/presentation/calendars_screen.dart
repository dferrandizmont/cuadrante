import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/icons/parity_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../application/calendars_controller.dart';
import '../domain/calendar.dart';
import 'calendar_dot.dart';
import 'calendar_editor_sheet.dart';
import 'calendar_messages.dart';

/// Calendars (`/ajustes/calendarios`): the list with the one on screen and
/// the one the widget and alarms follow marked, a button to add one and,
/// per row, the editor.
class CalendarsScreen extends ConsumerWidget {
  const CalendarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(calendarsControllerProvider);
    return Scaffold(
      appBar: ContentAppBar.adaptive(context, title: Text(l10n.calendarsTitle)),
      body: PageBody(
        child: state.when(
          data: (data) => _Content(state: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorState(
            onRetry: () => ref.invalidate(calendarsControllerProvider),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.state});

  final CalendarsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final activeId = ref.watch(
      scheduleControllerProvider.select((s) => s.calendarId),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.l),
            child: Text(
              l10n.calendarsIntro,
              style: context.type.meta.copyWith(color: colors.textMuted),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < state.calendars.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: Sp.l + 14 + Sp.m,
                      color: colors.border,
                    ),
                  _CalendarRow(
                    calendar: state.calendars[i],
                    isActive: state.calendars[i].id == activeId,
                    isPrimary: state.calendars[i].id == state.primaryId,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sp.l),
          SecondaryButton(
            key: const ValueKey('calendars-add'),
            label: l10n.calendarsAdd,
            icon: AppIcons.add,
            onPressed: () => showCalendarEditor(context),
          ),
          // Needs two to compare.
          if (state.calendars.length >= 2) ...[
            const SizedBox(height: Sp.s),
            SecondaryButton(
              key: const ValueKey('calendars-compare'),
              label: l10n.compareOpen,
              icon: ParityIcons.compare,
              onPressed: () => context.push(AppRoutes.compare),
            ),
          ],
          if (state.archived.isNotEmpty) ...[
            const SizedBox(height: Sp.l),
            _ArchivedCalendars(calendars: state.archived),
          ],
        ],
      ),
    );
  }
}

/// «Archivados (2)»: collapsed by default; open, each archived calendar with
/// «Recuperar» (H-T07-1), preserving its rotations and days.
class _ArchivedCalendars extends ConsumerStatefulWidget {
  const _ArchivedCalendars({required this.calendars});

  final List<Calendar> calendars;

  @override
  ConsumerState<_ArchivedCalendars> createState() => _ArchivedCalendarsState();
}

class _ArchivedCalendarsState extends ConsumerState<_ArchivedCalendars> {
  bool _open = false;

  Future<void> _restore(Calendar calendar) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await ref.read(calendarsControllerProvider.notifier).restore(calendar.id);
      message = l10n.calendarsRestored(calendar.name);
    } catch (error) {
      message = calendarErrorMessage(l10n, error);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    return Column(
      key: const ValueKey('calendars-archived'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          expanded: _open,
          child: InkWell(
            key: const ValueKey('calendars-archived-toggle'),
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
                        l10n.calendarsArchivedSection(widget.calendars.length),
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
        if (_open)
          for (final calendar in widget.calendars)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.card),
              child: AppCard(
                key: ValueKey('calendar-archived-${calendar.id}'),
                padding: const EdgeInsets.all(Sp.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CalendarDot(colorValue: calendar.colorValue, size: 14),
                        const SizedBox(width: Sp.m),
                        Expanded(
                          child: Text(
                            calendar.name,
                            style: type.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Sp.s),
                    Semantics(
                      label: l10n.calendarsRestoreSemantic(calendar.name),
                      excludeSemantics: true,
                      button: true,
                      onTap: () => _restore(calendar),
                      child: SecondaryButton(
                        key: ValueKey('calendar-restore-${calendar.id}'),
                        label: l10n.calendarsRestore,
                        icon: AppIcons.undo,
                        expand: false,
                        onPressed: () => _restore(calendar),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.calendar,
    required this.isActive,
    required this.isPrimary,
  });

  final Calendar calendar;
  final bool isActive;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          key: ValueKey('calendar-row-${calendar.id}'),
          onTap: () => showCalendarEditor(context, calendar: calendar),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Sp.l,
                vertical: Sp.m,
              ),
              child: Row(
                children: [
                  CalendarDot(colorValue: calendar.colorValue, size: 14),
                  const SizedBox(width: Sp.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calendar.name,
                          style: type.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (isActive || isPrimary)
                          Padding(
                            padding: const EdgeInsets.only(top: Sp.xs),
                            child: Wrap(
                              spacing: Sp.s,
                              runSpacing: Sp.xs,
                              children: [
                                if (isActive)
                                  _Badge(
                                    label: l10n.calendarsActiveBadge,
                                    tone: colors.accentTone,
                                  ),
                                if (isPrimary)
                                  _Badge(
                                    label: l10n.calendarsPrimaryBadge,
                                    tone: TonePair(
                                      colors.surfaceRaised,
                                      colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;
  final TonePair tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: Rad.chipSmallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sp.s,
          vertical: Sp.hair,
        ),
        child: Text(
          label,
          style: context.type.caption.copyWith(
            color: tone.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
