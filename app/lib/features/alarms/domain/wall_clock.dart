import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'alarm_planner.dart';

bool _loadedDefaultZones = false;

/// Default when no device zone is available (tests and desktop hosts).
tz.Location defaultAlarmLocation() {
  if (!_loadedDefaultZones) {
    tzdata.initializeTimeZones();
    _loadedDefaultZones = true;
  }
  return tz.getLocation('Europe/Madrid');
}

const int _msPerDay = Duration.millisecondsPerDay;

/// The instant the wall-clock time of [alarm] has in [location].
///
/// Daylight-saving rules (Europe/Madrid, same everywhere):
/// - A time that does not exist (the hour skipped in March, 02:00-03:00 on
///   2026-03-29) moves **forward** by the length of the gap: 02:30 rings at
///   03:30 summer time, never earlier than asked.
/// - A time that happens twice (the hour repeated in October, 02:00-03:00 on
///   2026-10-25) uses the **first** occurrence (summer time), so the alarm is
///   not an hour late.
/// - Any other time is exactly that wall-clock time, so a 04:30 alarm rings at
///   04:30 on the day the clocks change.
tz.TZDateTime resolveAlarmInstant(PlannedAlarm alarm, tz.Location location) =>
    resolveWallClock(
      location,
      alarm.fireDate.year,
      alarm.fireDate.month,
      alarm.fireDate.day,
      alarm.fireMinute,
    );

/// See [resolveAlarmInstant]; [minuteOfDay] is `0..1439`.
tz.TZDateTime resolveWallClock(
  tz.Location location,
  int year,
  int month,
  int day,
  int minuteOfDay,
) {
  // The wall clock as if it were UTC, then shifted by each offset the zone
  // uses in the day before and the day after: those are the offsets on either
  // side of a transition.
  final wallMs = DateTime.utc(
    year,
    month,
    day,
    0,
    minuteOfDay,
  ).millisecondsSinceEpoch;
  final before = location.timeZone(wallMs - _msPerDay).offset.inMilliseconds;
  final after = location.timeZone(wallMs + _msPerDay).offset.inMilliseconds;

  final candidates = <int>{};
  for (final offset in {before, after}) {
    final instant = wallMs - offset;
    if (location.timeZone(instant).offset.inMilliseconds == offset) {
      candidates.add(instant);
    }
  }
  final int instant;
  if (candidates.isEmpty) {
    // In the gap: read it with the offset in force before the clocks moved,
    // which lands after the gap.
    instant = wallMs - before;
  } else {
    // One match = a normal time; two = repeated hour, take the first.
    instant = candidates.reduce((a, b) => a < b ? a : b);
  }
  return tz.TZDateTime.fromMillisecondsSinceEpoch(location, instant);
}
