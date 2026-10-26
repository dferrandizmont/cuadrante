import 'package:cuadrante/features/alarms/data/wall_clock.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location madrid;

  setUpAll(() {
    tzdata.initializeTimeZones();
    madrid = tz.getLocation('Europe/Madrid');
  });

  tz.TZDateTime at(int y, int m, int d, int h, [int min = 0]) =>
      resolveWallClock(madrid, y, m, d, h * 60 + min);

  String utc(tz.TZDateTime t) => t.toUtc().toIso8601String();

  test('a normal winter / summer time is exactly that wall-clock time', () {
    expect(utc(at(2026, 1, 15, 20, 30)), '2026-01-15T19:30:00.000Z'); // CET
    expect(utc(at(2026, 7, 15, 20, 30)), '2026-07-15T18:30:00.000Z'); // CEST
    final t = at(2026, 7, 15, 20, 30);
    expect((t.hour, t.minute), (20, 30));
  });

  group('spring forward, 2026-03-29 (02:00 -> 03:00)', () {
    test('a time that does not exist moves forward by the gap', () {
      for (final (h, m, wantHour, wantMin) in [
        (2, 0, 3, 0),
        (2, 30, 3, 30),
        (2, 59, 3, 59),
      ]) {
        final t = at(2026, 3, 29, h, m);
        expect(t.day, 29);
        expect((t.hour, t.minute), (wantHour, wantMin), reason: '$h:$m');
        expect(t.timeZoneOffset, const Duration(hours: 2));
      }
      expect(utc(at(2026, 3, 29, 2, 30)), '2026-03-29T01:30:00.000Z');
    });

    test('times around the gap keep their wall-clock hour', () {
      expect(utc(at(2026, 3, 29, 1, 59)), '2026-03-29T00:59:00.000Z');
      expect(utc(at(2026, 3, 29, 3)), '2026-03-29T01:00:00.000Z');
      final t = at(2026, 3, 29, 4, 30);
      expect((t.hour, t.minute), (4, 30));
      expect(utc(t), '2026-03-29T02:30:00.000Z');
    });

    test('an alarm never rings before the time it asked for', () {
      final before = at(2026, 3, 29, 1, 59);
      final inGap = at(2026, 3, 29, 2, 30);
      final after = at(2026, 3, 29, 3, 0);
      expect(inGap.isAfter(before), isTrue);
      expect(inGap.isAfter(after), isTrue);
    });
  });

  group('fall back, 2026-10-25 (03:00 -> 02:00)', () {
    test('an ambiguous time uses the first occurrence (summer time)', () {
      expect(utc(at(2026, 10, 25, 2)), '2026-10-25T00:00:00.000Z');
      expect(utc(at(2026, 10, 25, 2, 30)), '2026-10-25T00:30:00.000Z');
      expect(utc(at(2026, 10, 25, 2, 59)), '2026-10-25T00:59:00.000Z');
      expect(at(2026, 10, 25, 2, 30).timeZoneOffset, const Duration(hours: 2));
    });

    test('times around the repeated hour are unambiguous', () {
      expect(utc(at(2026, 10, 25, 1, 59)), '2026-10-24T23:59:00.000Z');
      expect(utc(at(2026, 10, 25, 3)), '2026-10-25T02:00:00.000Z');
      final t = at(2026, 10, 25, 20, 30);
      expect((t.hour, t.minute), (20, 30));
      expect(utc(t), '2026-10-25T19:30:00.000Z');
    });
  });

  test('a 22:00 shift keeps its alarm at the same local time across DST', () {
    // 90 minutes before: 20:30 on the 24th (CEST) and the 25th (CEST), and on
    // the 26th (CET, one hour later in UTC).
    expect(utc(at(2026, 10, 24, 20, 30)), '2026-10-24T18:30:00.000Z');
    expect(utc(at(2026, 10, 26, 20, 30)), '2026-10-26T19:30:00.000Z');
  });

  test('resolves a planned alarm from its fire date and minute', () {
    // Early shift: fires on the previous day at 23:00.
    final alarm = _alarm(const CivilDate(2026, 10, 24), 23 * 60);
    final t = resolveAlarmInstant(alarm, madrid);
    expect((t.year, t.month, t.day, t.hour), (2026, 10, 24, 23));
  });
}

PlannedAlarm _alarm(CivilDate fireDate, int fireMinute) => PlannedAlarm(
  id: 1,
  fireDate: fireDate,
  fireMinute: fireMinute,
  shiftDate: fireDate.addDays(1),
  shiftTypeId: 'early',
  title: 't',
  body: 'b',
);
