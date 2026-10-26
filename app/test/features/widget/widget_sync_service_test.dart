import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/application/widget_sync_service.dart';
import 'package:cuadrante/features/widget/data/widget_publisher.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot_builder.dart';
import 'package:cuadrante/features/widget/domain/widget_strings.dart';
import 'package:cuadrante/features/widget/domain/widget_sync_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

const _today = CivilDate(2026, 10, 19);

Schedule _schedule([String first = 'night']) => Schedule(
  shiftTypes: allTypes,
  patterns: [
    Pattern(
      id: 'rot',
      name: 'rot',
      steps: [
        [first],
        ['rest'],
      ],
    ),
  ],
  runs: [PatternRun(id: 'r', patternId: 'rot', startDate: _today, seq: 1)],
  entries: const {},
);

Future<void> main() async {
  await initializeLocale();
  late FakeWidgetPublisher publisher;
  late CivilDate today;
  late String first;
  late String zone;
  late WidgetSyncService service;

  setUp(() {
    publisher = FakeWidgetPublisher();
    today = _today;
    first = 'night';
    zone = 'Europe/Madrid';
    service = WidgetSyncService(
      publisher: publisher,
      buildSnapshot: (strings) async => buildWidgetSnapshot(
        schedule: _schedule(first),
        holidays: const {},
        today: today,
        timeZone: zone,
        strings: strings,
        generatedAt: DateTime.utc(2026, 10, 19, 8),
      ),
    );
    service.strings = WidgetStrings.es;
  });

  tearDown(() => service.dispose());

  test('the first sync publishes; an unchanged one only reloads', () async {
    await service.request(WidgetSyncTrigger.appStart);
    expect(publisher.published, hasLength(1));
    expect(service.lastPlan!.reasons, {WidgetRefreshReason.neverPublished});

    final reloads = publisher.reloadCount;
    await service.request(WidgetSyncTrigger.appResumed);
    expect(publisher.published, hasLength(1), reason: 'nothing changed');
    expect(publisher.reloadCount, reloads + 1, reason: 'resume reloads');
  });

  test('a new day, a new zone and new content each republish', () async {
    await service.request(WidgetSyncTrigger.appStart);

    today = _today.addDays(1);
    await service.request(WidgetSyncTrigger.dayChanged);
    expect(publisher.published, hasLength(2));
    expect(service.lastPlan!.reasons, contains(WidgetRefreshReason.dateRolled));

    zone = 'Atlantic/Canary';
    await service.request(WidgetSyncTrigger.timeZoneChanged);
    expect(publisher.published, hasLength(3));
    expect(
      service.lastPlan!.reasons,
      contains(WidgetRefreshReason.timeZoneChanged),
    );

    first = 'morning';
    await service.request(WidgetSyncTrigger.appResumed);
    expect(publisher.published, hasLength(4));
    expect(
      service.lastPlan!.reasons,
      contains(WidgetRefreshReason.contentChanged),
    );
    expect(
      WidgetSnapshotHeader.tryParse(publisher.stored)!.firstDate,
      today.toIso(),
    );
  });

  test('edit triggers wait for a quiet period and coalesce', () async {
    await service.request(WidgetSyncTrigger.appStart);
    final runs = service.runs;
    first = 'afternoon';
    await service.request(WidgetSyncTrigger.scheduleChanged);
    await service.request(WidgetSyncTrigger.scheduleChanged);
    await service.request(WidgetSyncTrigger.holidaysChanged);
    expect(service.runs, runs, reason: 'still inside the debounce');
    await Future<void>.delayed(
      WidgetSyncPlanner.editDebounce + const Duration(milliseconds: 200),
    );
    await service.flush();
    expect(service.runs, runs + 1, reason: 'one run for the whole burst');
    expect(publisher.published, hasLength(2));
  });

  test('triggers wait for the texts and run once they arrive', () async {
    final waiting = WidgetSyncService(
      publisher: publisher,
      buildSnapshot: (strings) async => buildWidgetSnapshot(
        schedule: _schedule(),
        holidays: const {},
        today: _today,
        timeZone: zone,
        strings: strings,
      ),
    );
    addTearDown(waiting.dispose);
    await waiting.request(WidgetSyncTrigger.appStart);
    expect(publisher.published, isEmpty);
    waiting.strings = WidgetStrings.es;
    await waiting.flush();
    expect(publisher.published, hasLength(1));
  });

  test('a failing run reports the error and later runs still work', () async {
    final errors = <Object>[];
    var fail = true;
    final flaky = WidgetSyncService(
      publisher: publisher,
      buildSnapshot: (strings) async {
        if (fail) throw StateError('database busy');
        return buildWidgetSnapshot(
          schedule: _schedule(),
          holidays: const {},
          today: _today,
          timeZone: zone,
          strings: strings,
        );
      },
      onError: (e, s) => errors.add(e),
    )..strings = WidgetStrings.es;
    addTearDown(flaky.dispose);
    await flaky.request(WidgetSyncTrigger.appStart);
    expect(errors, hasLength(1));
    expect(publisher.published, isEmpty);
    fail = false;
    await flaky.request(WidgetSyncTrigger.appResumed);
    expect(publisher.published, hasLength(1));
  });
}
