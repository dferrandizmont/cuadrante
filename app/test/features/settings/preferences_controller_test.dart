import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

/// A repository whose writes can be made to fail.
class _FlakyRepository extends PreferencesRepository {
  _FlakyRepository(super.db);

  bool failWrites = false;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    if (failWrites) throw StateError('disk full');
    return super.setThemeMode(mode);
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = openMemoryDatabase());
  tearDown(() => db.close());

  ProviderContainer container([List<Override> overrides = const []]) {
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts on the preferences bootstrap loaded', () {
    final c = container([
      initialPreferencesProvider.overrideWithValue(
        const Preferences(themeMode: ThemeMode.dark, weekStart: 7),
      ),
    ]);
    expect(c.read(preferencesProvider).themeMode, ThemeMode.dark);
    expect(c.read(preferencesProvider).weekStart, 7);
  });

  test('without bootstrap it reads the stored ones right after', () async {
    await PreferencesRepository(db).setThemeMode(ThemeMode.dark);
    final c = container();
    expect(c.read(preferencesProvider), Preferences.defaults);
    await pumpEventQueue();
    expect(c.read(preferencesProvider).themeMode, ThemeMode.dark);
  });

  test('changes are applied at once and persisted', () async {
    final c = container();
    final controller = c.read(preferencesProvider.notifier);

    final write = controller.setWeekStart(WeekStart.sunday);
    expect(c.read(preferencesProvider).weekStart, 7, reason: 'immediate');
    await write;
    await controller.setWeekNumbers(true);
    await controller.setThemeMode(ThemeMode.light);

    expect(
      await PreferencesRepository(db).load(),
      const Preferences(
        themeMode: ThemeMode.light,
        weekStart: 7,
        weekNumbers: true,
      ),
    );
  });

  test('a change made before the first read wins over it', () async {
    await PreferencesRepository(db).setThemeMode(ThemeMode.dark);
    final c = container();
    c.read(preferencesProvider);
    await c.read(preferencesProvider.notifier).setThemeMode(ThemeMode.light);
    await pumpEventQueue();
    expect(c.read(preferencesProvider).themeMode, ThemeMode.light);
  });

  test('a failed write puts the previous value back and tells', () async {
    final repository = _FlakyRepository(db);
    final c = container([
      preferencesRepositoryProvider.overrideWithValue(repository),
      initialPreferencesProvider.overrideWithValue(Preferences.defaults),
    ]);
    final controller = c.read(preferencesProvider.notifier);
    await controller.setThemeMode(ThemeMode.dark);

    repository.failWrites = true;
    await expectLater(
      controller.setThemeMode(ThemeMode.light),
      throwsStateError,
    );
    expect(c.read(preferencesProvider).themeMode, ThemeMode.dark);
    expect((await repository.load()).themeMode, ThemeMode.dark);
  });

  test('reload adopts what the database holds now (after a restore)', () async {
    final c = container([
      initialPreferencesProvider.overrideWithValue(Preferences.defaults),
    ]);
    final repository = PreferencesRepository(db);
    await repository.setWeekStart(WeekStart.sunday);
    await repository.setWeekNumbers(true);
    expect(c.read(preferencesProvider), Preferences.defaults);

    await c.read(preferencesProvider.notifier).reload();
    expect(c.read(preferencesProvider).weekStart, 7);
    expect(c.read(preferencesProvider).weekNumbers, isTrue);
  });
}
