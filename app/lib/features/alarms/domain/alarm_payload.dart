import 'dart:convert';

import '../../schedule/domain/civil_date.dart';

/// Prefix of the payload of every planned alarm: marks the notification as
/// ours (the scheduler only ever cancels notifications with this prefix).
const String alarmPayloadPrefix = 'cuadrante.alarm:';

/// Prefix of a snoozed alarm. Deliberately not [alarmPayloadPrefix]: a resync
/// replaces the planned alarms and must leave a snooze alone.
const String alarmSnoozePayloadPrefix = 'cuadrante.alarm.snooze:';

/// Prefix of the "Probar aviso" notification (same reason).
const String alarmTestPayloadPrefix = 'cuadrante.alarm.test:';

/// What an alarm is for.
enum AlarmKind {
  /// Rings `minutesBefore` minutes before the shift starts.
  shift,

  /// Rings the evening before, at a fixed local time.
  dayBefore,

  /// The reminder of a day's note (docs/paridad.md, A1). It belongs to a day,
  /// not to a shift: `shiftTypeId` is empty and `shiftDate` is the day of
  /// the note. No buttons, so it cannot be snoozed.
  reminder,
}

/// What travels inside a notification, so that a notification action can act
/// on it without opening the app: the snooze handler runs in a background
/// isolate with no database, no context and no localizations, so the texts it
/// needs to ring again (title, body and button labels) ride along.
///
/// Format: `<prefix><typeId>:<yyyy-MM-dd>:<kind>:<json>`. The first three
/// fields never contain a colon (`typeId` is percent-encoded), the JSON may.
class AlarmPayload {
  const AlarmPayload({
    required this.shiftTypeId,
    required this.shiftDate,
    required this.kind,
    required this.title,
    required this.body,
    this.snoozeLabel,
    this.awakeLabel,
    this.sound,
    this.segment = 0,
  });

  final String shiftTypeId;

  /// Day the shift starts.
  final CivilDate shiftDate;
  final AlarmKind kind;
  final String title;
  final String body;

  /// Labels of the notification buttons; null = the notification has none.
  final String? snoozeLabel;
  final String? awakeLabel;

  /// Custom sound (content URI) of the shift type, or null for the default.
  /// It rides along so that a snoozed copy, scheduled from a background
  /// isolate that knows nothing about shift types, rings on the same channel.
  final String? sound;

  /// Which part of a split shift the alarm is for: 0 the first (or the only)
  /// one, 1 the second. Part of the identity of the snoozed copy, so the two
  /// alarms of a split shift do not replace each other. Encoded under `g`
  /// only when it is not 0, so every other payload is byte-identical to the
  /// ones written before.
  final int segment;

  String encode({String prefix = alarmPayloadPrefix}) =>
      '$prefix${Uri.encodeComponent(shiftTypeId)}:${shiftDate.toIso()}:'
      '${kind.name}:'
      '${jsonEncode({'t': title, 'b': body, if (snoozeLabel != null) 's': snoozeLabel, if (awakeLabel != null) 'a': awakeLabel, if (sound != null) 'c': sound, if (segment != 0) 'g': segment})}';

  /// The same alarm, to be sent again as a snooze.
  String encodeAsSnooze() => encode(prefix: alarmSnoozePayloadPrefix);

  /// Null for anything that is not one of our planned or snoozed alarms (or
  /// that cannot be read): an action on it is ignored.
  static AlarmPayload? decode(String? payload) {
    if (payload == null) return null;
    final String rest;
    if (payload.startsWith(alarmPayloadPrefix)) {
      rest = payload.substring(alarmPayloadPrefix.length);
    } else if (payload.startsWith(alarmSnoozePayloadPrefix)) {
      rest = payload.substring(alarmSnoozePayloadPrefix.length);
    } else {
      return null;
    }
    final first = rest.indexOf(':');
    final second = first < 0 ? -1 : rest.indexOf(':', first + 1);
    final third = second < 0 ? -1 : rest.indexOf(':', second + 1);
    if (third < 0) return null;
    try {
      final kindName = rest.substring(second + 1, third);
      final kind = AlarmKind.values.where((k) => k.name == kindName);
      if (kind.isEmpty) return null;
      final json = jsonDecode(rest.substring(third + 1));
      if (json is! Map) return null;
      final title = json['t'];
      final body = json['b'];
      final snooze = json['s'];
      final awake = json['a'];
      final sound = json['c'];
      final segment = json['g'];
      return AlarmPayload(
        shiftTypeId: Uri.decodeComponent(rest.substring(0, first)),
        shiftDate: CivilDate.parse(rest.substring(first + 1, second)),
        kind: kind.first,
        title: title is String ? title : '',
        body: body is String ? body : '',
        snoozeLabel: snooze is String ? snooze : null,
        awakeLabel: awake is String ? awake : null,
        sound: sound is String && sound.isNotEmpty ? sound : null,
        segment: segment is int && segment > 0 ? segment : 0,
      );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}
