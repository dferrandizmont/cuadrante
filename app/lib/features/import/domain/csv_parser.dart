import '../../holidays/domain/text_fold.dart';
import '../../schedule/domain/schedule_domain.dart';
import 'import_models.dart';

/// Rows read from a CSV, with the delimiter that was detected.
class CsvTable {
  const CsvTable({
    required this.rows,
    required this.delimiter,
    required this.hasHeader,
  });

  /// Every non-empty row, header included.
  final List<List<String>> rows;
  final String delimiter;

  /// The first row names the columns.
  final bool hasHeader;

  List<String> get header => hasHeader ? rows.first : const [];

  /// The rows with data.
  List<List<String>> get dataRows => hasHeader ? rows.sublist(1) : rows;

  int get columnCount => rows.fold(0, (m, r) => r.length > m ? r.length : m);

  /// The same rows, read with or without a header row.
  CsvTable withHeader(bool value) => CsvTable(
    rows: rows,
    delimiter: delimiter,
    hasHeader: value && rows.length > 1,
  );
}

/// What a column of a CSV can be.
enum CsvRole { date, title, start, end }

/// Which column holds what. Columns are 0-based; `null` = not used.
class CsvColumns {
  const CsvColumns({
    required this.date,
    required this.title,
    this.start,
    this.end,
  });

  final int date;
  final int title;
  final int? start;
  final int? end;

  /// These columns with [column] given to [role], so that no column has two
  /// roles. Another optional role (start, end) that had [column] loses it; a
  /// required one (date, title) takes the column [role] had before (a swap).
  /// When there is no such column to hand over (an optional role taking the
  /// column of the date or the title), nothing changes. [column] `null` only
  /// clears an optional role.
  CsvColumns assign(CsvRole role, int? column) {
    if (column == null) {
      return switch (role) {
        CsvRole.start => copyWith(clearStart: true, clearEnd: true),
        CsvRole.end => copyWith(clearEnd: true),
        _ => this,
      };
    }
    int? current(CsvRole r) => switch (r) {
      CsvRole.date => date,
      CsvRole.title => title,
      CsvRole.start => start,
      CsvRole.end => end,
    };
    final previous = current(role);
    var next = this;
    for (final other in CsvRole.values) {
      if (other == role || current(other) != column) continue;
      final required = other == CsvRole.date || other == CsvRole.title;
      if (!required) {
        next = other == CsvRole.start
            ? next.copyWith(clearStart: true)
            : next.copyWith(clearEnd: true);
      } else if (previous != null) {
        next = other == CsvRole.date
            ? next.copyWith(date: previous)
            : next.copyWith(title: previous);
      } else {
        return this;
      }
    }
    return switch (role) {
      CsvRole.date => next.copyWith(date: column),
      CsvRole.title => next.copyWith(title: column),
      CsvRole.start => next.copyWith(start: column),
      CsvRole.end => next.copyWith(end: column),
    };
  }

  CsvColumns copyWith({
    int? date,
    int? title,
    int? start,
    int? end,
    bool clearStart = false,
    bool clearEnd = false,
  }) => CsvColumns(
    date: date ?? this.date,
    title: title ?? this.title,
    start: clearStart ? null : start ?? this.start,
    end: clearEnd ? null : end ?? this.end,
  );
}

/// What reading the rows with a [CsvColumns] gave.
class CsvReading {
  const CsvReading({
    required this.occurrences,
    required this.skippedRows,
    required this.skippedExamples,
    required this.truncated,
  });

  final List<EventOccurrence> occurrences;

  /// Rows left out: no valid date or no title.
  final int skippedRows;

  /// Line numbers (1-based, header counted) of the first few skipped rows.
  final List<int> skippedExamples;
  final bool truncated;
}

/// Rows read at most; the rest of a huge file is ignored.
const int _maxCsvRows = 60000;

/// Columns kept per row: a hostile file with thousands of columns would
/// otherwise make the screens that show them (the preview, the column picker)
/// as wide as the file. The rest of the row is dropped.
const int maxCsvColumns = 50;

/// Longest text kept in a cell (the same limit as a title).
const int maxCsvCellLength = maxImportTitleLength;

/// Reads CSV text: delimiter `,`, `;` or tab (detected), `"` quoting with
/// `""` escapes and line breaks inside quotes, any line ending. Throws
/// [ImportException] ([ImportProblem.notCsv]) when no row has two or more
/// columns.
CsvTable parseCsv(String text) {
  var source = text;
  if (source.startsWith('﻿')) source = source.substring(1);
  final delimiter = _detectDelimiter(source);
  final rows = _readRows(source, delimiter);
  if (rows.isEmpty || rows.every((r) => r.length < 2)) {
    throw const ImportException(ImportProblem.notCsv);
  }
  final first = rows.first;
  final hasHeader =
      rows.length > 1 && !first.any((cell) => parseCsvDate(cell) != null);
  return CsvTable(rows: rows, delimiter: delimiter, hasHeader: hasHeader);
}

