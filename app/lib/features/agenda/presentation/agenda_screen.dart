import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_date_format.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/icons/selection_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar/presentation/day_detail_sheet.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../application/agenda_mode.dart';
import '../domain/agenda.dart';
import '../domain/agenda_dates.dart';

/// The agenda (`/agenda`): «Notas» lists the days with a note (and the
/// holidays the person added) from today on, grouped by month; «Turnos»
/// lists every one of the next 60 days with its shifts, days off included.
/// The search field looks through ALL notes, past and future, and the names
/// of the shifts, and a date typed in it («15/10», «15 oct») brings that day
/// to the top.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final schedule = ref.watch(
      scheduleControllerProvider.select((s) => s.schedule),
    );
    final holidays = ref.watch(holidaysProvider).values;
    final today = CivilDate.fromDateTime(ref.watch(minuteClockProvider));
    final mode = ref.watch(agendaModeProvider);
    final query = _search.text.trim();
    final searching = query.isNotEmpty;

    final search = searching
        ? searchAgenda(
            schedule,
            holidays,
            query,
            today,
            holidayKeywords:
                '${l10n.agendaHoliday('')} ${l10n.holidayImportTitle}',
            months: agendaMonthLookup(
              Localizations.localeOf(context).languageCode,
            ),
          )
        : null;
    final dateItem = search?.dateItem;
    final items =
        search?.items ??
        (mode == AgendaMode.shifts
            ? upcomingShiftDays(schedule, holidays, today)
            : upcomingAgenda(schedule, holidays, today));

    Widget body;
    if (items.isEmpty && dateItem == null) {
      body = searching
          ? EmptyState(
              icon: SelectionIcons.search,
              title: l10n.agendaNoResultsTitle,
              message: l10n.agendaNoResultsMessage(query),
              footer: _ScopeNote(text: l10n.agendaSearchScope),
            )
          : EmptyState(
              icon: AppIcons.note,
              title: l10n.agendaEmptyTitle,
              message: l10n.agendaEmptyMessage,
            );
    } else {
      body = _AgendaList(
        items: items,
        dateItem: dateItem,
        today: today,
        // Days off are written out in the shifts list (a day with nothing
        // on it is a day off, not a gap).
        showFree: !searching && mode == AgendaMode.shifts,
        // Search results can be from any year: always say it.
        alwaysShowYear: searching,
        header: searching
            ? l10n.agendaResults(items.length + (dateItem == null ? 0 : 1))
            : null,
        footer: search != null && search.truncated
            ? l10n.agendaTruncated(items.length)
            : null,
        // How far the search reaches (H-T09-4).
        scope: searching ? l10n.agendaSearchScope : null,
      );
    }

    return Scaffold(
      appBar: ContentAppBar.adaptive(context, title: Text(l10n.agendaTitle)),
      body: PageBody(
        child: Column(
          children: [
            _ModeToggle(
              mode: mode,
              onSelected: ref.read(agendaModeProvider.notifier).select,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.s),
              child: TextField(
                key: const ValueKey('agenda-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  // One short word where the long hint would be cut (H-T09-1);
                  // what it searches is said under the results.
                  hintText: textScaleOf(context) >= kLargeHintScale - 0.001
                      ? l10n.agendaSearchHintShort
                      : l10n.agendaSearchHint,
                  prefixIcon: Icon(
                    SelectionIcons.search,
                    color: colors.textMuted,
                  ),
                  suffixIcon: searching
                      ? IconButton(
                          key: const ValueKey('agenda-search-clear'),
                          tooltip: l10n.agendaSearchClear,
                          icon: Icon(AppIcons.close),
                          onPressed: () => setState(_search.clear),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// The two options of the agenda, «Notas» and «Turnos», as two pills (the
/// chosen one has a check and a bolder label).
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onSelected});

  final AgendaMode mode;
  final ValueChanged<AgendaMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, 0),
      // A Wrap, not a Row: with large text or a long translation the second
      // pill goes to the next line instead of breaking a word.
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: Sp.s,
          runSpacing: Sp.s,
          children: [
            ChoicePill(
              key: const ValueKey('agenda-mode-notes'),
              label: l10n.agendaModeNotes,
              selected: mode == AgendaMode.notes,
              onTap: () => onSelected(AgendaMode.notes),
            ),
            ChoicePill(
              key: const ValueKey('agenda-mode-shifts'),
              label: l10n.agendaModeShifts,
              selected: mode == AgendaMode.shifts,
              onTap: () => onSelected(AgendaMode.shifts),
            ),
          ],
        ),
      ),
    );
  }
}

