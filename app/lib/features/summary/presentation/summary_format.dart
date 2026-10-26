import '../../../core/format/app_date_format.dart';
import '../../../core/l10n/l10n.dart';
import '../../calendar/presentation/shift_format.dart';
import '../../schedule/domain/schedule_domain.dart';

/// Worked time as "152 h 30 min", "8 h", "45 min" or "0 h". Unlike
/// `durationText` it never switches to days: 152 hours stay 152 hours.
String formatHours(AppLocalizations l10n, int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) {
    return rest == 0 ? l10n.durationHours(0) : l10n.durationMinutes(rest);
  }
  return rest == 0
      ? l10n.durationHours(hours)
      : l10n.durationHoursMinutes(hours, rest);
}

/// [formatHours] with its sign for a difference: "+8 h", "−4 h 30 min".
String formatSignedHours(AppLocalizations l10n, int minutes) {
  final sign = minutes < 0 ? '−' : '+';
  return '$sign${formatHours(l10n, minutes.abs())}';
}

/// "19 oct 2026": a date of a free range (with the year, without the dot).
String formatRangeDate(String locale, CivilDate date) =>
    AppDateFormat(locale)
        .dayMonthYear(DateTime(date.year, date.month, date.day));

/// "19 oct 2026 – 25 oct 2026".
String formatRange(String locale, CivilDate from, CivilDate to) =>
    '${formatRangeDate(locale, from)} – ${formatRangeDate(locale, to)}';

/// "Ene", "Sep": the short month name of a table, capitalized and without the
/// dot Spanish adds ("ene.").
String monthAbbreviation(String locale, CivilDate month) => capitalize(
  AppDateFormat(locale).monthShort(DateTime(month.year, month.month)),
);
