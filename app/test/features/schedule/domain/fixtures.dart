import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

/// Every preset template as a shift type whose id is its key.
final allTypes = [for (final t in shiftTemplates) t.toShiftType(t.key)];

Pattern presetPattern(String presetId) =>
    patternPresetById(presetId)
        .materialize({for (final t in shiftTemplates) t.key: t.key});

Schedule presetSchedule(
  String presetId,
  CivilDate start, {
  int stepOffset = 0,
  CivilDate? end,
  Map<CivilDate, DayEntry> entries = const {},
}) => Schedule(
  shiftTypes: allTypes,
  patterns: [presetPattern(presetId)],
  runs: [
    PatternRun(
      id: 'r1',
      patternId: presetId,
      startDate: start,
      endDate: end,
      stepOffset: stepOffset,
      seq: 1,
    ),
  ],
  entries: entries,
);

/// Shift ids of each day, joined with `+` (`''` for an empty day).
List<String> idsOf(Schedule s, CivilDate from, int days) => [
  for (final d in s.resolveRange(from, from.addDays(days - 1)))
    d.shiftIds.join('+'),
];

/// Shift codes of each day (`+` for several shifts, `-` for none), space-joined.
String codesOf(Schedule s, CivilDate from, int days) => [
  for (final d in s.resolveRange(from, from.addDays(days - 1)))
    d.isEmpty ? '-' : d.shifts.map((t) => t.code).join('+'),
].join(' ');

const jan1 = CivilDate(2026, 1, 1);
