import '../../schedule/domain/schedule_domain.dart';
import 'event_grouping.dart';
import 'import_models.dart';

// The LRHSoft «Calendario de Turnos» (Shifter) backup, as plain data. The
// file itself is read by `data/lrhsoft_reader.dart`; everything here is pure
// and also runs in a background isolate. Format and traps: docs/importar.md.

/// One shift type of an LRHSoft backup (`tablaTurnos`).
class LrhsoftShiftType {
  const LrhsoftShiftType({
    required this.id,
    required this.name,
    this.abbreviation,
    this.colorValue,
    this.startMinute,
    this.endMinute,
    this.segment2StartMinute,
    this.segment2EndMinute,
  });

  /// `tablaTurnos._id`; the days point at it.
  final int id;

  /// `texto`. May be empty.
  final String name;

  /// `abreviatura` («Mor.», «Mor./Aft.»): free text, not a valid code.
  final String? abbreviation;

  /// ARGB as an unsigned 32-bit number (the file stores it signed).
  final int? colorValue;

  /// First segment, clock minutes. Both `null` = no times (an all-day item
  /// such as «Libre»: the file stores 00:00-00:00).
  final int? startMinute;
  final int? endMinute;

  /// Second segment of a split shift (`turnoPartido = 1`). Both or none.
  final int? segment2StartMinute;
  final int? segment2EndMinute;

  bool get hasTimes => startMinute != null;
}

/// One day of an LRHSoft backup (`dias`): up to two shifts and a note.
class LrhsoftDay {
  const LrhsoftDay({required this.date, this.shiftIds = const [], this.note});

  final CivilDate date;

  /// `turno1` then `turno2`, the ones that are set.
  final List<int> shiftIds;

  /// The note as plain text (the file stores HTML); `null` when empty.
  final String? note;
}

/// What the reader gets out of a backup.
class LrhsoftBackup {
  const LrhsoftBackup({
    required this.shiftTypes,
    required this.days,
    this.invalidRows = 0,
  });

  final List<LrhsoftShiftType> shiftTypes;

  /// Days that have a shift or a note, in date order.
  final List<LrhsoftDay> days;

  /// Rows skipped or fields dropped for being invalid: a date or a time that
  /// does not exist, a shift that is not in `tablaTurnos`, a second segment
  /// that does not fit the first.
  final int invalidRows;

  CivilDate? get firstDate => days.isEmpty ? null : days.first.date;
  CivilDate? get lastDate => days.isEmpty ? null : days.last.date;
}

// ---- decoding ----------------------------------------------------------------

/// The date in `dias.fecha` / `festivos.fecha`: `year * 10000 + month0 * 100 +
/// day`, with the month counted **from 0** (20260909 is 9 October 2026).
/// `null` when the number is not a real date.
CivilDate? decodeLrhsoftDate(Object? raw) {
  if (raw is! int || raw < 19000101 || raw > 22001131) return null;
  final year = raw ~/ 10000;
  final month = (raw ~/ 100) % 100 + 1;
  final day = raw % 100;
  if (month < 1 || month > 12 || day < 1) return null;
  if (day > CivilDate(year, month, 1).daysInMonth) return null;
  return CivilDate(year, month, day);
}

final RegExp _time = RegExp(r'^(\d{1,2}):(\d{2})$');

