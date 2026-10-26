import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/l10n/catalog_texts.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/onboarding/data/onboarding_repository.dart';
import 'package:cuadrante/features/import/presentation/import_screen.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/settings/data/preferences_repository.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import 'onboarding_support.dart';

const _factoryKey = 'onboarding.factoryCatalog';

Future<Object> _catalog(AppDatabase db) async => {
  for (final table in ['shift_types', 'patterns', 'calendars'])
    table: [
      for (final row
          in await db.customSelect('SELECT * FROM $table ORDER BY id').get())
        row.data,
    ],
};

Future<BootstrapResult> _boot(AppDatabase db) => bootstrapApp(
  database: db,
  config: const AppConfig(useDemoData: false),
  now: () => onboardingNow,
);

void main() {
  setUpAll(initializeLocale);

  for (final action in ['onboarding-import', 'onboarding-import-lrhsoft']) {
    testWidgets('factory language is settled before $action opens', (
      tester,
    ) async {
      final app = await FirstLaunch.open(tester);
      await app.tap(key('onboarding-language'));
      await app.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Euskara'),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await app.tap(key('onboarding-skip'));
      }
      await app.tap(key(action));
      expect(find.byType(ImportScreen), findsOneWidget);
      final l10n = lookupAppLocalizations(const Locale('eu'));
      expect(
        app.schedule.shiftTypes.firstWhere((s) => s.id == 'morning').name,
        l10n.catalogShiftMorningName,
      );
      expect(
        (await app.real(() => CalendarsRepository(app.database).get('main')))!
            .name,
        l10n.catalogCalendarMainName,
      );
      expect(
        (await app.real(() => app.database.select(app.database.settings).get()))
            .any((row) => row.key == _factoryKey),
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final before = await app.real(() => _catalog(app.database));
      expect(
        await app.real(
          () => OnboardingRepository(app.database).finalizeFactoryCatalog(
            catalogTextsFrom(lookupAppLocalizations(const Locale('en'))),
          ),
        ),
        isFalse,
      );
      expect(await app.real(() => _catalog(app.database)), before);
      expect(tester.takeException(), isNull);
    });
  }
  for (final language in [
    AppLanguage.eu,
    AppLanguage.en,
    AppLanguage.ca,
    AppLanguage.gl,
  ]) {
    testWidgets(
      'onboarding chooses ${language.name}, persists it and freezes factory names',
      (tester) async {
        final app = await FirstLaunch.open(tester);
        final l10n = lookupAppLocalizations(language.locale!);
        final endonym = switch (language) {
          AppLanguage.eu => 'Euskara',
          AppLanguage.en => 'English',
          AppLanguage.ca => 'Català',
          _ => 'Galego',
        };
        await app.tap(key('onboarding-language'));
        await app.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(endonym),
          ),
        );
        expect(app.title, l10n.onboardingProfessionTitle);
        if (language == AppLanguage.eu) {
          await app.tap(key('onboarding-profession-nursing'));
          await app.tap(key('onboarding-next'));
          await app.tap(key('onboarding-skip'));
          await app.tap(key('onboarding-pattern-12h'));
          await app.tap(key('onboarding-next'));
          await app.tap(key('onboarding-next'));
          await app.tap(key('onboarding-next'));
        } else {
          for (var i = 0; i < 4; i++) {
            await app.tap(key('onboarding-skip'));
          }
        }
        expect(app.title, l10n.onboardingReadyTitle);
        expect(
          app.schedule.shiftTypes.firstWhere((t) => t.id == 'morning').name,
          l10n.catalogShiftMorningName,
        );
        expect(
          app.schedule.shiftTypes.firstWhere((t) => t.id == 'morning').code,
          l10n.catalogShiftMorningCode,
        );
        final calendar = await app.real(
          () => CalendarsRepository(app.database).get('main'),
        );
        expect(calendar!.name, l10n.catalogCalendarMainName);
        final beforeRestart = await app.real(() => _catalog(app.database));
        await tester.pumpWidget(const SizedBox.shrink());
        final restarted = await app.real(() => _boot(app.database));
        expect(restarted.preferences.language, language);
        expect(restarted.onboarding.needed, isFalse);
        expect(await app.real(() => _catalog(app.database)), beforeRestart);
        // Later language changes apply to the interface, preserving all data.
        await app.real(
          () => PreferencesRepository(app.database).setLanguage(AppLanguage.es),
        );
        await app.real(() => _boot(app.database));
        expect(await app.real(() => _catalog(app.database)), beforeRestart);
        expect(
          (await app.real(
            () => app.database.select(app.database.settings).get(),
          )).any((r) => r.key == _factoryKey),
          isFalse,
        );
      },
    );
  }

  testWidgets(
    'skipping without choosing a language keeps the system factory language',
    (tester) async {
      final app = await FirstLaunch.open(tester);
      for (var i = 0; i < 4; i++) {
        await app.tap(key('onboarding-skip'));
      }
      final l10n = lookupAppLocalizations(const Locale('es'));
      expect(
        app.schedule.shiftTypes.firstWhere((t) => t.id == 'night').name,
        l10n.catalogShiftNightName,
      );
      expect(
        (await app.real(() => CalendarsRepository(app.database).get('main')))!
            .name,
        l10n.catalogCalendarMainName,
      );
      expect(
        (await app.real(() => PreferencesRepository(app.database).load()))
            .language,
        AppLanguage.system,
      );
    },
  );

  test(
    'an existing empty database is not granted factory provenance',
    () async {
      final file = File(
        '${makeTempDir('existing-empty-onboarding').path}/app.sqlite',
      );
      final old = AppDatabase(NativeDatabase(file));
      await old.customSelect('SELECT * FROM calendars').get();
      await CalendarsRepository(old).rename('main', 'Mi calendario personal');
      await old.close();
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      await _boot(db);
      expect(db.createdThisOpen, isFalse);
      final before = await _catalog(db);
      final repository = OnboardingRepository(db);
      expect(
        await repository.finalizeFactoryCatalog(
          catalogTextsFrom(lookupAppLocalizations(const Locale('eu'))),
        ),
        isFalse,
      );
      expect(await _catalog(db), before);
      expect(
        (await CalendarsRepository(db).get('main'))!.name,
        'Mi calendario personal',
      );
    },
  );

  test(
    'an unfinished first launch can resume in its chosen language',
    () async {
      final file = File('${makeTempDir('resume-onboarding').path}/app.sqlite');
      final first = AppDatabase(NativeDatabase(file));
      await _boot(first);
      await PreferencesRepository(first).setLanguage(AppLanguage.eu);
      await first.close();
      final resumed = AppDatabase(NativeDatabase(file));
      addTearDown(resumed.close);
      final boot = await _boot(resumed);
      expect(boot.preferences.language, AppLanguage.eu);
      expect(boot.onboarding.needed, isTrue);
      expect(resumed.createdThisOpen, isFalse);
      final texts = lookupAppLocalizations(const Locale('eu'));
      expect(
        await OnboardingRepository(resumed)
            .finalizeFactoryCatalog(catalogTextsFrom(texts)),
        isTrue,
      );
      expect(
        (await CalendarsRepository(resumed).get('main'))!.name,
        texts.catalogCalendarMainName,
      );
      expect(
        (await ScheduleRepository(resumed).load('main')).schedule
            .shiftTypeById('night')!
            .name,
        texts.catalogShiftNightName,
      );
    },
  );

  test(
    'backup excludes provenance and restoring ends provisional setup',
    () async {
      final db = openMemoryDatabase();
      addTearDown(db.close);
      await _boot(db);
      final backups = BackupRepository(
        db,
        safetyDirectory: makeTempDir('factory-backup'),
        appVersion: 'test',
      );
      final backup = await backups.readAll();
      expect(backup.settings.containsKey(_factoryKey), isFalse);
      await backups.restore(backup);
      // RestoreCoordinator marks onboarding done after every successful
      // restore, including one with exactly the same visible factory values.
      await OnboardingRepository(db).markDone();
      final before = await _catalog(db);
      expect(
        await OnboardingRepository(db).finalizeFactoryCatalog(
          catalogTextsFrom(lookupAppLocalizations(const Locale('eu'))),
        ),
        isFalse,
      );
      expect(await _catalog(db), before);
      expect(
        (await db.select(db.settings).get()).any((r) => r.key == _factoryKey),
        isFalse,
      );
    },
  );

  for (final change in [
    'edited shift',
    'edited calendar',
    'imported type',
    'imported day',
    'done',
  ]) {
    test(
      'factory provenance is consumed without renaming after $change',
      () async {
        final db = openMemoryDatabase();
        addTearDown(db.close);
        await _boot(db);
        final repository = OnboardingRepository(db);
        switch (change) {
          case 'edited shift':
            await db.customStatement(
              "UPDATE shift_types SET name = 'Turno personal' WHERE id = 'morning'",
            );
          case 'edited calendar':
            await CalendarsRepository(db).rename('main', 'Familia');
          case 'imported type':
            await ScheduleRepository(db).saveShiftType(
              const ShiftType(
                id: 'imported',
                name: 'Imported',
                code: 'IMP',
                colorValue: 0xff123456,
                category: ShiftCategory.work,
              ),
            );
          case 'imported day':
            await ScheduleRepository(db).apply(
              'main',
              ScheduleChange(
                patch: EntriesPatch({
                  onboardingToday: EntryChange(
                    null,
                    DayEntry(
                      date: onboardingToday,
                      shiftTypeIds: const ['night'],
                      note: 'Personal',
                    ),
                  ),
                }),
              ),
            );
          case 'done':
            await repository.markDone();
        }
        final before = await _catalog(db);
        final daysBefore = await db
            .customSelect('SELECT * FROM day_entries ORDER BY date')
            .get();
        expect(
          await repository.finalizeFactoryCatalog(
            catalogTextsFrom(lookupAppLocalizations(const Locale('eu'))),
          ),
          isFalse,
        );
        expect(await _catalog(db), before);
        expect(
          (await db
                  .customSelect('SELECT * FROM day_entries ORDER BY date')
                  .get())
              .map((r) => r.data)
              .toList(),
          daysBefore.map((r) => r.data).toList(),
        );
        expect(
          (await db.select(db.settings).get()).any((r) => r.key == _factoryKey),
          isFalse,
        );
      },
    );
  }
}
