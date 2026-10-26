import 'dart:async';

import 'package:cuadrante/features/alarms/application/alarm_providers.dart';
import 'package:cuadrante/features/alarms/data/alarm_sounds.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../calendar/harness.dart';

// The «Sonido» row of the shift type editor (docs/paridad.md, A3). The
// platform channel is faked with FakeAlarmSounds.

const _cosmic = 'content://media/internal/audio/media/42';
const _beacon = 'content://media/internal/audio/media/77';

Finder _key(String key) => find.byKey(ValueKey(key));

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _reveal(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// Settings -> Mis turnos -> the row of [id].
Future<void> _openEditor(WidgetTester tester, String id) async {
  await tester.tap(find.byTooltip('Abrir ajustes'));
  await tester.pumpAndSettle();
  await tester.tap(_key('settings-shifts'));
  await tester.pumpAndSettle();
  await _tap(tester, 'shift-row-$id');
}

Text _soundValue(WidgetTester tester) => tester.widget<Text>(
  find.descendant(of: _key('shift-sound'), matching: find.byType(Text)),
);

/// What is stored for the Noche shift type, once every write has finished.
Future<String?> _storedSound(WidgetTester tester) async {
  final container = _container(tester);
  final snapshot = await tester.runAsync(() async {
    await container.read(scheduleControllerProvider.notifier).pendingWrites;
    return container.read(scheduleRepositoryProvider).load(mainCalendarId);
  });
  return snapshot!.schedule.shiftTypeById('night')!.alarmSound;
}

Future<void> _seedNightSound(ScheduleRepository repository, String uri) async {
  final snapshot = await repository.load(mainCalendarId);
  final night = snapshot.schedule.shiftTypeById('night')!;
  await repository.saveShiftType(night.copyWith(alarmSound: uri));
}

void main() {
  late FakeAlarmSounds sounds;

  setUp(() {
    sounds = FakeAlarmSounds(titles: {_cosmic: 'Cosmic', _beacon: 'Beacon'});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String? storedSound,
    bool supported = true,
  }) async {
    sounds.supported = supported;
    await pumpCalendar(
      tester,
      overrides: [alarmSoundsProvider.overrideWithValue(sounds)],
      prepare: storedSound == null
          ? null
          : (repository) => _seedNightSound(repository, storedSound),
    );
  }

  testWidgets('the Alarma section shows «Predeterminado» until a sound is '
      'chosen', (tester) async {
    await pumpApp(tester);
    await _openEditor(tester, 'night');
    await _reveal(tester, 'shift-sound');
    expect(find.text('ALARMA'), findsOneWidget);
    expect(find.text('Sonido'), findsOneWidget);
    expect(_soundValue(tester).data, 'Predeterminado');
    expect(_key('shift-sound-reset'), findsNothing);
  });

  testWidgets('choosing a sound shows its name and saving stores it', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openEditor(tester, 'night');
    sounds.choice = const AlarmSoundChoice(uri: _cosmic, title: 'Cosmic');

    await _tap(tester, 'shift-sound');

    expect(sounds.pickCalls, [null], reason: 'nothing selected before');
    expect(_soundValue(tester).data, 'Cosmic');
    expect(_key('shift-sound-reset'), findsOneWidget);
    // Not stored until «Guardar».
    expect(await _storedSound(tester), isNull);

    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), _cosmic);
    expect(
      _container(tester)
          .read(scheduleControllerProvider)
          .schedule
          .shiftTypeById('night')!
          .alarmSound,
      _cosmic,
    );
  });

  testWidgets('it persists: reopening shows the stored sound by name and the '
      'picker starts on it', (tester) async {
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    await _reveal(tester, 'shift-sound');
    // The name arrives from the phone a moment after the form opens.
    await tester.pumpAndSettle();
    expect(_soundValue(tester).data, 'Cosmic');

    sounds.choice = const AlarmSoundChoice(uri: _beacon, title: 'Beacon');
    await _tap(tester, 'shift-sound');
    expect(sounds.pickCalls, [_cosmic]);
    expect(_soundValue(tester).data, 'Beacon');
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), _beacon);
  });

  testWidgets('«Usar el predeterminado» clears it', (tester) async {
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    await _tap(tester, 'shift-sound-reset');
    expect(_soundValue(tester).data, 'Predeterminado');
    expect(_key('shift-sound-reset'), findsNothing);
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), isNull);
  });

  testWidgets('picking the default entry of the system list clears it too', (
    tester,
  ) async {
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    sounds.choice = const AlarmSoundChoice(); // uri null = the default
    await _tap(tester, 'shift-sound');
    expect(_soundValue(tester).data, 'Predeterminado');
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), isNull);
  });

  testWidgets('going back from the system picker changes nothing', (
    tester,
  ) async {
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    sounds.choice = null;
    await _tap(tester, 'shift-sound');
    expect(sounds.pickCalls, hasLength(1));
    expect(_soundValue(tester).data, 'Cosmic');
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), _cosmic);
  });

  testWidgets('a picker that fails leaves the row usable: no crash, and the '
      'next tap opens the picker again', (tester) async {
    final failing = _FailingPickSounds(titles: {_cosmic: 'Cosmic'});
    sounds = failing;
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');

    await _tap(tester, 'shift-sound');
    expect(tester.takeException(), isNull);
    expect(failing.pickCalls, hasLength(1));
    // Nothing changed.
    expect(_soundValue(tester).data, 'Cosmic');
    expect(
      tester.widget<OutlinedButton>(_soundButtonKey).onPressed,
      isNotNull,
      reason: 'the row is on again',
    );

    failing.fail = false;
    failing.choice = const AlarmSoundChoice(uri: _beacon, title: 'Beacon');
    await _tap(tester, 'shift-sound');
    expect(failing.pickCalls, hasLength(2));
    expect(_soundValue(tester).data, 'Beacon');
  });

  testWidgets('while the picker is open the row is off and a second tap does '
      'not open another', (tester) async {
    final slow = _SlowPickSounds(titles: {_cosmic: 'Cosmic'});
    sounds = slow;
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    await _reveal(tester, 'shift-sound');

    await tester.tap(_key('shift-sound'));
    await tester.pump();
    expect(tester.widget<OutlinedButton>(_soundButtonKey).onPressed, isNull);
    expect(slow.pickCalls, hasLength(1));

    slow.answer.complete(const AlarmSoundChoice(uri: _beacon, title: 'Beacon'));
    await tester.pumpAndSettle();
    expect(_soundValue(tester).data, 'Beacon');
    expect(tester.widget<OutlinedButton>(_soundButtonKey).onPressed, isNotNull);
  });

  testWidgets('editing something else keeps the sound', (tester) async {
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    await _reveal(tester, 'shift-name');
    await tester.enterText(_key('shift-name'), 'Noche larga');
    await tester.pump();
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), _cosmic);
  });

  testWidgets('a sound that is gone says so and the default one rings; '
      'saving does not lose the choice', (tester) async {
    sounds.missing.add(_cosmic);
    await pumpApp(tester, storedSound: _cosmic);
    await _openEditor(tester, 'night');
    await _reveal(tester, 'shift-sound');
    await tester.pumpAndSettle();
    expect(_soundValue(tester).data, 'No disponible: suena el predeterminado');
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), _cosmic);
  });

  testWidgets('a shift an alarm cannot ring for has no sound row', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openEditor(tester, 'night');
    expect(_key('shift-sound'), findsOneWidget);

    await _tap(tester, 'category-absence');
    expect(_key('shift-sound'), findsNothing);
    await _tap(tester, 'category-work');
    expect(_key('shift-sound'), findsOneWidget);

    await _tap(tester, 'shift-no-times');
    expect(_key('shift-sound'), findsNothing);
  });

  testWidgets('where the phone has no sounds to choose (iOS, desktop) there '
      'is no row, and a stored value is kept', (tester) async {
    await pumpApp(tester, storedSound: _cosmic, supported: false);
    await _openEditor(tester, 'night');
    await _reveal(tester, 'shift-save');
    expect(_key('shift-sound'), findsNothing);
    await _tap(tester, 'shift-save');
    expect(await _storedSound(tester), _cosmic);
  });
}

final _soundButtonKey = find.descendant(
  of: find.byKey(const ValueKey('shift-sound')),
  matching: find.byWidgetPredicate((w) => w is OutlinedButton),
);

class _FailingPickSounds extends FakeAlarmSounds {
  _FailingPickSounds({super.titles});

  bool fail = true;

  @override
  Future<AlarmSoundChoice?> pick({String? current}) {
    if (fail) {
      pickCalls.add(current);
      return Future.error(StateError('the Activity died'));
    }
    return super.pick(current: current);
  }
}

class _SlowPickSounds extends FakeAlarmSounds {
  _SlowPickSounds({super.titles});

  final answer = Completer<AlarmSoundChoice?>();

  @override
  Future<AlarmSoundChoice?> pick({String? current}) {
    pickCalls.add(current);
    return answer.future;
  }
}
