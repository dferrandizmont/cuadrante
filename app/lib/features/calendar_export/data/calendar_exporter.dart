import '../../schedule/domain/schedule_domain.dart';
import '../domain/device_calendar_api.dart';
import '../domain/export_events.dart';

/// Name of the calendar Cuadrante creates on the phone.
const String exportCalendarName = 'Turnly';

/// Where an export writes.
sealed class ExportTarget {
  const ExportTarget();
}

/// A calendar that is already on the phone.
class ExistingCalendar extends ExportTarget {
  const ExistingCalendar(this.id);

  final String id;
}

/// A new calendar called [exportCalendarName], created first.
class NewCalendar extends ExportTarget {
  const NewCalendar({this.colorValue});

  final int? colorValue;
}

/// What an export did.
class ExportResult {
  const ExportResult({
    required this.deviceCalendarId,
    required this.created,
    required this.removed,
    required this.unchanged,
    required this.failed,
    required this.calendarCreated,
    this.replaced = 0,
  });

  final String deviceCalendarId;

  /// Events added (new ones and the replacements of changed ones).
  final int created;

  /// Events of a previous export removed (changed, repeated or no longer
  /// wanted).
  final int removed;

  /// Of [removed], the ones this export wrote again: **replaced**. The rest
  /// were only removed, with nothing in their place (the days off or the
  /// absences were switched off).
  final int replaced;

  /// Events already right, left as they were.
  final int unchanged;

  /// Events that could not be written or removed.
  final int failed;

  /// The calendar was created by this export.
  final bool calendarCreated;

  bool get hasFailures => failed > 0;
}

/// The one-off export of the shifts to a calendar of the phone. Writes through
/// [DeviceCalendarApi]: tests use a fake.
class CalendarExporter {
  CalendarExporter(this._api);

  final DeviceCalendarApi _api;

  /// The calendars an export can write to: writable and visible.
  Future<List<DeviceCalendarInfo>> writableCalendars() async {
    final all = await _api.calendars();
    return [
      for (final c in all)
        if (!c.readOnly && !c.hidden) c,
    ];
  }

  /// What exporting would do, without doing it (used for the counts shown
  /// before the button). [deviceCalendarId] `null` = a calendar that does not
  /// exist yet: everything is new.
  Future<ExportPlan> preview({
    required Schedule schedule,
    required String appCalendarId,
    required String? deviceCalendarId,
    required CivilDate from,
    required CivilDate to,
    required bool includeRest,
    bool includeAbsences = false,
  }) async {
    final desired = buildExportEvents(
      schedule,
      calendarId: appCalendarId,
      from: from,
      to: to,
      includeRest: includeRest,
      includeAbsences: includeAbsences,
    );
    final existing = deviceCalendarId == null
        ? const <DeviceEvent>[]
        : await _existing(deviceCalendarId, from, to);
    return planExport(
      desired: desired,
      existing: existing,
      deviceCalendarId: deviceCalendarId ?? '',
      calendarId: appCalendarId,
      from: from,
      to: to,
    );
  }

  Future<List<DeviceEvent>> _existing(
    String deviceCalendarId,
    CivilDate from,
    CivilDate to,
  ) {
    // Wider than the exported dates: an event of ours the user dragged to
    // another day still has its tag, and must be found to be replaced instead
    // of leaving a second copy. Which events are ours and in range is decided
    // by the tag in `planExport`, not by where the event sits now. (The end
    // keeps two extra days: a night shift of the last day ends the day after.)
    final start = from.addDays(-exportSearchMarginDays);
    final end = to.addDays(exportSearchMarginDays + 2);
    return _api.events(
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day),
      calendarIds: [deviceCalendarId],
    );
  }

  /// Writes the shifts of [schedule] from [from] to [to] to [target],
  /// replacing the events a previous export left there for that range.
  /// Throws [CalendarApiException] when the permission is missing or the
  /// calendar cannot be read; failures on single events are counted in
  /// [ExportResult.failed] and the rest goes on.
  Future<ExportResult> export({
    required Schedule schedule,
    required String appCalendarId,
    required ExportTarget target,
    required CivilDate from,
    required CivilDate to,
    required bool includeRest,
    bool includeAbsences = false,
    void Function(int done, int total)? onProgress,
  }) async {
    if (await _api.access() != CalendarAccess.granted) {
      throw const CalendarApiException(CalendarApiError.permissionDenied);
    }
    var calendarCreated = false;
    final String deviceCalendarId;
    switch (target) {
      case ExistingCalendar(:final id):
        deviceCalendarId = id;
      case NewCalendar(:final colorValue):
        deviceCalendarId = await _api.createCalendar(
          name: exportCalendarName,
          colorValue: colorValue,
        );
        calendarCreated = true;
    }

    final desired = buildExportEvents(
      schedule,
      calendarId: appCalendarId,
      from: from,
      to: to,
      includeRest: includeRest,
      includeAbsences: includeAbsences,
    );
    final existing = calendarCreated
        ? const <DeviceEvent>[]
        : await _existing(deviceCalendarId, from, to);
    final plan = planExport(
      desired: desired,
      existing: existing,
      deviceCalendarId: deviceCalendarId,
      calendarId: appCalendarId,
      from: from,
      to: to,
    );

    final total = plan.toDelete.length + plan.toCreate.length;
    var done = 0;
    var failed = 0;
    var removed = 0;
    var replaced = 0;
    var created = 0;
    final isReplaced = plan.isReplaced;
    // Old copies go first: a failure then leaves a gap that the next export
    // fills, never a second copy of a shift.
    // Tags whose old copy could not be deleted: their replacement is not
    // written (it would sit beside the old one). The next export retries both.
    final stuck = <String>{};
    for (final event in plan.toDelete) {
      try {
        await _api.deleteEvent(event.instanceId);
        removed++;
        if (isReplaced(event)) replaced++;
      } on CalendarApiException {
        failed++;
        final tag = ExportTag.parse(event.description);
        if (tag != null) stuck.add(tag.key);
      }
      onProgress?.call(++done, total);
    }
    for (final event in plan.toCreate) {
      if (stuck.contains(event.tag)) {
        failed++;
        onProgress?.call(++done, total);
        continue;
      }
      try {
        await _api.createEvent(
          calendarId: deviceCalendarId,
          title: event.title,
          start: event.start,
          end: event.end,
          allDay: event.allDay,
          description: event.description,
        );
        created++;
      } on CalendarApiException catch (e) {
        // The permission going away in the middle ends the export.
        if (e.error == CalendarApiError.permissionDenied) rethrow;
        failed++;
      }
      onProgress?.call(++done, total);
    }
    return ExportResult(
      deviceCalendarId: deviceCalendarId,
      created: created,
      removed: removed,
      replaced: replaced,
      unchanged: plan.unchanged,
      failed: failed,
      calendarCreated: calendarCreated,
    );
  }
}
