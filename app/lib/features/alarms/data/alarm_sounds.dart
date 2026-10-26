import 'package:flutter/services.dart';

import '../../schedule/domain/shift_type.dart' show maxAlarmSoundLength;

/// What the sound picker answered: [uri] is a `content://` URI of the system
/// (null = "the default sound"), [title] its display name when the system
/// gave one.
class AlarmSoundChoice {
  const AlarmSoundChoice({this.uri, this.title});

  final String? uri;
  final String? title;

  @override
  bool operator ==(Object other) =>
      other is AlarmSoundChoice && other.uri == uri && other.title == title;

  @override
  int get hashCode => Object.hash(uri, title);
}

/// The phone's own alarm / notification sounds (docs/alarmas.md, "Sonido por
/// tipo de turno"). On Android it talks to `MainActivity`
/// ([PlatformAlarmSounds]); elsewhere there is nothing to choose
/// ([NoAlarmSounds]) and the field of the shift type is kept but not used
/// (iOS will use bundled sounds, later, on the Mac).
abstract interface class AlarmSounds {
  /// Whether this platform lets the user choose a sound.
  bool get supported;

  /// Opens the system sound picker with [current] selected. `null` = the user
  /// went back; otherwise the choice (a null [AlarmSoundChoice.uri] is "the
  /// default sound").
  Future<AlarmSoundChoice?> pick({String? current});

  /// Display name of the sound at [uri], or null when it cannot be read.
  Future<String?> title(String uri);

  /// Whether the sound at [uri] can still be played (the file or the media it
  /// lives on may be gone). Anything that cannot be told is "not available".
  Future<bool> isAvailable(String uri);
}

/// The Android implementation: the `app.cuadrante/sounds` channel of
/// `MainActivity` (`ACTION_RINGTONE_PICKER`, `RingtoneManager`).
class PlatformAlarmSounds implements AlarmSounds {
  const PlatformAlarmSounds({this._channel = const MethodChannel(channelName)});

  static const String channelName = 'app.cuadrante/sounds';

  final MethodChannel _channel;

  @override
  bool get supported => true;

  @override
  Future<AlarmSoundChoice?> pick({String? current}) async {
    final Object? reply;
    try {
      reply = await _channel.invokeMethod<Object?>('pick', {
        'current': current,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
    if (reply is! Map) return null;
    final uri = reply['uri'];
    final title = reply['title'];
    return AlarmSoundChoice(
      uri: uri is String && uri.isNotEmpty && uri.length <= maxAlarmSoundLength
          ? uri
          : null,
      title: title is String && title.isNotEmpty ? title : null,
    );
  }

  @override
  Future<String?> title(String uri) async {
    try {
      final title = await _channel.invokeMethod<String>('title', {'uri': uri});
      return title == null || title.isEmpty ? null : title;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> isAvailable(String uri) async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable', {'uri': uri}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// No sound to choose (iOS, desktop, tests without a fake).
class NoAlarmSounds implements AlarmSounds {
  const NoAlarmSounds();

  @override
  bool get supported => false;

  @override
  Future<AlarmSoundChoice?> pick({String? current}) async => null;

  @override
  Future<String?> title(String uri) async => null;

  @override
  Future<bool> isAvailable(String uri) async => true;
}

/// In-memory sounds for tests: [choice] is what the next [pick] answers,
/// [titles] the names, [missing] the URIs that are gone.
class FakeAlarmSounds implements AlarmSounds {
  FakeAlarmSounds({
    this.supported = true,
    this.choice,
    Map<String, String>? titles,
    Set<String>? missing,
  }) : titles = titles ?? {},
       missing = missing ?? {};

  @override
  bool supported;

  /// The answer of the next [pick]; null = the user went back.
  AlarmSoundChoice? choice;
  final Map<String, String> titles;
  final Set<String> missing;

  /// The `current` of every [pick] call.
  final List<String?> pickCalls = [];

  @override
  Future<AlarmSoundChoice?> pick({String? current}) async {
    pickCalls.add(current);
    return choice;
  }

  @override
  Future<String?> title(String uri) async => titles[uri];

  @override
  Future<bool> isAvailable(String uri) async => !missing.contains(uri);
}
