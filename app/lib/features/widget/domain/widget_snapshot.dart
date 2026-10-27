import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../schedule/domain/civil_date.dart';

/// Key of the snapshot in the widget storage (App Group `UserDefaults` on iOS,
/// `SharedPreferences` on Android). The value is the JSON string.
const String kWidgetSnapshotKey = 'cuadrante.widget.snapshot';

/// App Group shared by the app and the WidgetKit extension.
const String kWidgetAppGroupId = 'group.es.cuadrante.app';

/// `kind` of the iOS widget (one kind, six families).
const String kWidgetIosKind = 'CuadranteWidget';

/// Version of the JSON the native side reads. Bump on breaking changes.
const int kWidgetSnapshotVersion = 2;

/// Days of the timeline: today and the 59 following ones.
const int kWidgetDays = 60;

/// Days of the strip of the medium widget.
const int kWidgetStripDays = 7;

/// Cells of the month grid of the large widget: 6 weeks of 7 days.
const int kWidgetMonthCells = 42;

/// Maximum agenda length and the two-week grid size.
const int kWidgetUpcomingDays = 14;

/// The encoded snapshot must stay below this many bytes.
const int kWidgetSnapshotMaxBytes = 200 * 1024;

/// Colours of one shift colour in the app (`ShiftSwatch.forColor`), as ARGB
/// ints (`0xAARRGGBB`, unsigned, so they are always positive numbers in JSON):
/// the bar, the tint (cell background), the ink (code) and the disc (badge)
/// of the swatch, for the light and the dark theme. "dim" is the variant of
/// the days of the neighbouring months in the month grid.
class WidgetStyle {
  const WidgetStyle({
    required this.barLight,
    required this.tintLight,
    required this.inkLight,
    required this.discLight,
    required this.barDark,
    required this.tintDark,
    required this.inkDark,
    required this.discDark,
    required this.dimBarLight,
    required this.dimTintLight,
    required this.dimInkLight,
    required this.dimDiscLight,
    required this.dimBarDark,
    required this.dimTintDark,
    required this.dimInkDark,
    required this.dimDiscDark,
  });

  factory WidgetStyle.fromJson(Map<String, Object?> j) => WidgetStyle(
    barLight: _int(j, 'barLight'),
    tintLight: _int(j, 'tintLight'),
    inkLight: _int(j, 'inkLight'),
    discLight: _int(j, 'discLight'),
    barDark: _int(j, 'barDark'),
    tintDark: _int(j, 'tintDark'),
    inkDark: _int(j, 'inkDark'),
    discDark: _int(j, 'discDark'),
    dimBarLight: _int(j, 'dimBarLight'),
    dimTintLight: _int(j, 'dimTintLight'),
    dimInkLight: _int(j, 'dimInkLight'),
    dimDiscLight: _int(j, 'dimDiscLight'),
    dimBarDark: _int(j, 'dimBarDark'),
    dimTintDark: _int(j, 'dimTintDark'),
    dimInkDark: _int(j, 'dimInkDark'),
    dimDiscDark: _int(j, 'dimDiscDark'),
  );

  final int barLight;
  final int tintLight;
  final int inkLight;
  final int discLight;
  final int barDark;
  final int tintDark;
  final int inkDark;
  final int discDark;
  final int dimBarLight;
  final int dimTintLight;
  final int dimInkLight;
  final int dimDiscLight;
  final int dimBarDark;
  final int dimTintDark;
  final int dimInkDark;
  final int dimDiscDark;

  Map<String, Object?> toJson() => {
    'barLight': barLight,
    'tintLight': tintLight,
    'inkLight': inkLight,
    'discLight': discLight,
    'barDark': barDark,
    'tintDark': tintDark,
    'inkDark': inkDark,
    'discDark': discDark,
    'dimBarLight': dimBarLight,
    'dimTintLight': dimTintLight,
    'dimInkLight': dimInkLight,
    'dimDiscLight': dimDiscLight,
    'dimBarDark': dimBarDark,
    'dimTintDark': dimTintDark,
    'dimInkDark': dimInkDark,
    'dimDiscDark': dimDiscDark,
  };
}

/// One shift of a day, with its own colours (used by the small widget): the
/// same four colours per theme as [WidgetStyle], without the out-of-month
/// variant.
class WidgetShift {
  const WidgetShift({
    required this.code,
    required this.name,
    required this.timeLabel,
    required this.compactTime,
    required this.category,
    required this.barLight,
    required this.tintLight,
    required this.inkLight,
    required this.discLight,
    required this.barDark,
    required this.tintDark,
    required this.inkDark,
    required this.discDark,
  });

