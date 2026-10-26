import 'package:intl/date_symbols.dart' show DateSymbols;
import 'package:intl/intl.dart';

import '../../../core/format/text_fold.dart';
import '../../schedule/domain/schedule_domain.dart';

/// Month names (folded: no accents, no case, no dots) to month numbers
/// (1-12), as the date search of the agenda reads them. Build it with
/// [agendaMonthLookup].
typedef AgendaMonthLookup = Map<String, int>;

final Map<String, AgendaMonthLookup> _lookupCache = {};

/// The month names the search of dates understands for [locale] (a language
/// code: «es», «ca», «gl», «eu», «en»): the long and short names of its `intl`
/// symbols, their first three letters, and the Spanish ones as a fallback
/// (what the person may type whatever the language of the app). The
/// language's own names win when both languages use one for different months.
/// In Basque the months also go without their final «-a» («azaro» for
/// «azaroa»), the way the person may write them. Needs
/// `initializeDateFormatting` for [locale] (the app does it for all its
/// languages; a language without data only gets the Spanish names).
AgendaMonthLookup agendaMonthLookup(String locale) {
  final lang = locale.split(RegExp('[-_]')).first;
  final cached = _lookupCache[lang];
  if (cached != null) return cached;
  final lookup = _buildLookup(lang);
  // Not kept when the date data was not loaded yet (it would stay empty).
  if (lookup.isNotEmpty) _lookupCache[lang] = lookup;
  return lookup;
}

AgendaMonthLookup _buildLookup(String lang) {
  final lookup = <String, int>{};
  void add(String name, int month) {
    final key = _cleanMonth(name);
    if (key.isEmpty) return;
    lookup.putIfAbsent(key, () => month);
  }

  for (final code in {lang, 'es'}) {
    final DateSymbols symbols;
    try {
      symbols = DateFormat.MMMM(code).dateSymbols;
    } on Object {
      continue;
    }
    final tables = [
      symbols.MONTHS,
      symbols.STANDALONEMONTHS,
      symbols.SHORTMONTHS,
      symbols.STANDALONESHORTMONTHS,
    ];
    for (final table in tables) {
      for (var i = 0; i < table.length && i < 12; i++) {
        add(table[i], i + 1);
      }
    }
    // «sep», «set»...: the first three letters of a long name, unless another
    // month already took them.
    for (var i = 0; i < symbols.STANDALONEMONTHS.length && i < 12; i++) {
      final key = _cleanMonth(symbols.STANDALONEMONTHS[i]);
      if (key.length > 3) add(key.substring(0, 3), i + 1);
    }
    // Basque: the months also without their final «-a» («azaro» for
    // «azaroa»), as in «15 azaro» or «azaro 15». Only Basque: the names of
    // the months in the other languages do not end that way.
    if (code == _basque) {
      for (var i = 0; i < symbols.STANDALONEMONTHS.length && i < 12; i++) {
        add(_basqueStem(symbols.STANDALONEMONTHS[i]), i + 1);
      }
    }
  }
  return Map.unmodifiable(lookup);
}

/// The language code of Basque.
const String _basque = 'eu';

/// The Basque month name without its final «-a» («azaro» for «azaroa»): the
/// months in Basque carry the article, but the person may write the bare
/// stem («15 azaro»).
String _basqueStem(String name) {
  final clean = _cleanMonth(name);
  if (clean.length < 3 || !clean.endsWith('a')) return clean;
  return clean.substring(0, clean.length - 1);
}

/// Folds [name] and drops the dots and the Catalan «de »/«d'» that some
/// symbol tables put in front of the name.
String _cleanMonth(String name) =>
    foldSpanish(name)
        .replaceAll('.', '')
        .replaceFirst(RegExp(r"^(de |d')"), '')
        .trim();

final RegExp _numericDate = RegExp(
  r'^(\d{1,2})\s*[/\-.]\s*(\d{1,2})(?:\s*[/\-.]\s*(\d{4}|\d{2}))?$',
);

/// «15», «15a» (Basque), «15th», «2026ko» (Basque).
final RegExp _numberToken = RegExp(r'^(\d{1,4})(?:st|nd|rd|th|a|ko|ean)?$');

/// Words that join the parts of a date and mean nothing by themselves: «15
/// de octubre», «15 d'octubre», «15 of October».
const Set<String> _fillers = {'de', 'del', 'd', 'l', 'of'};

