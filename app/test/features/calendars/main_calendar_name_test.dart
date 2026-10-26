import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';

/// H-T21-2 / H-T21-3: a NEW install names its first calendar in the app's
/// language; one that already exists is never renamed.
void main() {
  tearDown(() => debugPhoneLocales = const [Locale('es', 'ES')]);

  const names = {
    'es': 'Mi cuadrante',
    'ca': 'El meu quadrant',
    'gl': 'O meu cadro de quendas',
    'eu': 'Nire txanden egutegia',
    'en': 'My roster',
  };

  for (final entry in names.entries) {
    test('a new install on a ${entry.key} phone: «${entry.value}»', () async {
      debugPhoneLocales = [Locale(entry.key)];
      final db = openMemoryDatabase();
      addTearDown(db.close);
      await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: db,
        now: () => DateTime(2026, 10, 19, 12),
      );
      final calendars = await CalendarsRepository(db).list();
      expect(calendars.map((c) => c.id), [mainCalendarId]);
      expect(calendars.single.name, entry.value);
    });
  }

  test('opening it again in another language never renames it', () async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    Future<void> boot(String language) async {
      debugPhoneLocales = [Locale(language)];
      await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: db,
        now: () => DateTime(2026, 10, 19, 12),
      );
    }

    await boot('ca');
    await boot('gl');
    await boot('eu');
    await boot('en');
    await boot('es');
    final calendars = await CalendarsRepository(db).list();
    expect(calendars.single.name, 'El meu quadrant');
  });

  test('a calendar the person renamed keeps their name', () async {
    debugPhoneLocales = const [Locale('gl')];
    final db = openMemoryDatabase();
    addTearDown(db.close);
    await bootstrapApp(
      config: const AppConfig(useDemoData: false),
      database: db,
      now: () => DateTime(2026, 10, 19, 12),
    );
    await CalendarsRepository(db).rename(mainCalendarId, 'Hospital');
    debugPhoneLocales = const [Locale('en')];
    await bootstrapApp(
      config: const AppConfig(useDemoData: false),
      database: db,
      now: () => DateTime(2026, 10, 19, 12),
    );
    final calendars = await CalendarsRepository(db).list();
    expect(calendars.single.name, 'Hospital');
  });
}