  factory WidgetShift.fromJson(Map<String, Object?> j) => WidgetShift(
    code: _str(j, 'code'),
    name: _str(j, 'name'),
    timeLabel: _strOrNull(j, 'timeLabel'),
    compactTime: _strOrNull(j, 'compactTime'),
    category: _str(j, 'category'),
    barLight: _int(j, 'barLight'),
    tintLight: _int(j, 'tintLight'),
    inkLight: _int(j, 'inkLight'),
    discLight: _int(j, 'discLight'),
    barDark: _int(j, 'barDark'),
    tintDark: _int(j, 'tintDark'),
    inkDark: _int(j, 'inkDark'),
    discDark: _int(j, 'discDark'),
  );

  /// 1-3 characters ("N").
  final String code;
  final String name;

  /// "22:00–06:00" (24 h, en dash), or null for a shift without schedule.
  final String? timeLabel;

  /// "22–06" ("07:30–15" when the minutes are not :00), or null.
  final String? compactTime;

  /// `work`, `rest` or `absence`.
  final String category;
  final int barLight;
  final int tintLight;
  final int inkLight;
  final int discLight;
  final int barDark;
  final int tintDark;
  final int inkDark;
  final int discDark;

  Map<String, Object?> toJson() => {
    'code': code,
    'name': name,
    'timeLabel': timeLabel,
    'compactTime': compactTime,
    'category': category,
    'barLight': barLight,
    'tintLight': tintLight,
    'inkLight': inkLight,
    'discLight': discLight,
    'barDark': barDark,
    'tintDark': tintDark,
    'inkDark': inkDark,
    'discDark': discDark,
  };
}

/// One coloured band of a cell: its code and an index into
/// [WidgetSnapshot.styles]. A day with several shifts has one band each,
/// stacked top to bottom like in the app.
class WidgetBand {
  const WidgetBand({required this.code, required this.style});

  factory WidgetBand.fromJson(Map<String, Object?> j) =>
      WidgetBand(code: _str(j, 'code'), style: _int(j, 'style'));

  final String code;
  final int style;

  Map<String, Object?> toJson() => {'code': code, 'style': style};
}

/// Small widget (systemSmall): everything already composed.
class WidgetSmall {
  const WidgetSmall({
    required this.big,
    required this.isEmpty,
    required this.detail,
    required this.tomorrow,
  });

  factory WidgetSmall.fromJson(Map<String, Object?> j) => WidgetSmall(
    big: _str(j, 'big'),
    isEmpty: _bool(j, 'isEmpty'),
    detail: _strOrNull(j, 'detail'),
    tomorrow: _str(j, 'tomorrow'),
  );

  /// The big text: "N", "M+T" for several shifts, or "Sin turno" when
  /// [isEmpty] (the native side should shrink it).
  final String big;

  /// True on a day without shifts.
  final bool isEmpty;

  /// Under the big text: "22:00–06:00"; "06–14 + 14–22" for several shifts; the
  /// shift name when it has no schedule; null on an empty day.
  final String? detail;

  /// "Mañana: T 14–22" (the next day, even when it is outside the 60 days).
  final String tomorrow;

  Map<String, Object?> toJson() => {
    'big': big,
    'isEmpty': isEmpty,
    'detail': detail,
    'tomorrow': tomorrow,
  };
}

/// A day of the 7-day strip of the medium widget.
class WidgetStripCell {
  const WidgetStripCell({
    required this.date,
    required this.weekdayShort,
    required this.dayOfMonth,
    required this.isToday,
    required this.isHoliday,
    required this.hasNote,
    required this.bands,
  });

  factory WidgetStripCell.fromJson(Map<String, Object?> j) => WidgetStripCell(
    date: _str(j, 'date'),
    weekdayShort: _str(j, 'weekdayShort'),
    dayOfMonth: _int(j, 'dayOfMonth'),
    isToday: _bool(j, 'isToday'),
    isHoliday: _bool(j, 'isHoliday'),
    hasNote: _bool(j, 'hasNote'),
    bands: _list(j, 'bands', WidgetBand.fromJson),
  );

  final String date;
  final String weekdayShort;
  final int dayOfMonth;

  /// True only for the first cell, the day of the entry.
  final bool isToday;
  final bool isHoliday;
  final bool hasNote;

