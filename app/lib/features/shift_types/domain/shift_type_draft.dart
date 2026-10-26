import '../../schedule/domain/schedule_domain.dart';

/// Longest name of a shift type.
const int maxShiftNameLength = 24;

/// Longest code of a shift type, in **UTF-16 code units** (`String.length`):
/// that is what the engine asserts (1-3) and what the backup validates, so
/// two emojis (4 units) are too long even though they look like two
/// characters.
const int maxShiftCodeLength = 3;

/// Whether [rune] may be part of a code: a letter, a digit or a simple
/// symbol (`+ / - . * #`). Emojis, spaces and control characters may not.
bool isShiftCodeChar(int rune) {
  if (rune < 0x80) {
    return (rune >= 0x30 && rune <= 0x39) || // 0-9
        (rune >= 0x41 && rune <= 0x5A) || // A-Z
        (rune >= 0x61 && rune <= 0x7A) || // a-z
        '+/-.*#'.codeUnits.contains(rune);
  }
  return _letterOrDigit.hasMatch(String.fromCharCode(rune));
}

final RegExp _letterOrDigit = RegExp(r'^[\p{L}\p{N}]$', unicode: true);

/// [code] cut to at most [maxShiftCodeLength] UTF-16 units, keeping whole
/// characters (a surrogate pair is never split). Trims it first. When
/// nothing is left, [fallback].
String fitShiftCode(String code, {String fallback = '?'}) {
  final buffer = StringBuffer();
  var units = 0;
  for (final rune in code.trim().runes) {
    final width = rune > 0xFFFF ? 2 : 1;
    if (units + width > maxShiftCodeLength) break;
    buffer.writeCharCode(rune);
    units += width;
  }
  return buffer.isEmpty ? fallback : buffer.toString();
}

/// What the code field keeps of [text] (typed or pasted): only the
/// characters [isShiftCodeChar] accepts, cut to [maxShiftCodeLength] units.
String sanitizeShiftCode(String text) {
  final kept = String.fromCharCodes(text.runes.where(isShiftCodeChar));
  return fitShiftCode(kept, fallback: '');
}

/// "12,50" / "12.5" / "12" -> cents (1250 / 1250 / 1200). A blank text is
/// `null` (no rate). Throws [FormatException] for anything else: letters,
/// more than two decimals, negative numbers, more than [maxHourlyRateCents].
int? parseEuroCents(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final match = RegExp(r'^(\d{1,6})(?:[.,](\d{1,2}))?$').firstMatch(trimmed);
  if (match == null) throw FormatException('Not an amount', text);
  final euros = int.parse(match.group(1)!);
  final decimals = (match.group(2) ?? '').padRight(2, '0');
  final cents = euros * 100 + int.parse(decimals);
  if (cents > maxHourlyRateCents) throw FormatException('Too large', text);
  return cents;
}

/// Cents as the editor shows them: "12,50", "12" for whole euros.
String formatCentsInput(int cents) {
  final euros = cents ~/ 100;
  final rest = cents % 100;
  if (rest == 0) return '$euros';
  return '$euros,${rest.toString().padLeft(2, '0')}';
}

/// The field a [ShiftTypeProblem] belongs to.
enum ShiftTypeField { code, name, unpaidBreak, rate, fixedPlus, segment2 }

enum ShiftTypeIssue {
  codeEmpty,
  codeTooLong,
  codeTaken,
  nameEmpty,
  breakTooLong,
  rateInvalid,

  /// The second segment of a split shift is wrong (one issue for each
  /// [Segment2Problem]).
  segment2Incomplete,
  segment2StartOutOfRange,
  segment2DurationOutOfRange,
  segment2NotAfterFirst,
  segment2TooLong,
}

ShiftTypeIssue _issueOf(Segment2Problem problem) => switch (problem) {
  Segment2Problem.incomplete => ShiftTypeIssue.segment2Incomplete,
  // The form hides the section without times, so this does not happen from
  // the UI; it is still a problem if a draft gets here.
  Segment2Problem.noTimes => ShiftTypeIssue.segment2Incomplete,
  Segment2Problem.startOutOfRange => ShiftTypeIssue.segment2StartOutOfRange,
  Segment2Problem.durationOutOfRange =>
    ShiftTypeIssue.segment2DurationOutOfRange,
  Segment2Problem.notAfterFirst => ShiftTypeIssue.segment2NotAfterFirst,
  Segment2Problem.tooLong => ShiftTypeIssue.segment2TooLong,
};