/// From this text scale the search field shows a one-word hint.
const double kLargeHintScale = 1.3;

/// What the search covers, under «Nada encontrado».
class _ScopeNote extends StatelessWidget {
  const _ScopeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Sp.l),
    child: Text(
      text,
      key: const ValueKey('agenda-scope'),
      textAlign: TextAlign.center,
      style: context.type.meta.copyWith(color: context.colors.textMuted),
    ),
  );
}

/// A row of the flattened list: a month heading or a day.
sealed class _Entry {}

class _MonthEntry extends _Entry {
  _MonthEntry(this.year, this.month, {this.date = false});
  final int year;
  final int month;

  /// The heading of the day a searched date names (it comes before the text
  /// matches, which can have the same month).
  final bool date;
}

class _DayEntry extends _Entry {
  _DayEntry(this.item, {this.showFree = false});
  final AgendaItem item;

  /// Writes «Libre» if the day has no shifts (always for a searched date).
  final bool showFree;
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.items,
    required this.today,
    required this.alwaysShowYear,
    this.dateItem,
    this.showFree = false,
    this.header,
    this.footer,
    this.scope,
  });

  final List<AgendaItem> items;

  /// The day a searched date names, before [items].
  final AgendaItem? dateItem;
  final CivilDate today;
  final bool alwaysShowYear;

  /// Writes «Libre» on the days without shifts.
  final bool showFree;
  final String? header;
  final String? footer;

  /// What the search covers, under the results.
  final String? scope;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;
    final format = AppDateFormat.of(context);
    final entries = <_Entry>[
      if (dateItem != null) ...[
        _MonthEntry(dateItem!.date.year, dateItem!.date.month, date: true),
        _DayEntry(dateItem!, showFree: true),
      ],
      for (final group in groupByMonth(items)) ...[
        _MonthEntry(group.year, group.month),
        for (final item in group.items) _DayEntry(item),
      ],
    ];
    final extraTop = header == null ? 0 : 1;
    final bottom = [
      if (footer != null)
        (key: const ValueKey('agenda-truncated'), text: footer!),
      if (scope != null) (key: const ValueKey('agenda-scope'), text: scope!),
    ];
    final extraBottom = bottom.length;

    return ListView.builder(
      key: const ValueKey('agenda-list'),
      padding: const EdgeInsets.fromLTRB(Sp.page, 0, Sp.page, Sp.section),
      itemCount: entries.length + extraTop + extraBottom,
      itemBuilder: (context, index) {
        if (extraTop == 1 && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Sp.xs),
            child: Text(
              header!,
              key: const ValueKey('agenda-results'),
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          );
        }
        final position = index - extraTop;
        if (position >= entries.length) {
          final note = bottom[position - entries.length];
          return Padding(
            padding: const EdgeInsets.only(top: Sp.m),
            child: Text(
              note.text,
              key: note.key,
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          );
        }
        return switch (entries[position]) {
          _MonthEntry(:final year, :final month, :final date) => _MonthHeading(
            key: ValueKey(
              date ? 'agenda-month-date' : 'agenda-month-$year-$month',
            ),
            text: capitalize(
              alwaysShowYear || year != today.year
                  ? format.monthYear(DateTime(year, month))
                  : format.monthName(DateTime(year, month)),
            ),
          ),
          _DayEntry(:final item, showFree: final free) => _AgendaRow(
            key: ValueKey('agenda-day-${item.date.toIso()}'),
            item: item,
            isToday: item.date == today,
            showFree: free || showFree,
          ),
        };
      },
    );
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Sp.l, bottom: Sp.xs),
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

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    super.key,
    required this.item,
    required this.isToday,
    this.showFree = false,
  });

  final AgendaItem item;
  final bool isToday;

  /// Writes «Libre» when the day has no shifts.
  final bool showFree;

  bool get _free => showFree && item.shifts.isEmpty;

  String _spoken(BuildContext context) {
    final l10n = context.l10n;
    final format = AppDateFormat.of(context);
    final date = item.date;
    return [
      format.weekdayDayMonth(DateTime(date.year, date.month, date.day)),
      if (isToday) l10n.daySemanticsToday,
      if (item.shifts.isNotEmpty)
        item.shifts
            .map((s) => s.spoken(l10n, format))
            .reduce((a, b) => l10n.daySemanticsAnd(a, b)),
      if (_free) l10n.todayFreeTitle,
      if (item.ownHoliday != null)
        l10n.daySemanticsHoliday(item.ownHoliday!.name),
      if (item.note != null) l10n.agendaSemanticsNote(item.note!),
      if (item.note != null && item.reminderMinute != null)
        l10n.agendaSemanticsReminder(_clock(format, item.reminderMinute!)),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final format = AppDateFormat.of(context);
    final date = item.date;
    final dateTime = DateTime(date.year, date.month, date.day);
    final weekday = format.weekdayShort(dateTime).replaceAll('.', '');

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: _spoken(context),
      onTap: () => showDayDetail(context, date: date),
      child: InkWell(
        borderRadius: Rad.rowRadius,
        onTap: () => showDayDetail(context, date: date),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Sp.s,
            horizontal: Sp.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      isToday ? l10n.calendarToday : weekday,
                      maxLines: 1,
                      style: type.caption.copyWith(
                        color: isToday ? colors.accentText : colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: AppTypography.tabular(type.headline).copyWith(
                        fontWeight: isToday ? FontWeight.w900 : null,
                        color: item.ownHoliday != null
                            ? colors.holiday
                            : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.shifts.isNotEmpty)
                      Wrap(
                        spacing: Sp.xs,
                        runSpacing: Sp.xs,
                        children: [
                          for (final shift in item.shifts)
                            _ShiftChip(shift: shift),
                        ],
                      ),
                    if (_free)
                      Text(
                        l10n.todayFreeTitle,
                        key: const ValueKey('agenda-free'),
                        style: type.bodyStrong.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    if (item.ownHoliday != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: item.shifts.isEmpty && !_free ? 0 : Sp.xs,
                        ),
                        child: Text(
                          l10n.agendaHoliday(item.ownHoliday!.name),
                          style: type.bodyStrong.copyWith(
                            color: colors.holiday,
                          ),
                        ),
                      ),
                    if (item.note != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top:
                              item.shifts.isEmpty &&
                                  item.ownHoliday == null &&
                                  !_free
                              ? 0
                              : Sp.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.note!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: type.body,
                              ),
                            ),
                            if (item.reminderMinute != null)
                              Padding(
                                padding: const EdgeInsets.only(left: Sp.s),
                                child: _ReminderBell(
                                  time: _clock(format, item.reminderMinute!),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clock(AppDateFormat format, int minute) =>
    format.time(DateTime(2000, 1, 1, minute ~/ 60, minute % 60));

/// The small bell of a note with a reminder, with its time (never the icon
/// alone). The row reads the reminder out in its own semantics label.
class _ReminderBell extends StatelessWidget {
  const _ReminderBell({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      key: const ValueKey('agenda-reminder'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.bell, size: IconSize.inline, color: colors.textMuted),
        const SizedBox(width: Sp.xs),
        Text(
          time,
          style: AppTypography.tabular(
            context.type.caption.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// A shift as a small chip: colour, code, name and, below, its hours (never
/// colour alone).
class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.shift});

  final ShiftType shift;

  @override
  Widget build(BuildContext context) {
    final swatch = shift.swatch(context.colors.brightness);
    final caption = context.type.caption;
    final times = shift.timeRange(AppDateFormat.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: swatch.disc,
        borderRadius: Rad.chipSmallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.s, vertical: Sp.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${shift.code} · ${shift.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: caption.copyWith(
                color: swatch.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (times != null)
              Text(
                times,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.tabular(
                  caption.copyWith(color: swatch.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
