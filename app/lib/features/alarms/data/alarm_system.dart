import 'dart:async';

import 'package:flutter/services.dart';

/// How the device clock moved under the running app.
enum ClockChange { timezone, time }

/// What the alarms need from Android beyond the notifications plugin
/// (`app.cuadrante/alarm_system`, `AlarmSystemChannel.kt`): whether the
/// notification permission is blocked for good, the screen of the system
/// settings that fixes it, and a notice when the time zone or the time is
/// changed while the app is alive.
abstract interface class AlarmSystem {
  /// True when the notifications are off and asking for the permission again
  /// does nothing (denied twice, or switched off in the system settings):
  /// the user has to turn them on in the settings (H-T11-1).
  Future<bool> notificationsBlocked();

  /// Call right before showing the system prompt: lets the platform tell
  /// "never asked" from "denied for good".
  Future<void> markNotificationsAsked();

  /// Opens the app's notification settings. False if no screen opened.
  Future<bool> openNotificationSettings();

  /// A broadcast stream: the time zone or the time changed (H-T11-4).
  Stream<ClockChange> get clockChanges;
}

/// The Android implementation, over the platform channel.
class PlatformAlarmSystem implements AlarmSystem {
  PlatformAlarmSystem({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_onCall);
  }

  static const String channelName = 'app.cuadrante/alarm_system';

  final MethodChannel _channel;
  final StreamController<ClockChange> _changes =
      StreamController<ClockChange>.broadcast();

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method != 'clockChanged') return null;
    _changes.add(
      call.arguments == 'timezone' ? ClockChange.timezone : ClockChange.time,
    );
    return null;
  }

  @override
  Stream<ClockChange> get clockChanges => _changes.stream;

  @override
  Future<bool> notificationsBlocked() async {
    try {
      return await _channel.invokeMethod<bool>('notificationsBlocked') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> markNotificationsAsked() async {
    try {
      await _channel.invokeMethod<void>('markNotificationsAsked');
    } on PlatformException {
      // Best effort: without the mark the card just says «Permitir».
    } on MissingPluginException {
      // Same.
    }
  }

  @override
  Future<bool> openNotificationSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// Hosts without these system screens (tests, desktop, iOS for now).
class NoAlarmSystem implements AlarmSystem {
  const NoAlarmSystem();

  @override
  Stream<ClockChange> get clockChanges => const Stream<ClockChange>.empty();

  @override
  Future<bool> notificationsBlocked() async => false;

  @override
  Future<void> markNotificationsAsked() async {}

  @override
  Future<bool> openNotificationSettings() async => false;
}

/// For tests: the answers are fields and the clock notices are pushed by hand.
class FakeAlarmSystem implements AlarmSystem {
  bool blocked = false;
  int openedSettings = 0;
  int markedAsked = 0;
  final StreamController<ClockChange> _controller =
      StreamController<ClockChange>.broadcast();

  /// Pushes a clock notice, as the platform would.
  void emit(ClockChange change) => _controller.add(change);

  @override
  Stream<ClockChange> get clockChanges => _controller.stream;

  @override
  Future<bool> notificationsBlocked() async => blocked;

  @override
  Future<void> markNotificationsAsked() async => markedAsked++;

  @override
  Future<bool> openNotificationSettings() async {
    openedSettings++;
    return true;
  }
}
