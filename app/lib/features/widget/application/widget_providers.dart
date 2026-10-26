import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/diagnostics/crash_reporting.dart';
import '../../../core/providers.dart';
import '../../calendars/application/primary_schedule.dart';
import '../../holidays/application/holidays_provider.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../../settings/application/preferences_controller.dart';
import '../data/widget_publisher.dart';
import '../domain/widget_snapshot_builder.dart';
import 'widget_sync_service.dart';

/// The widgets of the platform on a phone; an in-memory fake on a host
/// without widgets (tests, desktop). Tests override it with their own
/// [FakeWidgetPublisher].
final widgetPublisherProvider = Provider<WidgetPublisher>(
  (ref) => !kIsWeb && (Platform.isAndroid || Platform.isIOS)
      ? HomeWidgetPublisher()
      : FakeWidgetPublisher(),
);

/// IANA id of the device's current time zone. Read again on every sync (the
/// zone can change while the process lives). Tests override it.
final widgetTimeZoneProvider = Provider<Future<String> Function()>(
  (ref) =>
      () async => (await FlutterTimezone.getLocalTimezone()).identifier,
);

/// The coalescing publisher of the widget snapshot. Reads the schedule of the
/// PRIMARY calendar (the one the alarms follow too), the holidays, the clock
/// and the zone fresh on every run, so it never publishes from a stale copy.
final widgetSyncProvider = Provider<WidgetSyncService>((ref) {
  final clock = ref.watch(clockProvider);
  final service = WidgetSyncService(
    publisher: ref.watch(widgetPublisherProvider),
    buildSnapshot: (strings) async {
      final schedule = await readPrimarySchedule(ref);
      final now = clock();
      String zone;
      try {
        zone = await ref.read(widgetTimeZoneProvider)();
      } catch (_) {
        zone = now.timeZoneName;
      }
      return buildWidgetSnapshot(
        schedule: schedule,
        holidays: ref.read(holidaysProvider),
        today: CivilDate.fromDateTime(now),
        timeZone: zone,
        strings: strings,
        weekStart: ref.read(preferencesProvider).weekStart,
        generatedAt: now,
      );
    },
    onError: (error, stack) {
      final reporter = ref.read(crashReporterProvider);
      unawaited(
        reporter
            .record(redactError(error), stack, fatal: false)
            .catchError((Object _) {}),
      );
    },
  );
  ref.onDispose(service.dispose);
  return service;
});
