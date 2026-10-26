import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/crash_reporting.dart';
import '../../../core/providers.dart';
import '../../../core/theme/shift_palette.dart';
import '../../calendar/application/schedule_controller.dart';
import '../../calendar_export/application/device_calendar_providers.dart';
import '../../calendar_export/domain/device_calendar_api.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../shift_types/domain/shift_type_draft.dart';
import '../data/device_events_reader.dart';
import '../data/import_file_picker.dart';
import '../data/lrhsoft_reader.dart';
import '../domain/csv_parser.dart';
import '../domain/event_grouping.dart';
import '../domain/ics_expansion.dart';
import '../domain/ics_parser.dart';
import '../domain/import_files.dart';
import '../domain/import_models.dart';
import '../domain/import_plan.dart';
import '../domain/lrhsoft_backup.dart';
import '../domain/mapping_suggestions.dart';
import 'import_providers.dart';

/// Where the events come from. [lrhsoftFile] is the `.Shifter` backup of
/// LRHSoft «Calendario de Turnos».
enum ImportSourceKind { deviceCalendar, icsFile, csvFile, lrhsoftFile }

/// Steps of the wizard. Which of them a source goes through is
/// [ImportWizardState.steps].
enum ImportStep { source, calendars, range, columns, mapping, preview }

/// Everything the wizard knows so far.
class ImportWizardState {
  const ImportWizardState({
    required this.range,
    this.source,
    this.step = ImportStep.source,
    this.busy = false,
    this.problem,
    this.access,
    this.declined = false,
    this.calendars = const [],
    this.selectedCalendars = const {},
    this.fileName,
    this.ics,
    this.csv,
    this.columns,
    this.lrhsoft,
    this.notes = const {},
    this.skippedRows = 0,
    this.skippedExamples = const [],
    this.occurrences = const [],
    this.truncated = false,
    this.groups = const [],
    this.mappings = const {},
    this.suggested = const {},
    this.policy = ConflictPolicy.replace,
    this.applying = false,
  });

  final ImportSourceKind? source;
  final ImportStep step;

  /// Something is being read: the buttons wait.
  final bool busy;

  /// What went wrong in the step on screen (`null` = nothing).
  final ImportProblem? problem;

  // Phone calendar.
  final CalendarAccess? access;

  /// The user refused the system question (it may be asked again).
  final bool declined;
  final List<DeviceCalendarInfo> calendars;
  final Set<String> selectedCalendars;

  // Files.
  /// The name of the file the user recognises (`null` when the system made
  /// the name up, like Android's «.bin»).
  final String? fileName;
  final IcsDocument? ics;
  final CsvTable? csv;
  final CsvColumns? columns;

  /// The LRHSoft backup that was read ([ImportSourceKind.lrhsoftFile]).
  final LrhsoftBackup? lrhsoft;

  /// Day notes of the source inside the range (an LRHSoft backup has them).
  final Map<CivilDate, String> notes;

  /// Rows of the file that were left out: CSV rows without a valid date or
  /// shift, rows of an LRHSoft backup that were not valid.
  final int skippedRows;
  final List<int> skippedExamples;

  final ImportRange range;

  // Events, grouped, and what to do with each group.
  final List<EventOccurrence> occurrences;
  final bool truncated;
  final List<EventGroup> groups;
  final Map<String, GroupMapping> mappings;

  /// Groups whose mapping is still the automatic suggestion.
  final Set<String> suggested;
  final ConflictPolicy policy;
  final bool applying;

  List<ImportStep> get steps => switch (source) {
    null => const [ImportStep.source],
    ImportSourceKind.deviceCalendar => const [
      ImportStep.source,
      ImportStep.calendars,
      ImportStep.range,
      ImportStep.mapping,
      ImportStep.preview,
    ],
    ImportSourceKind.icsFile || ImportSourceKind.lrhsoftFile => const [
      ImportStep.source,
      ImportStep.range,
      ImportStep.mapping,
      ImportStep.preview,
    ],
    ImportSourceKind.csvFile => const [
      ImportStep.source,
      ImportStep.columns,
      ImportStep.mapping,
      ImportStep.preview,
    ],
  };