  /// Empty on a day without shifts.
  final List<WidgetBand> bands;

  Map<String, Object?> toJson() => {
    'date': date,
    'weekdayShort': weekdayShort,
    'dayOfMonth': dayOfMonth,
    'isToday': isToday,
    'isHoliday': isHoliday,
    'hasNote': hasNote,
    'bands': [for (final b in bands) b.toJson()],
  };
}

/// Medium widget (systemMedium): the day and the six following ones.
class WidgetMedium {
  const WidgetMedium({required this.cells});

  factory WidgetMedium.fromJson(Map<String, Object?> j) =>
      WidgetMedium(cells: _list(j, 'cells', WidgetStripCell.fromJson));

  /// Exactly [kWidgetStripDays] cells, the first one being the day itself.
  final List<WidgetStripCell> cells;

  Map<String, Object?> toJson() => {
    'cells': [for (final c in cells) c.toJson()],
  };
}

/// Pointer of a day to its month grid (large widget).
class WidgetLarge {
  const WidgetLarge({required this.month, required this.todayCell});

  factory WidgetLarge.fromJson(Map<String, Object?> j) =>
      WidgetLarge(month: _int(j, 'month'), todayCell: _int(j, 'todayCell'));

  /// Index into [WidgetSnapshot.months].
  final int month;

  /// Index (0-41) of the day's own cell in that month's `cells`: the one to
  /// draw as today.
  final int todayCell;

  Map<String, Object?> toJson() => {'month': month, 'todayCell': todayCell};
}

/// Lock-screen widgets (accessory families): plain text, the system tints
/// them, so there are no colours.
class WidgetLock {
  const WidgetLock({
    required this.inline,
    required this.circular,
    required this.rectangular,
  });

  factory WidgetLock.fromJson(Map<String, Object?> j) => WidgetLock(
    inline: _str(j, 'inline'),
    circular: _str(j, 'circular'),
    rectangular: [for (final l in _rawList(j, 'rectangular')) l! as String],
  );

  /// "N · 22:00" (codes and start of the first shift), "N" when the shift has
  /// no schedule, "Sin turno" on an empty day.
  final String inline;

  /// "N"; "M+" for several shifts (first code and a plus); the empty-day
  /// symbol ("–") on an empty day.
  final String circular;

  /// Exactly two lines: "N · 22:00–06:00" and "Mañana: T 14–22".
  final List<String> rectangular;

  Map<String, Object?> toJson() => {
    'inline': inline,
    'circular': circular,
    'rectangular': rectangular,
  };
}

/// One day of the timeline.
class WidgetDay {
  const WidgetDay({
    required this.date,
    required this.weekday,
    required this.weekdayShort,
    required this.dayOfMonth,
    required this.dateLabel,
    required this.isHoliday,
    required this.holidayName,
    required this.hasNote,
    required this.shifts,
    required this.small,
    required this.medium,
    required this.large,
    required this.lock,
  });

  factory WidgetDay.fromJson(Map<String, Object?> j) => WidgetDay(
    date: _str(j, 'date'),
    weekday: _int(j, 'weekday'),
    weekdayShort: _str(j, 'weekdayShort'),
    dayOfMonth: _int(j, 'dayOfMonth'),
    dateLabel: _str(j, 'dateLabel'),
    isHoliday: _bool(j, 'isHoliday'),
    holidayName: _strOrNull(j, 'holidayName'),
    hasNote: _bool(j, 'hasNote'),
    shifts: _list(j, 'shifts', WidgetShift.fromJson),
    small: WidgetSmall.fromJson(_map(j, 'small')),
    medium: WidgetMedium.fromJson(_map(j, 'medium')),
    large: WidgetLarge.fromJson(_map(j, 'large')),
    lock: WidgetLock.fromJson(_map(j, 'lock')),
  );

  /// `yyyy-MM-dd`, the civil date. Day `i` of the list is `firstDate + i`.
  final String date;

  /// 1 = Monday ... 7 = Sunday.
  final int weekday;
  final String weekdayShort;
  final int dayOfMonth;

  /// "lun 19".
  final String dateLabel;
  final bool isHoliday;
  final String? holidayName;

  /// The day has a non-empty note.
  final bool hasNote;

  /// In display order; empty on a day without shifts.
  final List<WidgetShift> shifts;
  final WidgetSmall small;
  final WidgetMedium medium;
  final WidgetLarge large;
  final WidgetLock lock;

