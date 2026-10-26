import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

void main() {
  late AppDatabase db;
  late PreferencesRepository repository;

  setUp(() {
    db = openMemoryDatabase();
    repository = PreferencesRepository(db);
  });
  tearDown(() => db.close());

  Future<void> store(String key, String json) => db
      .into(db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion(key: Value(key), value: Value(json)),
      );

  Future<String?> stored(String key) async {
    final row = await (db.select(
      db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  test('nothing stored: the defaults', () async {
    expect(await repository.load(), Preferences.defaults);
    expect(Preferences.defaults.themeMode, ThemeMode.system);
    expect(Preferences.defaults.weekStart, 1);
    expect(Preferences.defaults.weekNumbers, isFalse);
  });

  test('every preference makes the round trip', () async {
    await repository.setThemeMode(ThemeMode.dark);
    await repository.setWeekStart(WeekStart.sunday);
    await repository.setWeekNumbers(true);

    expect(
      await repository.load(),
      const Preferences(
        themeMode: ThemeMode.dark,
        weekStart: 7,
        weekNumbers: true,
      ),
    );
    // And back.
    await repository.setThemeMode(ThemeMode.light);
    await repository.setWeekStart(WeekStart.monday);
    await repository.setWeekNumbers(false);
    expect(
      await repository.load(),
      const Preferences(themeMode: ThemeMode.light),
    );
  });

  test('stored as JSON under the documented keys', () async {
    await repository.setThemeMode(ThemeMode.dark);
    await repository.setWeekStart(WeekStart.sunday);
    await repository.setWeekNumbers(true);

    expect(await stored('appearance.themeMode'), '"dark"');
    expect(await stored('calendar.weekStart'), '7');
    expect(await stored('calendar.weekNumbers'), 'true');
    expect(PreferenceKeys.themeMode, 'appearance.themeMode');
    expect(PreferenceKeys.weekStart, 'calendar.weekStart');
    expect(PreferenceKeys.weekNumbers, 'calendar.weekNumbers');
  });

  test('writing twice keeps one row per key', () async {
    await repository.setWeekStart(WeekStart.sunday);
    await repository.setWeekStart(WeekStart.monday);
    final rows = await (db.select(
      db.settings,
    )..where((s) => s.key.equals('calendar.weekStart'))).get();
    expect(rows, hasLength(1));
    expect(rows.single.value, '1');
  });

  test('values the app does not offer fall back to the default', () async {
    await store('appearance.themeMode', '"sepia"');
    await store('calendar.weekStart', '3');
    await store('calendar.weekNumbers', '"yes"');
    expect(await repository.load(), Preferences.defaults);

    await store('appearance.themeMode', 'not json {');
    await store('calendar.weekStart', '7.5');
    await store('calendar.weekNumbers', 'null');
    expect(await repository.load(), Preferences.defaults);
  });

  test('one bad row does not spoil the others', () async {
    await store('appearance.themeMode', '"dark"');
    await store('calendar.weekStart', '"monday"');
    await store('calendar.weekNumbers', 'true');
    expect(
      await repository.load(),
      const Preferences(themeMode: ThemeMode.dark, weekNumbers: true),
    );
  });

  test('the language: "system" by default, stored by code', () async {
    expect(Preferences.defaults.language, AppLanguage.system);
    for (final language in AppLanguage.values) {
      await repository.setLanguage(language);
      expect((await repository.load()).language, language);
      expect(await stored('appearance.language'), '"${language.name}"');
    }
    expect(PreferenceKeys.language, 'appearance.language');
  });

  test('an unknown language is read as "system"', () async {
    await store('appearance.language', '"fr"');
    expect((await repository.load()).language, AppLanguage.system);
    await store('appearance.language', '7');
    expect((await repository.load()).language, AppLanguage.system);
  });

  test('other settings are left alone', () async {
    await store('alarms', '{"enabled":true}');
    await repository.setThemeMode(ThemeMode.dark);
    expect(await stored('alarms'), '{"enabled":true}');
  });

  test('only Monday and Sunday are accepted as the first day', () async {
    await expectLater(repository.setWeekStart(3), throwsArgumentError);
    expect(await stored('calendar.weekStart'), isNull);
  });
}
