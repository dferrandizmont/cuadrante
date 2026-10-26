import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../schedule/domain/schedule_domain.dart';
import 'ics_parser.dart';
import 'import_models.dart';
import 'recurrence.dart';

/// Rule steps one expansion may spend in all, over every event of the file.
/// When they run out the expansion stops and the result is marked truncated.
const int maxIcsExpansionSteps = 2000000;

/// Moves iCalendar times to the wall clock of the phone (the target zone):
/// `...Z` and `TZID=` times are converted, floating times and dates stay as
/// they are. The time-zone database is only loaded the first time a
/// conversion needs it.
class IcsZones {
  IcsZones({this.targetZone = 'Europe/Madrid'});

  final String targetZone;

  /// Zones named in the file that this phone's database does not know; their
  /// times were read as floating.
  final Set<String> unknownZones = {};

  static bool _loaded = false;
  tz.Location? _target;
  final _locations = <String, tz.Location?>{};

  bool _ensureDatabase() {
    if (_loaded) return true;
    try {
      tzdata.initializeTimeZones();
      _loaded = true;
    } catch (_) {
      return false;
    }
    return true;
  }

  tz.Location? get _targetLocation {
    if (_target != null) return _target;
    if (!_ensureDatabase()) return null;
    try {
      return _target = tz.getLocation(targetZone);
    } catch (_) {
      try {
        return _target = tz.getLocation('Europe/Madrid');
      } catch (_) {
        return null;
      }
    }
  }

  tz.Location? _location(String zone) {
    if (_locations.containsKey(zone)) return _locations[zone];
    if (!_ensureDatabase()) return _locations[zone] = null;
    tz.Location? found;
    final candidates = <String>[
      _windowsZones[zone] ?? zone,
      // Old exports prefix the name: /freeassociation.sourceforge.net/Europe/Madrid
      if (zone.contains('/')) ...[
        zone.split('/').skip(zone.split('/').length - 2).join('/'),
      ],
    ];
    for (final name in candidates) {
      try {
        found = tz.getLocation(name);
        break;
      } catch (_) {
        // Try the next spelling.
      }
    }
    if (found == null) unknownZones.add(zone);
    return _locations[zone] = found;
  }

  /// [time] (which must have a time of day) on the wall clock of the target
  /// zone.
  ({CivilDate date, int minute}) toLocal(IcsTime time) {
    final minute = time.minute!;
    final zone = time.zone;
    if (zone == null || zone == targetZone) {
      return (date: time.date, minute: minute);
    }
    final DateTime instant;
    if (zone == 'UTC') {
      instant = DateTime.utc(
        time.date.year,
        time.date.month,
        time.date.day,
        minute ~/ 60,
        minute % 60,
      );
    } else {
      final location = _location(zone);
      if (location == null) return (date: time.date, minute: minute);
      instant = tz.TZDateTime(
        location,
        time.date.year,
        time.date.month,
        time.date.day,
        minute ~/ 60,
        minute % 60,
      );
    }
    final target = _targetLocation;
    if (target == null) return (date: time.date, minute: minute);
    final local = tz.TZDateTime.from(instant, target);
    return (
      date: CivilDate(local.year, local.month, local.day),
      minute: local.hour * 60 + local.minute,
    );
  }
}

/// Windows (Outlook) zone names, which some `.ics` files use as `TZID`.
const Map<String, String> _windowsZones = {
  'Romance Standard Time': 'Europe/Madrid',
  'W. Europe Standard Time': 'Europe/Berlin',
  'Central Europe Standard Time': 'Europe/Budapest',
  'Central European Standard Time': 'Europe/Warsaw',
  'GMT Standard Time': 'Europe/London',
  'Greenwich Standard Time': 'Atlantic/Reykjavik',
  'E. Europe Standard Time': 'Europe/Chisinau',
  'FLE Standard Time': 'Europe/Kiev',
  'Eastern Standard Time': 'America/New_York',
  'Central Standard Time': 'America/Chicago',
  'Pacific Standard Time': 'America/Los_Angeles',
  'UTC': 'UTC',
  'Etc/UTC': 'UTC',
  'GMT': 'UTC',
  'Z': 'UTC',
};

int _wallMinutes(CivilDate date, int minute) => date.epochDay * 1440 + minute;

String _instanceKey(CivilDate date, int minute) => '${date.toIso()}T$minute';

