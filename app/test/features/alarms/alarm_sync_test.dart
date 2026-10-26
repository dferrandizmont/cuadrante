import 'dart:async';

import 'package:cuadrante/features/alarms/application/alarm_sync.dart';
import 'package:cuadrante/features/alarms/data/alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

const _strings = AlarmStrings(
  title: _title,
  body: _body,
  channelName: 'Alarmas',
  channelDescription: 'Descripcion',
  dayBeforeTitle: _dayBeforeTitle,
  snoozeAction: 'Posponer',
  awakeAction: 'Despierto',
  testTitle: 'Prueba',
  testBody: 'Cuerpo de prueba',
  reminderTitle: 'Recordatorio',
  reminderEmptyBody: 'Tienes un recordatorio para hoy',
  reminderChannelName: 'Recordatorios de notas',
  reminderChannelDescription: 'Descripción',
);
String _title(String name, String start) => '$name $start';
String _dayBeforeTitle(String name, String start) => 'Mañana $name $start';
String _body(String name, String start, String end) => '$name $start-$end';

const _night = ShiftType(
  id: 'night',
  code: 'N',
  name: 'Noche',
  colorValue: 0xFF336699,
  category: ShiftCategory.work,
  startMinute: 22 * 60,
  endMinute: 6 * 60,
);

const _today = CivilDate(2026, 10, 19);

Schedule _scheduleWithNights(int count) => Schedule(
  shiftTypes: const [_night],
  entries: {
    for (var i = 1; i <= count; i++)
      _today.addDays(i): DayEntry(
        date: _today.addDays(i),
        shiftTypeIds: const ['night'],
      ),
  },
);

const _settings = AlarmSettings(
  enabled: true,
  byShiftType: {'night': AlarmTypeSettings(enabled: true)},
);