/// Years the search accepts when the person writes four digits.
const int _firstYear = 1900;
const int _lastYear = 2199;

/// The day that [query] names, or `null` when it is not a date (the agenda
/// then only searches the text). Accepts, accent- and case-insensitively:
/// - numbers: `15/10`, `15-10`, `15.10`, `15/10/2026`, `15-10-26`;
/// - a day and a month name, in the languages given by [months]: `15 oct`,
///   `15 octubre`, `15 de octubre`, `15 d'octubre`, `15 octubre 2026`,
///   `oct 15`, `October 15, 2026`;
/// - Basque, year first: `2026ko urriaren 15a`;
/// - Basque, the months with or without their final «-a» and the day before
///   or after them: `15 azaro`, `azaroa 15`, `2026 azaroa 15`,
///   `15 azaroa 2026`.
///
/// A two-digit year is 20xx. Without a year, the next occurrence from
/// [today]: [today] itself or later this year, otherwise next year (a 29
/// February waits for the next leap year). A day that does not exist
/// (`31/02`, `31 nov`, `29/02/2027`) gives `null`.
CivilDate? parseAgendaDate(
  String query,
  CivilDate today, {
  required AgendaMonthLookup months,
}) {
  final raw = query.trim();
  if (raw.isEmpty) return null;

  final numeric = _numericDate.firstMatch(raw);
  if (numeric != null) {
    return _build(
      day: int.parse(numeric[1]!),
      month: int.parse(numeric[2]!),
      yearText: numeric[3],
      today: today,
    );
  }

  final tokens = foldSpanish(raw)
      .replaceAll(RegExp(r"[/,.']"), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty && !_fillers.contains(t))
      .toList();
  int? month;
  var monthIndex = -1;
  final numbers = <(int position, String digits)>[];
  for (var i = 0; i < tokens.length; i++) {
    final number = _numberToken.firstMatch(tokens[i]);
    if (number != null) {
      numbers.add((i, number[1]!));
      continue;
    }
    final named = _monthOf(tokens[i], months);
    if (named == null || month != null) return null;
    month = named;
    monthIndex = i;
  }
  if (month == null || numbers.isEmpty || numbers.length > 2) return null;

  final String dayText;
  String? yearText;
  if (numbers.length == 1) {
    dayText = numbers.single.$2;
  } else {
    final (firstPosition, first) = numbers[0];
    final (secondPosition, second) = numbers[1];
    if (first.length == 4 && second.length == 4) return null;
    if (first.length == 4 && firstPosition < monthIndex) {
      (dayText, yearText) = (second, first); // year, month, day (Basque)
    } else if (second.length == 4) {
      (dayText, yearText) = (first, second);
    } else if (firstPosition < monthIndex && secondPosition > monthIndex) {
      (dayText, yearText) = (first, second); // day, month, year
    } else if (firstPosition > monthIndex) {
      (dayText, yearText) = (first, second); // month, day, year
    } else {
      return null;
    }
  }
  return _build(
    day: int.parse(dayText),
    month: month,
    yearText: yearText,
    today: today,
    dayDigits: dayText.length,
  );
}

/// The month of [word], also with the Basque endings of «urriaren».
int? _monthOf(String word, AgendaMonthLookup months) {
  final direct = months[word];
  if (direct != null) return direct;
  for (final suffix in const ['ren', 'ko']) {
    if (word.length > suffix.length + 2 && word.endsWith(suffix)) {
      final stem = months[word.substring(0, word.length - suffix.length)];
      if (stem != null) return stem;
    }
  }
  return null;
}

CivilDate? _build({
  required int day,
  required int month,
  required String? yearText,
  required CivilDate today,
  int dayDigits = 2,
}) {
  if (dayDigits > 2 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  if (yearText != null) {
    if (yearText.length != 2 && yearText.length != 4) return null;
    final year = yearText.length == 2
        ? 2000 + int.parse(yearText)
        : int.parse(yearText);
    if (year < _firstYear || year > _lastYear) return null;
    return day <= CivilDate(year, month, 1).daysInMonth
        ? CivilDate(year, month, day)
        : null;
  }
  // The next time that day comes round; a 29 February may be 4 years away
  // (8 across a skipped leap year such as 2100).
  for (var year = today.year; year <= today.year + 8; year++) {
    if (day > CivilDate(year, month, 1).daysInMonth) continue;
    final date = CivilDate(year, month, day);
    if (!date.isBefore(today)) return date;
  }
  return null;
}
