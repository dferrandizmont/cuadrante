import 'package:cuadrante/features/alarms/application/alarm_sync.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/alarms/domain/wall_clock.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

ShiftType _shift(String id, int minute) => ShiftType(
  id: id,
  code: id.substring(0, 1).toUpperCase(),
  name: id,
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: minute,
  endMinute: 23 * 60,
);

AlarmSettings _settings(List<ShiftType> types) => AlarmSettings(
  enabled: true,
  horizonDays: 30,
  byShiftType: {
    for (final type in types)
      type.id: const AlarmTypeSettings(enabled: true, minutesBefore: 0),
  },
);

void main() {
  late tz.Location madrid;
  setUp(() => madrid = defaultAlarmLocation());

  test(
    'spring resync at 03:00 retains the 02:30 reminder until 03:30',
    () async {
      const date = CivilDate(2026, 3, 29);
      final shift = _shift('shift', 3 * 60 + 15);
      final schedule = Schedule(
        shiftTypes: [shift],
        entries: {
          date: const DayEntry(
            date: date,
            shiftTypeIds: ['shift'],
            noteReminderMinute: 2 * 60 + 30,
          ),
        },
      );
      final scheduler = FakeAlarmScheduler();
      var now = DateTime.utc(2026, 3, 28, 20);
      final sync = AlarmSync(
        scheduler: scheduler,
        loadSettings: () async => _settings([shift]),
        readSchedule: () => schedule,
        now: () => now,
        strings: AlarmStrings.blank,
      );
      addTearDown(sync.dispose);
      await sync.resync();
      expect(scheduler.scheduled.map((a) => a.kind), [
        AlarmKind.shift,
        AlarmKind.reminder,
      ], reason: '03:15 precedes a gap time resolved to 03:30');
      final reminder = scheduler.scheduled.last;
      expect(
        resolveAlarmInstant(reminder, madrid).toUtc(),
        DateTime.utc(2026, 3, 29, 1, 30),
      );

      now = DateTime.utc(2026, 3, 29, 1); // 03:00 summer time.
      await sync.resync();
      expect(scheduler.scheduled.last, reminder);
      expect(scheduler.scheduled, hasLength(2));

      now = DateTime.utc(2026, 3, 29, 1, 30);
      await sync.resync();
      expect(scheduler.scheduled, isEmpty);
    },
  );

  test('autumn repeated hour never schedules the first 02:30 twice', () async {
    const date = CivilDate(2026, 10, 25);
    final schedule = Schedule(
      entries: {
        date: const DayEntry(date: date, noteReminderMinute: 2 * 60 + 30),
      },
    );
    final scheduler = FakeAlarmScheduler();
    var now = DateTime.utc(2026, 10, 25, 0, 15); // First 02:15.
    final sync = AlarmSync(
      scheduler: scheduler,
      loadSettings: () async => AlarmSettings.disabled,
      readSchedule: () => schedule,
      now: () => now,
      strings: AlarmStrings.blank,
    );
    addTearDown(sync.dispose);
    await sync.resync();
    expect(scheduler.scheduled, hasLength(1));
    expect(
      resolveAlarmInstant(scheduler.scheduled.single, madrid).toUtc(),
      DateTime.utc(2026, 10, 25, 0, 30),
    );

    now = DateTime.utc(2026, 10, 25, 1, 15); // Second 02:15.
    await sync.resync();
    expect(scheduler.scheduled, isEmpty);
  });

  test('the 60-alarm cap selects the soonest resolved instants', () {
    const spring = CivilDate(2026, 3, 29);
    final normal = [
      _shift('a', 6 * 60),
      _shift('b', 12 * 60),
      _shift('c', 18 * 60),
    ];
    final gap = _shift('gap', 2 * 60 + 30);
    final valid = _shift('valid', 3 * 60 + 15);
    final types = [...normal, gap, valid];
    final schedule = Schedule(
      shiftTypes: types,
      entries: {
        for (var i = 1; i <= 20; i++)
          spring.addDays(-i): DayEntry(
            date: spring.addDays(-i),
            shiftTypeIds: i == 1 ? ['a', 'b'] : ['a', 'b', 'c'],
          ),
        spring: const DayEntry(date: spring, shiftTypeIds: ['gap', 'valid']),
      },
    );
    final plan = planAlarms(
      schedule: schedule,
      settings: _settings(types),
      now: DateTime.utc(2026, 3, 8, 23),
      strings: AlarmStrings.blank,
      location: madrid,
    );
    expect(plan, hasLength(maxPendingAlarms));
    expect(plan.last.shiftTypeId, 'valid');
    expect(
      plan.any((a) => a.shiftTypeId == 'gap'),
      isFalse,
      reason: '02:30 resolves to 03:30, later than 03:15',
    );
  });
}