  Map<String, Object?> toJson() => {
    'date': date,
    'weekday': weekday,
    'weekdayShort': weekdayShort,
    'dayOfMonth': dayOfMonth,
    'dateLabel': dateLabel,
    'isHoliday': isHoliday,
    'holidayName': holidayName,
    'hasNote': hasNote,
    'shifts': [for (final s in shifts) s.toJson()],
    'small': small.toJson(),
    'medium': medium.toJson(),
    'large': large.toJson(),
    'lock': lock.toJson(),
  };
}

/// A cell of a month grid.
class WidgetMonthCell {
  const WidgetMonthCell({
    required this.date,
    required this.dayOfMonth,
    required this.inMonth,
    required this.isHoliday,
    required this.hasNote,
    required this.bands,
  });

  factory WidgetMonthCell.fromJson(Map<String, Object?> j) => WidgetMonthCell(
    date: _str(j, 'date'),
    dayOfMonth: _int(j, 'dayOfMonth'),
    inMonth: _bool(j, 'inMonth'),
    isHoliday: _bool(j, 'isHoliday'),
    hasNote: _bool(j, 'hasNote'),
    bands: _list(j, 'bands', WidgetBand.fromJson),
  );

  final String date;
  final int dayOfMonth;

  /// False for the days of the neighbouring months that fill the grid: draw
  /// them with the `dim*` colours of the style.
  final bool inMonth;
  final bool isHoliday;
  final bool hasNote;

  /// Empty on a day without shifts.
  final List<WidgetBand> bands;

  Map<String, Object?> toJson() => {
    'date': date,
    'dayOfMonth': dayOfMonth,
    'inMonth': inMonth,
    'isHoliday': isHoliday,
    'hasNote': hasNote,
    'bands': [for (final b in bands) b.toJson()],
  };
}

/// The month grid of the large widget, shared by all the days of that month.
class WidgetMonth {
  const WidgetMonth({
    required this.key,
    required this.title,
    required this.cells,
  });

  factory WidgetMonth.fromJson(Map<String, Object?> j) => WidgetMonth(
    key: _str(j, 'key'),
    title: _str(j, 'title'),
    cells: _list(j, 'cells', WidgetMonthCell.fromJson),
  );

  /// `yyyy-MM`.
  final String key;

  /// "Octubre 2026".
  final String title;

  /// Exactly [kWidgetMonthCells] cells, row by row. The first one is the first
  /// day of the week (Monday, or Sunday when the user picked it) on or before
  /// the 1st.
  final List<WidgetMonthCell> cells;

  Map<String, Object?> toJson() => {
    'key': key,
    'title': title,
    'cells': [for (final c in cells) c.toJson()],
  };
}

/// Lightweight view of a snapshot (or of its stored JSON) for deciding
/// whether it needs republishing. Reads only the stable header keys, so it
/// works with snapshots of other versions.
class WidgetSnapshotHeader {
  const WidgetSnapshotHeader({
    required this.version,
    required this.generatedAt,
    required this.timeZone,
    required this.firstDate,
    required this.lastDate,
    required this.contentHash,
  });

  /// Reads the header of [json]; null when it is missing or unreadable.
  static WidgetSnapshotHeader? tryParse(String? json) {
    if (json == null) return null;
    try {
      final j = (jsonDecode(json) as Map).cast<String, Object?>();
      final firstDate = _str(j, 'firstDate');
      final lastDate = _str(j, 'lastDate');
      // Dates the planner will compare: a damaged one is no header at all.
      CivilDate.parse(firstDate);
      CivilDate.parse(lastDate);
      return WidgetSnapshotHeader(
        version: _int(j, 'v'),
        generatedAt: DateTime.parse(_str(j, 'generatedAt')),
        timeZone: _str(j, 'timeZone'),
        firstDate: firstDate,
        lastDate: lastDate,
        contentHash: _str(j, 'contentHash'),
      );
    } on Object {
      return null;
    }
  }

  final int version;
  final DateTime generatedAt;
  final String timeZone;

  /// `yyyy-MM-dd` of the first and the last day.
  final String firstDate;
  final String lastDate;
  final String contentHash;
}

/// Lightweight auxiliary day for agenda and two-week widgets. These entries
/// may be outside the timeline; they never extend its validity.
class WidgetDisplayDay {
  const WidgetDisplayDay({
    required this.date,
    required this.weekdayShort,
    required this.dayOfMonth,
    required this.dateLabel,
    required this.isHoliday,
    required this.hasNote,
    required this.shifts,
  });

