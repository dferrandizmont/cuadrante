import 'package:collection/collection.dart';

import '../../calendars/domain/calendar.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'backup_errors.dart';

const _deepEq = DeepCollectionEquality();

/// Value equality over [props] for the plain data classes below.
abstract class _Value {
  const _Value();

  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      _deepEq.equals(props, (other as _Value).props);

  @override
  int get hashCode => _deepEq.hash(props);

  @override
  String toString() => '$runtimeType$props';
}

/// A `calendars` row (format version 2). A version 1 file has none: reading
/// it creates [BackupCalendar.defaultMain].
class BackupCalendar extends _Value {
  const BackupCalendar({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
  });

  /// The calendar `main` ("Mi cuadrante", indigo) every database has, with
  /// the given timestamps.
  const BackupCalendar.defaultMain({this.createdAt = 0, this.updatedAt = 0})
    : id = mainCalendarId,
      name = mainCalendarName,
      colorValue = mainCalendarColor,
      sortOrder = 0,
      archived = false;

  factory BackupCalendar.fromJson(Map<String, Object?> json) {
    final r = _JsonReader(json, 'calendar');
    return BackupCalendar(
      id: r.string('id'),
      name: r.string('name'),
      colorValue: r.integer('colorValue'),
      sortOrder: r.integer('sortOrder'),
      archived: r.boolean('archived'),
      createdAt: r.integer('createdAt'),
      updatedAt: r.integer('updatedAt'),
    );
  }

  final String id;
  final String name;
  final int colorValue;
  final int sortOrder;
  final bool archived;

  /// Milliseconds since the epoch (UTC).
  final int createdAt;
  final int updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'sortOrder': sortOrder,
    'archived': archived,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    colorValue,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
}

/// A `shift_types` row, timestamps and palette position included.
class BackupShiftType extends _Value {
  const BackupShiftType({
    required this.id,
    required this.code,
    required this.name,
    required this.colorValue,
    required this.category,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.startMinute,
    this.endMinute,
    this.paidMinutes,
    this.nightOverride,
    this.hourlyRateCents,
    this.fixedPlusCents,
    this.icon,
    this.alarmSound,
    this.segment2StartMinute,
    this.segment2DurationMinutes,
    this.archived = false,
  });

  /// [readHourlyRate] is false for a version 1 file, which has no such field;
  /// [readV3Fields] is false for a version 1 or 2 file, which have no icon,
  /// alarm sound or second segment (they are ignored even if present).
  factory BackupShiftType.fromJson(
    Map<String, Object?> json, {
    bool readHourlyRate = true,
    bool readV3Fields = true,
  }) {
    final r = _JsonReader(json, 'shiftType');
    return BackupShiftType(
      id: r.string('id'),
      code: r.string('code'),
      name: r.string('name'),
      colorValue: r.integer('colorValue'),
      category: r.enumValue('category', ShiftCategory.values),
      startMinute: r.integerOrNull('startMinute'),
      endMinute: r.integerOrNull('endMinute'),
      paidMinutes: r.integerOrNull('paidMinutes'),
      nightOverride: r.boolOrNull('nightOverride'),
      hourlyRateCents: readHourlyRate
          ? r.integerOrNull('hourlyRateCents')
          : null,
      fixedPlusCents: readV3Fields ? r.integerOrNull('fixedPlusCents') : null,
      // A key this build does not know is no icon (never an error).
      icon: readV3Fields ? ShiftIcon.fromKey(r.stringOrNull('icon')) : null,
      alarmSound: readV3Fields ? r.stringOrNull('alarmSound') : null,
      segment2StartMinute: readV3Fields
          ? r.integerOrNull('segment2StartMinute')
          : null,
      segment2DurationMinutes: readV3Fields
          ? r.integerOrNull('segment2DurationMinutes')
          : null,
      sortOrder: r.integer('sortOrder'),
      archived: r.boolean('archived'),
      createdAt: r.integer('createdAt'),
      updatedAt: r.integer('updatedAt'),
    );
  }

  final String id;
  final String code;
  final String name;
  final int colorValue;
  final ShiftCategory category;
  final int? startMinute;
  final int? endMinute;
  final int? paidMinutes;
  final bool? nightOverride;

