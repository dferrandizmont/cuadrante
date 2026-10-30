import 'package:device_calendar_plus/device_calendar_plus.dart' as dcp;

import '../domain/device_calendar_api.dart';

/// [DeviceCalendarApi] on top of `device_calendar_plus` (CalendarContract on
/// Android, EventKit on iOS). The calendar permission is only ever asked by
/// [requestAccess], which the screens call when the user starts an import or
/// an export; no method here prompts on its own.
class PluginDeviceCalendarApi implements DeviceCalendarApi {
  PluginDeviceCalendarApi([dcp.DeviceCalendar? plugin])
    : _plugin = plugin ?? dcp.DeviceCalendar.instance;

  final dcp.DeviceCalendar _plugin;

  static CalendarAccess _map(dcp.CalendarPermissionStatus status) =>
      switch (status) {
        dcp.CalendarPermissionStatus.granted => CalendarAccess.granted,
        dcp.CalendarPermissionStatus.writeOnly => CalendarAccess.writeOnly,
        dcp.CalendarPermissionStatus.denied => CalendarAccess.denied,
        dcp.CalendarPermissionStatus.restricted => CalendarAccess.restricted,
        dcp.CalendarPermissionStatus.notDetermined =>
          CalendarAccess.notDetermined,
      };

  /// Runs a plugin call, turning its exceptions into [CalendarApiException].
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on dcp.DeviceCalendarException catch (e) {
      throw CalendarApiException(switch (e.errorCode) {
        dcp.DeviceCalendarError.permissionDenied ||
        dcp.DeviceCalendarError.permissionsNotDeclared =>
          CalendarApiError.permissionDenied,
        dcp.DeviceCalendarError.readOnly => CalendarApiError.readOnly,
        dcp.DeviceCalendarError.notFound => CalendarApiError.notFound,
        dcp.DeviceCalendarError.calendarUnavailable =>
          CalendarApiError.unavailable,
        _ => CalendarApiError.failed,
      });
    } on CalendarApiException {
      rethrow;
    } catch (_) {
      // Nothing from the platform (a message may carry titles or accounts)
      // goes any further.
      throw const CalendarApiException(CalendarApiError.failed);
    }
  }

  @override
  Future<CalendarAccess> access() async =>
      _map(await _call(_plugin.hasPermissions));

  @override
  Future<CalendarAccess> requestAccess() async =>
      _map(await _call(() => _plugin.requestPermissions()));

  @override
  Future<void> openSettings() => _call(_plugin.openAppSettings);

  @override
  Future<List<DeviceCalendarInfo>> calendars() => _call(() async {
    final all = await _plugin.listCalendars();
    return [
      for (final c in all)
        DeviceCalendarInfo(
          id: c.id,
          name: c.name,
          accountName: c.accountName,
          accountType: c.accountType,
          colorValue: parseHexColor(c.colorHex),
          readOnly: c.readOnly,
          hidden: c.hidden,
        ),
    ];
  });

  @override
  Future<List<DeviceEvent>> events(
    DateTime start,
    DateTime end, {
    List<String>? calendarIds,
  }) => _call(() async {
    final found = await _plugin.listEvents(
      start,
      end,
      calendarIds: calendarIds,
    );
    return [
      for (final e in found)
        DeviceEvent(
          instanceId: e.instanceId,
          calendarId: e.calendarId,
          title: e.title,
          description: e.description,
          start: e.startDate,
          end: e.endDate,
          allDay: e.isAllDay,
          cancelled: e.status == dcp.EventStatus.canceled,
          colorValue: parseHexColor(e.colorHex),
        ),
    ];
  });

  @override
  Future<String> createCalendar({required String name, int? colorValue}) =>
      _call(
        () => _plugin.createCalendar(
          name: name,
          colorHex: colorValue == null ? null : _toHex(colorValue),
          // Android: a local account, so no Google account is touched. iOS
          // ignores it and picks iCloud, or the local source.
          platformOptions: const dcp.CreateCalendarOptionsAndroid(
            accountName: 'Turnly',
          ),
        ),
      );

  @override
  Future<String> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    String? description,
  }) => _call(
    () => _plugin.createEvent(
      calendarId: calendarId,
      title: title,
      startDate: start,
      endDate: end,
      isAllDay: allDay,
      description: description,
    ),
  );

  @override
  Future<void> deleteEvent(String instanceId) async {
    try {
      await _call(() => _plugin.deleteEvent(instanceId: instanceId));
    } on CalendarApiException catch (e) {
      if (e.error != CalendarApiError.notFound) rethrow;
    }
  }
}

/// `#RRGGBB` (or `#AARRGGBB`) as an opaque ARGB int; `null` for anything else.
int? parseHexColor(String? hex) {
  if (hex == null) return null;
  final text = hex.trim().replaceFirst('#', '');
  if (text.length != 6 && text.length != 8) return null;
  final value = int.tryParse(text, radix: 16);
  if (value == null) return null;
  return text.length == 6 ? 0xFF000000 | value : value;
}

String _toHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
