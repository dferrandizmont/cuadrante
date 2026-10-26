import 'dart:async';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/alarm_channels.dart';
import '../domain/alarm_planner.dart';
import '../domain/alarm_strings.dart';
import 'alarm_actions.dart';
import 'alarm_scheduler.dart';
import 'alarm_sounds.dart';
import 'alarm_system.dart';
import 'wall_clock.dart';

/// Android channel of the shift alarms with the default sound. Shift types
/// with a custom sound ring on their own channel (`alarm_channels.dart`).
const String alarmChannelId = defaultAlarmChannelId;

/// Monochrome status-bar icon (`res/drawable/ic_stat_alarm.xml`).
const String _androidSmallIcon = 'ic_stat_alarm';

/// iOS notification category with the "Posponer" and "Ya estoy despierto"
/// actions. Declared at initialization; iOS is tested on a Mac later.
const String alarmIosCategory = 'cuadrante.alarm.shift';

/// Runs when a button of an alarm notification is tapped and the app is not
/// in front (on Android: in a background isolate that the plugin starts,
/// also when the app process is dead).
///
/// Top level and `vm:entry-point` so the Dart compiler keeps it. The isolate
/// has only plugins: no database, no providers, no localizations, which is
/// why the texts the snoozed copy needs travel in the payload
/// (`AlarmPayload`). Errors are swallowed: there is nobody to tell.
@pragma('vm:entry-point')
Future<void> alarmNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    await handleAlarmAction(
      scheduler: LocalAlarmScheduler(),
      actionId: response.actionId,
      payload: response.payload,
      now: DateTime.now(),
    );
  } catch (_) {
    // Nothing to report to from here.
  }
}

/// `flutter_local_notifications` implementation.
///
/// Android: exact alarms (`exactAllowWhileIdle`) when the user has granted
/// "Alarms and reminders" (`SCHEDULE_EXACT_ALARM`), otherwise inexact ones
/// (`inexactAllowWhileIdle`, a few minutes of drift). The plugin's boot and
/// package-replaced receivers (AndroidManifest) re-arm everything after a
/// reboot or an update. The channel is high importance with the alarm audio
/// usage, so it follows the alarm volume instead of the ringer.
///
/// iOS: plain local notifications (64 pending at most, see `maxPendingAlarms`).
/// Written against the plugin docs; not compiled in the Windows environment.
class LocalAlarmScheduler implements AlarmScheduler {
  /// [localZone] gives the IANA id of the device's current time zone (tests
  /// inject their own); it is read again on every [replaceAll], because the
  /// zone can change while the process lives.
  ///
  /// [sounds] answers whether a custom alarm sound can still be played; null
  /// (the snooze isolate, tests) trusts every sound. Each question to it is
  /// bounded by [soundTimeout] ([defaultSoundTimeout]): a provider that never
  /// answers must not hold the mutex and stop every later resync.
  LocalAlarmScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? localZone,
    this._sounds,
    this._system,
    this.soundTimeout = defaultSoundTimeout,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localZone = localZone ?? _deviceZone;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _localZone;
  final AlarmSounds? _sounds;

  /// Marks the notification prompt as asked, so the platform can tell a
  /// permission denied for good from one never asked (H-T11-1). Null in the
  /// snooze isolate and in tests.
  final AlarmSystem? _system;

  /// How long a sound check may take before it counts as "no answer".
  static const Duration defaultSoundTimeout = Duration(seconds: 3);
  final Duration soundTimeout;

  static Future<String> _deviceZone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  final AsyncMutex _mutex = AsyncMutex();
  Future<void>? _init;
  bool _zonesLoaded = false;
  tz.Location? _zone;
  AlarmStrings? _strings;
  String? _registeredSnooze;
  String? _registeredAwake;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() => _init ??= _initializeOnce();

  /// Plugin setup, cached once it worked. A failure is not cached: the next
  /// call tries again.
  Future<void> _initializeOnce() async {
    try {
      await _doInitialize();
    } catch (_) {
      _init = null;
      rethrow;
    }
  }

