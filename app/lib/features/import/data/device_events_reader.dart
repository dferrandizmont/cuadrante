import '../../calendar_export/domain/device_calendar_api.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/import_models.dart';

/// What reading the phone's calendars gave.
class DeviceRead {
  const DeviceRead(this.events, {this.truncated = false});

  final List<RawEvent> events;

  /// There were more than [maxImportEvents] events: the earliest are here.
  final bool truncated;
}

/// Months read per call: a huge range is read in slices, and the reading
/// stops as soon as the cap is passed instead of loading everything.
const int _sliceMonths = 3;

/// Reads the events of [calendarIds] that touch [range], as [RawEvent]s.
/// Recurring events come already expanded by the phone. Cancelled events are
/// left out. At most [maxImportEvents] events are kept.
Future<DeviceRead> readDeviceEvents(
  DeviceCalendarApi api,
  List<String> calendarIds,
  ImportRange range,
) async {
  final seen = <String>{};
  final out = <RawEvent>[];
  var truncated = false;

  var from = range.from;
  while (!from.isAfter(range.to)) {
    var next = addMonths(from, _sliceMonths);
    if (!next.isAfter(from)) next = from.addDays(1);
    final sliceEnd = next.addDays(-1).isAfter(range.to)
        ? range.to
        : next.addDays(-1);
    final found = await api.events(
      DateTime(from.year, from.month, from.day),
      DateTime(sliceEnd.year, sliceEnd.month, sliceEnd.day + 1),
      calendarIds: calendarIds,
    );
    for (final e in found) {
      if (e.cancelled || !seen.add(e.instanceId)) continue;
      if (out.length >= maxImportEvents) {
        truncated = true;
        break;
      }
      out.add(rawEventFromDevice(e));
    }
    if (truncated) break;
    from = sliceEnd.addDays(1);
  }
  return DeviceRead(out, truncated: truncated);
}

/// A phone event as a [RawEvent]. All-day events are floating dates (the end
/// is exclusive; an end inside the last day, as iOS gives it, still covers
/// that day). Timed events use their local start and end.
RawEvent rawEventFromDevice(DeviceEvent e) {
  final start = CivilDate.fromDateTime(e.start);
  if (e.allDay) {
    var end = CivilDate.fromDateTime(e.end);
    final atMidnight = e.end.hour == 0 && e.end.minute == 0;
    if (!atMidnight) end = end.addDays(1);
    return RawEvent(
      title: e.title,
      startDate: start,
      endDate: end.isAfter(start) ? end : start.addDays(1),
      allDay: true,
      colorValue: e.colorValue,
    );
  }
  final sameMoment = !e.end.isAfter(e.start);
  return RawEvent(
    title: e.title,
    startDate: start,
    startMinute: e.start.hour * 60 + e.start.minute,
    endDate: sameMoment ? null : CivilDate.fromDateTime(e.end),
    endMinute: sameMoment ? null : e.end.hour * 60 + e.end.minute,
    colorValue: e.colorValue,
  );
}