  /// Days that will be looked at: groups that are not ignored.
  int get mappedDays => [
    for (final g in groups)
      if (mappings[g.key] is! IgnoreGroup && mappings[g.key] != null) g.count,
  ].fold(0, (a, b) => a + b);

  /// The days the import covers: the days of the shifts plus the days of
  /// the notes. A day with two shifts counts once, so this is the same
  /// number the previous step says (H-T22-14).
  int get coveredDays =>
      {for (final o in occurrences) o.date, ...notes.keys}.length;

  bool get hasImportableNotes =>
      notes.values.any((note) => note.trim().isNotEmpty);

  bool get canContinueFromMapping => mappedDays > 0 || hasImportableNotes;

  ImportWizardState copyWith({
    ImportSourceKind? source,
    ImportStep? step,
    bool? busy,
    ImportProblem? problem,
    bool clearProblem = false,
    CalendarAccess? access,
    bool? declined,
    List<DeviceCalendarInfo>? calendars,
    Set<String>? selectedCalendars,
    String? fileName,
    IcsDocument? ics,
    CsvTable? csv,
    CsvColumns? columns,
    LrhsoftBackup? lrhsoft,
    Map<CivilDate, String>? notes,
    int? skippedRows,
    List<int>? skippedExamples,
    ImportRange? range,
    List<EventOccurrence>? occurrences,
    bool? truncated,
    List<EventGroup>? groups,
    Map<String, GroupMapping>? mappings,
    Set<String>? suggested,
    ConflictPolicy? policy,
    bool? applying,
  }) => ImportWizardState(
    source: source ?? this.source,
    step: step ?? this.step,
    busy: busy ?? this.busy,
    problem: clearProblem ? null : problem ?? this.problem,
    access: access ?? this.access,
    declined: declined ?? this.declined,
    calendars: calendars ?? this.calendars,
    selectedCalendars: selectedCalendars ?? this.selectedCalendars,
    fileName: fileName ?? this.fileName,
    ics: ics ?? this.ics,
    csv: csv ?? this.csv,
    columns: columns ?? this.columns,
    lrhsoft: lrhsoft ?? this.lrhsoft,
    notes: notes ?? this.notes,
    skippedRows: skippedRows ?? this.skippedRows,
    skippedExamples: skippedExamples ?? this.skippedExamples,
    range: range ?? this.range,
    occurrences: occurrences ?? this.occurrences,
    truncated: truncated ?? this.truncated,
    groups: groups ?? this.groups,
    mappings: mappings ?? this.mappings,
    suggested: suggested ?? this.suggested,
    policy: policy ?? this.policy,
    applying: applying ?? this.applying,
  );
}

/// What a finished import did (for the message after it).
class ImportOutcome {
  const ImportOutcome({
    required this.step,
    required this.days,
    required this.newTypes,
    required this.newTypeIds,
    required this.firstDay,
    this.notes = 0,
    this.notesOnly = false,
  });

  /// The undo step ([ScheduleController.undoIfLast]).
  final ScheduleChange step;

  /// Days written.
  final int days;
  final int newTypes;

  /// Notes written, and whether no shift groups were selected.
  final int notes;
  final bool notesOnly;

  /// The ids of the shift types the import created: the undo takes them
  /// away when nothing uses them any more (H-T22-8).
  final List<String> newTypeIds;

  /// The earliest day written (the month to show).
  final CivilDate firstDay;
}