  factory WidgetDisplayDay.fromJson(Map<String, Object?> j) => WidgetDisplayDay(
    date: _str(j, 'date'),
    weekdayShort: _str(j, 'weekdayShort'),
    dayOfMonth: _int(j, 'dayOfMonth'),
    dateLabel: _str(j, 'dateLabel'),
    isHoliday: _bool(j, 'isHoliday'),
    hasNote: _bool(j, 'hasNote'),
    shifts: _list(j, 'shifts', WidgetShift.fromJson),
  );

  final String date;
  final String weekdayShort;
  final int dayOfMonth;
  final String dateLabel;
  final bool isHoliday;
  final bool hasNote;
  final List<WidgetShift> shifts;

  Map<String, Object?> toJson() => {
    'date': date,
    'weekdayShort': weekdayShort,
    'dayOfMonth': dayOfMonth,
    'dateLabel': dateLabel,
    'isHoliday': isHoliday,
    'hasNote': hasNote,
    'shifts': [for (final s in shifts) s.toJson()],
  };
}

/// Optional additive accessibility extension. Dates are shared by strips and
/// months to keep the snapshot below 200 KB. Notes contain presence only.
class WidgetDescriptions {
  WidgetDescriptions({
    required this.today,
    required Map<String, String> days,
    required Map<String, String> absences,
  }) : days = Map.unmodifiable(days),
       absences = Map.unmodifiable(absences);

  factory WidgetDescriptions.fromJson(Map<String, Object?> j) =>
      WidgetDescriptions(
        today: _str(j, 'today'),
        days: _map(j, 'days').cast<String, String>(),
        absences: _map(j, 'absences').cast<String, String>(),
      );

  final String today;
  final Map<String, String> days;
  // Auxiliary widgets use these redacted labels instead of private absences.
  final Map<String, String> absences;

  Map<String, Object?> toJson() => {
    'today': today,
    'days': days,
    'absences': absences,
  };
}

/// Everything the native widgets need, as JSON (see `docs/widget-contrato.md`).
/// Build it with `buildWidgetSnapshot`.
class WidgetSnapshot {
  WidgetSnapshot({
    required this.generatedAt,
    required this.timeZone,
    required this.locale,
    required this.firstDate,
    required this.lastDate,
    required this.staleTitle,
    required this.staleBody,
    required List<String> weekdayHeaders,
    required List<WidgetStyle> styles,
    required List<WidgetMonth> months,
    required List<WidgetDay> days,
    List<WidgetDisplayDay> displayDays = const [],
    this.noShift = '',
    this.descriptions,
    String? contentHash,
    this.version = kWidgetSnapshotVersion,
  }) : weekdayHeaders = List.unmodifiable(weekdayHeaders),
       styles = List.unmodifiable(styles),
       months = List.unmodifiable(months),
       days = List.unmodifiable(days),
       displayDays = List.unmodifiable(displayDays),
       _storedHash = contentHash;

  factory WidgetSnapshot.fromJson(Map<String, Object?> j) {
    final version = _int(j, 'v');
    if (version != 1 && version != kWidgetSnapshotVersion) {
      throw FormatException('Unsupported widget snapshot version $version');
    }
    return WidgetSnapshot(
      version: version,
      generatedAt: DateTime.parse(_str(j, 'generatedAt')),
      contentHash: _str(j, 'contentHash'),
      timeZone: _str(j, 'timeZone'),
      locale: _str(j, 'locale'),
      firstDate: _str(j, 'firstDate'),
      lastDate: _str(j, 'lastDate'),
      staleTitle: _str(j, 'staleTitle'),
      staleBody: _str(j, 'staleBody'),
      weekdayHeaders: [
        for (final h in _rawList(j, 'weekdayHeaders')) h! as String,
      ],
      styles: _list(j, 'styles', WidgetStyle.fromJson),
      months: _list(j, 'months', WidgetMonth.fromJson),
      days: _list(j, 'days', WidgetDay.fromJson),
      displayDays: version >= 2
          ? _list(j, 'displayDays', WidgetDisplayDay.fromJson)
          : const [],
      noShift: version >= 2 ? _str(j, 'noShift') : '',
      descriptions: j['descriptions'] == null
          ? null
          : WidgetDescriptions.fromJson(_map(j, 'descriptions')),
    );
  }

  /// Decodes [json]; throws [FormatException] when it is not a snapshot of
  /// this version.
  factory WidgetSnapshot.decode(String json) {
    try {
      return WidgetSnapshot.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('Invalid widget snapshot: $e');
    }
  }