/// «HH:mm» as minutes since midnight, `null` when it is not a time.
int? parseLrhsoftTime(Object? raw) {
  if (raw is! String) return null;
  final match = _time.firstMatch(raw.trim());
  if (match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  if (hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}

/// An ARGB colour stored as a signed 32-bit integer, as an unsigned one
/// (`-551046` becomes `0xFFF7 7...`). `null` when it is not an integer.
int? decodeLrhsoftColor(Object? raw) => raw is int ? raw & 0xFFFFFFFF : null;

// Every pattern here runs in linear time on hostile input: no two unbounded
// quantifiers can take turns over the same characters.
final RegExp _lineBreaks = RegExp(
  r'<\s*br\s*(?:/\s*)?>|<\s*/\s*(?:p|div)\s*>',
  caseSensitive: false,
);
final RegExp _tags = RegExp(r'<[^<>]*>');
final RegExp _entity = RegExp(
  r'&(#[xX][0-9a-fA-F]{1,6}|#\d{1,7}|[a-zA-Z]{1,32});',
);

// C0/C1 controls (but tab and newline), the line and paragraph separators and
// the bidi overrides and isolates, which could make a note look like another.
final RegExp _invisible = RegExp(
  r'[\u0000-\u0008\u000B-\u001F\u007F-\u009F\u2028\u2029\u202A-\u202E\u2066-\u2069]',
);
final RegExp _manyBreaks = RegExp(r'\n{3,}');

const Map<String, String> _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'aacute': 'á',
  'eacute': 'é',
  'iacute': 'í',
  'oacute': 'ó',
  'uacute': 'ú',
  'Aacute': 'Á',
  'Eacute': 'É',
  'Iacute': 'Í',
  'Oacute': 'Ó',
  'Uacute': 'Ú',
  'ntilde': 'ñ',
  'Ntilde': 'Ñ',
  'uuml': 'ü',
  'Uuml': 'Ü',
  'iexcl': '¡',
  'iquest': '¿',
  'euro': '€',
  'ordm': 'º',
  'ordf': 'ª',
  'agrave': 'à',
  'egrave': 'è',
  'ograve': 'ò',
  'ccedil': 'ç',
  'middot': '·',
};

/// The note of a day as plain text. LRHSoft stores Android HTML
/// (`<p dir="ltr">Revisi&#243;n m&#233;dica</p>`): the line breaks of the
/// source are not breaks, `<br>`, `</p>` and `</div>` are, the tags go away
/// and the entities are decoded. `null` when nothing is left.
String? lrhsoftNoteText(Object? html) {
  if (html is! String || html.isEmpty) return null;
  // Cut first: a hostile note of megabytes must not cost a regex pass each.
  final source = html.length > maxImportNoteLength * 8
      ? html.substring(0, maxImportNoteLength * 8)
      : html;
  var text = source
      .replaceAll('\r', '')
      .replaceAll('\n', ' ')
      .replaceAll(_lineBreaks, '\n')
      .replaceAll(_tags, '');
  text = text.replaceAllMapped(_entity, (m) {
    final body = m[1]!;
    if (body.startsWith('#')) {
      final code = body[1] == 'x' || body[1] == 'X'
          ? int.tryParse(body.substring(2), radix: 16)
          : int.tryParse(body.substring(1));
      if (code == null ||
          code == 0 ||
          code > 0x10FFFF ||
          (code >= 0xD800 && code <= 0xDFFF)) {
        return '';
      }
      return String.fromCharCode(code);
    }
    return _namedEntities[body] ?? m[0]!;
  });
  text = text
      .replaceAll(' ', ' ')
      .replaceAll(_invisible, '')
      .split('\n')
      .map((line) => line.trim())
      .join('\n')
      .replaceAll(_manyBreaks, '\n\n')
      .trim();
  if (text.isEmpty) return null;
  return text.length > maxImportNoteLength
      ? _clip(text, maxImportNoteLength)
      : text;
}

String _clip(String text, int max) {
  var end = max;
  final last = text.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return text.substring(0, end);
}

// ---- to the import pipeline ---------------------------------------------------

/// What an LRHSoft backup gives the wizard inside a range: one occurrence per
/// shift and day (the pipeline groups them by shift name) and the notes.
class LrhsoftExpansion {
  const LrhsoftExpansion(this.occurrences, this.notes);

  final List<EventOccurrence> occurrences;

  /// Day notes inside the range, plain text.
  final Map<CivilDate, String> notes;
}

/// The title each shift type of [backup] goes by in the wizard: its name, or
/// its abbreviation, or «Turno N» when it has neither. Two types whose names
/// the pipeline would merge (same after [normalizeTitle]) get their
/// abbreviation or their number added so they stay apart.
Map<int, String> lrhsoftTitles(LrhsoftBackup backup) {
  final titles = <int, String>{};
  final seen = <String>{};
  for (final type in backup.shiftTypes) {
    final name = type.name.trim();
    final abbreviation = type.abbreviation?.trim() ?? '';
    var title = name.isNotEmpty
        ? name
        : abbreviation.isNotEmpty
        ? abbreviation
        : 'Turno ${type.id}';
    if (seen.contains(normalizeTitle(title))) {
      title = abbreviation.isNotEmpty && name.isNotEmpty
          ? '$name ($abbreviation)'
          : '$title (${type.id})';
      if (seen.contains(normalizeTitle(title))) title = '$title ${type.id}';
    }
    title = clipTitle(title);
    seen.add(normalizeTitle(title));
    titles[type.id] = title;
  }
  return titles;
}

/// Turns the days of [backup] inside [range] into occurrences and notes.
/// A shift without times is an all-day occurrence; one with times belongs to
/// the day it starts (a night shift that ends the next morning stays on its
/// own day, as in the engine). The same shift twice in a day counts once.
LrhsoftExpansion expandLrhsoft(LrhsoftBackup backup, ImportRange range) {
  final titles = lrhsoftTitles(backup);
  final types = {for (final t in backup.shiftTypes) t.id: t};
  final occurrences = <EventOccurrence>[];
  final notes = <CivilDate, String>{};
  for (final day in backup.days) {
    if (!range.contains(day.date)) continue;
    final note = day.note;
    if (note != null && note.isNotEmpty) notes[day.date] = note;
    final done = <int>{};
    for (final id in day.shiftIds) {
      final type = types[id];
      if (type == null || !done.add(id)) continue;
      final title = titles[id]!;
      final abbreviation = type.abbreviation?.trim();
      final hint = abbreviation == null || abbreviation.isEmpty
          ? null
          : abbreviation;
      occurrences.add(
        type.hasTimes
            ? EventOccurrence(
                title: title,
                date: day.date,
                startMinute: type.startMinute,
                endMinute: type.endMinute,
                colorValue: type.colorValue,
                segment2StartMinute: type.segment2StartMinute,
                segment2EndMinute: type.segment2EndMinute,
                codeHint: hint,
              )
            : EventOccurrence(
                title: title,
                date: day.date,
                allDay: true,
                colorValue: type.colorValue,
                codeHint: hint,
              ),
      );
    }
  }
  return LrhsoftExpansion(occurrences, notes);
}

/// The dates the wizard starts with for [backup]: from its first day to its
/// last, at most five years (the most recent ones).
ImportRange lrhsoftDefaultRange(LrhsoftBackup backup, CivilDate today) {
  final first = backup.firstDate;
  final last = backup.lastDate;
  if (first == null || last == null) return ImportRange.around(today);
  return ImportRange(first, last).clamped();
}