  /// Pay per hour in cents; `null` = none.
  final int? hourlyRateCents;

  /// Optional format v3 extension: fixed cents per worked shift.
  final int? fixedPlusCents;

  /// Format version 3: icon, alarm sound and second segment of a split
  /// shift (docs/datos.md, "Esquema v3").
  final ShiftIcon? icon;
  final String? alarmSound;
  final int? segment2StartMinute;
  final int? segment2DurationMinutes;
  final int sortOrder;
  final bool archived;

  /// Milliseconds since the epoch (UTC).
  final int createdAt;
  final int updatedAt;

  /// This shift type without its alarm sound (`alarmSound: null`).
  BackupShiftType withoutAlarmSound() => BackupShiftType(
    id: id,
    code: code,
    name: name,
    colorValue: colorValue,
    category: category,
    startMinute: startMinute,
    endMinute: endMinute,
    paidMinutes: paidMinutes,
    nightOverride: nightOverride,
    hourlyRateCents: hourlyRateCents,
    fixedPlusCents: fixedPlusCents,
    icon: icon,
    segment2StartMinute: segment2StartMinute,
    segment2DurationMinutes: segment2DurationMinutes,
    sortOrder: sortOrder,
    archived: archived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  ShiftType toShiftType() => ShiftType(
    id: id,
    code: code,
    name: name,
    colorValue: colorValue,
    category: category,
    startMinute: startMinute,
    endMinute: endMinute,
    paidMinutes: paidMinutes,
    nightOverride: nightOverride,
    hourlyRateCents: hourlyRateCents,
    fixedPlusCents: fixedPlusCents,
    icon: icon,
    alarmSound: alarmSound,
    segment2StartMinute: segment2StartMinute,
    segment2DurationMinutes: segment2DurationMinutes,
  );

  /// The version 3 keys are written **only when they have a value**: a
  /// shift type without them serialises exactly as it did in version 2, so
  /// the canonical bytes and the fingerprint of data that never used them
  /// are the ones they always were.
  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'colorValue': colorValue,
    'category': category.name,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'paidMinutes': paidMinutes,
    'nightOverride': nightOverride,
    'hourlyRateCents': hourlyRateCents,
    'fixedPlusCents': ?fixedPlusCents,
    'icon': ?icon?.key,
    'alarmSound': ?alarmSound,
    'segment2StartMinute': ?segment2StartMinute,
    'segment2DurationMinutes': ?segment2DurationMinutes,
    'sortOrder': sortOrder,
    'archived': archived,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    colorValue,
    category,
    startMinute,
    endMinute,
    paidMinutes,
    nightOverride,
    hourlyRateCents,
    fixedPlusCents,
    icon,
    alarmSound,
    segment2StartMinute,
    segment2DurationMinutes,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
}

/// A `patterns` row.
class BackupPattern extends _Value {
  const BackupPattern({
    required this.id,
    required this.name,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BackupPattern.fromJson(Map<String, Object?> json) {
    final r = _JsonReader(json, 'pattern');
    return BackupPattern(
      id: r.string('id'),
      name: r.string('name'),
      steps: r.stringMatrix('steps'),
      createdAt: r.integer('createdAt'),
      updatedAt: r.integer('updatedAt'),
    );
  }

  final String id;
  final String name;

  /// One list of shift type ids per day of the cycle.
  final List<List<String>> steps;
  final int createdAt;
  final int updatedAt;

  Pattern toPattern() => Pattern(id: id, name: name, steps: steps);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'steps': steps,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [id, name, steps, createdAt, updatedAt];
}

/// A `pattern_runs` row.
class BackupPatternRun extends _Value {
  const BackupPatternRun({
    required this.id,
    required this.patternId,
    required this.startDate,
    required this.seq,
    required this.createdAt,
    this.calendarId = mainCalendarId,
    this.endDate,
    this.stepOffset = 0,
  });

  /// Reads a run. A version 1 file has no calendars: its reader passes
  /// [calendarId] (`main`); a version 2 file carries it.
  factory BackupPatternRun.fromJson(
    Map<String, Object?> json, {
    String? calendarId,
  }) {
    final r = _JsonReader(json, 'patternRun');
    return BackupPatternRun(
      id: r.string('id'),
      calendarId: calendarId ?? r.string('calendarId'),
      patternId: r.string('patternId'),
      startDate: r.date('startDate'),
      endDate: r.dateOrNull('endDate'),
      stepOffset: r.integer('stepOffset'),
      seq: r.integer('seq'),
      createdAt: r.integer('createdAt'),
    );
  }

  final String id;

  /// The calendar the run belongs to.
  final String calendarId;
  final String patternId;
  final CivilDate startDate;
  final CivilDate? endDate;
  final int stepOffset;
  final int seq;
  final int createdAt;

  PatternRun toRun() => PatternRun(
    id: id,
    patternId: patternId,
    startDate: startDate,
    endDate: endDate,
    stepOffset: stepOffset,
    seq: seq,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'calendarId': calendarId,
    'patternId': patternId,
    'startDate': startDate.toIso(),
    'endDate': endDate?.toIso(),
    'stepOffset': stepOffset,
    'seq': seq,
    'createdAt': createdAt,
  };

  @override
  List<Object?> get props => [
    id,
    calendarId,
    patternId,
    startDate,
    endDate,
    stepOffset,
    seq,
    createdAt,
  ];
}

/// A `day_entries` row: a manual exception (override and/or note).
class BackupDayEntry extends _Value {
  const BackupDayEntry({
    required this.date,
    required this.updatedAt,
    this.calendarId = mainCalendarId,
    this.shiftTypeIds,
    this.note,
    this.noteReminderMinute,
    this.overtimeMinutes,
    this.earlyLeaveMinutes,
  });

  /// Reads an exception. A version 1 file has no calendars: its reader
  /// passes [calendarId] (`main`); a version 2 file carries it. [readV3Fields]
  /// is false for a version 1 or 2 file, which have no reminder, overtime or
  /// early leave (they are ignored even if present).
  factory BackupDayEntry.fromJson(
    Map<String, Object?> json, {
    String? calendarId,
    bool readV3Fields = true,
  }) {
    final r = _JsonReader(json, 'dayEntry');
    return BackupDayEntry(
      calendarId: calendarId ?? r.string('calendarId'),
      date: r.date('date'),
      shiftTypeIds: r.stringListOrNull('shiftTypeIds'),
      note: r.stringOrNull('note'),
      noteReminderMinute: readV3Fields
          ? r.integerOrNull('noteReminderMinute')
          : null,
      overtimeMinutes: readV3Fields ? r.integerOrNull('overtimeMinutes') : null,
      earlyLeaveMinutes: readV3Fields
          ? r.integerOrNull('earlyLeaveMinutes')
          : null,
      updatedAt: r.integer('updatedAt'),
    );
  }

  /// The calendar the day belongs to.
  final String calendarId;
  final CivilDate date;

  /// `null` = does not replace the pattern; `[]` = empty day.
  final List<String>? shiftTypeIds;
  final String? note;

  /// Format version 3: the minute of the day the note rings, and the extra
  /// and missing minutes of the day.
  final int? noteReminderMinute;
  final int? overtimeMinutes;
  final int? earlyLeaveMinutes;
  final int updatedAt;

  DayEntry toEntry() => DayEntry(
    date: date,
    shiftTypeIds: shiftTypeIds,
    note: note,
    noteReminderMinute: noteReminderMinute,
    overtimeMinutes: overtimeMinutes,
    earlyLeaveMinutes: earlyLeaveMinutes,
  );

  /// The version 3 keys are written only when they have a value (see
  /// [BackupShiftType.toJson]).
  Map<String, Object?> toJson() => {
    'calendarId': calendarId,
    'date': date.toIso(),
    'shiftTypeIds': shiftTypeIds,
    'note': note,
    'noteReminderMinute': ?noteReminderMinute,
    'overtimeMinutes': ?overtimeMinutes,
    'earlyLeaveMinutes': ?earlyLeaveMinutes,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [
    calendarId,
    date,
    shiftTypeIds,
    note,
    noteReminderMinute,
    overtimeMinutes,
    earlyLeaveMinutes,
    updatedAt,
  ];
}

/// A holiday the user added (`holidays.source = 'user'`). The database id is
/// not part of the backup: it is a meaningless auto-increment.
class BackupHoliday extends _Value {
  const BackupHoliday({
    required this.date,
    required this.scope,
    required this.name,
    this.regionCode,
    this.municipalityCode,
  });

  factory BackupHoliday.fromJson(Map<String, Object?> json) {
    final r = _JsonReader(json, 'holiday');
    return BackupHoliday(
      date: r.date('date'),
      scope: r.string('scope'),
      name: r.string('name'),
      regionCode: r.stringOrNull('regionCode'),
      municipalityCode: r.stringOrNull('municipalityCode'),
    );
  }

  final CivilDate date;

  /// `national` / `regional` / `local`.
  final String scope;
  final String name;
  final String? regionCode;
  final String? municipalityCode;

  Map<String, Object?> toJson() => {
    'date': date.toIso(),
    'scope': scope,
    'name': name,
    'regionCode': regionCode,
    'municipalityCode': municipalityCode,
  };

  String get _sortKey =>
      '${date.toIso()}\u0000$scope\u0000$name\u0000${regionCode ?? ''}'
      '\u0000${municipalityCode ?? ''}';

  @override
  List<Object?> get props => [date, scope, name, regionCode, municipalityCode];
}

/// An `absence_balances` row.
class BackupAbsenceBalance extends _Value {
  const BackupAbsenceBalance({
    required this.year,
    required this.type,
    required this.allowedDays,
  });

  factory BackupAbsenceBalance.fromJson(Map<String, Object?> json) {
    final r = _JsonReader(json, 'absenceBalance');
    return BackupAbsenceBalance(
      year: r.integer('year'),
      type: r.string('type'),
      allowedDays: r.number('allowedDays'),
    );
  }

  final int year;
  final String type;
  final double allowedDays;

  Map<String, Object?> toJson() => {
    'year': year,
    'type': type,
    'allowedDays': allowedDays,
  };

  @override
  List<Object?> get props => [year, type, allowedDays];
}

const _holidayScopes = {'national', 'regional', 'local'};

/// Everything the user owns in the database, as the `.cuadrante` file holds it.
///
/// The lists are normalised on construction, so equal data compares equal and
/// serialises to the same bytes: calendars and shift types by id, runs by
/// `seq`, entries by (calendar, date), holidays by (date, scope, name, ...),
/// balances by (year, type). **Patterns keep the order given** (the order of
/// the pattern list in the app is their insertion order; they have no sort
/// column).
///
/// This is the model of format version 3. Without [calendars] the data has
/// the calendar `main` (what a version 1 file means); runs and entries default
/// to it. What versions 1 and 2 do not carry (rates, icons, alarm sounds,
/// second segments, reminders, overtime, early leave) is `null`.
class BackupData {
  BackupData({
    Iterable<BackupCalendar>? calendars,
    Iterable<BackupShiftType> shiftTypes = const [],
    Iterable<BackupPattern> patterns = const [],
    Iterable<BackupPatternRun> patternRuns = const [],
    Iterable<BackupDayEntry> dayEntries = const [],
    Iterable<BackupHoliday> holidays = const [],
    Iterable<BackupAbsenceBalance> absenceBalances = const [],
    Map<String, String> settings = const {},
  }) : calendars = List.unmodifiable(
         (calendars ?? const [BackupCalendar.defaultMain()]).toList()
           ..sort((a, b) => a.id.compareTo(b.id)),
       ),
       shiftTypes = List.unmodifiable(
         shiftTypes.toList()..sort((a, b) => a.id.compareTo(b.id)),
       ),
       patterns = List.unmodifiable(patterns),
       patternRuns = List.unmodifiable(
         patternRuns.toList()..sort((a, b) => a.seq.compareTo(b.seq)),
       ),
       dayEntries = List.unmodifiable(
         dayEntries.toList()..sort((a, b) {
           final byCalendar = a.calendarId.compareTo(b.calendarId);
           return byCalendar != 0 ? byCalendar : a.date.compareTo(b.date);
         }),
       ),
       holidays = List.unmodifiable(
         holidays.toList()..sort((a, b) => a._sortKey.compareTo(b._sortKey)),
       ),
       absenceBalances = List.unmodifiable(
         absenceBalances.toList()..sort((a, b) {
           final byYear = a.year.compareTo(b.year);
           return byYear != 0 ? byYear : a.type.compareTo(b.type);
         }),
       ),
       settings = Map.unmodifiable(settings);

  /// Parses the `data` object of a **version 1** file (no calendars): every
  /// run and day goes to the calendar `main`, created here with [migratedAt]
  /// (milliseconds since the epoch) as its timestamps. Throws
  /// [FormatException] on anything unexpected. A key a version 1 file does
  /// not define (`calendars`, `calendarId`, `hourlyRateCents`) is ignored
  /// even if present: the checksum already covered the file as written.
  factory BackupData.fromJsonV1(
    Map<String, Object?> json, {
    required int migratedAt,
  }) {
    final r = _JsonReader(json, 'data');
    return BackupData(
      calendars: [
        BackupCalendar.defaultMain(
          createdAt: migratedAt,
          updatedAt: migratedAt,
        ),
      ],
      shiftTypes: r.objects(
        'shiftTypes',
        (o) => BackupShiftType.fromJson(
          o,
          readHourlyRate: false,
          readV3Fields: false,
        ),
      ),
      patterns: r.objects('patterns', BackupPattern.fromJson),
      patternRuns: r.objects(
        'patternRuns',
        (o) => BackupPatternRun.fromJson(o, calendarId: mainCalendarId),
      ),
      dayEntries: r.objects(
        'dayEntries',
        (o) => BackupDayEntry.fromJson(
          o,
          calendarId: mainCalendarId,
          readV3Fields: false,
        ),
      ),
      holidays: r.objects('holidays', BackupHoliday.fromJson),
      absenceBalances: r.objects(
        'absenceBalances',
        BackupAbsenceBalance.fromJson,
      ),
      settings: r.stringMap('settings'),
    );
  }

  /// Parses the `data` object of a **version 2** file (calendars, no icon,
  /// alarm sound, second segment, reminder, overtime or early leave). Throws
  /// [FormatException] on anything unexpected. A key a version 2 file does
  /// not define (the version 3 fields) is ignored even if present: the
  /// checksum already covered the file as written.
  factory BackupData.fromJsonV2(Map<String, Object?> json) {
    final r = _JsonReader(json, 'data');
    return BackupData(
      calendars: r.objects('calendars', BackupCalendar.fromJson),
      shiftTypes: r.objects(
        'shiftTypes',
        (o) => BackupShiftType.fromJson(o, readV3Fields: false),
      ),
      patterns: r.objects('patterns', BackupPattern.fromJson),
      patternRuns: r.objects('patternRuns', BackupPatternRun.fromJson),
      dayEntries: r.objects(
        'dayEntries',
        (o) => BackupDayEntry.fromJson(o, readV3Fields: false),
      ),
      holidays: r.objects('holidays', BackupHoliday.fromJson),
      absenceBalances: r.objects(
        'absenceBalances',
        BackupAbsenceBalance.fromJson,
      ),
      settings: r.stringMap('settings'),
    );
  }

  /// Parses the `data` object of a **version 3** file (the current one).
  /// Throws [FormatException] on anything unexpected; the codec turns that
  /// into `CorruptBackup`. Unknown keys are ignored (forward compatibility).
  factory BackupData.fromJson(Map<String, Object?> json) {
    final r = _JsonReader(json, 'data');
    return BackupData(
      calendars: r.objects('calendars', BackupCalendar.fromJson),
      shiftTypes: r.objects('shiftTypes', BackupShiftType.fromJson),
      patterns: r.objects('patterns', BackupPattern.fromJson),
      patternRuns: r.objects('patternRuns', BackupPatternRun.fromJson),
      dayEntries: r.objects('dayEntries', BackupDayEntry.fromJson),
      holidays: r.objects('holidays', BackupHoliday.fromJson),
      absenceBalances: r.objects(
        'absenceBalances',
        BackupAbsenceBalance.fromJson,
      ),
      settings: r.stringMap('settings'),
    );
  }

  final List<BackupCalendar> calendars;
  final List<BackupShiftType> shiftTypes;
  final List<BackupPattern> patterns;
  final List<BackupPatternRun> patternRuns;
  final List<BackupDayEntry> dayEntries;
  final List<BackupHoliday> holidays;
  final List<BackupAbsenceBalance> absenceBalances;

  /// Setting key -> its JSON text, exactly as stored (`calendars.active` and
  /// `calendars.primary` among them).
  final Map<String, String> settings;

  Map<String, Object?> toJson() => {
    'calendars': [for (final c in calendars) c.toJson()],
    'shiftTypes': [for (final t in shiftTypes) t.toJson()],
    'patterns': [for (final p in patterns) p.toJson()],
    'patternRuns': [for (final r in patternRuns) r.toJson()],
    'dayEntries': [for (final e in dayEntries) e.toJson()],
    'holidays': [for (final h in holidays) h.toJson()],
    'absenceBalances': [for (final b in absenceBalances) b.toJson()],
    'settings': settings,
  };

  /// The engine view of one calendar (what it would show): the shift types
  /// and patterns are common, the runs and days are those of [calendarId].
  Schedule toSchedule([String calendarId = mainCalendarId]) => Schedule(
    shiftTypes: [for (final t in shiftTypes) t.toShiftType()],
    patterns: [for (final p in patterns) p.toPattern()],
    runs: [
      for (final r in patternRuns)
        if (r.calendarId == calendarId) r.toRun(),
    ],
    entries: {
      for (final e in dayEntries)
        if (e.calendarId == calendarId) e.date: e.toEntry(),
    },
  );

  /// How many shift types carry an alarm sound that is not a system one
  /// ([isSystemAlarmSound]).
  int get foreignAlarmSoundCount => shiftTypes
      .where((t) => t.alarmSound != null && !isSystemAlarmSound(t.alarmSound!))
      .length;

  /// This data with every alarm sound that is not a system one
  /// ([isSystemAlarmSound]) dropped (`null`: the shift type rings with the
  /// default sound). A file is untrusted input: a `content://` URI of the
  /// app's own FileProvider, or of any other app, must never be handed to the
  /// notification service. Dropping it is not an error, so the rest of the
  /// backup restores. Returns `this` when there is nothing to drop.
  BackupData sanitized() {
    if (foreignAlarmSoundCount == 0) return this;
    return BackupData(
      calendars: calendars,
      shiftTypes: [
        for (final t in shiftTypes)
          t.alarmSound != null && !isSystemAlarmSound(t.alarmSound!)
              ? t.withoutAlarmSound()
              : t,
      ],
      patterns: patterns,
      patternRuns: patternRuns,
      dayEntries: dayEntries,
      holidays: holidays,
      absenceBalances: absenceBalances,
      settings: settings,
    );
  }

  /// Checks what the database and the engine would enforce (so a restore
  /// never starts a write it cannot finish, nor writes what `Schedule` then
  /// refuses to load), foreign keys included. Throws [CorruptBackup] with the
  /// first problem found.
  ///
  /// References that the engine tolerates are **not** errors: a pattern step
  /// or a day entry naming a shift type that does not exist is skipped by
  /// `Schedule`, and a legitimate database can hold one, so refusing it would
  /// make a good backup unrestorable.
  void validate() {
    Never fail(String message) => throw CorruptBackup(message);

    final calendarIds = <String>{};
    for (final c in calendars) {
      if (c.id.isEmpty) fail('A calendar has an empty id');
      if (!calendarIds.add(c.id)) fail('Duplicate calendar id "${c.id}"');
      if (c.name.trim().isEmpty) fail('Calendar "${c.id}" has no name');
      if (c.colorValue < 0 || c.colorValue > 0xFFFFFFFF) {
        fail('Calendar "${c.id}" has a color out of range');
      }
    }
    if (calendars.every((c) => c.archived)) {
      // The app always has a calendar it can show.
      fail('There is no calendar that is not archived');
    }

    final typeIds = <String>{};
    for (final t in shiftTypes) {
      if (t.id.isEmpty) fail('A shift type has an empty id');
      if (!typeIds.add(t.id)) fail('Duplicate shift type id "${t.id}"');
      if (t.code.isEmpty || t.code.length > 3) {
        fail('Shift type "${t.id}" has a code of ${t.code.length} characters');
      }
      if (t.name.isEmpty) fail('Shift type "${t.id}" has no name');
      if (t.colorValue < 0 || t.colorValue > 0xFFFFFFFF) {
        fail('Shift type "${t.id}" has a color out of range');
      }
      if ((t.startMinute == null) != (t.endMinute == null)) {
        fail('Shift type "${t.id}" has only one of start and end');
      }
      for (final m in [t.startMinute, t.endMinute]) {
        if (m != null && (m < 0 || m > 1439)) {
          fail('Shift type "${t.id}" has a time out of range');
        }
      }
      final rate = t.hourlyRateCents;
      if (rate != null && (rate < 0 || rate > maxHourlyRateCents)) {
        fail('Shift type "${t.id}" has an hourly rate out of range');
      }
      final plus = t.fixedPlusCents;
      if (plus != null && (plus < 0 || plus > maxFixedPlusCents)) {
        fail('Shift type "${t.id}" has a fixed plus out of range');
      }
      final sound = t.alarmSound;
      if (sound != null &&
          (sound.isEmpty || sound.length > maxAlarmSoundLength)) {
        fail('Shift type "${t.id}" has an invalid alarm sound');
      }
      final segment = checkSegment2(
        startMinute: t.startMinute,
        endMinute: t.endMinute,
        segment2StartMinute: t.segment2StartMinute,
        segment2DurationMinutes: t.segment2DurationMinutes,
      );
      if (segment != null) {
        fail(
          'Shift type "${t.id}" has an invalid second segment '
          '(${segment.name})',
        );
      }
    }

    final patternIds = <String>{};
    for (final p in patterns) {
      if (p.id.isEmpty) fail('A pattern has an empty id');
      if (!patternIds.add(p.id)) fail('Duplicate pattern id "${p.id}"');
      if (p.name.isEmpty) fail('Pattern "${p.id}" has no name');
      if (p.steps.isEmpty) fail('Pattern "${p.id}" has no steps');
    }

    final runIds = <String>{};
    final seqs = <int>{};
    for (final r in patternRuns) {
      if (r.id.isEmpty) fail('A run has an empty id');
      if (!runIds.add(r.id)) fail('Duplicate run id "${r.id}"');
      if (!seqs.add(r.seq)) fail('Duplicate run seq ${r.seq}');
      if (!patternIds.contains(r.patternId)) {
        fail('Run "${r.id}" points at a missing pattern "${r.patternId}"');
      }
      if (!calendarIds.contains(r.calendarId)) {
        fail('Run "${r.id}" points at a missing calendar "${r.calendarId}"');
      }
      final end = r.endDate;
      if (end != null && end.isBefore(r.startDate)) {
        fail('Run "${r.id}" ends before it starts');
      }
    }

    final dates = <(String, CivilDate)>{};
    for (final e in dayEntries) {
      if (!calendarIds.contains(e.calendarId)) {
        fail('Day ${e.date} points at a missing calendar "${e.calendarId}"');
      }
      if (!dates.add((e.calendarId, e.date))) {
        fail('Duplicate day entry ${e.date} in calendar "${e.calendarId}"');
      }
      final reminder = e.noteReminderMinute;
      if (reminder != null && !DayEntry.isReminderMinute(reminder)) {
        fail('Day ${e.date} has a reminder out of the day');
      }
      for (final extra in [e.overtimeMinutes, e.earlyLeaveMinutes]) {
        if (extra != null && (extra < 0 || extra > maxDayExtraMinutes)) {
          // A day holds 24 h at most (what the editor allows): more would
          // overflow the sums of the summary into absurd hours and euros.
          fail('Day ${e.date} has overtime or early leave out of 0-1440');
        }
      }
    }

    // One own holiday per day, like `addUserHoliday` (delete-by-date, then
    // insert); the table has no unique constraint, so the file must not bring
    // two on the same date.
    final holidayDates = <CivilDate>{};
    for (final h in holidays) {
      if (!holidayDates.add(h.date)) {
        fail('Duplicate own holiday on ${h.date}');
      }
      // The repository refuses a blank name when the user adds one.
      if (h.name.trim().isEmpty) fail('A holiday has no name');
      if (!_holidayScopes.contains(h.scope)) {
        fail('Holiday "${h.name}" has an unknown scope "${h.scope}"');
      }
    }

    final balances = <(int, String)>{};
    for (final b in absenceBalances) {
      if (!balances.add((b.year, b.type))) {
        fail('Duplicate absence balance ${b.year}/${b.type}');
      }
      if (!b.allowedDays.isFinite) {
        fail('Absence balance ${b.year}/${b.type} is not a number');
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BackupData &&
      _deepEq.equals(calendars, other.calendars) &&
      _deepEq.equals(shiftTypes, other.shiftTypes) &&
      _deepEq.equals(patterns, other.patterns) &&
      _deepEq.equals(patternRuns, other.patternRuns) &&
      _deepEq.equals(dayEntries, other.dayEntries) &&
      _deepEq.equals(holidays, other.holidays) &&
      _deepEq.equals(absenceBalances, other.absenceBalances) &&
      _deepEq.equals(settings, other.settings);

  @override
  int get hashCode => Object.hash(
    _deepEq.hash(calendars),
    _deepEq.hash(shiftTypes),
    _deepEq.hash(patterns),
    _deepEq.hash(patternRuns),
    _deepEq.hash(dayEntries),
    _deepEq.hash(holidays),
    _deepEq.hash(absenceBalances),
    _deepEq.hash(settings),
  );
}

/// Strict typed access to a decoded JSON object. Every mismatch is a
/// [FormatException] naming the field.
class _JsonReader {
  _JsonReader(this._map, this._what);

  final Map<String, Object?> _map;
  final String _what;

  Never _bad(String key, String expected) =>
      throw FormatException('$_what.$key: expected $expected');

  String string(String key) {
    final v = _map[key];
    return v is String ? v : _bad(key, 'a string');
  }

  String? stringOrNull(String key) => _map[key] == null ? null : string(key);

  int integer(String key) {
    final v = _map[key];
    if (v is int) return v;
    // Another writer may print 3 as 3.0.
    if (v is double && v.isFinite && v == v.truncateToDouble()) {
      return v.toInt();
    }
    return _bad(key, 'an integer');
  }

  int? integerOrNull(String key) => _map[key] == null ? null : integer(key);

  double number(String key) {
    final v = _map[key];
    return v is num && v.isFinite ? v.toDouble() : _bad(key, 'a number');
  }

  bool boolean(String key) {
    final v = _map[key];
    return v is bool ? v : _bad(key, 'a boolean');
  }

  bool? boolOrNull(String key) => _map[key] == null ? null : boolean(key);

  T enumValue<T extends Enum>(String key, List<T> values) {
    final name = string(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    return _bad(key, 'one of ${values.map((v) => v.name).join('/')}');
  }

  CivilDate date(String key) {
    final text = string(key);
    try {
      return CivilDate.parse(text);
    } on FormatException {
      return _bad(key, 'an ISO date');
    }
  }

  CivilDate? dateOrNull(String key) => _map[key] == null ? null : date(key);

  List<String> _strings(Object? v, String key) {
    if (v is! List) return _bad(key, 'a list of strings');
    return List<String>.unmodifiable([
      for (final s in v) s is String ? s : _bad(key, 'a list of strings'),
    ]);
  }

  List<String>? stringListOrNull(String key) =>
      _map[key] == null ? null : _strings(_map[key], key);

  List<List<String>> stringMatrix(String key) {
    final v = _map[key];
    if (v is! List) return _bad(key, 'a list of lists');
    return List.unmodifiable([for (final row in v) _strings(row, key)]);
  }

  List<T> objects<T>(String key, T Function(Map<String, Object?>) parse) {
    final v = _map[key];
    if (v is! List) return _bad(key, 'a list');
    return [
      for (final o in v)
        o is Map<String, Object?> ? parse(o) : _bad(key, 'a list of objects'),
    ];
  }

  Map<String, String> stringMap(String key) {
    final v = _map[key];
    if (v is! Map) return _bad(key, 'an object');
    return {
      for (final e in v.entries)
        e.key as String: e.value is String
            ? e.value! as String
            : _bad(key, 'string values'),
    };
  }
}
