import '../../schedule/domain/civil_date.dart';

/// Alarm choices of one shift type. Off until the user opts in.
class AlarmTypeSettings {
  const AlarmTypeSettings({
    this.enabled = false,
    this.minutesBefore = defaultMinutesBefore,
    this.label,
    this.dayBefore = false,
    this.dayBeforeMinute = defaultDayBeforeMinute,
    this.secondSegment = true,
  }) : assert(dayBeforeMinute >= 0 && dayBeforeMinute < 1440);

  static const int defaultMinutesBefore = 90;

  /// 20:00, in minutes after midnight.
  static const int defaultDayBeforeMinute = 20 * 60;

  /// Longest lead we accept (a day): the planner's search window relies on it.
  static const int maxMinutesBefore = 24 * 60;

  static const AlarmTypeSettings off = AlarmTypeSettings();

  final bool enabled;

  /// How long before the shift starts the alarm rings.
  final int minutesBefore;

  /// Custom title of the notification; null or blank = "Turno de X a las H".
  /// It only replaces the title of the alarm before the shift, not that of
  /// the day-before reminder.
  final String? label;

  /// Also remind the day before, at [dayBeforeMinute] (wall-clock time).
  final bool dayBefore;

  /// Minutes after 00:00 at which the day-before reminder rings, `0..1439`.
  final int dayBeforeMinute;

  /// Also ring before the second segment of a split shift (A12), with the
  /// same lead as the first. On by default, so a split shift rings twice;
  /// it only matters for types that have a second segment, and the day-before
  /// reminder (about the shift as a whole) does not depend on it.
  final bool secondSegment;