/// The default range for a file: the days it mentions, but never further
/// than the usual horizon (the next six months): a series that runs to 2099
/// opens on the dates around today, not on the end of the century. Open-ended
/// series go on to the horizon. At most five years; a file that starts after
/// the horizon keeps its own start.
ImportRange defaultFileRange(IcsDocument document, CivilDate today) {
  final first = document.firstDate;
  final last = document.lastDate;
  if (first == null || last == null) return ImportRange.around(today);
  final horizon = ImportRange.around(today).to;
  if (first.isAfter(horizon)) {
    return ImportRange(first, last).clampedKeepingStart();
  }
  var to = last.isAfter(horizon) ? horizon : last;
  if (document.hasOpenEndedRules && horizon.isAfter(to)) to = horizon;
  return ImportRange(first, to).clamped();
}

// The closures below hold only the data they work on, so they can cross to a
// background isolate.
Future<IcsDocument> _readIcs(ImportRunner run, Uint8List bytes) =>
    run(() => readIcsFile(bytes));

/// The table of a CSV and the columns guessed for it, both worked out in the
/// background.
Future<({CsvTable table, CsvColumns? columns})> _readCsv(
  ImportRunner run,
  Uint8List bytes,
) => run(() {
  final table = readCsvFile(bytes);
  return (table: table, columns: guessColumns(table));
});

Future<CsvColumns?> _guessColumnsIn(ImportRunner run, CsvTable table) =>
    run(() => guessColumns(table));

Future<CsvReading> _readRowsIn(
  ImportRunner run,
  CsvTable table,
  CsvColumns columns,
) => run(() => readCsv(table, columns));

Future<Expansion> _expandDeviceIn(
  ImportRunner run,
  List<RawEvent> events,
  ImportRange range,
) => run(() => expandEvents(events, range));

/// Reads an LRHSoft backup in the background. It writes its own private temp
/// copy of the bytes and deletes it before returning.
Future<LrhsoftBackup> _readLrhsoft(ImportRunner run, Uint8List bytes) =>
    run(() => readLrhsoftBackup(bytes));

Future<LrhsoftExpansion> _expandLrhsoftIn(
  ImportRunner run,
  LrhsoftBackup backup,
  ImportRange range,
) => run(() => expandLrhsoft(backup, range));

Future<List<EventGroup>> _groupIn(
  ImportRunner run,
  List<EventOccurrence> occurrences,
) => run(() => groupEvents(occurrences));

Future<Expansion> _expandIcsIn(
  ImportRunner run,
  IcsDocument document,
  ImportRange range,
  String zone,
) => run(() => expandIcs(document, range, targetZone: zone));

class ImportWizard extends Notifier<ImportWizardState> {
  @override
  ImportWizardState build() {
    final today = CivilDate.fromDateTime(ref.read(clockProvider)());
    return ImportWizardState(range: ImportRange.around(today));
  }

  CivilDate get _today => CivilDate.fromDateTime(ref.read(clockProvider)());

  void _report(Object error, StackTrace stack) {
    try {
      unawaited(
        ref
            .read(crashReporterProvider)
            .record(redactError(error), stack, fatal: false)
            .catchError((Object _) {}),
      );
    } catch (_) {
      // A reporter that throws must not break the wizard.
    }
  }

  /// Waits for a background job, but not for ever
  /// ([importTimeoutProvider]): after that the step fails with
  /// [ImportProblem.tooComplex]. The job itself may keep running (an isolate
  /// cannot be stopped from here); its result is ignored.
  Future<T> _bounded<T>(Future<T> job) => job.timeout(
    ref.read(importTimeoutProvider),
    onTimeout: () => throw const ImportException(ImportProblem.tooComplex),
  );

  /// A failure in a step: shown as a typed problem, never as raw text.
  void _fail(Object error, StackTrace stack) {
    final problem = switch (error) {
      ImportException(:final problem) => problem,
      CalendarApiException(error: final api) => switch (api) {
        CalendarApiError.permissionDenied => ImportProblem.permissionDenied,
        CalendarApiError.unavailable => ImportProblem.calendarUnavailable,
        _ => ImportProblem.readFailed,
      },
      _ => ImportProblem.unknown,
    };
    if (error is! ImportException && error is! CalendarApiException) {
      _report(error, stack);
    }
    if (!ref.mounted) return;
    state = state.copyWith(busy: false, problem: problem);
  }