/// Something wrong with the form; [other] is the name of the shift type that
/// already uses the code (for [ShiftTypeIssue.codeTaken]).
class ShiftTypeProblem {
  const ShiftTypeProblem(this.issue, {this.other});

  final ShiftTypeIssue issue;
  final String? other;

  @override
  bool operator ==(Object other) =>
      other is ShiftTypeProblem &&
      other.issue == issue &&
      other.other == this.other;

  @override
  int get hashCode => Object.hash(issue, other);
}

/// What the shift type form holds while it is being edited. Plain Dart so the
/// rules (validation, paid minutes, rate parsing) are tested without widgets.
class ShiftTypeDraft {
  const ShiftTypeDraft({
    this.code = '',
    this.name = '',
    this.colorValue = 0xFFF5A524,
    this.category = ShiftCategory.work,
    this.hasTimes = true,
    this.startMinute = 8 * 60,
    this.endMinute = 16 * 60,
    this.unpaidBreakText = '',
    this.nightOverride,
    this.rateText = '',
    this.fixedPlusText = '',
    this.icon,
    this.alarmSound,
    this.segment2StartMinute,
    this.segment2DurationMinutes,
  });

  /// A draft that shows [type] as it is stored.
  factory ShiftTypeDraft.fromShiftType(ShiftType type) {
    final paid = type.paidMinutes;
    final unpaid = paid == null ? 0 : type.scheduledMinutes - paid;
    return ShiftTypeDraft(
      code: type.code,
      name: type.name,
      colorValue: type.colorValue,
      category: type.category,
      hasTimes: type.hasTimes,
      startMinute: type.startMinute ?? 8 * 60,
      endMinute: type.endMinute ?? 16 * 60,
      unpaidBreakText: unpaid > 0 ? '$unpaid' : '',
      nightOverride: type.nightOverride,
      rateText: type.hourlyRateCents == null
          ? ''
          : formatCentsInput(type.hourlyRateCents!),
      fixedPlusText: type.fixedPlusCents == null
          ? ''
          : formatCentsInput(type.fixedPlusCents!),
      icon: type.icon,
      alarmSound: type.alarmSound,
      segment2StartMinute: type.segment2StartMinute,
      segment2DurationMinutes: type.segment2DurationMinutes,
    );
  }

  final String code;
  final String name;
  final int colorValue;
  final ShiftCategory category;
  final bool hasTimes;

  /// Minutes since 00:00 (kept while "sin horario" is on, so switching back
  /// does not lose them).
  final int startMinute;
  final int endMinute;

  /// Minutes of unpaid break, as typed ("" = none). The stored value is
  /// `paidMinutes = duration - break`.
  final String unpaidBreakText;

  /// `null` = automatic, `true` = always night, `false` = never.
  final bool? nightOverride;

  /// Hourly rate in euros as typed ("12,50"; "" = none).
  final String rateText;

  /// Fixed euros earned once per work shift ("30,50"; "" = none).
  final String fixedPlusText;

  bool get fixedPlusApplies => category == ShiftCategory.work;

  /// Icon and alarm sound of the shift type being edited (the draft carries
  /// them through, so that editing a type never drops what it already has).
  final ShiftIcon? icon;
  final String? alarmSound;

  /// The second segment of a split shift (A12), as the clock minute where it
  /// starts and how long it lasts; both null = the shift is not split (the
  /// «Turno partido» switch is off). While the switch is on and the segment
  /// does not fit the first one, [validate] says why and the form cannot be
  /// saved: nothing is dropped silently.
  final int? segment2StartMinute;
  final int? segment2DurationMinutes;

  /// The «Turno partido» switch is on.
  bool get isSplit => segment2StartMinute != null;

  /// Whether the form shows the split-shift section: the shift has times.
  bool get splitSectionApplies => hasTimes;

  /// Clock minute where the second segment ends; `null` when not split.
  int? get segment2EndMinute => isSplit && segment2DurationMinutes != null
      ? (segment2StartMinute! + segment2DurationMinutes!) % 1440
      : null;

  /// What is wrong with the second segment, `null` when it is fine or the
  /// switch is off (or the section does not apply).
  Segment2Problem? get segment2Problem => splitSectionApplies && isSplit
      ? checkSegment2(
          startMinute: startMinute,
          endMinute: endMinute,
          segment2StartMinute: segment2StartMinute,
          segment2DurationMinutes: segment2DurationMinutes,
        )
      : null;

  /// Minutes the shift is scheduled to work: the first segment plus, when
  /// the second one is valid, its duration.
  int get scheduledMinutes =>
      durationMinutes + (segment2Fits ? segment2DurationMinutes! : 0);

