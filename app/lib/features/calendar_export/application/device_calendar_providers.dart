import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plugin_device_calendar_api.dart';
import '../domain/device_calendar_api.dart';

/// The phone's calendar. The import and the export both go through it; tests
/// override it with a fake.
final deviceCalendarApiProvider = Provider<DeviceCalendarApi>(
  (ref) => PluginDeviceCalendarApi(),
);