  // ---- source ---------------------------------------------------------------

  /// Starts again from the choice of source (keeps nothing of the old one).
  void reset() => state = ImportWizardState(
    range: ImportRange.around(_today),
    policy: state.policy,
  );

  /// «Desde el calendario del móvil». Looks at the permission; it asks only
  /// when the user taps the button of the permission card.
  Future<void> chooseDeviceCalendar() async {
    if (state.busy) return;
    state = ImportWizardState(
      range: ImportRange.around(_today),
      source: ImportSourceKind.deviceCalendar,
      step: ImportStep.calendars,
    );
    await _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    state = state.copyWith(busy: true, clearProblem: true);
    try {
      final api = ref.read(deviceCalendarApiProvider);
      final access = await api.access();
      if (!ref.mounted) return;
      if (access != CalendarAccess.granted) {
        state = state.copyWith(busy: false, access: access);
        return;
      }
      final all = await api.calendars();
      if (!ref.mounted) return;
      state = state.copyWith(
        busy: false,
        access: access,
        calendars: [
          for (final c in all)
            if (!c.hidden) c,
        ],
      );
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  /// The button of the permission card: shows the system question.
  Future<void> requestAccess() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearProblem: true);
    try {
      final outcome = await ref.read(deviceCalendarApiProvider).askForAccess();
      if (!ref.mounted) return;
      if (outcome.access == CalendarAccess.granted) {
        await _loadCalendars();
      } else {
        state = state.copyWith(
          busy: false,
          access: outcome.access,
          declined: outcome.declined,
        );
      }
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  /// Opens the settings of the app (the permission was refused for good).
  Future<void> openAppSettings() async {
    try {
      await ref.read(deviceCalendarApiProvider).openSettings();
    } catch (_) {
      // Nothing to do: the card keeps its text.
    }
  }

  /// Reads the permission again (after coming back from the settings).
  Future<void> recheckAccess() async {
    if (state.busy || state.source != ImportSourceKind.deviceCalendar) return;
    await _loadCalendars();
  }

  void toggleCalendar(String id) {
    final selected = {...state.selectedCalendars};
    if (!selected.add(id)) selected.remove(id);
    state = state.copyWith(selectedCalendars: selected);
  }

  /// Opens the file picker for [kind] and goes on with the file.
  Future<void> chooseFile(ImportFileKind kind) async {
    if (state.busy) return;
    final PickedImportFile? picked;
    try {
      picked = await ref.read(importFilePickerProvider)(kind);
    } catch (error, stack) {
      _fail(error, stack);
      return;
    }
    if (picked == null || !ref.mounted) return;
    await loadFile(picked, asked: kind);
  }

  /// Reads [file] (picked, or handed to the app by the system) and goes to
  /// the next step of its kind.
  ///
  /// [asked] is the kind of file the user asked for: the LRHSoft source
  /// only reads LRHSoft backups, so any other file says so in the LRHSoft
  /// way and never as a CSV (H-T22-11).
  Future<void> loadFile(PickedImportFile file, {ImportFileKind? asked}) async {
    final problem = file.problem;
    if (problem != null) {
      state = state.copyWith(problem: problem);
      return;
    }
    final bytes = file.bytes!;
    final kind = file.kind;
    final today = _today;
    state = ImportWizardState(
      range: ImportRange.around(today),
      source: switch (kind) {
        ImportFileKind.ics => ImportSourceKind.icsFile,
        ImportFileKind.csv => ImportSourceKind.csvFile,
        ImportFileKind.lrhsoft => ImportSourceKind.lrhsoftFile,
      },
      busy: true,
      fileName: file.realName,
    );
    final run = ref.read(importRunnerProvider);
    try {
      if (asked == ImportFileKind.lrhsoft && kind != ImportFileKind.lrhsoft) {
        // It is not a copy of LRHSoft: say so in the LRHSoft way, never as
        // a CSV.
        throw const ImportException(ImportProblem.notLrhsoftFile);
      }
      if (kind == ImportFileKind.lrhsoft) {
        final backup = await _bounded(_readLrhsoft(run, bytes));
        if (!ref.mounted) return;
        if (backup.days.isEmpty) {
          throw const ImportException(ImportProblem.noEvents);
        }
        state = state.copyWith(
          busy: false,
          lrhsoft: backup,
          skippedRows: backup.invalidRows,
          range: lrhsoftDefaultRange(backup, today),
          step: ImportStep.range,
        );
      } else if (kind == ImportFileKind.ics) {
        final document = await _bounded(_readIcs(run, bytes));
        if (!ref.mounted) return;
        if (document.events.isEmpty) {
          throw const ImportException(ImportProblem.noEvents);
        }
        state = state.copyWith(
          busy: false,
          ics: document,
          range: defaultFileRange(document, today),
          step: ImportStep.range,
        );
      } else {
        final read = await _bounded(_readCsv(run, bytes));
        if (!ref.mounted) return;
        final table = read.table;
        final columns = read.columns;
        if (columns == null) {
          throw const ImportException(ImportProblem.notCsv);
        }
        state = state.copyWith(
          busy: false,
          csv: table,
          columns: columns,
          step: ImportStep.columns,
        );
      }
    } catch (error, stack) {
      // Back to the choice, with the reason.
      if (ref.mounted) {
        state = ImportWizardState(
          range: ImportRange.around(today),
          policy: state.policy,
        );
      }
      _fail(error, stack);
    }
  }

  // ---- range and columns ------------------------------------------------------

  void setRange(ImportRange range) {
    if (!range.isValid) return;
    state = state.copyWith(range: range.clamped(), clearProblem: true);
  }

  Future<void> setHeader(bool hasHeader) async {
    final table = state.csv;
    if (table == null || state.busy) return;
    final next = table.withHeader(hasHeader);
    state = state.copyWith(csv: next, busy: true, clearProblem: true);
    try {
      final guessed = await _bounded(
        _guessColumnsIn(ref.read(importRunnerProvider), next),
      );
      if (!ref.mounted) return;
      state = state.copyWith(busy: false, columns: guessed ?? state.columns);
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  void setColumns(CsvColumns columns) =>
      state = state.copyWith(columns: columns);

  // ---- moving between steps -----------------------------------------------------

  /// The step before the current one; `false` when it is the first (the
  /// screen then closes).
  bool back() {
    if (state.busy || state.applying) return true;
    final steps = state.steps;
    final index = steps.indexOf(state.step);
    if (index <= 0) return false;
    state = state.copyWith(step: steps[index - 1], clearProblem: true);
    return true;
  }

  /// Goes to the next step, reading what it needs first.
  Future<void> next() async {
    if (state.busy || state.applying) return;
    final steps = state.steps;
    final index = steps.indexOf(state.step);
    if (index < 0 || index >= steps.length - 1) return;
    final target = steps[index + 1];
    state = state.copyWith(clearProblem: true);
    switch (state.step) {
      case ImportStep.calendars:
        if (state.selectedCalendars.isEmpty) return;
        state = state.copyWith(step: target);
      case ImportStep.range:
        await _readEvents(target);
      case ImportStep.columns:
        await _readRows(target);
      case ImportStep.mapping:
        if (!state.canContinueFromMapping) return;
        state = state.copyWith(step: target);
      case ImportStep.source || ImportStep.preview:
        break;
    }
  }

  Future<void> _readEvents(ImportStep target) async {
    state = state.copyWith(busy: true);
    try {
      final range = state.range;
      final Expansion expansion;
      var truncated = false;
      var notes = const <CivilDate, String>{};
      if (state.source == ImportSourceKind.lrhsoftFile) {
        final expanded = await _bounded(
          _expandLrhsoftIn(
            ref.read(importRunnerProvider),
            state.lrhsoft!,
            range,
          ),
        );
        if (!ref.mounted) return;
        expansion = Expansion(expanded.occurrences);
        notes = expanded.notes;
      } else if (state.source == ImportSourceKind.deviceCalendar) {
        final read = await readDeviceEvents(
          ref.read(deviceCalendarApiProvider),
          state.selectedCalendars.toList(),
          range,
        );
        if (!ref.mounted) return;
        expansion = await _bounded(
          _expandDeviceIn(ref.read(importRunnerProvider), read.events, range),
        );
        truncated = read.truncated;
      } else {
        final zone = await ref.read(importTimeZoneProvider)();
        expansion = await _bounded(
          _expandIcsIn(ref.read(importRunnerProvider), state.ics!, range, zone),
        );
      }
      if (!ref.mounted) return;
      if (expansion.occurrences.isEmpty && notes.isEmpty) {
        throw const ImportException(ImportProblem.noEvents);
      }
      await _setOccurrences(
        expansion.occurrences,
        truncated: truncated || expansion.truncated,
        target: target,
        notes: notes,
      );
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  Future<void> _readRows(ImportStep target) async {
    final table = state.csv;
    final columns = state.columns;
    if (table == null || columns == null) return;
    state = state.copyWith(busy: true);
    try {
      final reading = await _bounded(
        _readRowsIn(ref.read(importRunnerProvider), table, columns),
      );
      if (!ref.mounted) return;
      if (reading.occurrences.isEmpty) {
        throw const ImportException(ImportProblem.noEvents);
      }
      state = state.copyWith(
        skippedRows: reading.skippedRows,
        skippedExamples: reading.skippedExamples,
      );
      await _setOccurrences(
        reading.occurrences,
        truncated: reading.truncated,
        target: target,
      );
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  /// Groups [occurrences] and gives each group its first mapping: what the
  /// user chose before for the same title, else the suggestion, else ignore.
  Future<void> _setOccurrences(
    List<EventOccurrence> occurrences, {
    required bool truncated,
    required ImportStep target,
    Map<CivilDate, String> notes = const {},
  }) async {
    final groups = await _bounded(
      _groupIn(ref.read(importRunnerProvider), occurrences),
    );
    if (!ref.mounted) return;
    final palette = ref.read(scheduleControllerProvider).palette;
    final mappings = <String, GroupMapping>{};
    final suggested = <String>{};
    // A backup of another shift app comes with real shift types: those that
    // match none of yours start as new types (editable, or «Ignorar») instead
    // of being left out. Calendar events are not shifts, so they never do.
    final createsByDefault = state.source == ImportSourceKind.lrhsoftFile;
    final drafts = <ShiftTypeDraft>[];
    for (final group in groups) {
      final before = state.mappings[group.key];
      if (before != null) {
        mappings[group.key] = before;
        if (state.suggested.contains(group.key)) suggested.add(group.key);
        continue;
      }
      final suggestion = suggestMapping(group, palette);
      if (suggestion == null && createsByDefault) {
        final draft = draftFromGroup(
          group,
          existing: palette,
          alsoTaken: drafts,
          palette: _editorColors,
          keepSourceColor: true,
        );
        drafts.add(draft);
        mappings[group.key] = CreateType(
          ref.read(importIdGeneratorProvider)(),
          draft,
        );
        suggested.add(group.key);
      } else if (suggestion == null) {
        mappings[group.key] = const IgnoreGroup();
      } else {
        mappings[group.key] = MapToType(suggestion.type.id);
        suggested.add(group.key);
      }
    }
    state = state.copyWith(
      busy: false,
      occurrences: occurrences,
      notes: notes,
      truncated: truncated,
      groups: groups,
      mappings: mappings,
      suggested: suggested,
      step: target,
    );
  }

  // ---- mapping --------------------------------------------------------------

  void setMapping(String key, GroupMapping mapping) {
    state = state.copyWith(
      mappings: {...state.mappings, key: mapping},
      suggested: {...state.suggested}..remove(key),
    );
  }

  /// The draft of a new shift type for the group [key]: prefilled from its
  /// events (name, hours, colour, a free code). Nothing changes until
  /// [useDraft]. When the group already has a new type, that one is returned.
  ShiftTypeDraft proposeDraft(String key, {String fallbackName = 'Turno'}) {
    final current = state.mappings[key];
    if (current is CreateType) return current.draft;
    final group = state.groups.firstWhere((g) => g.key == key);
    final others = [
      for (final MapEntry(key: other, :value) in state.mappings.entries)
        if (other != key && value is CreateType) value.draft,
    ];
    return draftFromGroup(
      group,
      existing: ref.read(scheduleControllerProvider).palette,
      alsoTaken: others,
      palette: _editorColors,
      fallbackName: fallbackName,
      keepSourceColor: state.source == ImportSourceKind.lrhsoftFile,
    );
  }

  /// The group [key] becomes a new shift type with [draft] (the same one when
  /// it already had one).
  void useDraft(String key, ShiftTypeDraft draft) {
    final current = state.mappings[key];
    final id = current is CreateType
        ? current.id
        : ref.read(importIdGeneratorProvider)();
    setMapping(key, CreateType(id, draft));
  }

  /// The shift types a new type for [key] must not share its code with: the
  /// ones in the palette and the other types this import creates.
  List<ShiftType> typesToAvoid(String key) {
    final existing = ref.read(scheduleControllerProvider).palette;
    return [
      ...existing,
      for (final MapEntry(key: other, :value) in state.mappings.entries)
        if (other != key && value is CreateType && value.isCreatable)
          value.draft.toShiftType(value.id),
    ];
  }

  void setPolicy(ConflictPolicy policy) =>
      state = state.copyWith(policy: policy);

  // ---- the end ----------------------------------------------------------------

  /// What the import would do on the calendar being shown.
  ImportPlan plan(Schedule schedule) => buildImportPlan(
    schedule: schedule,
    occurrences: state.occurrences,
    mappings: state.mappings,
    policy: state.policy,
    notes: state.notes,
  );

  /// Applies the import as ONE undoable step on the calendar being shown.
  /// `null` when there was nothing to write.
  ImportOutcome? apply() {
    if (state.applying) return null;
    state = state.copyWith(applying: true);
    try {
      ImportPlan? planned;
      final step = ref.read(scheduleControllerProvider.notifier).applyPlanned((
        current,
      ) {
        planned = plan(current);
        return (change: planned!.change, newTypes: planned!.newTypes);
      });
      final done = planned;
      if (step == null || done == null) return null;
      return ImportOutcome(
        step: step,
        days: done.written,
        newTypes: done.newTypes.length,
        newTypeIds: [for (final t in done.newTypes) t.id],
        firstDay: done.changedDates.first,
        notes: done.notesWritten,
        notesOnly: state.mappedDays == 0,
      );
    } catch (error, stack) {
      _fail(error, stack);
      return null;
    } finally {
      if (ref.mounted) state = state.copyWith(applying: false);
    }
  }
}

final List<int> _editorColors = [
  for (final c in ShiftPalette.editorChoices) c.toARGB32(),
];

final importWizardProvider =
    NotifierProvider.autoDispose<ImportWizard, ImportWizardState>(
      ImportWizard.new,
    );

/// What the import would do to the calendar being shown with the choices
/// made so far (the preview and the button read it); `null` before there are
/// groups or importable notes.
final importPlanProvider = Provider.autoDispose<ImportPlan?>((ref) {
  final wizard = ref.watch(importWizardProvider);
  if (wizard.groups.isEmpty && !wizard.hasImportableNotes) return null;
  final schedule = ref.watch(
    scheduleControllerProvider.select((s) => s.schedule),
  );
  return buildImportPlan(
    schedule: schedule,
    occurrences: wizard.occurrences,
    mappings: wizard.mappings,
    policy: wizard.policy,
    notes: wizard.notes,
  );
});
