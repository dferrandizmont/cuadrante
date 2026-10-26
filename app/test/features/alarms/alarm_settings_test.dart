import 'dart:convert';

import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

const _d1 = CivilDate(2026, 10, 21);
const _d2 = CivilDate(2026, 10, 22);

void main() {
  group('AlarmTypeSettings', () {
    test('day-before reminder: off at 20:00 by default', () {
      const s = AlarmTypeSettings();
      expect(s.dayBefore, isFalse);
      expect(s.dayBeforeMinute, 20 * 60);
      expect(
        s.copyWith(dayBefore: true, dayBeforeMinute: 21 * 60 + 15),
        isNot(s),
      );
    });

    test('JSON round trip keeps every field', () {
      const s = AlarmTypeSettings(
        enabled: true,
        minutesBefore: 75,
        label: 'A trabajar',
        dayBefore: true,
        dayBeforeMinute: 21 * 60 + 15,
      );
      expect(s.toJson(), {
        'enabled': true,
        'minutesBefore': 75,
        'label': 'A trabajar',
        'dayBefore': true,
        'dayBeforeMinute': 21 * 60 + 15,
      });
      expect(AlarmTypeSettings.fromJson(s.toJson()), s);
    });

    test('settings stored before the day-before reminder read as off', () {
      final s = AlarmTypeSettings.fromJson({
        'enabled': true,
        'minutesBefore': 60,
      });
      expect(s.enabled, isTrue);
      expect(s.minutesBefore, 60);
      expect(s.dayBefore, isFalse);
      expect(s.dayBeforeMinute, AlarmTypeSettings.defaultDayBeforeMinute);
    });

    test('is tolerant with wrong types and out-of-range values', () {
      final wrong = AlarmTypeSettings.fromJson({
        'enabled': 'yes',
        'dayBefore': 1,
        'dayBeforeMinute': 'noon',
        'minutesBefore': null,
      });
      expect(wrong.enabled, isFalse);
      expect(wrong.dayBefore, isFalse);
      expect(wrong.dayBeforeMinute, 20 * 60);
      expect(wrong.minutesBefore, AlarmTypeSettings.defaultMinutesBefore);

      expect(
        AlarmTypeSettings.fromJson({'dayBeforeMinute': 99999}).dayBeforeMinute,
        1439,
      );
      expect(
        AlarmTypeSettings.fromJson({'dayBeforeMinute': -30}).dayBeforeMinute,
        0,
      );
      expect(
        AlarmTypeSettings.fromJson({'dayBeforeMinute': double.nan})
            .dayBeforeMinute,
        20 * 60,
      );
    });
  });

  group('AlarmSettings skipped days', () {
    test('JSON shape: sorted ISO dates under "skipped"', () {
      final s = const AlarmSettings(
        enabled: true,
        byShiftType: {
          'night': AlarmTypeSettings(
            enabled: true,
            minutesBefore: 90,
            dayBefore: true,
          ),
        },
      ).withSkipped(_d2, skipped: true).withSkipped(_d1, skipped: true);
      expect(s.toJson(), {
        'version': 1,
        'enabled': true,
        'horizonDays': 14,
        'types': {
          'night': {
            'enabled': true,
            'minutesBefore': 90,
            'dayBefore': true,
            'dayBeforeMinute': 1200,
          },
        },
        'skipped': ['2026-10-21', '2026-10-22'],
      });
      // Through real JSON text, like the database does.
      final decoded = jsonDecode(jsonEncode(s.toJson())) as Map;
      expect(AlarmSettings.fromJson(decoded.cast<String, Object?>()), s);
    });

    test('old JSON without "skipped" has no skipped days', () {
      final s = AlarmSettings.fromJson({
        'enabled': true,
        'horizonDays': 7,
        'types': {
          'night': {'enabled': true, 'minutesBefore': 45},
        },
      });
      expect(s.skippedDates, isEmpty);
      expect(s.forShiftType('night').minutesBefore, 45);
    });

    test('malformed entries are ignored, valid ones kept', () {
      final s = AlarmSettings.fromJson({
        'skipped': [
          '2026-10-21',
          '2026-13-40',
          'mañana',
          42,
          null,
          '2026-10-21',
          '2026-10-22',
        ],
      });
      expect(s.skippedDates, {_d1, _d2});
      expect(AlarmSettings.fromJson({'skipped': 'nope'}).skippedDates, isEmpty);
      expect(
        AlarmSettings.fromJson({
          'skipped': {'a': 1},
        }).skippedDates,
        isEmpty,
      );
    });

    test('reading is capped, so a corrupt row cannot grow without bound', () {
      final s = AlarmSettings.fromJson({
        'skipped': [
          for (var i = 0; i < 1000; i++)
            CivilDate(2026, 1, 1).addDays(i).toIso(),
        ],
      });
      expect(s.skippedDates.length, AlarmSettings.maxSkippedDates);
    });

    test(
      'withSkipped adds and removes, and is a no-op when nothing changes',
      () {
        const base = AlarmSettings(enabled: true);
        final skipped = base.withSkipped(_d1, skipped: true);
        expect(skipped.isSkipped(_d1), isTrue);
        expect(skipped.isSkipped(_d2), isFalse);
        expect(
          identical(skipped.withSkipped(_d1, skipped: true), skipped),
          isTrue,
        );
        expect(skipped.withSkipped(_d1, skipped: false), base);
        expect(identical(base.withSkipped(_d1, skipped: false), base), isTrue);
      },
    );

    test('pruneSkipped drops the days before today and keeps today', () {
      final s = const AlarmSettings()
          .withSkipped(const CivilDate(2026, 10, 1), skipped: true)
          .withSkipped(const CivilDate(2026, 10, 18), skipped: true)
          .withSkipped(const CivilDate(2026, 10, 19), skipped: true)
          .withSkipped(const CivilDate(2026, 11, 2), skipped: true);
      final pruned = s.pruneSkipped(const CivilDate(2026, 10, 19));
      expect(pruned.skippedDates, {
        const CivilDate(2026, 10, 19),
        const CivilDate(2026, 11, 2),
      });
      // Nothing old: the very same object.
      expect(
        identical(pruned.pruneSkipped(const CivilDate(2026, 10, 19)), pruned),
        isTrue,
      );
    });

    test('equality and hash include the skipped days', () {
      final a = const AlarmSettings().withSkipped(_d1, skipped: true);
      final b = const AlarmSettings().withSkipped(_d1, skipped: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const AlarmSettings()));
      expect(a, isNot(a.withSkipped(_d2, skipped: true)));
    });
  });

  group('repository', () {
    late AppDatabase db;
    late AlarmSettingsRepository repository;

    setUp(() {
      db = openMemoryDatabase();
      repository = AlarmSettingsRepository(db);
    });
    tearDown(() => db.close());

    test('stores and reads back the new fields', () async {
      final settings = const AlarmSettings(
        enabled: true,
        byShiftType: {
          'night': AlarmTypeSettings(
            enabled: true,
            minutesBefore: 120,
            label: 'Noche',
            dayBefore: true,
            dayBeforeMinute: 19 * 60 + 30,
          ),
        },
      ).withSkipped(_d1, skipped: true);
      await repository.save(settings);
      expect(await repository.load(), settings);
    });

    test('a row written by the previous version still loads', () async {
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion(
              key: const Value(alarmSettingsKey),
              value: Value(
                jsonEncode({
                  'version': 1,
                  'enabled': true,
                  'horizonDays': 14,
                  'types': {
                    'night': {
                      'enabled': true,
                      'minutesBefore': 90,
                      'label': 'Noche',
                    },
                  },
                }),
              ),
            ),
          );
      final s = await repository.load();
      expect(s.enabled, isTrue);
      expect(s.forShiftType('night').enabled, isTrue);
      expect(s.forShiftType('night').dayBefore, isFalse);
      expect(s.skippedDates, isEmpty);
    });
  });
}
