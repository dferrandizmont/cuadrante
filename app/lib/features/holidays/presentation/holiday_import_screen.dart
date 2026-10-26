import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/format/text_measure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/button_row.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../calendar_export/application/device_calendar_providers.dart';
import '../../calendar_export/domain/device_calendar_api.dart';
import '../../calendar_export/presentation/calendar_permission_card.dart';
import '../../import/data/device_events_reader.dart';
import '../../import/domain/import_models.dart';
import '../../import/presentation/import_date_row.dart';
import '../../import/presentation/import_format.dart';
import '../../schedule/domain/civil_date.dart';
import '../application/holidays_provider.dart';
import '../data/holiday_repository.dart';
import '../domain/holiday_import.dart';

/// Read-only phone calendar import. Nothing is stored before the preview's
/// final action, and the returned receipt identifies exactly this run's rows.
class HolidayImportScreen extends ConsumerStatefulWidget {
  const HolidayImportScreen({super.key});

  @override
  ConsumerState<HolidayImportScreen> createState() =>
      _HolidayImportScreenState();
}

class _HolidayImportScreenState extends ConsumerState<HolidayImportScreen> {
  int _step = 0;
  bool _busy = true;
  CalendarAccess? _access;
  bool _declined = false;
  List<DeviceCalendarInfo> _calendars = const [];
  final Set<String> _selected = {};
  late ImportRange _range;
  DeviceRead? _read;
  ImportProblem? _problem;
  bool _clamped = false;

  DeviceCalendarApi get _api => ref.read(deviceCalendarApiProvider);

