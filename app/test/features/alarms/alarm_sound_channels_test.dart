import 'dart:async';

import 'package:cuadrante/features/alarms/data/alarm_actions.dart';
import 'package:cuadrante/features/alarms/data/alarm_sounds.dart';
import 'package:cuadrante/features/alarms/data/local_alarm_scheduler.dart';
import 'package:cuadrante/features/alarms/domain/alarm_channels.dart';
import 'package:cuadrante/features/alarms/domain/alarm_planner.dart';
import 'package:cuadrante/features/alarms/domain/alarm_strings.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

// A channel per alarm sound (docs/paridad.md, A3): the pure naming and
// cleanup rules, and how LocalAlarmScheduler uses them.

const _soundA = 'content://media/internal/audio/media/42';
const _soundB = 'content://media/internal/audio/media/77';

const _strings = AlarmStrings(
  title: _t2,
  body: _t3,
  channelName: 'Alarmas de turno',
  channelDescription: 'Descripción',
  dayBeforeTitle: _t2,
  snoozeAction: 'Posponer 10 min',
  awakeAction: 'Ya estoy despierto',
  testTitle: 'Prueba',
  testBody: 'Cuerpo',
  reminderTitle: 'Recordatorio',
  reminderEmptyBody: 'Tienes un recordatorio para hoy',
  reminderChannelName: 'Recordatorios de notas',
  reminderChannelDescription: 'Los avisos de tus notas',
);
String _t2(String a, String b) => '$a $b';
String _t3(String a, String b, String c) => '$a $b $c';

PlannedAlarm _shift(
  int id,
  int day, {
  String? sound,
  AlarmKind kind = AlarmKind.shift,
}) => PlannedAlarm(
  id: id,
  fireDate: CivilDate(2026, 10, day),
  fireMinute: 20 * 60 + 30,
  shiftDate: CivilDate(2026, 10, day),
  shiftTypeId: 'night',
  title: 'Turno',
  body: 'Cuerpo',
  kind: kind,
  snoozeLabel: kind == AlarmKind.shift ? 'Posponer' : null,
  awakeLabel: kind == AlarmKind.shift ? 'Despierto' : null,
  sound: sound,
);

const _reminder = PlannedAlarm(
  id: 5,
  fireDate: CivilDate(2026, 10, 21),
  fireMinute: 9 * 60,
  shiftDate: CivilDate(2026, 10, 21),
  shiftTypeId: '',
  title: 'Recordatorio',
  body: 'Dentista',
  kind: AlarmKind.reminder,
);

class _Call {
  _Call(this.id, this.details, this.payload);
  final int id;
  final NotificationDetails details;
  final String? payload;
  AndroidNotificationDetails get android => details.android!;
}

/// The Android side of the plugin: records the channels it is asked to
/// create and delete, and holds the ones "already on the phone".
class _FakeAndroid implements AndroidFlutterLocalNotificationsPlugin {
  final created = <AndroidNotificationChannel>[];
  final deleted = <String>[];
  final existing = <AndroidNotificationChannel>[];
  Object? failCreateFor;

  AndroidNotificationChannel? channel(String id) =>
      created.where((c) => c.id == id).lastOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #createNotificationChannel:
        final c =
            invocation.positionalArguments.first as AndroidNotificationChannel;
        if (failCreateFor == c.id) {
          return Future<void>.error(StateError('no channel'));
        }
        created.add(c);
        return Future<void>.value();
      case #getNotificationChannels:
        return Future<List<AndroidNotificationChannel>?>.value([...existing]);
      case #deleteNotificationChannel:
        deleted.add(invocation.namedArguments[#channelId] as String);
        return Future<void>.value();
      case #canScheduleExactNotifications:
        return Future<bool?>.value(true);
    }
    return super.noSuchMethod(invocation);
  }
}

class _Plugin implements FlutterLocalNotificationsPlugin {
  _Plugin(this.android);

  final _FakeAndroid android;
  final scheduled = <_Call>[];

