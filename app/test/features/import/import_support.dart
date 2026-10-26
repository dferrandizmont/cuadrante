import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

/// The four shift types most of the import tests use.
const morning = ShiftType(
  id: 'morning',
  code: 'M',
  name: 'Mañana',
  colorValue: 0xFFF5A524,
  category: ShiftCategory.work,
  startMinute: 6 * 60,
  endMinute: 14 * 60,
);
const afternoon = ShiftType(
  id: 'afternoon',
  code: 'T',
  name: 'Tarde',
  colorValue: 0xFFF06A3F,
  category: ShiftCategory.work,
  startMinute: 14 * 60,
  endMinute: 22 * 60,
);
const night = ShiftType(
  id: 'night',
  code: 'N',
  name: 'Noche',
  colorValue: 0xFF4B4FD1,
  category: ShiftCategory.work,
  startMinute: 22 * 60,
  endMinute: 6 * 60,
);
const rest = ShiftType(
  id: 'rest',
  code: 'L',
  name: 'Libre',
  colorValue: 0xFFE4E4E7,
  category: ShiftCategory.rest,
);

const baseTypes = [morning, afternoon, night, rest];

/// An empty schedule with [baseTypes].
Schedule emptySchedule({
  Map<CivilDate, DayEntry> entries = const {},
  List<PatternRun> runs = const [],
  List<Pattern> patterns = const [],
}) => Schedule(
  shiftTypes: baseTypes,
  patterns: patterns,
  runs: runs,
  entries: entries,
);

/// A timed event on [date].
EventOccurrence timed(
  String title,
  CivilDate date,
  int startHour,
  int endHour, {
  int? colorValue,
}) => EventOccurrence(
  title: title,
  date: date,
  startMinute: startHour * 60,
  endMinute: endHour * 60,
  colorValue: colorValue,
);

/// An all-day event on [date].
EventOccurrence allDay(String title, CivilDate date) =>
    EventOccurrence(title: title, date: date, allDay: true);

/// [count] consecutive days from [from].
List<CivilDate> daysFrom(CivilDate from, int count) => [
  for (var i = 0; i < count; i++) from.addDays(i),
];