  /// The pay section (break, night, rate) only applies to worked shifts with
  /// times; the other categories never store those fields.
  bool get paySectionApplies => category == ShiftCategory.work && hasTimes;

  /// The alarm section (the sound) only applies to shifts an alarm can ring
  /// for: with times and not an absence (the same rule as `canShiftTypeRing`
  /// of the alarm planner). The chosen sound is kept in the draft either way.
  bool get alarmSectionApplies => hasTimes && category != ShiftCategory.absence;

  /// `(end - start) mod 1440`, 0 meaning 24 h (as the engine counts it).
  int get durationMinutes => hasTimes ? _duration(startMinute, endMinute) : 0;

  /// The shift ends on the next day (08:00-08:00 included: 24 h).
  bool get endsNextDay => hasTimes && endMinute <= startMinute;

  bool get isTwentyFourHours =>
      hasTimes &&
      startMinute == endMinute &&
      _duration(startMinute, endMinute) == 1440;

  /// Unpaid break in minutes, `null` when the text is not a whole number.
  int? get unpaidBreakMinutes {
    final text = unpaidBreakText.trim();
    if (text.isEmpty) return 0;
    return RegExp(r'^\d{1,4}$').hasMatch(text) ? int.parse(text) : null;
  }

  ShiftTypeDraft copyWith({
    String? code,
    String? name,
    int? colorValue,
    ShiftCategory? category,
    bool? hasTimes,
    int? startMinute,
    int? endMinute,
    String? unpaidBreakText,
    bool? nightOverride,
    bool clearNightOverride = false,
    String? rateText,
    String? fixedPlusText,
    ShiftIcon? icon,
    bool clearIcon = false,
    String? alarmSound,
    bool clearAlarmSound = false,
    int? segment2StartMinute,
    int? segment2DurationMinutes,
    int? segment2EndMinute,
    bool clearSegment2 = false,
  }) => ShiftTypeDraft(
    code: code ?? this.code,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    category: category ?? this.category,
    hasTimes: hasTimes ?? this.hasTimes,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    unpaidBreakText: unpaidBreakText ?? this.unpaidBreakText,
    nightOverride: clearNightOverride
        ? null
        : nightOverride ?? this.nightOverride,
    rateText: rateText ?? this.rateText,
    fixedPlusText: fixedPlusText ?? this.fixedPlusText,
    icon: clearIcon ? null : icon ?? this.icon,
    alarmSound: clearAlarmSound ? null : alarmSound ?? this.alarmSound,
    segment2StartMinute: clearSegment2
        ? null
        : segment2StartMinute ?? this.segment2StartMinute,
    segment2DurationMinutes: clearSegment2
        ? null
        : segment2EndMinute != null
        // The form picks the end as a clock time: the duration follows from
        // it and the (new) start. Same start and end = 24 h, as everywhere.
        ? _duration(
            segment2StartMinute ?? this.segment2StartMinute ?? 0,
            segment2EndMinute,
          )
        : segment2DurationMinutes ?? this.segment2DurationMinutes,
  );

  /// Whole-draft equality: the form compares the draft with the one it
  /// opened with to know whether leaving would lose changes.
  @override
  bool operator ==(Object other) =>
      other is ShiftTypeDraft &&
      other.code == code &&
      other.name == name &&
      other.colorValue == colorValue &&
      other.category == category &&
      other.hasTimes == hasTimes &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.unpaidBreakText == unpaidBreakText &&
      other.nightOverride == nightOverride &&
      other.rateText == rateText &&
      other.fixedPlusText == fixedPlusText &&
      other.icon == icon &&
      other.alarmSound == alarmSound &&
      other.segment2StartMinute == segment2StartMinute &&
      other.segment2DurationMinutes == segment2DurationMinutes;

  @override
  int get hashCode => Object.hash(
    code,
    name,
    colorValue,
    category,
    hasTimes,
    startMinute,
    endMinute,
    unpaidBreakText,
    nightOverride,
    rateText,
    fixedPlusText,
    icon,
    alarmSound,
    segment2StartMinute,
    segment2DurationMinutes,
  );

  /// The draft with the «Turno partido» switch on: a second segment of 4 h
  /// that starts 4 h after the first one ends (09:00-13:00 + 17:00-21:00).
  /// It may not fit the times; [validate] then says so.
  ShiftTypeDraft withSplit() => copyWith(
    segment2StartMinute: (endMinute + 4 * 60) % 1440,
    segment2DurationMinutes: 4 * 60,
  );

