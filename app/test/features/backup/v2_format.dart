import 'dart:typed_data';

import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/canonical_json.dart';

import 'backup_test_support.dart';

/// Format version 2, as the 0.3 – 0.5 releases wrote it, rebuilt from the
/// version 3 model so the tests can keep proving that those files read and
/// restore the same. Production code only reads version 2; it never writes
/// it any more.

/// The keys version 3 added to shift types and to days.
const _v3ShiftTypeKeys = [
  'icon',
  'alarmSound',
  'segment2StartMinute',
  'segment2DurationMinutes',
];
const _v3DayKeys = [
  'noteReminderMinute',
  'overtimeMinutes',
  'earlyLeaveMinutes',
];

/// The `data` object of a version 2 file: [data] without what version 3
/// added (the keys above).
Map<String, Object?> v2DataJson(BackupData data) {
  final json = data.toJson();
  for (final t in json['shiftTypes']! as List) {
    for (final key in _v3ShiftTypeKeys) {
      (t as Map<String, Object?>).remove(key);
    }
  }
  for (final e in json['dayEntries']! as List) {
    for (final key in _v3DayKeys) {
      (e as Map<String, Object?>).remove(key);
    }
  }
  return json;
}

/// The checksum a version 2 writer put on [data].
String v2Checksum(BackupData data) =>
    BackupCodec.checksumOfJson(v2DataJson(data));

/// The canonical (uncompressed) bytes of a version 2 file.
Uint8List v2JsonBytes(
  BackupData data, {
  required String appVersion,
  required String exportedAt,
}) => canonicalJsonBytes(_v2Envelope(data, appVersion, exportedAt));

/// A version 2 `.cuadrante` file for [data].
Uint8List v2File(
  BackupData data, {
  String appVersion = '0.3.0',
  String exportedAt = '2026-12-01T10:30:00Z',
}) => gzipEnvelope(_v2Envelope(data, appVersion, exportedAt));

Map<String, Object?> _v2Envelope(
  BackupData data,
  String appVersion,
  String exportedAt,
) => {
  'format': BackupCodec.formatName,
  'schemaVersion': 2,
  'appVersion': appVersion,
  'exportedAt': exportedAt,
  'data': v2DataJson(data),
  'checksum': v2Checksum(data),
};
