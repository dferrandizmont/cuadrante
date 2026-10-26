import 'package:cuadrante/features/alarms/data/alarm_sounds.dart';
import 'package:cuadrante/features/alarms/domain/alarm_payload.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The platform channel of the sound picker (faked at the binary messenger),
// the sound in the notification payload and the draft rule (A3).

const _uri = 'content://media/internal/audio/media/42';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PlatformAlarmSounds.channelName);
  const sounds = PlatformAlarmSounds();
  final calls = <MethodCall>[];

  void reply(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PlatformAlarmSounds', () {
    test('the channel name is the one MainActivity registers', () {
      expect(PlatformAlarmSounds.channelName, 'app.cuadrante/sounds');
      expect(sounds.supported, isTrue);
    });

    test(
      'pick sends the current sound and reads the uri and the title',
      () async {
        reply((_) async => {'uri': _uri, 'title': 'Cosmic'});
        final choice = await sounds.pick(current: 'content://media/x/1');
        expect(calls.single.method, 'pick');
        expect(calls.single.arguments, {'current': 'content://media/x/1'});
        expect(choice, const AlarmSoundChoice(uri: _uri, title: 'Cosmic'));
      },
    );

    test('the default entry comes back as a null uri', () async {
      reply((_) async => {'uri': null, 'title': null});
      final choice = await sounds.pick();
      expect(choice, isNotNull);
      expect(choice!.uri, isNull);
    });

    test('going back is null, not a choice', () async {
      reply((_) async => null);
      expect(await sounds.pick(), isNull);
    });

    test(
      'an uri that is empty or does not fit the database is the default',
      () async {
        reply((_) async => {'uri': '', 'title': 'x'});
        expect((await sounds.pick())!.uri, isNull);
        reply((_) async => {'uri': 'content://${'a' * 600}', 'title': 'x'});
        expect((await sounds.pick())!.uri, isNull);
      },
    );

    test('a failing channel never throws: no picker, no title, not '
        'available', () async {
      reply((_) async => throw PlatformException(code: 'busy'));
      expect(await sounds.pick(), isNull);
      expect(await sounds.title(_uri), isNull);
      expect(await sounds.isAvailable(_uri), isFalse);
    });

    test(
      'without the native side (iOS, tests) nothing throws either',
      () async {
        // No handler registered: MissingPluginException.
        expect(await sounds.pick(), isNull);
        expect(await sounds.title(_uri), isNull);
        expect(await sounds.isAvailable(_uri), isFalse);
      },
    );

    test('title and availability pass the uri', () async {
      reply((call) async => call.method == 'title' ? 'Cosmic' : true);
      expect(await sounds.title(_uri), 'Cosmic');
      expect(await sounds.isAvailable(_uri), isTrue);
      expect(calls.map((c) => c.method), ['title', 'isAvailable']);
      expect(calls.every((c) => (c.arguments as Map)['uri'] == _uri), isTrue);
    });

    test('an empty title is no title', () async {
      reply((_) async => '');
      expect(await sounds.title(_uri), isNull);
    });
  });

  group('NoAlarmSounds', () {
    test('offers nothing and trusts what is stored', () async {
      const none = NoAlarmSounds();
      expect(none.supported, isFalse);
      expect(await none.pick(), isNull);
      expect(await none.title(_uri), isNull);
      expect(await none.isAvailable(_uri), isTrue);
    });
  });

  group('payload', () {
    final date = DateTime(2026, 10, 20);

    test('carries the sound, so a snooze keeps it', () {
      final payload = AlarmPayload(
        shiftTypeId: 'night',
        shiftDate: CivilDate.fromDateTime(date),
        kind: AlarmKind.shift,
        title: 'Turno',
        body: 'Cuerpo',
        snoozeLabel: 'Posponer',
        awakeLabel: 'Despierto',
        sound: _uri,
      );
      final decoded = AlarmPayload.decode(payload.encode())!;
      expect(decoded.sound, _uri);
      expect(AlarmPayload.decode(payload.encodeAsSnooze())!.sound, _uri);
    });

    test('an old payload without a sound reads as the default sound', () {
      final old =
          '${alarmPayloadPrefix}night:2026-10-20:shift:'
          '{"t":"T","b":"B","s":"S","a":"A"}';
      final decoded = AlarmPayload.decode(old)!;
      expect(decoded.sound, isNull);
      expect(decoded.kind, AlarmKind.shift);
    });

    test('a reminder has no type and no sound', () {
      final payload = AlarmPayload(
        shiftTypeId: '',
        shiftDate: CivilDate.fromDateTime(date),
        kind: AlarmKind.reminder,
        title: 'Recordatorio',
        body: 'Dentista: 10:00',
      );
      final decoded = AlarmPayload.decode(payload.encode())!;
      expect(decoded.kind, AlarmKind.reminder);
      expect(decoded.shiftTypeId, '');
      expect(decoded.body, 'Dentista: 10:00');
      expect(decoded.sound, isNull);
    });

    test('a damaged sound field is ignored', () {
      final bad =
          '${alarmPayloadPrefix}night:2026-10-20:shift:'
          '{"t":"T","b":"B","c":42}';
      expect(AlarmPayload.decode(bad)!.sound, isNull);
      final empty =
          '${alarmPayloadPrefix}night:2026-10-20:shift:'
          '{"t":"T","b":"B","c":""}';
      expect(AlarmPayload.decode(empty)!.sound, isNull);
    });
  });

  group('ShiftTypeDraft', () {
    ShiftTypeDraft draft({
      ShiftCategory category = ShiftCategory.work,
      bool hasTimes = true,
    }) => ShiftTypeDraft(
      code: 'N',
      name: 'Noche',
      colorValue: 0xFF336699,
      category: category,
      hasTimes: hasTimes,
      alarmSound: _uri,
    );

    test('the alarm section applies where an alarm can ring', () {
      expect(draft().alarmSectionApplies, isTrue);
      expect(draft(category: ShiftCategory.rest).alarmSectionApplies, isTrue);
      expect(
        draft(category: ShiftCategory.absence).alarmSectionApplies,
        isFalse,
      );
      expect(draft(hasTimes: false).alarmSectionApplies, isFalse);
    });

    test('the sound travels to the shift type and survives other edits', () {
      final d = draft().copyWith(name: 'Noche');
      expect(d.alarmSound, _uri);
      expect(d.copyWith(clearAlarmSound: true).alarmSound, isNull);
      // Even where the section is hidden the choice is not lost.
      expect(
        draft(category: ShiftCategory.absence).toShiftType('x').alarmSound,
        _uri,
      );
    });
  });
}