void main() {
  late FakeAlarmScheduler scheduler;
  late AlarmSettings settings;
  late Schedule schedule;
  late int settingsLoads;
  late List<Object> errors;
  late AlarmSync sync;

  setUp(() {
    scheduler = FakeAlarmScheduler();
    settings = _settings;
    schedule = _scheduleWithNights(3);
    settingsLoads = 0;
    errors = [];
    sync = AlarmSync(
      scheduler: scheduler,
      loadSettings: () async {
        settingsLoads++;
        return settings;
      },
      readSchedule: () => schedule,
      now: () => DateTime(2026, 10, 19, 12),
      strings: _strings,
      onError: (e, _) => errors.add(e),
    );
    addTearDown(sync.dispose);
  });

  test('a run configures the scheduler and schedules the plan', () async {
    await sync.resync();
    expect(scheduler.initialized, isTrue);
    expect(scheduler.strings, isNotNull);
    expect(scheduler.replaceCalls, 1);
    expect(scheduler.scheduled, hasLength(3));
    expect(scheduler.scheduled.first.title, 'Noche 22:00');
    expect(errors, isEmpty);
  });

  test('the schedule may be read asynchronously (the primary calendar can '
      'come from the database)', () async {
    var reads = 0;
    final asyncSync = AlarmSync(
      scheduler: scheduler,
      loadSettings: () async => settings,
      readSchedule: () async {
        reads++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return schedule;
      },
      now: () => DateTime(2026, 10, 19, 12),
      strings: _strings,
      onError: (e, _) => errors.add(e),
    );
    addTearDown(asyncSync.dispose);

    await asyncSync.resync();

    expect(reads, 1);
    expect(scheduler.scheduled, hasLength(3));
    expect(errors, isEmpty);
  });

  test('many requests while one run is in flight cost one more run', () async {
    final gate = scheduler.gate = Completer<void>();
    final first = sync.resync();
    // Let the first run reach the scheduler and wait there.
    await pumpEventQueue();
    expect(scheduler.replaceCalls, 1);

    final others = [for (var i = 0; i < 50; i++) sync.resync()];
    schedule = _scheduleWithNights(2);
    await pumpEventQueue();
    expect(scheduler.replaceCalls, 1, reason: 'nothing runs in parallel');

    gate.complete();
    await Future.wait([first, ...others]);
    expect(scheduler.replaceCalls, 2, reason: '1 in flight + 1 coalesced');
    expect(sync.runs, 2);
    // The coalesced run planned from the latest schedule.
    expect(scheduler.scheduled, hasLength(2));
  });

  test('simultaneous requests share one run', () async {
    await Future.wait([for (var i = 0; i < 20; i++) sync.resync()]);
    expect(scheduler.replaceCalls, 1);
    expect(settingsLoads, 1);
  });

  testWidgets('a burst of changes inside the debounce reschedules once', (
    tester,
  ) async {
    for (var i = 0; i < 30; i++) {
      sync.requestResync();
      await tester.pump(const Duration(milliseconds: 200));
    }
    // 30 changes, each under a second after the previous one: no run yet.
    expect(scheduler.replaceCalls, 0);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(scheduler.replaceCalls, 1);
    // Nothing else is pending.
    await tester.pump(const Duration(seconds: 5));
    expect(scheduler.replaceCalls, 1);
  });

  test('without permission nothing is scheduled and ours is cleared', () async {
    await sync.resync();
    expect(scheduler.scheduled, isNotEmpty);
    scheduler.permission = AlarmPermission.denied;
    await sync.resync();
    expect(scheduler.scheduled, isEmpty);
    // Granted later (the user comes back from system settings): back.
    scheduler.permission = AlarmPermission.granted;
    await sync.resync();
    expect(scheduler.scheduled, hasLength(3));
  });

  test('settings off schedules nothing but still clears', () async {
    await sync.resync();
    expect(scheduler.scheduled, isNotEmpty);
    settings = AlarmSettings.disabled;
    await sync.resync();
    expect(scheduler.replaceCalls, 2);
    expect(scheduler.scheduled, isEmpty);
  });

  test('waits for the strings, then runs', () async {
    sync.strings = null;
    await sync.resync();
    expect(scheduler.replaceCalls, 0);
    sync.strings = _strings;
    await sync.resync();
    expect(scheduler.replaceCalls, 1);
  });

  test('a failing run is reported and does not stop the next one', () async {
    var fail = true;
    final failing = AlarmSync(
      scheduler: scheduler,
      loadSettings: () async {
        if (fail) throw StateError('db closed');
        return settings;
      },
      readSchedule: () => schedule,
      now: () => DateTime(2026, 10, 19, 12),
      strings: _strings,
      onError: (e, _) => errors.add(e),
    );
    addTearDown(failing.dispose);
    await failing.resync();
    expect(errors, hasLength(1));
    expect(scheduler.replaceCalls, 0);
    fail = false;
    await failing.resync();
    expect(scheduler.replaceCalls, 1);
  });

  test('a run that fails after dispose reports nothing (the provider and its '
      'ref are gone: reading them would throw)', () async {
    final entered = Completer<void>();
    final gate = Completer<void>();
    final disposedMidRun = AlarmSync(
      scheduler: scheduler,
      loadSettings: () async => settings,
      readSchedule: () async {
        entered.complete();
        await gate.future;
        throw StateError('db closed');
      },
      now: () => DateTime(2026, 10, 19, 12),
      strings: _strings,
      onError: (e, _) => errors.add(e),
    );
    final run = disposedMidRun.resync();
    await entered.future;
    disposedMidRun.dispose();
    gate.complete();
    await run;
    expect(errors, isEmpty);
  });

  testWidgets('dispose cancels a pending debounce', (tester) async {
    sync.requestResync();
    sync.dispose();
    await tester.pump(const Duration(seconds: 5));
    await sync.resync();
    expect(scheduler.replaceCalls, 0);
  });

  test('rescheduling the same plan is idempotent: same ids', () async {
    await sync.resync();
    final first = scheduler.scheduled.map((a) => a.id).toList();
    await sync.resync();
    expect(scheduler.scheduled.map((a) => a.id).toList(), first);
    expect(scheduler.history, hasLength(2));
  });
}
