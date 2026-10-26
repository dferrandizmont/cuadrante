import '../../schedule/domain/schedule_domain.dart';
import '../../shift_types/domain/free_color.dart';
import '../../shift_types/domain/shift_type_draft.dart';
import 'event_grouping.dart';

/// Why a shift type is suggested for a group.
enum SuggestionReason {
  /// The title is the name of the type («Mañana»).
  name,

  /// The title is the code of the type («M»).
  code,

  /// The title contains the name or the code («Turno mañana», «Turno M»), or
  /// the name contains the title («Guardia» for «Guardia 24 h»).
  similar,

  /// Same hours, nothing in the title (needs a recurring group).
  times,
}

class MappingSuggestion {
  const MappingSuggestion(this.type, this.reason, this.score);

  final ShiftType type;
  final SuggestionReason reason;

  /// 0..100; only 50 and above is ever suggested.
  final int score;
}

/// A hours-only suggestion needs at least this many days of the group: one
/// «Dentista» at 08:00-14:00 is not a Mañana.
const int minDaysForTimesSuggestion = 4;

/// The best shift type of [types] for [group], or `null` when none fits well
/// enough. By title first (name, code, one inside the other), then by hours
/// (same start and end, or within half an hour, for recurring groups).
MappingSuggestion? suggestMapping(EventGroup group, Iterable<ShiftType> types) {
  MappingSuggestion? best;
  for (final type in types) {
    final candidate = _score(group, type);
    if (candidate != null && (best == null || candidate.score > best.score)) {
      best = candidate;
    }
  }
  return best;
}

MappingSuggestion? _score(EventGroup group, ShiftType type) {
  final title = group.key;
  final name = normalizeTitle(type.name);
  final code = normalizeTitle(type.code);

  if (title.isNotEmpty) {
    if (title == name) {
      return MappingSuggestion(type, SuggestionReason.name, 100);
    }
    if (title == code) {
      return MappingSuggestion(type, SuggestionReason.code, 95);
    }
    final words = title.split(' ');
    if (name.isNotEmpty && _containsWords(words, name.split(' '))) {
      return MappingSuggestion(type, SuggestionReason.similar, 85);
    }
    if (title.length >= 3 &&
        name.isNotEmpty &&
        _containsWords(name.split(' '), words)) {
      return MappingSuggestion(type, SuggestionReason.similar, 80);
    }
    if (code.isNotEmpty && words.length > 1 && words.contains(code)) {
      return MappingSuggestion(type, SuggestionReason.similar, 75);
    }
    // «Descanso», «Free», «Day off»... are the day off of any calendar.
    if (type.category == ShiftCategory.rest && _restTitles.contains(title)) {
      final isLibre = name == 'libre' || name == 'descanso';
      return MappingSuggestion(
        type,
        SuggestionReason.similar,
        isLibre ? 83 : 82,
      );
    }
  }

  final byTimes = _timesScore(group, type);
  if (byTimes != null) {
    return MappingSuggestion(type, SuggestionReason.times, byTimes);
  }
  return null;
}

/// Titles (normalized) that mean a day off in the calendars people come from.
const Set<String> _restTitles = {
  'libre',
  'dia libre',
  'descanso',
  'dia de descanso',
  'free',
  'free time',
  'day off',
  'off',
  'rest',
  'rest day',
};

/// Whether [haystack] holds all of [needle] as consecutive words.
bool _containsWords(List<String> haystack, List<String> needle) {
  if (needle.isEmpty || needle.length > haystack.length) return false;
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var all = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        all = false;
        break;
      }
    }
    if (all) return true;
  }
  return false;
}

int? _timesScore(EventGroup group, ShiftType type) {
  if (!group.hasTimes ||
      group.endMinute == null ||
      !type.hasTimes ||
      group.count < minDaysForTimesSuggestion) {
    return null;
  }
  final startGap = _circularGap(group.startMinute!, type.startMinute!);
  final endGap = _circularGap(group.endMinute!, type.endMinute!);
  if (startGap == 0 && endGap == 0) return 70;
  if (startGap <= 30 && endGap <= 30) return 60;
  return null;
}

/// Distance between two times of day, going round midnight.
int _circularGap(int a, int b) {
  final d = (a - b).abs() % 1440;
  return d > 720 ? 1440 - d : d;
}