  /// What the phone still has pending (a snooze, for instance).
  final pending = <PendingNotificationRequest>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #initialize:
        return Future<bool?>.value(true);
      case #zonedSchedule:
        scheduled.add(
          _Call(
            invocation.namedArguments[#id] as int,
            invocation.namedArguments[#notificationDetails]
                as NotificationDetails,
            invocation.namedArguments[#payload] as String?,
          ),
        );
        return Future<void>.value();
      case #pendingNotificationRequests:
        return Future<List<PendingNotificationRequest>>.value([...pending]);
      case #resolvePlatformSpecificImplementation:
        if (invocation.typeArguments.isNotEmpty &&
            invocation.typeArguments.first ==
                AndroidFlutterLocalNotificationsPlugin) {
          return android;
        }
        return null;
    }
    return super.noSuchMethod(invocation);
  }
}

AndroidNotificationChannel _existingChannel(String id) =>
    AndroidNotificationChannel(id, 'x');

void main() {
  group('channel ids', () {
    test('no sound is the default channel, a sound its own', () {
      expect(alarmSoundChannelId(null), 'shift_alarms');
      final a = alarmSoundChannelId(_soundA);
      final b = alarmSoundChannelId(_soundB);
      expect(a, startsWith('shift_alarm_'));
      expect(a, matches(RegExp(r'^shift_alarm_[0-9a-f]{8}$')));
      expect(a, isNot(b));
      expect(alarmSoundChannelId(_soundA), a, reason: 'stable');
      expect(a, isNot(defaultAlarmChannelId));
    });

    test('the default channel never looks like a sound channel', () {
      expect(
        defaultAlarmChannelId.startsWith(alarmSoundChannelPrefix),
        isFalse,
      );
      expect(reminderChannelId.startsWith(alarmSoundChannelPrefix), isFalse);
    });

    test('a reminder has its own channel whatever the sound', () {
      expect(alarmChannelIdFor(AlarmKind.reminder, null), reminderChannelId);
      expect(alarmChannelIdFor(AlarmKind.reminder, _soundA), reminderChannelId);
      expect(
        alarmChannelIdFor(AlarmKind.shift, _soundA),
        alarmSoundChannelId(_soundA),
      );
      expect(
        alarmChannelIdFor(AlarmKind.dayBefore, _soundA),
        alarmSoundChannelId(_soundA),
      );
      expect(
        alarmChannelIdFor(AlarmKind.dayBefore, null),
        defaultAlarmChannelId,
      );
    });

    test('a sound that is gone falls back to the default one', () {
      expect(effectiveAlarmSound(_soundA, {}), _soundA);
      expect(effectiveAlarmSound(_soundA, {_soundA}), isNull);
      expect(effectiveAlarmSound(_soundB, {_soundA}), _soundB);
      expect(effectiveAlarmSound(null, {_soundA}), isNull);
    });
  });

  group('cleanup of unused channels', () {
    test('only sound channels nobody uses are stale', () {
      final used = alarmSoundChannelId(_soundA);
      final unused = alarmSoundChannelId(_soundB);
      final stale = staleSoundChannelIds(
        [
          defaultAlarmChannelId,
          reminderChannelId,
          used,
          unused,
          'other_plugin_channel',
          'shift_alarm_', // the bare prefix is still ours to clean
        ],
        [_soundA],
      );
      expect(stale, {unused, 'shift_alarm_'});
    });

    test('with no sound in use every sound channel is stale, and the '
        'default stays', () {
      final a = alarmSoundChannelId(_soundA);
      expect(
        staleSoundChannelIds([defaultAlarmChannelId, reminderChannelId, a], []),
        {a},
      );
      expect(staleSoundChannelIds(const [], [_soundA]), isEmpty);
    });
  });

  group('LocalAlarmScheduler', () {
    late _FakeAndroid android;
    late _Plugin plugin;
    late FakeAlarmSounds sounds;
    late LocalAlarmScheduler scheduler;

    setUp(() {
      android = _FakeAndroid();
      plugin = _Plugin(android);
      sounds = FakeAlarmSounds(titles: {_soundA: 'Cosmic', _soundB: 'Beacon'});
      scheduler = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
        sounds: sounds,
      );
    });

    test(
      'configure creates the default alarm channel and the reminders one',
      () async {
        await scheduler.configure(_strings);
        final alarm = android.channel(alarmChannelId)!;
        expect(alarm.importance, Importance.max);
        expect(alarm.audioAttributesUsage, AudioAttributesUsage.alarm);
        expect(alarm.sound, isNull);
        final reminder = android.channel(reminderChannelId)!;
        expect(reminder.name, 'Recordatorios de notas');
        expect(reminder.importance, Importance.high);
        expect(
          reminder.audioAttributesUsage,
          AudioAttributesUsage.notification,
        );
        expect(
          reminder.sound,
          isNull,
          reason: 'the default notification sound',
        );
      },
    );

    test(
      'each sound gets its channel, created before the alarm uses it',
      () async {
        await scheduler.configure(_strings);
        android.created.clear();
        await scheduler.replaceAll([
          _shift(1, 20, sound: _soundA),
          _shift(2, 21, sound: _soundB),
          _shift(3, 22, sound: _soundA),
          _shift(4, 23),
        ]);

        final idA = alarmSoundChannelId(_soundA);
        final idB = alarmSoundChannelId(_soundB);
        expect({for (final c in android.created) c.id}, {idA, idB});
        final channelA = android.channel(idA)!;
        expect((channelA.sound as UriAndroidNotificationSound).sound, _soundA);
        expect(channelA.name, 'Alarmas de turno · Cosmic');
        expect(channelA.importance, Importance.max);
        expect(channelA.audioAttributesUsage, AudioAttributesUsage.alarm);

        expect(plugin.scheduled.map((c) => c.android.channelId), [
          idA,
          idB,
          idA,
          alarmChannelId,
        ]);
        expect(
          (plugin.scheduled.first.android.sound as UriAndroidNotificationSound)
              .sound,
          _soundA,
        );
        expect(plugin.scheduled.last.android.sound, isNull);
        // The payload says which sound the alarm rings with (for a snooze).
        expect(
          AlarmPayload.decode(plugin.scheduled.first.payload)!.sound,
          _soundA,
        );
        expect(
          AlarmPayload.decode(plugin.scheduled.last.payload)!.sound,
          isNull,
        );
      },
    );

    test('a sound that is gone rings on the default channel, without '
        'creating one and without crashing', () async {
      sounds.missing.add(_soundA);
      await scheduler.configure(_strings);
      android.created.clear();
      await scheduler.replaceAll([_shift(1, 20, sound: _soundA)]);

      expect(android.created, isEmpty);
      final call = plugin.scheduled.single;
      expect(call.android.channelId, alarmChannelId);
      expect(call.android.sound, isNull);
      expect(AlarmPayload.decode(call.payload)!.sound, isNull);
    });

    test('a sound check that fails counts as gone', () async {
      final broken = _ThrowingSounds();
      final s = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
        sounds: broken,
      );
      await s.configure(_strings);
      await s.replaceAll([_shift(1, 20, sound: _soundA)]);
      expect(plugin.scheduled.single.android.channelId, alarmChannelId);
    });

    test('a sound check that never answers times out: the resync finishes on '
        'the default channel and the next one is not blocked', () async {
      final s = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
        sounds: _NeverAnsweringSounds(),
        soundTimeout: const Duration(milliseconds: 50),
      );
      await s.configure(_strings);
      await s
          .replaceAll([_shift(1, 20, sound: _soundA)])
          .timeout(const Duration(seconds: 5));
      expect(plugin.scheduled.single.android.channelId, alarmChannelId);
      expect(
        AlarmPayload.decode(plugin.scheduled.single.payload)!.sound,
        isNull,
      );
      // The mutex was released: a later resync still runs.
      await s.replaceAll([_shift(2, 21)]).timeout(const Duration(seconds: 5));
      expect(plugin.scheduled.length, 2);
    });

