// ignore_for_file: prefer_initializing_formals
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';

/// The phone's calendar in memory: calendars, events, a permission that
/// answers like the system does, and a record of what was called.
class FakeDeviceCalendar implements DeviceCalendarApi {
  FakeDeviceCalendar({
    CalendarAccess access = CalendarAccess.granted,
    CalendarAccess onRequest = CalendarAccess.granted,
    List<DeviceCalendarInfo> calendars = const [],
    List<DeviceEvent> events = const [],
    this.retryableDenials = 0,
  }) : _access = access,
       _onRequest = onRequest,
       _calendars = [...calendars],
       _events = [...events];

  CalendarAccess _access;
  final CalendarAccess _onRequest;

  /// How many refusals of the system question can still be asked again (what
  /// Android does with the first one: the question answers «denied», but the
  /// permission read afterwards is «never asked» until the system stops
  /// showing it). 0 is iOS: a refusal is final.
  final int retryableDenials;
  int _denials = 0;
  final List<DeviceCalendarInfo> _calendars;
  final List<DeviceEvent> _events;
  int _nextId = 1;

  int requests = 0;
  int settingsOpened = 0;
  int calendarListings = 0;
  int eventListings = 0;
  int createdCalendars = 0;
  int createdEvents = 0;
  int deletedEvents = 0;

  /// Ids of events whose creation fails with [CalendarApiError.failed].
  final Set<String> failCreatingTitles = {};

  /// Instance ids whose deletion fails.
  final Set<String> failDeleting = {};

  /// The next call that touches the calendars throws this.
  CalendarApiError? failNext;

  /// The user changed the permission in the system settings.
  void setAccess(CalendarAccess access) => _access = access;

  List<DeviceEvent> get allEvents => List.unmodifiable(_events);

  List<DeviceEvent> eventsOf(String calendarId) => [
    for (final e in _events)
      if (e.calendarId == calendarId) e,
  ];

  List<DeviceCalendarInfo> get allCalendars => List.unmodifiable(_calendars);

  void addEvent(DeviceEvent event) => _events.add(event);

  /// Adds a calendar and returns its id.
  String addCalendar(
    String name, {
    String? account,
    String? accountType,
    int? color,
    bool readOnly = false,
    bool hidden = false,
  }) {
    final id = 'cal-${_nextId++}';
    _calendars.add(
      DeviceCalendarInfo(
        id: id,
        name: name,
        accountName: account,
        accountType: accountType,
        colorValue: color,
        readOnly: readOnly,
        hidden: hidden,
      ),
    );
    return id;
  }

  /// Adds an event with simple local dates.
  String addSimpleEvent(
    String calendarId,
    String title,
    DateTime start,
    DateTime end, {
    bool allDay = false,
    String? description,
  }) {
    final id = 'ev-${_nextId++}';
    _events.add(
      DeviceEvent(
        instanceId: id,
        calendarId: calendarId,
        title: title,
        description: description,
        start: start,
        end: end,
        allDay: allDay,
      ),
    );
    return id;
  }

  void _check() {
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw CalendarApiException(error);
    }
    if (_access != CalendarAccess.granted) {
      throw const CalendarApiException(CalendarApiError.permissionDenied);
    }
  }

  @override
  Future<CalendarAccess> access() async =>
      _access == CalendarAccess.denied &&
          _denials > 0 &&
          _denials <= retryableDenials
      ? CalendarAccess.notDetermined
      : _access;

  @override
  Future<CalendarAccess> requestAccess() async {
    requests++;
    final access = await this.access();
    if (access == CalendarAccess.notDetermined ||
        access == CalendarAccess.denied ||
        access == CalendarAccess.writeOnly) {
      _access = _onRequest;
      if (_access == CalendarAccess.denied) _denials++;
    }
    return _access;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<List<DeviceCalendarInfo>> calendars() async {
    _check();
    calendarListings++;
    return List.of(_calendars);
  }

  @override
  Future<List<DeviceEvent>> events(
    DateTime start,
    DateTime end, {
    List<String>? calendarIds,
  }) async {
    _check();
    eventListings++;
    return [
      for (final e in _events)
        if ((calendarIds == null ||
                calendarIds.isEmpty ||
                calendarIds.contains(e.calendarId)) &&
            e.start.isBefore(end) &&
            (e.end.isAfter(start) || e.start == start))
          e,
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<String> createCalendar({required String name, int? colorValue}) async {
    _check();
    createdCalendars++;
    return addCalendar(name, account: 'Cuadrante', color: colorValue);
  }

  @override
  Future<String> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    String? description,
  }) async {
    _check();
    if (failCreatingTitles.contains(title)) {
      throw const CalendarApiException(CalendarApiError.failed);
    }
    if (!_calendars.any((c) => c.id == calendarId)) {
      throw const CalendarApiException(CalendarApiError.notFound);
    }
    createdEvents++;
    return addSimpleEvent(
      calendarId,
      title,
      start,
      end,
      allDay: allDay,
      description: description,
    );
  }

  @override
  Future<void> deleteEvent(String instanceId) async {
    _check();
    if (failDeleting.contains(instanceId)) {
      throw const CalendarApiException(CalendarApiError.failed);
    }
    if (_events.any((e) => e.instanceId == instanceId)) {
      deletedEvents++;
      _events.removeWhere((e) => e.instanceId == instanceId);
    }
  }
}
