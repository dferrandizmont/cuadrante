/// How much of the phone's calendar this app may use.
enum CalendarAccess {
  /// Read and write.
  granted,

  /// iOS 17+ "add only": events can be created but not read, changed or
  /// deleted. Not enough for import or for a re-export.
  writeOnly,
  denied,

  /// The system does not let this app use calendars (parental controls).
  restricted,

  /// Never asked.
  notDetermined,
}

/// Why a call to the phone's calendar failed.
enum CalendarApiError {
  permissionDenied,

  /// The calendar cannot be changed (a subscribed or read-only account).
  readOnly,
  notFound,

  /// No calendar provider on the phone, or it did not answer.
  unavailable,
  failed,
}

class CalendarApiException implements Exception {
  const CalendarApiException(this.error);

  final CalendarApiError error;

  @override
  String toString() => 'CalendarApiException(${error.name})';
}

/// A calendar of the phone, as the import and the export show it.
class DeviceCalendarInfo {
  const DeviceCalendarInfo({
    required this.id,
    required this.name,
    this.accountName,
    this.accountType,
    this.colorValue,
    this.readOnly = false,
    this.hidden = false,
  });

  final String id;
  final String name;

  /// The account that owns it («nombre@example.com», «iCloud», «local»).
  final String? accountName;
  final String? accountType;

  /// ARGB, `null` when the calendar has no colour.
  final int? colorValue;
  final bool readOnly;
  final bool hidden;

  /// The calendar lives in an account that syncs it to a server (Google,
  /// iCloud, Exchange...): what is written to it leaves the phone. Local
  /// calendars (`local`, `LOCAL`) and calendars with no account type are not.
  bool get isSynced {
    final type = accountType?.trim().toLowerCase();
    return type != null && type.isNotEmpty && type != 'local';
  }
}

/// An event of the phone's calendar, with the dates in the phone's local time.
class DeviceEvent {
  const DeviceEvent({
    required this.instanceId,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.allDay = false,
    this.cancelled = false,
    this.colorValue,
  });

  /// Unique per occurrence (a recurring event gives one per day).
  final String instanceId;
  final String calendarId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  /// All-day events are floating dates: use the date parts of [start] and
  /// [end], never convert them.
  final bool allDay;
  final bool cancelled;
  final int? colorValue;
}

/// The phone's calendar, narrowed to what Cuadrante needs. The only code that
/// knows the plugin is `PluginDeviceCalendarApi`; everything else (and every
/// test) talks to this.
abstract interface class DeviceCalendarApi {
  /// The permission now, without asking.
  Future<CalendarAccess> access();

  /// Shows the system question (full access). Returns the answer.
  Future<CalendarAccess> requestAccess();

  /// Opens the settings of the app, to grant a permission that was refused.
  Future<void> openSettings();

  /// Every calendar, read-only and hidden ones included.
  Future<List<DeviceCalendarInfo>> calendars();

  /// The events that overlap `[start, end)`, in [calendarIds] (all when
  /// `null` or empty).
  Future<List<DeviceEvent>> events(
    DateTime start,
    DateTime end, {
    List<String>? calendarIds,
  });

  /// Creates a calendar and returns its id.
  Future<String> createCalendar({required String name, int? colorValue});

  /// Creates an event and returns its id. For an all-day event [start] and
  /// [end] are dates and [end] is exclusive.
  Future<String> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    String? description,
  });

  /// Deletes one event (a missing one is not an error).
  Future<void> deleteEvent(String instanceId);
}

/// What the permission card shows after the system question was answered
/// (H-T14-6): the same rule as the notification permission
/// (`NotificationPermissionPolicy`), blocked only when asking again can do
/// nothing.
///
/// The answer to the prompt itself says "denied" the first time on Android,
/// but that first denial can be asked again; the plugin reports it as
/// [CalendarAccess.notDetermined] when it is read afterwards (and as
/// [CalendarAccess.denied] only once the system will not show the question any
/// more, or on iOS, where a refusal is final). So a refusal is taken as
/// blocked only if the permission read again says so too.
class CalendarPromptOutcome {
  const CalendarPromptOutcome(this.access, {required this.declined});

  /// What the card should treat as the state of the permission.
  final CalendarAccess access;

  /// The user refused the question that was just shown (even if it can be
  /// asked again): the card says so instead of repeating the first text.
  final bool declined;
}

extension AskForCalendarAccess on DeviceCalendarApi {
  /// Shows the system question and works out what the card should say.
  Future<CalendarPromptOutcome> askForAccess() async {
    final answer = await requestAccess();
    if (answer != CalendarAccess.denied) {
      return CalendarPromptOutcome(answer, declined: false);
    }
    CalendarAccess now;
    try {
      now = await access();
    } catch (_) {
      now = CalendarAccess.denied;
    }
    return CalendarPromptOutcome(
      now == CalendarAccess.notDetermined || now == CalendarAccess.granted
          ? now
          : CalendarAccess.denied,
      declined: true,
    );
  }
}
