import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/application/widget_sync.dart';
import 'package:cuadrante/features/widget/data/widget_publisher.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot.dart';
import 'package:cuadrante/features/widget/domain/widget_snapshot_builder.dart';
import 'package:cuadrante/features/widget/domain/widget_strings.dart';
import 'package:cuadrante/features/widget/domain/widget_sync_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../schedule/domain/fixtures.dart';

const _today = CivilDate(2026, 10, 19);

Schedule _schedule({Map<CivilDate, DayEntry> entries = const {}}) => Schedule(
  shiftTypes: allTypes,
  patterns: const [
    Pattern(
      id: 'rot',
      name: 'rot',
      steps: [
        ['night'],
        ['afternoon'],
        ['morning'],
        ['rest'],
      ],
    ),
  ],
  runs: [PatternRun(id: 'r', patternId: 'rot', startDate: _today, seq: 1)],
  entries: entries,
);

WidgetSnapshot _snapshot(
  CivilDate today, {
  String tz = 'Europe/Madrid',
  Schedule? schedule,
}) => buildWidgetSnapshot(
  schedule: schedule ?? _schedule(),
  holidays: const {},
  today: today,
  timeZone: tz,
  strings: WidgetStrings.es,
  generatedAt: DateTime.utc(2026, 10, 19, 8),
);

