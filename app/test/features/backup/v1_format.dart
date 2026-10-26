import 'dart:typed_data';

import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/canonical_json.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';

import 'backup_test_support.dart';

/// Format version 1, as the 0.1 / 0.2 releases wrote it, rebuilt from the
/// version 2 model so the tests can keep proving that those files read and
/// restore the same. Production code only reads version 1; it never writes
/// it any more.

/// The `data` object of a version 1 file: [data] without what version 2
/// added (`calendars`, `calendarId` on runs and days, `hourlyRateCents`).
/// Only meaningful for data with the single calendar `main` and no rates.
Map<String, Object?> v1DataJson(BackupData data) {
  final json = data.toJson();
  json.remove('calendars');
  for (final t in json['shiftTypes']! as List) {
    (t as Map<String, Object?>).remove('hourlyRateCents');
  }
  for (final key in ['patternRuns', 'dayEntries']) {
    for (final o in json[key]! as List) {
      (o as Map<String, Object?>).remove('calendarId');
    }
  }
  return json;
}

/// The checksum a version 1 writer put on [data].
String v1Checksum(BackupData data) =>
    BackupCodec.checksumOfJson(v1DataJson(data));

/// The canonical (uncompressed) bytes of a version 1 file.
Uint8List v1JsonBytes(
  BackupData data, {
  required String appVersion,
  required String exportedAt,
}) => canonicalJsonBytes(_v1Envelope(data, appVersion, exportedAt));

/// A version 1 `.cuadrante` file for [data].
Uint8List v1File(
  BackupData data, {
  String appVersion = '0.2.0',
  String exportedAt = '2026-10-19T09:00:00Z',
}) => gzipEnvelope(_v1Envelope(data, appVersion, exportedAt));

Map<String, Object?> _v1Envelope(
  BackupData data,
  String appVersion,
  String exportedAt,
) => {
  'format': BackupCodec.formatName,
  'schemaVersion': 1,
  'appVersion': appVersion,
  'exportedAt': exportedAt,
  'data': v1DataJson(data),
  'checksum': v1Checksum(data),
};

/// The digest the fingerprint of the restore matrix had in version 1: entities
/// as version 1 wrote them plus the resolved days of the calendar `main`.
/// `golden_v1.expected.json` records it; it must not change when a version 1
/// file is read by a later build.
String v1FingerprintDigest(
  BackupData data, {
  required CivilDate from,
  required CivilDate to,
}) {
  final entities = sha256Hex(canonicalJsonBytes(v1DataJson(data)));
  final days = resolvedDayLines(data.toSchedule(), from: from, to: to);
  return sha256Hex(
    canonicalJsonBytes({
      'from': from.toIso(),
      'to': to.toIso(),
      'entities': entities,
      'days': days,
    }),
  );
}