/// A shift type the user can create from [group]: the name and the hours of
/// the events, a code nobody uses yet and a colour not in use.
///
/// [existing] are the shift types already there (their codes and colours are
/// avoided); [alsoTaken] are the codes and colours of the types created for
/// other groups of the same import. With [keepSourceColor] (a source that
/// has real shift types, an LRHSoft backup) the colour of the source is used
/// as it is (free colours are allowed) instead of moving to one nobody uses.
ShiftTypeDraft draftFromGroup(
  EventGroup group, {
  required Iterable<ShiftType> existing,
  Iterable<ShiftTypeDraft> alsoTaken = const [],
  List<int> palette = const [],
  String fallbackName = 'Turno',
  bool keepSourceColor = false,
}) {
  final rawName = group.title.trim();
  final name = rawName.isEmpty
      ? fallbackName
      : rawName.length > maxShiftNameLength
      ? rawName.substring(0, maxShiftNameLength).trim()
      : rawName;
  final takenCodes = <String>[
    for (final t in existing) t.code,
    for (final d in alsoTaken) d.code,
  ];
  final upper = rawName.toUpperCase();
  // A title that is already short (M, LD, N12) is the code itself.
  final direct = rawName.length <= maxShiftCodeLength
      ? sanitizeShiftCode(upper)
      : '';
  final lowered = {for (final c in takenCodes) c.toLowerCase()};
  final hint = group.codeHint;
  final fromHint = hint == null
      ? ''
      : suggestCodeFromAbbreviation(hint, name, takenCodes);
  final code = fromHint.isNotEmpty
      ? fromHint
      : direct.isNotEmpty && !lowered.contains(direct.toLowerCase())
      ? direct
      : suggestShiftCode(name, takenCodes);
  final safeCode = code.isEmpty ? 'X' : code;

  final usedColors = <int>{
    for (final t in existing) t.colorValue,
    for (final d in alsoTaken) d.colorValue,
  };
  final fromSource = group.colorValue;
  final int color;
  if (fromSource != null && keepSourceColor) {
    color = FreeColor.normalize(fromSource);
  } else if (fromSource != null && !usedColors.contains(fromSource)) {
    color = fromSource;
  } else {
    color = palette.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => palette.isEmpty ? 0xFF4B4FD1 : palette.first,
    );
  }

  final timed = group.hasTimes;
  return ShiftTypeDraft(
    name: name,
    code: safeCode,
    colorValue: color,
    category: timed ? ShiftCategory.work : _categoryFor(group.key),
    hasTimes: timed,
    startMinute: group.startMinute ?? 8 * 60,
    endMinute:
        group.endMinute ?? ((group.startMinute ?? 8 * 60) + 8 * 60) % 1440,
    segment2StartMinute: timed && group.endMinute != null
        ? group.segment2StartMinute
        : null,
    segment2DurationMinutes:
        timed &&
            group.endMinute != null &&
            group.segment2StartMinute != null &&
            group.segment2EndMinute != null
        ? _minutesBetween(group.segment2StartMinute!, group.segment2EndMinute!)
        : null,
  );
}

/// Minutes from [start] to [end] going forward; the same time twice is 24 h.
int _minutesBetween(int start, int end) {
  final d = (end - start) % 1440;
  return d == 0 ? 1440 : d;
}

final RegExp _nonAlphanumeric = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// A code for a new shift type from the short text another app uses for it
/// («Mor.», «Mor./Aft.», «N», «GM»), or `''` when there is nothing to use.
///
/// One word of up to three characters is the code itself («Mor.» is «Mor»);
/// a longer word is cut to three; several words give their initials
/// («Mor./Aft.» is «MA»). A code that [taken] already uses (any case) is
/// replaced by the first letters of [name], as in the shift editor.
String suggestCodeFromAbbreviation(
  String abbreviation,
  String name,
  Iterable<String> taken,
) {
  final words = [
    for (final w in abbreviation.split(_nonAlphanumeric))
      if (w.isNotEmpty) w,
  ];
  if (words.isEmpty) return suggestShiftCode(name, taken);
  final candidate = words.length == 1
      ? fitShiftCode(words.first, fallback: '')
      : fitShiftCode(
          words.take(maxShiftCodeLength).map((w) => w.substring(0, 1)).join(),
          fallback: '',
        ).toUpperCase();
  final used = {for (final c in taken) c.toLowerCase()};
  if (candidate.isNotEmpty && !used.contains(candidate.toLowerCase())) {
    return candidate;
  }
  return suggestShiftCode(name, taken);
}

final RegExp _restWords = RegExp(
  r'\b(libre|libres|descanso|descansos|festivo|festivos|off|rest|free|saliente)\b',
);
final RegExp _absenceWords = RegExp(
  r'\b(vacaciones|vacacion|permiso|baja|moscoso|moscosos|asuntos propios|'
  r'libre disposicion|ausencia|enfermedad|licencia|excedencia|holiday)\b',
);

ShiftCategory _categoryFor(String key) {
  if (_absenceWords.hasMatch(key)) return ShiftCategory.absence;
  if (_restWords.hasMatch(key)) return ShiftCategory.rest;
  return ShiftCategory.work;
}
