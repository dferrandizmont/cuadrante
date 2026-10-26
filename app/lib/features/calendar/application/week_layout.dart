import '../../schedule/domain/civil_date.dart';

/// Week arithmetic of the month grid, for a week that starts on Monday (1) or
/// Sunday (7), like [DateTime.weekday]. Pure functions: the grid, its header
/// and its week numbers all go through here.

/// The date of the first cell of the 6 x 7 grid of the month that begins on
/// [firstOfMonth]: the last [weekStart] on or before it.
CivilDate monthGridStart(CivilDate firstOfMonth, int weekStart) =>
    firstOfMonth.addDays(-((firstOfMonth.weekday - weekStart) % 7));

/// The weekdays (1 = Monday ... 7 = Sunday) in the order of the header row.
List<int> weekdayOrder(int weekStart) => [
  for (var i = 0; i < 7; i++) (weekStart - 1 + i) % 7 + 1,
];

/// ISO 8601 week number (1 to 53) of [date]: weeks start on Monday and week 1
/// is the one with the first Thursday of the year.
int isoWeekNumber(CivilDate date) {
  final thursday = date.addDays(DateTime.thursday - date.weekday);
  final yearStart = CivilDate(thursday.year, 1, 1);
  return thursday.differenceInDays(yearStart) ~/ 7 + 1;
}

/// The number shown for a row of the grid that starts on [rowStart]: the ISO
/// week of the row's Thursday. With Monday-first rows that is the ISO week of
/// the row; with Sunday-first rows (Sunday to Saturday) it is the ISO week of
/// the Monday to Saturday part, so the row never shows a number that belongs
/// to the week before.
int rowWeekNumber(CivilDate rowStart) =>
    isoWeekNumber(rowStart.addDays((DateTime.thursday - rowStart.weekday) % 7));