Future<void> main() async {
  await initializeLocale();
  final published = _snapshot(_today);

  group('needsRefresh', () {
    bool needs({
      WidgetSnapshotHeader? header,
      CivilDate today = _today,
      String tz = 'Europe/Madrid',
      String? hash,
    }) => WidgetSyncPlanner.needsRefresh(
      published: header ?? published.header,
      today: today,
      timeZone: tz,
      contentHash: hash ?? published.contentHash,
    );

    test('nothing published', () {
      final d = WidgetSyncPlanner.evaluate(
        published: null,
        today: _today,
        timeZone: 'Europe/Madrid',
      );
      expect(d.needsRefresh, isTrue);
      expect(d.reasons, {WidgetRefreshReason.neverPublished});
    });

    test('same day, zone, version and content: no', () {
      expect(needs(), isFalse);
      // Without a hash the content check is skipped.
      expect(
        WidgetSyncPlanner.needsRefresh(
          published: published.header,
          today: _today,
          timeZone: 'Europe/Madrid',
        ),
        isFalse,
      );
    });

    test('the date rolled', () {
      final d = WidgetSyncPlanner.evaluate(
        published: published.header,
        today: _today.addDays(1),
        timeZone: 'Europe/Madrid',
        contentHash: _snapshot(_today.addDays(1)).contentHash,
      );
      expect(d.reasons, contains(WidgetRefreshReason.dateRolled));
      expect(needs(today: _today.addDays(1)), isTrue);
    });

    test('the clock went back', () {
      expect(needs(today: _today.addDays(-1)), isTrue);
    });

    test('time zone change', () {
      final d = WidgetSyncPlanner.evaluate(
        published: published.header,
        today: _today,
        timeZone: 'Atlantic/Canary',
        contentHash: published.contentHash,
      );
      expect(d.reasons, {WidgetRefreshReason.timeZoneChanged});
    });

    test('version change', () {
      final d = WidgetSyncPlanner.evaluate(
        published: published.header,
        today: _today,
        timeZone: 'Europe/Madrid',
        contentHash: published.contentHash,
        version: kWidgetSnapshotVersion + 1,
      );
      expect(d.reasons, {WidgetRefreshReason.versionChanged});
    });

    test('an edit changes the content hash', () {
      final edited = _snapshot(
        _today,
        schedule: _schedule(
          entries: {
            _today.addDays(5): DayEntry(
              date: _today.addDays(5),
              shiftTypeIds: const ['vacation'],
            ),
          },
        ),
      );
      final d = WidgetSyncPlanner.evaluate(
        published: published.header,
        today: _today,
        timeZone: 'Europe/Madrid',
        contentHash: edited.contentHash,
      );
      expect(d.reasons, {WidgetRefreshReason.contentChanged});
    });

    test('an edit outside the 60 days does not matter', () {
      final far = _snapshot(
        _today,
        schedule: _schedule(
          entries: {
            _today.addDays(200): DayEntry(
              date: _today.addDays(200),
              shiftTypeIds: const ['vacation'],
            ),
          },
        ),
      );
      expect(far.contentHash, published.contentHash);
    });

    test('several reasons at once', () {
      final d = WidgetSyncPlanner.evaluate(
        published: published.header,
        today: _today.addDays(3),
        timeZone: 'Atlantic/Canary',
        contentHash: 'other',
      );
      expect(d.reasons, {
        WidgetRefreshReason.dateRolled,
        WidgetRefreshReason.timeZoneChanged,
        WidgetRefreshReason.contentChanged,
      });
    });
  });

  group('plan', () {
    WidgetSyncPlan plan(WidgetSyncTrigger t, {bool changed = false}) =>
        WidgetSyncPlanner.plan(
          trigger: t,
          published: published.header,
          today: _today,
          timeZone: 'Europe/Madrid',
          contentHash: changed ? 'x' : published.contentHash,
        );

    test('opening the app reloads timelines even without changes', () {
      for (final t in [
        WidgetSyncTrigger.appStart,
        WidgetSyncTrigger.appResumed,
      ]) {
        final p = plan(t);
        expect(p.republish, isFalse, reason: t.name);
        expect(p.reloadTimelines, isTrue, reason: t.name);
      }
    });

    test('an edit that changes nothing visible does nothing', () {
      final p = plan(WidgetSyncTrigger.scheduleChanged);
      expect(p.republish, isFalse);
      expect(p.reloadTimelines, isFalse);
    });

    test('a visible edit republishes and reloads', () {
      final p = plan(WidgetSyncTrigger.scheduleChanged, changed: true);
      expect(p.republish, isTrue);
      expect(p.reloadTimelines, isTrue);
      expect(p.reasons, {WidgetRefreshReason.contentChanged});
    });

    test('nothing published yet: always publish', () {
      for (final t in WidgetSyncTrigger.values) {
        final p = WidgetSyncPlanner.plan(
          trigger: t,
          published: null,
          today: _today,
          timeZone: 'Europe/Madrid',
        );
        expect(p.republish, isTrue, reason: t.name);
      }
    });

    test('debounce: only edits wait', () {
      expect(
        WidgetSyncTrigger.scheduleChanged.debounce,
        WidgetSyncPlanner.editDebounce,
      );
      expect(
        WidgetSyncTrigger.holidaysChanged.debounce,
        WidgetSyncPlanner.editDebounce,
      );
      for (final t in [
        WidgetSyncTrigger.appStart,
        WidgetSyncTrigger.appResumed,
        WidgetSyncTrigger.dayChanged,
        WidgetSyncTrigger.timeZoneChanged,
        WidgetSyncTrigger.localeChanged,
      ]) {
        expect(t.debounce, Duration.zero, reason: t.name);
      }
    });
  });

  group('helpers', () {
    test('untilNextDay counts to the next local midnight', () {
      expect(
        WidgetSyncPlanner.untilNextDay(DateTime(2026, 10, 19, 23, 30)),
        const Duration(minutes: 30),
      );
      expect(
        WidgetSyncPlanner.untilNextDay(DateTime(2026, 10, 19)),
        const Duration(hours: 24),
      );
      expect(
        WidgetSyncPlanner.untilNextDay(DateTime(2026, 12, 31, 12)),
        const Duration(hours: 12),
      );
    });

    test('isStale: past the last day, before the first, or nothing', () {
      final h = published.header;
      expect(WidgetSyncPlanner.isStale(h, _today), isFalse);
      expect(WidgetSyncPlanner.isStale(h, _today.addDays(59)), isFalse);
      expect(WidgetSyncPlanner.isStale(h, _today.addDays(60)), isTrue);
      expect(WidgetSyncPlanner.isStale(h, _today.addDays(-1)), isTrue);
      expect(WidgetSyncPlanner.isStale(null, _today), isTrue);
    });

    test('isStale: a damaged header counts as stale instead of throwing', () {
      final good = published.header;
      WidgetSnapshotHeader damaged({String? first, String? last}) =>
          WidgetSnapshotHeader(
            version: good.version,
            generatedAt: good.generatedAt,
            timeZone: good.timeZone,
            firstDate: first ?? good.firstDate,
            lastDate: last ?? good.lastDate,
            contentHash: good.contentHash,
          );
      expect(WidgetSyncPlanner.isStale(damaged(first: 'x'), _today), isTrue);
      expect(WidgetSyncPlanner.isStale(damaged(last: 'x'), _today), isTrue);
    });
  });

  group('syncWidget with the fake publisher', () {
    test(
      'publish, then no-op, then edit, then next day, then new zone',
      () async {
        final pub = FakeWidgetPublisher();

        Future<WidgetSyncPlan> run(
          WidgetSyncTrigger t,
          CivilDate today, {
          String tz = 'Europe/Madrid',
          Schedule? schedule,
        }) => syncWidget(
          publisher: pub,
          trigger: t,
          build: () => _snapshot(today, tz: tz, schedule: schedule),
        );

        var p = await run(WidgetSyncTrigger.appStart, _today);
        expect(p.republish, isTrue);
        expect(pub.published, hasLength(1));
        expect(pub.reloadCount, 1);
        expect(WidgetSnapshot.decode(pub.stored!).firstDate, '2026-10-19');

        // Resume with nothing new: no publish, but the timelines reload.
        p = await run(WidgetSyncTrigger.appResumed, _today);
        expect(p.republish, isFalse);
        expect(pub.published, hasLength(1));
        expect(pub.reloadCount, 2);

        // Edit.
        final edited = _schedule(
          entries: {
            _today.addDays(1): DayEntry(
              date: _today.addDays(1),
              shiftTypeIds: const ['vacation'],
            ),
          },
        );
        p = await run(
          WidgetSyncTrigger.scheduleChanged,
          _today,
          schedule: edited,
        );
        expect(p.reasons, {WidgetRefreshReason.contentChanged});
        expect(pub.published, hasLength(2));

        // Same edit again: nothing.
        p = await run(
          WidgetSyncTrigger.scheduleChanged,
          _today,
          schedule: edited,
        );
        expect(p.republish, isFalse);
        expect(pub.published, hasLength(2));
        expect(pub.reloadCount, 3);

        // The date rolls over.
        p = await run(
          WidgetSyncTrigger.dayChanged,
          _today.addDays(1),
          schedule: edited,
        );
        expect(p.reasons, contains(WidgetRefreshReason.dateRolled));
        expect(pub.published, hasLength(3));
        expect(WidgetSnapshot.decode(pub.stored!).firstDate, '2026-10-20');

        // New time zone.
        p = await run(
          WidgetSyncTrigger.timeZoneChanged,
          _today.addDays(1),
          tz: 'Atlantic/Canary',
          schedule: edited,
        );
        expect(p.reasons, contains(WidgetRefreshReason.timeZoneChanged));
        expect(WidgetSnapshot.decode(pub.stored!).timeZone, 'Atlantic/Canary');
      },
    );

    test('an unreadable stored snapshot is replaced', () async {
      final pub = FakeWidgetPublisher()..stored = 'garbage';
      final p = await syncWidget(
        publisher: pub,
        trigger: WidgetSyncTrigger.appStart,
        build: () => _snapshot(_today),
      );
      expect(p.reasons, {WidgetRefreshReason.neverPublished});
      expect(WidgetSnapshot.tryDecode(pub.stored), isNotNull);
    });

    test('clear empties the store', () async {
      final pub = FakeWidgetPublisher();
      await pub.publish(_snapshot(_today).encode());
      await pub.clear();
      expect(await pub.readPublished(), isNull);
    });
  });
}
