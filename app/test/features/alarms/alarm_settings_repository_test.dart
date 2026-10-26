import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

void main() {
  late AppDatabase db;
  late AlarmSettingsRepository repository;

  setUp(() {
    db = openMemoryDatabase();
    repository = AlarmSettingsRepository(db);
  });
  tearDown(() => db.close());

  test('nothing stored: everything off, 14 days', () async {
    final settings = await repository.load();
    expect(settings, AlarmSettings.disabled);
    expect(settings.enabled, isFalse);
    expect(settings.horizonDays, 14);
    expect(settings.anyActive, isFalse);
  });

  test('round trip', () async {
    final settings = AlarmSettings(
      enabled: true,
      horizonDays: 7,
      byShiftType: {
        'night': const AlarmTypeSettings(
          enabled: true,
          minutesBefore: 120,
          label: 'Noche',
        ),
        'morning': const AlarmTypeSettings(enabled: false, minutesBefore: 45),
      },
    );
    await repository.save(settings);
    expect(await repository.load(), settings);
  });

  test('saving again replaces the row', () async {
    await repository.save(const AlarmSettings(enabled: true));
    await repository.save(const AlarmSettings(horizonDays: 3));
    expect(await repository.load(), const AlarmSettings(horizonDays: 3));
    expect(await db.select(db.settings).get(), hasLength(1));
  });

  test('a corrupt value reads as the defaults instead of throwing', () async {
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion(
            key: const Value(alarmSettingsKey),
            value: const Value('{not json'),
          ),
        );
    expect(await repository.load(), AlarmSettings.disabled);
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value(alarmSettingsKey),
            value: const Value('[1, 2]'),
          ),
        );
    expect(await repository.load(), AlarmSettings.disabled);
  });

  test('numbers that are not finite never break loading', () async {
    Future<void> store(String json) => db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(
            key: const Value(alarmSettingsKey),
            value: Value(json),
          ),
        );

    // 1e999 decodes to Infinity: no integer to round it to.
    await store('{"enabled":true,"horizonDays":1e999}');
    final infiniteHorizon = await repository.load();
    expect(infiniteHorizon.enabled, isTrue);
    expect(infiniteHorizon.horizonDays, AlarmSettings.defaultHorizonDays);

    await store(
      '{"enabled":true,"types":{"night":{"enabled":true,"minutesBefore":-1e999}}}',
    );
    final infiniteLead = await repository.load();
    expect(infiniteLead.forShiftType('night').enabled, isTrue);
    expect(
      infiniteLead.forShiftType('night').minutesBefore,
      AlarmTypeSettings.defaultMinutesBefore,
    );
  });

  test('fromJson ignores NaN and infinite numbers, clamps huge ones', () {
    final settings = AlarmSettings.fromJson({
      'enabled': true,
      'horizonDays': double.nan,
      'types': {
        'a': {'enabled': true, 'minutesBefore': double.infinity},
        'b': {'enabled': true, 'minutesBefore': double.nan},
        'c': {'enabled': true, 'minutesBefore': 1e30},
      },
    });
    expect(settings.horizonDays, AlarmSettings.defaultHorizonDays);
    expect(
      settings.forShiftType('a').minutesBefore,
      AlarmTypeSettings.defaultMinutesBefore,
    );
    expect(
      settings.forShiftType('b').minutesBefore,
      AlarmTypeSettings.defaultMinutesBefore,
    );
    expect(
      settings.forShiftType('c').minutesBefore,
      AlarmTypeSettings.maxMinutesBefore,
    );
    expect(
      AlarmSettings.fromJson({'horizonDays': 1e30}).horizonDays,
      AlarmSettings.maxHorizonDays,
    );
  });
}