/// Turns the events of [document] into [RawEvent]s for [range], expanding
/// recurring events (`RRULE`, `EXDATE`, `RECURRENCE-ID`) and moving every time
/// to the wall clock of [targetZone]. Capped like every import
/// ([maxImportEvents] events, [maxImportOccurrences] days).
Expansion expandIcs(
  IcsDocument document,
  ImportRange range, {
  String targetZone = 'Europe/Madrid',
}) {
  final zones = IcsZones(targetZone: targetZone);

  // Occurrences of a series that another event of the file replaces.
  final replaced = <String, Set<String>>{};
  for (final e in document.events) {
    final id = e.recurrenceId;
    if (id == null) continue;
    final set = replaced.putIfAbsent(e.uid, () => {});
    if (id.allDay) {
      set.add(id.date.toIso());
    } else {
      final local = zones.toLocal(id);
      set.add(_instanceKey(local.date, local.minute));
    }
  }

  final raws = <RawEvent>[];
  var truncated = false;
  // A bound on the work, not on the result: the cap of the result comes
  // after the events are sorted.
  const generationBudget = maxImportEvents * 4;

  // Steps of all the rules together: the work of a file is bounded as a
  // whole, not only rule by rule.
  final budget = StepBudget(maxIcsExpansionSteps);

  for (final event in document.events) {
    if (event.cancelled) continue;
    if (budget.exhausted) {
      truncated = true;
      break;
    }
    // One bad event (a date the calendar cannot hold, say) never ends the
    // import: it is left out and the rest goes on.
    try {
      final stop = _expandEvent(
        event,
        range: range,
        zones: zones,
        replaced: replaced,
        budget: budget,
        raws: raws,
        generationBudget: generationBudget,
      );
      if (stop) {
        truncated = true;
        break;
      }
    } catch (_) {
      continue;
    }
  }
  if (budget.exhausted) truncated = true;

  final expansion = expandEvents(raws, range);
  return Expansion(
    expansion.occurrences,
    truncated: truncated || expansion.truncated,
  );
}

/// Adds the occurrences of [event] inside [range] to [raws]. `true` when the
/// work budget of the whole file ran out and the expansion must stop.
bool _expandEvent(
  IcsEvent event, {
  required ImportRange range,
  required IcsZones zones,
  required Map<String, Set<String>> replaced,
  required StepBudget budget,
  required List<RawEvent> raws,
  required int generationBudget,
}) {
  final start = event.start;
  final exDays = <String>{};
  final exTimes = <String>{};
  for (final x in event.exceptions) {
    if (x.allDay) {
      exDays.add(x.date.toIso());
    } else {
      final local = zones.toLocal(x);
      exTimes.add(_instanceKey(local.date, local.minute));
    }
  }
  final skipped = replaced[event.uid] ?? const <String>{};

  // The days of the event in its own zone.
  final int span;
  final int? durationMinutes;
  if (start.allDay) {
    span = event.allDaySpanDays;
    durationMinutes = null;
  } else {
    span = 1;
    final from = zones.toLocal(start);
    final end = event.end;
    int? length;
    if (end != null && !end.allDay) {
      final to = zones.toLocal(end);
      length =
          _wallMinutes(to.date, to.minute) -
          _wallMinutes(from.date, from.minute);
    } else if (event.duration != null) {
      length = event.duration;
    }
    durationMinutes = (length == null || length < 0) ? null : length;
  }

  // Days that can reach the range, with two days of margin for the zone
  // change of a timed event. Anything outside is skipped before it counts
  // towards the work budget: a file of old one-off events must not use
  // up the room of the few that matter.
  final windowFrom = range.from.addDays(-(span + 2));
  final windowTo = range.to.addDays(2);
  final starts = event.rule == null
      ? [start.date]
      : event.rule!
            .datesBetween(start.date, windowFrom, windowTo, budget: budget)
            .toList();

  for (final day in starts) {
    if (day.isBefore(windowFrom) || day.isAfter(windowTo)) continue;
    if (raws.length >= generationBudget) return true;
    if (start.allDay) {
      if (exDays.contains(day.toIso()) || skipped.contains(day.toIso())) {
        continue;
      }
      raws.add(
        RawEvent(
          title: event.summary,
          startDate: day,
          endDate: day.addDays(span),
          allDay: true,
        ),
      );
      continue;
    }
    final local = zones.toLocal(
      IcsTime(day, minute: start.minute, zone: start.zone),
    );
    final key = _instanceKey(local.date, local.minute);
    if (exTimes.contains(key) ||
        exDays.contains(day.toIso()) ||
        exDays.contains(local.date.toIso()) ||
        skipped.contains(key)) {
      continue;
    }
    CivilDate? endDate;
    int? endMinute;
    if (durationMinutes != null) {
      final total = _wallMinutes(local.date, local.minute) + durationMinutes;
      endDate = CivilDate.fromEpochDay(total ~/ 1440);
      endMinute = total % 1440;
    }
    raws.add(
      RawEvent(
        title: event.summary,
        startDate: local.date,
        startMinute: local.minute,
        endDate: endDate,
        endMinute: endMinute,
      ),
    );
  }
  return false;
}