    test('a title that never answers does not stop the sound channel being '
        'created, just without the title in its name', () async {
      final s = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
        sounds: _NeverAnsweringSounds(available: true),
        soundTimeout: const Duration(milliseconds: 50),
      );
      await s.configure(_strings);
      await s
          .replaceAll([_shift(1, 20, sound: _soundA)])
          .timeout(const Duration(seconds: 5));
      final id = alarmSoundChannelId(_soundA);
      expect(android.channel(id)!.name, 'Alarmas de turno');
      expect(plugin.scheduled.single.android.channelId, id);
    });

    test(
      'a channel that cannot be created falls back to the default one',
      () async {
        await scheduler.configure(_strings);
        android.failCreateFor = alarmSoundChannelId(_soundA);
        await scheduler.replaceAll([
          _shift(1, 20, sound: _soundA),
          _shift(2, 21, sound: _soundB),
        ]);
        expect(plugin.scheduled.map((c) => c.android.channelId), [
          alarmChannelId,
          alarmSoundChannelId(_soundB),
        ]);
      },
    );

    test('without a sounds service every sound is trusted', () async {
      final trusting = LocalAlarmScheduler(
        plugin: plugin,
        localZone: () async => 'Europe/Madrid',
      );
      await trusting.configure(_strings);
      await trusting.replaceAll([_shift(1, 20, sound: _soundA)]);
      expect(
        plugin.scheduled.single.android.channelId,
        alarmSoundChannelId(_soundA),
      );
    });

    test('a reminder rings on its own channel, as a notification, with no '
        'buttons, whatever sound it was given', () async {
      await scheduler.configure(_strings);
      android.created.clear();
      await scheduler.replaceAll([_reminder.withSound(_soundA)]);
      expect(android.created, isEmpty);
      final call = plugin.scheduled.single;
      expect(call.android.channelId, reminderChannelId);
      expect(call.android.channelName, 'Recordatorios de notas');
      expect(call.android.actions, isNull);
      expect(call.android.sound, isNull);
      expect(
        call.android.audioAttributesUsage,
        AudioAttributesUsage.notification,
      );
      expect(call.android.category, AndroidNotificationCategory.reminder);
      expect(call.android.importance, Importance.high);
      expect(call.android.visibility, NotificationVisibility.private);
      final payload = AlarmPayload.decode(call.payload)!;
      expect(payload.kind, AlarmKind.reminder);
      expect(payload.sound, isNull);
    });

    test(
      'channels no alarm uses any more are deleted, the rest kept',
      () async {
        final used = alarmSoundChannelId(_soundA);
        final unused = alarmSoundChannelId(_soundB);
        android.existing.addAll([
          _existingChannel(alarmChannelId),
          _existingChannel(reminderChannelId),
          _existingChannel(used),
          _existingChannel(unused),
          _existingChannel('another_feature'),
        ]);
        await scheduler.configure(_strings);
        await scheduler.replaceAll([_shift(1, 20, sound: _soundA)]);
        expect(android.deleted, [unused]);
      },
    );

    test('with no alarm left all the sound channels go', () async {
      final unused = alarmSoundChannelId(_soundB);
      android.existing.addAll([
        _existingChannel(alarmChannelId),
        _existingChannel(unused),
      ]);
      await scheduler.configure(_strings);
      await scheduler.replaceAll(const []);
      expect(android.deleted, [unused]);
    });

    test('the channel of a pending snooze is not deleted, or Android would '
        'recreate it named after its raw id', () async {
      final snoozed = AlarmPayload(
        shiftTypeId: 'night',
        shiftDate: const CivilDate(2026, 10, 21),
        kind: AlarmKind.shift,
        title: 'Turno',
        body: 'Cuerpo',
        sound: _soundB,
      ).encodeAsSnooze();
      plugin.pending.add(
        PendingNotificationRequest(9, 'Turno', 'Cuerpo', snoozed),
      );
      final kept = alarmSoundChannelId(_soundB);
      final unused = alarmSoundChannelId(_soundA);
      android.existing.addAll([
        _existingChannel(alarmChannelId),
        _existingChannel(kept),
        _existingChannel(unused),
      ]);
      await scheduler.configure(_strings);
      // The plan has no alarm: nothing "uses" the channels but the snooze.
      await scheduler.replaceAll(const []);
      expect(android.deleted, [unused]);
    });

    test('a sound that went away is cleaned up too', () async {
      sounds.missing.add(_soundA);
      final id = alarmSoundChannelId(_soundA);
      android.existing.add(_existingChannel(id));
      await scheduler.configure(_strings);
      await scheduler.replaceAll([_shift(1, 20, sound: _soundA)]);
      expect(android.deleted, [id]);
    });

    test('a snooze keeps the sound of the alarm it repeats', () async {
      final alarm = _shift(1, 20, sound: _soundA);
      final result = await handleAlarmAction(
        scheduler: scheduler,
        actionId: snoozeActionId,
        payload: alarm.payload,
        now: DateTime.utc(2026, 10, 20, 18),
      );
      expect(result, AlarmActionResult.snoozed);
      final call = plugin.scheduled.single;
      expect(call.android.channelId, alarmSoundChannelId(_soundA));
      expect(
        (call.android.sound as UriAndroidNotificationSound).sound,
        _soundA,
      );
      // And the snoozed copy still carries it, for snoozing again.
      expect(AlarmPayload.decode(call.payload)!.sound, _soundA);
    });
  });
}

class _ThrowingSounds implements AlarmSounds {
  @override
  bool get supported => true;

  @override
  Future<AlarmSoundChoice?> pick({String? current}) async => null;

  @override
  Future<String?> title(String uri) => Future.error(StateError('boom'));

  @override
  Future<bool> isAvailable(String uri) => Future.error(StateError('boom'));
}

/// A provider that hangs: `title` never completes, and neither does
/// `isAvailable` unless [available] says it answers.
class _NeverAnsweringSounds implements AlarmSounds {
  _NeverAnsweringSounds({this.available = false});

  final bool available;

  @override
  bool get supported => true;

  @override
  Future<AlarmSoundChoice?> pick({String? current}) async => null;

  @override
  Future<String?> title(String uri) => Completer<String?>().future;

  @override
  Future<bool> isAvailable(String uri) =>
      available ? Future.value(true) : Completer<bool>().future;
}