  /// What is wrong with the draft ([others] are the shift types of the
  /// palette; the one being edited is left out by the caller). Empty = valid.
  Map<ShiftTypeField, ShiftTypeProblem> validate({
    Iterable<ShiftType> others = const [],
  }) {
    final problems = <ShiftTypeField, ShiftTypeProblem>{};

    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      problems[ShiftTypeField.code] = const ShiftTypeProblem(
        ShiftTypeIssue.codeEmpty,
      );
    } else if (trimmedCode.length > maxShiftCodeLength) {
      problems[ShiftTypeField.code] = const ShiftTypeProblem(
        ShiftTypeIssue.codeTooLong,
      );
    } else {
      final clash = others
          .where((t) => t.code.toLowerCase() == trimmedCode.toLowerCase())
          .firstOrNull;
      if (clash != null) {
        problems[ShiftTypeField.code] = ShiftTypeProblem(
          ShiftTypeIssue.codeTaken,
          other: clash.name,
        );
      }
    }

    if (name.trim().isEmpty) {
      problems[ShiftTypeField.name] = const ShiftTypeProblem(
        ShiftTypeIssue.nameEmpty,
      );
    }

    final segment2 = segment2Problem;
    if (segment2 != null) {
      problems[ShiftTypeField.segment2] = ShiftTypeProblem(_issueOf(segment2));
    }

    if (paySectionApplies) {
      final unpaid = unpaidBreakMinutes;
      if (unpaid == null || unpaid >= scheduledMinutes) {
        problems[ShiftTypeField.unpaidBreak] = const ShiftTypeProblem(
          ShiftTypeIssue.breakTooLong,
        );
      }
      try {
        parseEuroCents(rateText);
      } on FormatException {
        problems[ShiftTypeField.rate] = const ShiftTypeProblem(
          ShiftTypeIssue.rateInvalid,
        );
      }
    }
    if (fixedPlusApplies) {
      try {
        parseEuroCents(fixedPlusText);
      } on FormatException {
        problems[ShiftTypeField.fixedPlus] = const ShiftTypeProblem(
          ShiftTypeIssue.rateInvalid,
        );
      }
    }
    return problems;
  }

  /// The shift type this draft stands for, with id [id]. Only call it on a
  /// valid draft ([validate] is empty).
  ShiftType toShiftType(String id) {
    final pay = paySectionApplies;
    final unpaid = pay ? unpaidBreakMinutes ?? 0 : 0;
    return ShiftType(
      id: id,
      code: code.trim(),
      name: name.trim(),
      colorValue: colorValue,
      category: category,
      startMinute: hasTimes ? startMinute : null,
      endMinute: hasTimes ? endMinute : null,
      paidMinutes: unpaid > 0 ? scheduledMinutes - unpaid : null,
      nightOverride: pay ? nightOverride : null,
      hourlyRateCents: pay ? parseEuroCents(rateText) : null,
      fixedPlusCents: fixedPlusApplies ? parseEuroCents(fixedPlusText) : null,
      icon: icon,
      alarmSound: alarmSound,
      // A valid draft has a valid second segment or none; a type without
      // times has none (the form hides the section and the switch is moot).
      segment2StartMinute: segment2Fits ? segment2StartMinute : null,
      segment2DurationMinutes: segment2Fits ? segment2DurationMinutes : null,
    );
  }

  /// The switch is on and the second segment fits the first one with the
  /// times the draft has now.
  bool get segment2Fits =>
      splitSectionApplies &&
      segment2StartMinute != null &&
      segment2DurationMinutes != null &&
      segment2Problem == null;

  static int _duration(int start, int end) {
    final d = (end - start) % 1440;
    return d == 0 ? 1440 : d;
  }
}

/// A code to suggest for [name]: the first letter(s) in capitals, as short
/// as possible while no other shift type in [taken] uses it.
String suggestShiftCode(String name, Iterable<String> taken) {
  // One entry per character (a letter outside the BMP is one entry of two
  // UTF-16 units), so a prefix never cuts a surrogate pair.
  final letters = [
    for (final rune in name.runes)
      if (_letterOrDigit.hasMatch(String.fromCharCode(rune)))
        String.fromCharCode(rune).toUpperCase(),
  ];
  if (letters.isEmpty) return '';
  final used = {for (final c in taken) c.toLowerCase()};
  for (var n = 1; n <= letters.length; n++) {
    final candidate = letters.take(n).join();
    if (candidate.length > maxShiftCodeLength) break;
    if (!used.contains(candidate.toLowerCase())) return candidate;
  }
  return fitShiftCode(letters.first, fallback: '');
}