  /// Like [decode] but null on any error.
  static WidgetSnapshot? tryDecode(String? json) {
    if (json == null) return null;
    try {
      return WidgetSnapshot.decode(json);
    } on FormatException {
      return null;
    }
  }

  final int version;

  /// UTC instant the snapshot was built at. Not part of [contentHash].
  final DateTime generatedAt;

  /// IANA id ("Europe/Madrid"): the time zone whose midnights start each
  /// day of the timeline.
  final String timeZone;
  final String locale;

  /// First and last civil date (`yyyy-MM-dd`); the days in between are
  /// consecutive, [kWidgetDays] by default.
  final String firstDate;
  final String lastDate;

  /// Shown once the timeline is over (instead of any day).
  final String staleTitle;
  final String staleBody;

  /// Column headers of the month grid, in the order of its columns (Monday
  /// first, or Sunday first when the user picked it).
  final List<String> weekdayHeaders;

  /// Colours shared by strips and month grids; bands point here.
  final List<WidgetStyle> styles;
  final List<WidgetMonth> months;
  final List<WidgetDay> days;
  final List<WidgetDisplayDay> displayDays;
  final String noShift;
  final WidgetDescriptions? descriptions;

  final String? _storedHash;

  /// SHA-256 (hex) of the content: everything except [generatedAt] and the
  /// hash itself. Equal schedules give equal hashes.
  late final String contentHash = _storedHash ?? computeContentHash();

  WidgetSnapshotHeader get header => WidgetSnapshotHeader(
    version: version,
    generatedAt: generatedAt,
    timeZone: timeZone,
    firstDate: firstDate,
    lastDate: lastDate,
    contentHash: contentHash,
  );

  /// The day with civil date [isoDate], or null when outside the timeline.
  WidgetDay? dayOn(String isoDate) {
    for (final d in days) {
      if (d.date == isoDate) return d;
    }
    return null;
  }

  /// Recomputes the hash from the content (used to verify decoded data).
  String computeContentHash() =>
      sha256.convert(utf8.encode(jsonEncode(_body()))).toString();

  Map<String, Object?> _body() => {
    'v': version,
    'timeZone': timeZone,
    'locale': locale,
    'firstDate': firstDate,
    'lastDate': lastDate,
    'staleTitle': staleTitle,
    'staleBody': staleBody,
    'weekdayHeaders': weekdayHeaders,
    'styles': [for (final s in styles) s.toJson()],
    'months': [for (final m in months) m.toJson()],
    'days': [for (final d in days) d.toJson()],
    if (descriptions != null) 'descriptions': descriptions!.toJson(),
    if (version >= 2) 'noShift': noShift,
    if (version >= 2) 'displayDays': [for (final d in displayDays) d.toJson()],
  };

  /// Key order is fixed, so the same snapshot always encodes to the same text.
  Map<String, Object?> toJson() {
    final body = _body();
    return {
      'v': body['v'],
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'contentHash': contentHash,
      for (final e in body.entries)
        if (e.key != 'v') e.key: e.value,
    };
  }

  /// Compact JSON for the widget storage.
  String encode() {
    final text = jsonEncode(toJson());
    assert(
      utf8.encode(text).length < kWidgetSnapshotMaxBytes,
      'Widget snapshot too large: ${utf8.encode(text).length} bytes',
    );
    return text;
  }
}

// Strict readers: a wrong type throws, and decode turns it into a
// FormatException.

Object? _raw(Map<String, Object?> j, String k) {
  if (!j.containsKey(k)) throw FormatException('Missing key "$k"');
  return j[k];
}

int _int(Map<String, Object?> j, String k) => _raw(j, k)! as int;

String _str(Map<String, Object?> j, String k) => _raw(j, k)! as String;

String? _strOrNull(Map<String, Object?> j, String k) => _raw(j, k) as String?;

bool _bool(Map<String, Object?> j, String k) => _raw(j, k)! as bool;

Map<String, Object?> _map(Map<String, Object?> j, String k) =>
    (_raw(j, k)! as Map).cast<String, Object?>();

List<Object?> _rawList(Map<String, Object?> j, String k) =>
    (_raw(j, k)! as List).cast<Object?>();

List<T> _list<T>(
  Map<String, Object?> j,
  String k,
  T Function(Map<String, Object?>) read,
) => [
  for (final e in _rawList(j, k)) read((e! as Map).cast<String, Object?>()),
];