  Future<void> _doInitialize() async {
    if (!_zonesLoaded) {
      tzdata.initializeTimeZones();
      _zonesLoaded = true;
    }
    final strings = _strings;
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings(_androidSmallIcon),
        // Permission is asked in context (requestPermission), never at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            // Needs the localized labels, so `configure` sets the texts
            // before the first initialization.
            if (strings != null)
              DarwinNotificationCategory(
                alarmIosCategory,
                actions: [
                  DarwinNotificationAction.plain(
                    snoozeActionId,
                    strings.snoozeAction,
                  ),
                  DarwinNotificationAction.plain(
                    awakeActionId,
                    strings.awakeAction,
                  ),
                ],
              ),
          ],
        ),
      ),
      // Buttons that do not open the app land in the background handler; this
      // one covers the rest (iOS in the foreground, older plugin paths).
      onDidReceiveNotificationResponse: (response) {
        unawaited(
          handleAlarmAction(
            scheduler: this,
            actionId: response.actionId,
            payload: response.payload,
            now: DateTime.now(),
          ).catchError((Object _) => AlarmActionResult.ignored),
        );
      },
      onDidReceiveBackgroundNotificationResponse:
          alarmNotificationBackgroundHandler,
    );
    _registeredSnooze = strings?.snoozeAction;
    _registeredAwake = strings?.awakeAction;
  }

  /// The device's zone right now, also set as `tz.local` when it changed.
  /// If the zone cannot be read or is unknown: the last one known, or the
  /// app default (spec: Europe/Madrid) before any.
  Future<tz.Location> _currentZone() async {
    tz.Location? location;
    try {
      location = tz.getLocation(await _localZone());
    } catch (_) {
      location = null;
    }
    location ??= _zone ?? tz.getLocation('Europe/Madrid');
    if (_zone?.name != location.name) {
      tz.setLocalLocation(location);
      _zone = location;
    }
    return location;
  }

  @override
  Future<tz.Location> planningZone() async {
    await initialize();
    return _currentZone();
  }

  @override
  Future<void> configure(AlarmStrings strings) => _mutex.run(() async {
    _strings = strings;
    await initialize();
    // Darwin registers categories at initialization. Re-register only when
    // their labels changed (including initialization before texts arrived).
    // Permission flags stay false and the action handlers are retained.
    if (_registeredSnooze != strings.snoozeAction ||
        _registeredAwake != strings.awakeAction) {
      await _doInitialize();
    }
    final android = _android;
    if (android == null) return;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        alarmChannelId,
        strings.channelName,
        description: strings.channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    // Reminders of notes: high importance, the default notification sound and
    // volume (they are not an alarm clock).
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        reminderChannelId,
        strings.reminderChannelName,
        description: strings.reminderChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  });

  /// Creates the channel of the custom sound [sound] (an Android channel has
  /// the sound it was created with: calling this again changes nothing but
  /// its name). The name carries the sound's title so the system settings
  /// tell the channels apart.
  Future<void> _ensureSoundChannel(String sound) async {
    final android = _android;
    if (android == null) return;
    final strings = _strings;
    String? title;
    try {
      title = await _sounds
          ?.title(sound)
          .timeout(soundTimeout, onTimeout: () => null);
    } catch (_) {
      title = null;
    }
    final base = strings?.channelName ?? alarmChannelId;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        alarmSoundChannelId(sound),
        title == null ? base : '$base · $title',
        description: strings?.channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: UriAndroidNotificationSound(sound),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  /// Deletes the custom-sound channels that no alarm uses any more. A sound
  /// that a **pending notification** still carries (a snooze, which the plan
  /// does not know) keeps its channel: deleted, Android would recreate it
  /// from the snooze isolate, named after its raw id (`shift_alarm_1a2b3c4d`),
  /// because that isolate has no localized name to give it.
  Future<void> _deleteStaleSoundChannels(Iterable<String> inUse) async {
    final android = _android;
    if (android == null) return;
    final existing = await android.getNotificationChannels() ?? const [];
    final pending = await _plugin.pendingNotificationRequests();
    final pendingSounds = [
      for (final request in pending)
        ?AlarmPayload.decode(request.payload)?.sound,
    ];
    final stale = staleSoundChannelIds(
      [for (final c in existing) c.id],
      [...inUse, ...pendingSounds],
    );
    for (final id in stale) {
      await android.deleteNotificationChannel(channelId: id);
    }
  }

  /// Whether [sound] can still be played. A failing check counts as playable
  /// only without a sounds service (nothing to ask); with one, the channel
  /// is the default unless the service says yes.
  Future<bool> _playable(String sound) async {
    final sounds = _sounds;
    if (sounds == null) return true;
    try {
      return await sounds
          .isAvailable(sound)
          .timeout(soundTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AlarmPermission> permissionStatus() async {
    await initialize();
    if (Platform.isAndroid) {
      final enabled = await _android?.areNotificationsEnabled();
      return enabled == false
          ? AlarmPermission.denied
          : AlarmPermission.granted;
    }
    if (Platform.isIOS) {
      final options = await _ios?.checkPermissions();
      return (options?.isEnabled ?? false)
          ? AlarmPermission.granted
          : AlarmPermission.denied;
    }
    return AlarmPermission.granted;
  }

  @override
  Future<AlarmPermission> requestPermission() async {
    await initialize();
    bool? granted;
    if (Platform.isAndroid) {
      await _system?.markNotificationsAsked();
      granted = await _android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      granted = await _ios?.requestPermissions(alert: true, sound: true);
    }
    if (granted == true) return AlarmPermission.granted;
    // A null result (older Android) means "no prompt needed": re-read.
    return permissionStatus();
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    await initialize();
    return _exactAllowed();
  }

  /// [canScheduleExactAlarms] without [initialize] (the background isolate
  /// of the snooze action must not initialize the plugin again).
  Future<bool> _exactAllowed() async {
    if (!Platform.isAndroid) return true;
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> requestExactAlarmPermission() async {
    await initialize();
    if (!Platform.isAndroid) return;
    await _android?.requestExactAlarmsPermission();
  }

  /// Notification details. With [snoozeLabel] and [awakeLabel] the
  /// notification has the two buttons: "Posponer" (Android: handled in the
  /// background, the notification goes away) and "Ya estoy despierto".
  ///
  /// A reminder ([kind] `reminder`) rings on its own channel with the default
  /// notification sound and no buttons. Any other alarm rings on the channel
  /// of its [sound] (null = the default one); [sound] must already be
  /// resolved (see `effectiveAlarmSound`).
  NotificationDetails _details({
    String? snoozeLabel,
    String? awakeLabel,
    AlarmKind kind = AlarmKind.shift,
    String? sound,
  }) {
    final strings = _strings;
    final buttons = snoozeLabel != null && awakeLabel != null;
    final reminder = kind == AlarmKind.reminder;
    final channelId = alarmChannelIdFor(kind, sound);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        // The channel already exists (configure created it with the
        // localized name); this is only read when it does not. No localized
        // copy is available in the snooze isolate.
        (reminder ? strings?.reminderChannelName : strings?.channelName) ??
            channelId,
        channelDescription: reminder
            ? strings?.reminderChannelDescription
            : strings?.channelDescription,
        icon: _androidSmallIcon,
        importance: reminder ? Importance.high : Importance.max,
        priority: Priority.high,
        category: reminder
            ? AndroidNotificationCategory.reminder
            : AndroidNotificationCategory.alarm,
        // On the lock screen only the app name shows when the user hides
        // sensitive notifications (the system puts its own neutral
        // placeholder: the plugin cannot attach a custom public version).
        visibility: NotificationVisibility.private,
        audioAttributesUsage: reminder
            ? AudioAttributesUsage.notification
            : AudioAttributesUsage.alarm,
        playSound: true,
        // Before Android 8 the sound belongs to the notification; from 8 on
        // the channel decides and this is ignored.
        sound: sound == null || reminder
            ? null
            : UriAndroidNotificationSound(sound),
        enableVibration: true,
        actions: buttons
            ? [
                AndroidNotificationAction(snoozeActionId, snoozeLabel),
                AndroidNotificationAction(awakeActionId, awakeLabel),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        categoryIdentifier: buttons ? alarmIosCategory : null,
        // Needs the Time Sensitive Notifications capability (Mac phase); the
        // system treats it as a normal notification without it.
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  @override
  Future<void> scheduleOneOff(OneOffAlarm alarm) async {
    final mode = await _exactAllowed()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.zonedSchedule(
      id: alarm.id,
      title: alarm.title,
      body: alarm.body,
      // An absolute instant: any zone gives the same one, and UTC needs no
      // time-zone database (the snooze isolate never loads it).
      scheduledDate: tz.TZDateTime.from(alarm.fireAt, tz.UTC),
      notificationDetails: _details(
        snoozeLabel: alarm.snoozeLabel,
        awakeLabel: alarm.awakeLabel,
        // No availability check here (no sounds service in the isolate of
        // the snooze button): the alarm just rang on this channel. If the
        // sound went away meanwhile, the channel falls back to the default
        // tone by itself.
        sound: alarm.sound,
      ),
      androidScheduleMode: mode,
      payload: alarm.payload,
    );
  }

  @override
  Future<void> cancelSnoozes() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(alarmSnoozePayloadPrefix) ?? false) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  @override
  Future<void> replaceAll(List<PlannedAlarm> alarms) => _mutex.run(() async {
    await initialize();
    final mode = await canScheduleExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final location = await _currentZone();
    // Custom sounds: the ones that can still be played get their own channel
    // (created before the first alarm that needs it); a missing one falls
    // back to the default channel instead of ringing on nothing.
    final unavailable = <String>{};
    final inUse = <String>{};
    for (final alarm in alarms) {
      final sound = alarm.kind == AlarmKind.reminder ? null : alarm.sound;
      if (sound == null ||
          inUse.contains(sound) ||
          unavailable.contains(sound)) {
        continue;
      }
      if (await _playable(sound)) {
        inUse.add(sound);
        try {
          await _ensureSoundChannel(sound);
        } catch (_) {
          // The default channel is the safe place to ring on.
          inUse.remove(sound);
          unavailable.add(sound);
        }
      } else {
        unavailable.add(sound);
      }
    }
    final wanted = <int>{};
    // Schedule first (the same id replaces), cancel the stale ones after:
    // if the app dies halfway there is never a window without alarms.
    Object? firstError;
    StackTrace? firstStack;
    for (final planned in alarms) {
      wanted.add(planned.id);
      // The payload carries the sound it really rings with, so a snooze
      // never brings a missing sound back.
      final sound = planned.kind == AlarmKind.reminder
          ? null
          : effectiveAlarmSound(planned.sound, unavailable);
      final alarm = sound == planned.sound ? planned : planned.withSound(sound);
      try {
        await _plugin.zonedSchedule(
          id: alarm.id,
          title: alarm.title,
          body: alarm.body,
          scheduledDate: resolveAlarmInstant(alarm, location),
          notificationDetails: _details(
            snoozeLabel: alarm.snoozeLabel,
            awakeLabel: alarm.awakeLabel,
            kind: alarm.kind,
            sound: sound,
          ),
          androidScheduleMode: mode,
          payload: alarm.payload,
        );
      } catch (error, stack) {
        // One bad alarm must not drop the rest; the first error is rethrown
        // below so the caller still reports it.
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final ours = request.payload?.startsWith(alarmPayloadPrefix) ?? false;
      if (ours && !wanted.contains(request.id)) {
        await _plugin.cancel(id: request.id);
      }
    }
    try {
      await _deleteStaleSoundChannels(inUse);
    } catch (_) {
      // Only housekeeping: an unused channel does no harm.
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
  });
}