String _detectDelimiter(String text) {
  // The first lines outside quotes are enough: the delimiter that gives the
  // same number of (two or more) fields on most of them wins.
  final lines = text
      .split(RegExp(r'\r\n|\n|\r'))
      .where((l) => l.trim().isNotEmpty)
      .take(30)
      .toList();
  var best = ',';
  var bestScore = 0;
  var bestWidth = 0;
  for (final candidate in [';', ',', '\t']) {
    final widths = <int, int>{};
    for (final line in lines) {
      final w = _countFields(line, candidate);
      widths[w] = (widths[w] ?? 0) + 1;
    }
    widths.remove(1);
    for (final MapEntry(:key, :value) in widths.entries) {
      if (value > bestScore || (value == bestScore && key > bestWidth)) {
        best = candidate;
        bestScore = value;
        bestWidth = key;
      }
    }
  }
  return best;
}

int _countFields(String line, String delimiter) {
  var count = 1;
  var inQuote = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQuote = !inQuote;
    } else if (c == delimiter && !inQuote) {
      count++;
    }
  }
  return count;
}

List<List<String>> _readRows(String text, String delimiter) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuote = false;
  var cellStarted = false;

  void endCell() {
    // Columns past the cap are read (to find the end of the row) and dropped;
    // a long cell is cut when it is made.
    if (row.length < maxCsvColumns) row.add(clipTitle(cell.toString().trim()));
    cell.clear();
    cellStarted = false;
  }

  // A cell never holds more than a few times what is kept: a cell of
  // megabytes is not copied into memory just to be cut.
  const cellRoom = maxCsvCellLength * 4;
  void put(String s) {
    if (cell.length < cellRoom) cell.write(s);
  }

  void endRow() {
    endCell();
    if (row.any((c) => c.isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    if (rows.length >= _maxCsvRows) break;
    final c = text[i];
    if (inQuote) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          put('"');
          i++;
        } else {
          inQuote = false;
        }
      } else {
        put(c);
      }
      continue;
    }
    if (c == '"' && !cellStarted) {
      inQuote = true;
      cellStarted = true;
    } else if (c == delimiter) {
      endCell();
    } else if (c == '\r') {
      if (i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else if (c == '\n') {
      endRow();
    } else {
      put(c);
      cellStarted = true;
    }
  }
  if (cellStarted || cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

final RegExp _dayFirst = RegExp(
  r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})(?:[ T,]+(\d{1,2}):(\d{2})(?::\d{2})?)?$',
);
final RegExp _yearFirst = RegExp(
  r'^(\d{4})[/.\-](\d{1,2})[/.\-](\d{1,2})(?:[ T,]+(\d{1,2}):(\d{2})(?::\d{2})?(?:\.\d+)?Z?)?$',
);
final RegExp _compact = RegExp(r'^(\d{4})(\d{2})(\d{2})$');

/// A day written `dd/mm/yyyy` (also `-` or `.`, one-digit day or month and
/// two-digit year, read as 20yy) or `yyyy-mm-dd` (also `/`), alone or with a
/// time after it; `null` when it is not a real date. Day first, never
/// month first.
CivilDate? parseCsvDate(String text) => parseCsvDateTime(text)?.date;

/// Like [parseCsvDate], plus the time of day when the cell has one.
({CivilDate date, int? minute})? parseCsvDateTime(String text) {
  final value = text.trim();
  if (value.isEmpty) return null;
  int? year;
  int? month;
  int? day;
  String? hour;
  String? minute;
  var match = _yearFirst.firstMatch(value);
  if (match != null) {
    year = int.parse(match.group(1)!);
    month = int.parse(match.group(2)!);
    day = int.parse(match.group(3)!);
    hour = match.group(4);
    minute = match.group(5);
  } else if ((match = _dayFirst.firstMatch(value)) != null) {
    day = int.parse(match!.group(1)!);
    month = int.parse(match.group(2)!);
    final y = match.group(3)!;
    year = y.length == 2 ? 2000 + int.parse(y) : int.parse(y);
    hour = match.group(4);
    minute = match.group(5);
  } else if ((match = _compact.firstMatch(value)) != null) {
    year = int.parse(match!.group(1)!);
    month = int.parse(match.group(2)!);
    day = int.parse(match.group(3)!);
  } else {
    return null;
  }
  if (month < 1 || month > 12 || day < 1) return null;
  if (year < 1900 || year > 2200) return null;
  if (day > CivilDate(year, month, 1).daysInMonth) return null;
  int? at;
  if (hour != null && minute != null) {
    final h = int.parse(hour);
    final m = int.parse(minute);
    if (h < 24 && m < 60) at = h * 60 + m;
  }
  return (date: CivilDate(year, month, day), minute: at);
}

final RegExp _time = RegExp(r'^(\d{1,2})(?:[:.hH](\d{2})?)(?::\d{2})?$');

