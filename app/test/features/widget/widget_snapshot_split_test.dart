import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot_builder.dart';
import 'package:cuadrante/features/widget/domain/widget_strings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

/// 09:00-13:00 and 17:00-21:00.
const _partido = ShiftType(
  id: 'partido',
  code: 'P',
  name: 'Partido',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 9 * 60,
  endMinute: 13 * 60,
  segment2StartMinute: 17 * 60,
  segment2DurationMinutes: 4 * 60,
);

/// 07:30-11:00 and 16:30-20:00: minutes show.
const _withMinutes = ShiftType(
  id: 'minutes',
  code: 'Q',
  name: 'Con minutos',
  colorValue: 0xFF994466,
  category: ShiftCategory.work,
  startMinute: 7 * 60 + 30,
  endMinute: 11 * 60,
  segment2StartMinute: 16 * 60 + 30,
  segment2DurationMinutes: 3 * 60 + 30,
);

WidgetSnapshot _build(Map<CivilDate, List<String>> days) {
  final schedule = Schedule(
    shiftTypes: [...allTypes, _partido, _withMinutes],
    entries: {
      for (final e in days.entries)
        e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
    },
  );
  return buildWidgetSnapshot(
    schedule: schedule,
    holidays: const {},
    today: const CivilDate(2026, 10, 19),
    timeZone: 'Europe/Madrid',
    strings: WidgetStrings.es,
    generatedAt: DateTime.utc(2026, 10, 19, 8, 30),
  );
}

/// The widget shows the two ranges of a split shift as «09–13 · 17–21» in the
/// same string fields as always (docs/widget-contrato.md, no version bump).
Future<void> main() async {
  await initializeLocale();
  const today = CivilDate(2026, 10, 19);

  test('a split shift writes both ranges in the time fields', () {
    final s = _build({
      today: ['partido'],
      today.addDays(1): ['partido'],
    });
    final d = s.days.first;
    expect(d.shifts.single.timeLabel, '09–13 · 17–21');
    expect(d.shifts.single.compactTime, '09–13 · 17–21');
    expect(d.small.big, 'P');
    expect(d.small.detail, '09–13 · 17–21');
    expect(d.small.tomorrow, 'Mañana: P 09–13 · 17–21');
    expect(d.lock.inline, 'P · 09:00');
    expect(d.lock.circular, 'P');
    expect(d.lock.rectangular, [
      'P · 09–13 · 17–21',
      'Mañana: P 09–13 · 17–21',
    ]);
  });

  test('minutes show only when they are not :00', () {
    final s = _build({
      today: ['minutes'],
    });
    expect(s.days.first.small.detail, '07:30–11 · 16:30–20');
    expect(s.days.first.shifts.single.timeLabel, '07:30–11 · 16:30–20');
  });

  test('next to another shift the ranges are joined with plus', () {
    final s = _build({
      today: ['morning', 'partido'],
    });
    final d = s.days.first;
    expect(d.small.big, 'M+P');
    expect(d.small.detail, '06–14 + 09–13 · 17–21');
    expect(d.shifts.map((x) => x.code), ['M', 'P']);
    // One band per shift, not per segment.
    expect(d.small.isEmpty, isFalse);
  });

  test('shifts that are not split keep their text', () {
    final s = _build({
      today: ['night'],
      today.addDays(1): ['afternoon'],
    });
    expect(s.days.first.small.detail, '22:00–06:00');
    expect(s.days.first.shifts.single.compactTime, '22–06');
    expect(s.days.first.small.tomorrow, 'Mañana: T 14–22');
  });

  test('the content hash changes when the second segment does', () {
    final a = _build({
      today: ['partido'],
    });
    final b = buildWidgetSnapshot(
      schedule: Schedule(
        shiftTypes: [
          ...allTypes,
          _partido.copyWith(segment2StartMinute: 18 * 60),
        ],
        entries: {
          today: DayEntry(date: today, shiftTypeIds: const ['partido']),
        },
      ),
      holidays: const {},
      today: today,
      timeZone: 'Europe/Madrid',
      strings: WidgetStrings.es,
      generatedAt: DateTime.utc(2026, 10, 19, 8, 30),
    );
    expect(b.days.first.small.detail, '09–13 · 18–22');
    expect(a.contentHash, isNot(b.contentHash));
  });
}