  /// [label] without surrounding blanks, or null when there is none.
  String? get cleanLabel {
    final trimmed = label?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  AlarmTypeSettings copyWith({
    bool? enabled,
    int? minutesBefore,
    String? label,
    bool clearLabel = false,
    bool? dayBefore,
    int? dayBeforeMinute,
    bool? secondSegment,
  }) => AlarmTypeSettings(
    enabled: enabled ?? this.enabled,
    minutesBefore: minutesBefore ?? this.minutesBefore,
    label: clearLabel ? null : label ?? this.label,
    dayBefore: dayBefore ?? this.dayBefore,
    dayBeforeMinute: dayBeforeMinute ?? this.dayBeforeMinute,
    secondSegment: secondSegment ?? this.secondSegment,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'minutesBefore': minutesBefore,
    if (cleanLabel != null) 'label': cleanLabel,
    'dayBefore': dayBefore,
    'dayBeforeMinute': dayBeforeMinute,
    // Only written when turned off: the default (on) is what a missing key
    // reads as, so settings of a type without a second segment stay as they
    // were.
    if (!secondSegment) 'secondSegment': false,
  };

  /// Tolerant: wrong types (and NaN or infinite numbers) fall back to the
  /// defaults, lead and day-before time are clamped. Settings stored before
  /// the day-before reminder existed read as "no day-before reminder".
  factory AlarmTypeSettings.fromJson(Map<String, Object?> json) {
    final minutes = json['minutesBefore'];
    final label = json['label'];
    final dayBeforeMinute = json['dayBeforeMinute'];
    return AlarmTypeSettings(
      enabled: json['enabled'] == true,
      minutesBefore: minutes is num && minutes.isFinite
          ? minutes.clamp(0, maxMinutesBefore).round()
          : defaultMinutesBefore,
      label: label is String ? label : null,
      dayBefore: json['dayBefore'] == true,
      dayBeforeMinute: dayBeforeMinute is num && dayBeforeMinute.isFinite
          ? dayBeforeMinute.clamp(0, 1439).round()
          : defaultDayBeforeMinute,
      secondSegment: json['secondSegment'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AlarmTypeSettings &&
      other.enabled == enabled &&
      other.minutesBefore == minutesBefore &&
      other.cleanLabel == cleanLabel &&
      other.dayBefore == dayBefore &&
      other.dayBeforeMinute == dayBeforeMinute &&
      other.secondSegment == secondSegment;

  @override
  int get hashCode => Object.hash(
    enabled,
    minutesBefore,
    cleanLabel,
    dayBefore,
    dayBeforeMinute,
    secondSegment,
  );

  @override
  String toString() =>
      'AlarmTypeSettings(enabled: $enabled, minutesBefore: $minutesBefore, '
      'label: $cleanLabel, dayBefore: $dayBefore @ $dayBeforeMinute, '
      'secondSegment: $secondSegment)';
}

/// All alarm settings: a global switch and horizon, one [AlarmTypeSettings]
/// per shift type id and the days on which nothing rings. Everything off by
/// default.
class AlarmSettings {
  const AlarmSettings({
    this.enabled = false,
    this.horizonDays = defaultHorizonDays,
    this.byShiftType = const {},
    this.skippedDates = const {},
  });

  /// Days ahead that get scheduled (docs/plan-publicacion.md).
  static const int defaultHorizonDays = 14;
  static const int maxHorizonDays = 30;

  /// Most skipped days we read back (old ones are pruned and nothing plans
  /// more than [maxHorizonDays] ahead, so this is only a safety net).
  static const int maxSkippedDates = 400;

  static const AlarmSettings disabled = AlarmSettings();

  final bool enabled;
  final int horizonDays;

  /// Keyed by `ShiftType.id`. A missing key means [AlarmTypeSettings.off].
  final Map<String, AlarmTypeSettings> byShiftType;

  /// Days (the day a shift starts) on which no alarm rings, whatever the
  /// shift type: the "Sin alarma este día" switch of the day detail.
  final Set<CivilDate> skippedDates;

  AlarmTypeSettings forShiftType(String shiftTypeId) =>
      byShiftType[shiftTypeId] ?? AlarmTypeSettings.off;

  /// Whether any alarm could ring: the global switch and one type on.
  bool get anyActive => enabled && byShiftType.values.any((t) => t.enabled);

  bool isSkipped(CivilDate date) => skippedDates.contains(date);

  AlarmSettings copyWith({
    bool? enabled,
    int? horizonDays,
    Map<String, AlarmTypeSettings>? byShiftType,
    Set<CivilDate>? skippedDates,
  }) => AlarmSettings(
    enabled: enabled ?? this.enabled,
    horizonDays: horizonDays ?? this.horizonDays,
    byShiftType: byShiftType ?? this.byShiftType,
    skippedDates: skippedDates ?? this.skippedDates,
  );

  /// Returns a copy with [shiftTypeId] set to [settings].
  AlarmSettings withShiftType(String shiftTypeId, AlarmTypeSettings settings) =>
      copyWith(byShiftType: {...byShiftType, shiftTypeId: settings});

  /// Returns a copy where [date] is skipped ([skipped] true) or rings again.
  AlarmSettings withSkipped(CivilDate date, {required bool skipped}) {
    if (isSkipped(date) == skipped) return this;
    final next = {...skippedDates};
    skipped ? next.add(date) : next.remove(date);
    return copyWith(skippedDates: next);
  }

  /// Drops the skipped days before [today]: they can no longer matter.
  AlarmSettings pruneSkipped(CivilDate today) {
    if (skippedDates.every((d) => !d.isBefore(today))) return this;
    return copyWith(
      skippedDates: {
        for (final d in skippedDates)
          if (!d.isBefore(today)) d,
      },
    );
  }

  static const int jsonVersion = 1;

  Map<String, Object?> toJson() => {
    'version': jsonVersion,
    'enabled': enabled,
    'horizonDays': horizonDays,
    'types': {for (final e in byShiftType.entries) e.key: e.value.toJson()},
    // ISO dates, sorted, so the stored text is stable.
    'skipped': [for (final d in skippedDates.toList()..sort()) d.toIso()],
  };

  /// Tolerant: unknown or malformed parts fall back to the defaults (all off).
  factory AlarmSettings.fromJson(Map<String, Object?> json) {
    final horizon = json['horizonDays'];
    final types = json['types'];
    final skipped = json['skipped'];
    final byType = <String, AlarmTypeSettings>{};
    if (types is Map) {
      for (final e in types.entries) {
        final value = e.value;
        if (e.key is String && value is Map) {
          byType[e.key as String] = AlarmTypeSettings.fromJson(
            value.cast<String, Object?>(),
          );
        }
      }
    }
    final skippedDates = <CivilDate>{};
    if (skipped is List) {
      for (final item in skipped) {
        if (skippedDates.length >= maxSkippedDates) break;
        if (item is! String) continue;
        try {
          skippedDates.add(CivilDate.parse(item));
        } on FormatException {
          // A malformed date is simply not a skip.
        }
      }
    }
    return AlarmSettings(
      enabled: json['enabled'] == true,
      horizonDays: horizon is num && horizon.isFinite
          ? horizon.clamp(1, maxHorizonDays).round()
          : defaultHorizonDays,
      byShiftType: Map.unmodifiable(byType),
      skippedDates: Set.unmodifiable(skippedDates),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AlarmSettings &&
      other.enabled == enabled &&
      other.horizonDays == horizonDays &&
      _sameTypes(other.byShiftType, byShiftType) &&
      other.skippedDates.length == skippedDates.length &&
      other.skippedDates.containsAll(skippedDates);

  static bool _sameTypes(
    Map<String, AlarmTypeSettings> a,
    Map<String, AlarmTypeSettings> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    horizonDays,
    Object.hashAllUnordered(
      byShiftType.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(skippedDates),
  );

  @override
  String toString() =>
      'AlarmSettings(enabled: $enabled, horizonDays: $horizonDays, '
      'types: $byShiftType, skipped: ${skippedDates.length})';
}