  @override
  void initState() {
    super.initState();
    final year = ref.read(clockProvider)().year;
    _range = ImportRange(CivilDate(year, 1, 1), CivilDate(year + 1, 12, 31));
    _loadCalendars();
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = switch (error) {
        ImportException(:final problem) => problem,
        CalendarApiException(error: CalendarApiError.permissionDenied) =>
          ImportProblem.permissionDenied,
        CalendarApiException(error: CalendarApiError.unavailable) =>
          ImportProblem.calendarUnavailable,
        _ => ImportProblem.readFailed,
      };
      // A revoked permission goes back to the existing permission flow.
      if (_problem == ImportProblem.permissionDenied) {
        _step = 0;
        _access = null;
        _selected.clear();
        _calendars = const [];
      }
    });
  }

  Future<T> _bounded<T>(Future<T> job) => job.timeout(
    importWorkTimeout,
    onTimeout: () => throw const ImportException(ImportProblem.tooComplex),
  );

  Future<void> _loadCalendars() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final api = _api;
      final access = await _bounded(api.access());
      final calendars = access == CalendarAccess.granted
          ? await _bounded(api.calendars())
          : const <DeviceCalendarInfo>[];
      if (!mounted) return;
      final visible = calendars.where((c) => !c.hidden).toList()
        ..sort((a, b) {
          final account = (a.accountName ?? '').compareTo(b.accountName ?? '');
          return account != 0 ? account : a.name.compareTo(b.name);
        });
      setState(() {
        _access = access;
        _calendars = visible;
        _selected.retainAll(visible.map((c) => c.id));
        _busy = false;
      });
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _requestAccess() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final outcome = await _bounded(_api.askForAccess());
      if (!mounted) return;
      setState(() {
        _access = outcome.access;
        _declined = outcome.declined;
        _busy = false;
      });
      if (outcome.access == CalendarAccess.granted) await _loadCalendars();
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _openSettings() async {
    try {
      await _api.openSettings();
    } catch (_) {
      // The permission card stays available, as in the shift importer.
    }
  }

  void _back() {
    if (_busy) return;
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _step--;
        _problem = null;
      });
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final day = start ? _range.from : _range.to;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(day.year, day.month, day.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      currentDate: ref.read(clockProvider)(),
      helpText: start
          ? context.l10n.importRangeFrom
          : context.l10n.importRangeTo,
    );
    if (picked == null || !mounted) return;
    final date = CivilDate.fromDateTime(picked);
    var next = start ? _range.copyWith(from: date) : _range.copyWith(to: date);
    if (!next.isValid) next = ImportRange(date, date);
    setState(() {
      _clamped = next.days > maxImportRangeDays;
      _range = next.clamped();
      _problem = null;
    });
  }

  Future<void> _next() async {
    if (_busy || _selected.isEmpty || _access != CalendarAccess.granted) return;
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final read = await _bounded(
        readDeviceEvents(_api, _selected.toList(), _range),
      );
      if (!mounted) return;
      setState(() {
        _read = read;
        _step = 2;
        _busy = false;
      });
    } catch (error) {
      _fail(error);
    }
  }

  HolidayImportPlan _plan() => buildHolidayImportPlan(
    _read?.events ?? const [],
    _range,
    ref.read(holidayControllerProvider).calendar,
    fallbackName: context.l10n.holidaysSettingsAddDefaultName,
  );

  Future<void> _apply() async {
    if (_busy) return;
    final rows = _plan().toAdd;
    if (rows.isEmpty) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final receipt = await ref
          .read(holidayControllerProvider.notifier)
          .importUserHolidays(rows);
      if (mounted) Navigator.of(context).pop<HolidayImportReceipt>(receipt);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _problem = ImportProblem.unknown;
        });
      }
    }
  }

  List<Widget> _calendarWidgets() {
    final l10n = context.l10n;
    if (_access == null) return const [];
    if (_access != CalendarAccess.granted) {
      return [
        CalendarPermissionCard(
          access: _access,
          purpose: CalendarPermissionPurpose.read,
          busy: _busy,
          declined: _declined,
          onRequest: _requestAccess,
          onOpenSettings: _openSettings,
          onRecheck: _loadCalendars,
        ),
      ];
    }
    if (_calendars.isEmpty) return [Text(l10n.importCalendarsEmpty)];
    return [
      for (final calendar in _calendars)
        AppCard(
          padding: EdgeInsets.zero,
          child: CheckboxListTile(
            key: ValueKey('holiday-import-calendar-${calendar.id}'),
            value: _selected.contains(calendar.id),
            onChanged: _busy
                ? null
                : (_) => setState(() {
                    if (!_selected.add(calendar.id)) {
                      _selected.remove(calendar.id);
                    }
                  }),
            contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l),
            title: Text(calendar.name, style: context.type.body),
            subtitle: Text(
              [
                calendar.accountName ?? l10n.importCalendarsNoAccount,
                if (calendar.readOnly) l10n.importCalendarsReadOnly,
              ].join(' · '),
              style: context.type.meta.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _rangeWidgets() => [
    Text(context.l10n.holidayImportRangeHelp, style: context.type.body),
    const SizedBox(height: Sp.l),
    AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ImportDateRow(
            key: const ValueKey('holiday-import-from'),
            label: context.l10n.importRangeFrom,
            value: importDateText(context, _range.from),
            onTap: _busy ? null : () => _pickDate(start: true),
          ),
          ImportDateRow(
            key: const ValueKey('holiday-import-to'),
            label: context.l10n.importRangeTo,
            value: importDateText(context, _range.to),
            onTap: _busy ? null : () => _pickDate(start: false),
          ),
        ],
      ),
    ),
    if (_clamped)
      Text(context.l10n.importRangeClamped, style: context.type.meta),
  ];

  List<Widget> _previewWidgets(HolidayImportPlan plan) {
    final l10n = context.l10n;
    return [
      Text(l10n.holidayImportPreviewHelp, style: context.type.body),
      const SizedBox(height: Sp.m),
      Text(
        l10n.holidayImportIgnored(plan.ignoredTimed),
        key: const ValueKey('holiday-import-ignored'),
        style: context.type.meta,
      ),
      if (plan.cappedEvents > 0)
        Text(
          l10n.holidayImportCapped(plan.cappedEvents),
          style: context.type.meta,
        ),
      if (_read?.truncated == true)
        AppCallout(
          icon: AppIcons.error,
          title: l10n.importMappingTruncated(importLimitText(maxImportEvents)),
        ),
      if (plan.toAdd.isEmpty)
        Text(l10n.holidayImportEmpty, style: context.type.body),
    ];
  }

  Widget _previewRow(HolidayImportRow row, int index) {
    final l10n = context.l10n;
    return Padding(
      key: ValueKey('holiday-import-row-$index'),
      padding: const EdgeInsets.symmetric(vertical: Sp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(importDateText(context, row.date), style: context.type.body),
          LayoutBuilder(
            builder: (context, box) {
              final style = context.type.bodyStrong;
              final text = Text(row.name, style: style);
              // An external title can be a single long word. Keep it whole
              // and reachable without shrinking accessibility text.
              return longestWordWidth(context, row.name, style) > box.maxWidth
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: text,
                    )
                  : text;
            },
          ),
          Text(
            row.skipped ? l10n.holidayImportSkipped : l10n.holidayImportReady,
            style: context.type.meta.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.watch(holidayControllerProvider);
    final plan = _step == 2 ? _plan() : null;
    final mainLabel = plan == null
        ? l10n.importNext
        : l10n.holidayImportAdd(plan.toAdd.length);
    final title = switch (_step) {
      0 => l10n.importCalendarsTitle,
      1 => l10n.importRangeTitle,
      _ => l10n.importPreviewTitle,
    };
    final canContinue =
        _access == CalendarAccess.granted &&
        _selected.isNotEmpty &&
        (plan == null || plan.toAdd.isNotEmpty);
    final header = <Widget>[
      Text(l10n.importStepOf(_step + 1, 3), style: context.type.meta),
      const SizedBox(height: Sp.s),
      Semantics(header: true, child: Text(title, style: context.type.headline)),
      const SizedBox(height: Sp.m),
      if (_step == 0) ...[
        Text(l10n.holidayImportHelp, style: context.type.body),
        const SizedBox(height: Sp.l),
        ..._calendarWidgets(),
      ] else if (_step == 1)
        ..._rangeWidgets()
      else
        ..._previewWidgets(plan!),
      if (_busy)
        const Padding(
          padding: EdgeInsets.all(Sp.l),
          child: Center(child: ButtonSpinner()),
        ),
      if (_problem != null) ...[
        const SizedBox(height: Sp.m),
        AppCallout(
          icon: AppIcons.error,
          title: importProblemText(l10n, _problem!),
          primaryLabel: _step == 0 ? l10n.retry : null,
          onPrimary: _busy ? null : _loadCalendars,
        ),
      ],
    ];
    return PopScope(
      canPop: _step == 0 && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        // Long action name lives in the scrollable body; this short title
        // also fits the app bar with accessibility text sizes.
        appBar: ContentAppBar.adaptive(
          context,
          title: Text(l10n.holidayImportTitle),
        ),
        body: PageBody(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  key: ValueKey('holiday-import-step-$_step'),
                  padding: const EdgeInsets.all(Sp.page),
                  itemCount: header.length + (plan?.rows.length ?? 0),
                  itemBuilder: (context, index) => index < header.length
                      ? header[index]
                      : _previewRow(
                          plan!.rows[index - header.length],
                          index - header.length,
                        ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Sp.page,
                    Sp.s,
                    Sp.page,
                    Sp.m,
                  ),
                  child: AdaptiveButtonRow(
                    primaryFirstWhenStacked: true,
                    items: [
                      ButtonRowItem(
                        label: l10n.back,
                        child: SecondaryButton(
                          key: const ValueKey('holiday-import-back'),
                          label: l10n.back,
                          onPressed: _busy ? null : _back,
                        ),
                      ),
                      ButtonRowItem(
                        label: mainLabel,
                        flex: 2,
                        child: PrimaryButton(
                          key: const ValueKey('holiday-import-next'),
                          label: mainLabel,
                          loading: _busy,
                          onPressed: _busy || !canContinue
                              ? null
                              : _step == 2
                              ? _apply
                              : _next,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