/// `8:00`, `08:30`, `8.30`, `8h`, `8h30` or `22:00:00` as minutes since 00:00;
/// `null` for anything else.
int? parseCsvTime(String text) {
  final match = _time.firstMatch(text.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

/// The columns most likely to hold the date, the title or code and the
/// times, from the header names and from what the cells look like. `null`
/// when no column looks like dates.
CsvColumns? guessColumns(CsvTable table) {
  final columns = table.columnCount;
  final sample = table.dataRows.take(200).toList();
  if (columns < 2 || sample.isEmpty) return null;

  double ratio(int column, bool Function(String) test) {
    var seen = 0;
    var hits = 0;
    for (final row in sample) {
      if (column >= row.length || row[column].isEmpty) continue;
      seen++;
      if (test(row[column])) hits++;
    }
    return seen == 0 ? 0 : hits / seen;
  }

  String name(int column) => table.hasHeader && column < table.header.length
      ? foldSpanish(table.header[column])
      : '';
  bool nameIs(int column, List<String> words) =>
      words.any((w) => name(column).contains(w));

  final dateRatio = [
    for (var c = 0; c < columns; c++) ratio(c, (s) => parseCsvDate(s) != null),
  ];
  final timeRatio = [
    for (var c = 0; c < columns; c++) ratio(c, (s) => parseCsvTime(s) != null),
  ];

  int? date;
  for (var c = 0; c < columns; c++) {
    if (dateRatio[c] < 0.5) continue;
    if (date == null ||
        dateRatio[c] > dateRatio[date] ||
        (dateRatio[c] == dateRatio[date] &&
            nameIs(c, const ['fecha', 'date', 'dia', 'day']) &&
            !nameIs(date, const ['fecha', 'date', 'dia', 'day']))) {
      date = c;
    }
  }
  if (date == null) return null;

  final timeColumns = [
    for (var c = 0; c < columns; c++)
      if (c != date && timeRatio[c] >= 0.5 && dateRatio[c] < 0.5) c,
  ];
  int? start;
  int? end;
  for (final c in timeColumns) {
    if (nameIs(c, const ['inicio', 'start', 'desde', 'entrada', 'from'])) {
      start ??= c;
    } else if (nameIs(c, const ['fin', 'end', 'hasta', 'salida', 'to'])) {
      end ??= c;
    }
  }
  final rest = [
    for (final c in timeColumns)
      if (c != start && c != end) c,
  ];
  start ??= rest.isNotEmpty ? rest.removeAt(0) : null;
  end ??= rest.isNotEmpty ? rest.removeAt(0) : null;

  int? title;
  var bestScore = -1.0;
  for (var c = 0; c < columns; c++) {
    if (c == date || c == start || c == end) continue;
    final text = ratio(
      c,
      (s) => parseCsvDate(s) == null && parseCsvTime(s) == null,
    );
    if (text < 0.5) continue;
    var score = text;
    if (nameIs(c, const [
      'turno',
      'codigo',
      'code',
      'titulo',
      'title',
      'evento',
      'event',
      'summary',
      'asunto',
      'nombre',
      'name',
      'shift',
    ])) {
      score += 1;
    }
    if (score > bestScore) {
      bestScore = score;
      title = c;
    }
  }
  if (title == null) return null;
  return CsvColumns(date: date, title: title, start: start, end: end);
}

/// Reads the data rows of [table] with [columns]. A row without a valid date
/// or without a title is skipped (and counted). Rows with a start time (and
/// maybe an end time) are timed events; the others are all-day.
CsvReading readCsv(CsvTable table, CsvColumns columns) {
  final out = <EventOccurrence>[];
  final skippedLines = <int>[];
  var skipped = 0;
  var truncated = false;
  final offset = table.hasHeader ? 2 : 1;
  for (final (index, row) in table.dataRows.indexed) {
    String cell(int? column) =>
        column == null || column >= row.length ? '' : row[column];
    final when = parseCsvDateTime(cell(columns.date));
    final title = clipTitle(cell(columns.title).trim());
    if (when == null || title.isEmpty) {
      skipped++;
      if (skippedLines.length < 5) skippedLines.add(index + offset);
      continue;
    }
    if (out.length >= maxImportEvents) {
      truncated = true;
      break;
    }
    // A blank start cell falls back to the time written in the date cell.
    final startText = cell(columns.start).trim();
    final start = columns.start != null && startText.isNotEmpty
        ? parseCsvTime(startText)
        : when.minute;
    final end = start == null ? null : parseCsvTime(cell(columns.end));
    out.add(
      EventOccurrence(
        title: title,
        date: when.date,
        startMinute: start,
        endMinute: end,
        allDay: start == null,
      ),
    );
  }
  out.sort((a, b) => a.date.compareTo(b.date));
  return CsvReading(
    occurrences: out,
    skippedRows: skipped,
    skippedExamples: skippedLines,
    truncated: truncated,
  );
}
