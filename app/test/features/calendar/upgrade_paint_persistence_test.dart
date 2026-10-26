import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/core/l10n/l10n.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_loader.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;

import '../../drift/app_database/generated/schema_v1.dart' as v1;
import '../../support/spanish_phone.dart';
import '../../support/test_storage.dart';
import '../../support/v1_database.dart';
import '../holidays/bundle_support.dart';
import 'harness.dart' show cell;

void main() {
  setUpAll(initializeLocale);

  testWidgets('U02: grey September tap is ignored; October paint survives '
      'closing and reopening a migrated v1 file', (tester) async {
    useSpanishPhone(tester);
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final dir = makeTempDir('u02-paint');
    final file = File(p.join(dir.path, databaseFileName));
    Future<AppDatabase> open() async {
      // Migrate through the real opener, including the mandatory safety copy.
      final migrated = await openAppDatabase(directory: dir);
      await migrated.customSelect('SELECT 1').get();
      await migrated.close();
      // Keep this widget test's queries on its isolate: the same file and
      // repository, without background-isolate replies in Flutter fake time.
      return AppDatabase(NativeDatabase(file));
    }

    late AppDatabase db;
    await tester.runAsync(() async {
      final old = v1.DatabaseAtV1(NativeDatabase(file));
      await seedV1(old);
      // U02 starts without a rotation: its grey neighbours and the new day
      // must really be empty, so painting the default brush cannot be a no-op.
      await old.customStatement('DELETE FROM pattern_runs');
      // The same seven days that U02 painted in 0.2.0.
      for (var day = 5; day <= 11; day++) {
        await old.customStatement(
          'INSERT OR REPLACE INTO day_entries '
          '(date, shift_type_ids, updated_at) VALUES (?, ?, ?)',
          ['2026-10-${day.toString().padLeft(2, '0')}', '["afternoon"]', 1],
        );
      }
      await old.close();
      db = await open();
    });
    addTearDown(() => tester.runAsync(db.close));
    final now = DateTime(2026, 10, 26, 11);
    Future<void> mount() async {
      final boot = (await tester.runAsync(
        () => bootstrapApp(
          config: const AppConfig(useDemoData: false),
          database: db,
          now: () => now,
          holidayLoader: HolidayBundleLoader(bundle: shippedBundle()),
        ),
      ))!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            initialScheduleProvider.overrideWithValue(boot.schedule),
            initialHolidaysProvider.overrideWithValue(boot.holidays),
            clockProvider.overrideWithValue(() => now),
          ],
          // Exercise the real month and paint controllers. Native background
          // hosts (widget/alarms/backup) are outside this persistence test.
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const MonthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    ScheduleController controller() =>
        ProviderScope.containerOf(tester.element(find.byType(MonthScreen)))
            .read(scheduleControllerProvider.notifier);
    ScheduleState state() =>
        ProviderScope.containerOf(tester.element(find.byType(MonthScreen)))
            .read(scheduleControllerProvider);
    const grey = CivilDate(2026, 9, 28);
    const target = CivilDate(2026, 10, 1);
    await mount();
    final before = state().schedule;
    expect(before.resolve(grey).shiftIds, isEmpty);
    expect(before.resolve(target).shiftIds, isEmpty);
    await tester.tap(find.text('Pintar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('tool-morning')));
    await tester.tap(find.byKey(const ValueKey('tool-morning')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(cell(grey));
    await tester.tap(cell(grey));
    await tester.pumpAndSettle();
    expect(state().schedule.entries, before.entries);
    expect(state().canUndo, isFalse);
    await tester.tap(cell(target));
    await tester.pumpAndSettle();
    expect(state().schedule.resolve(target).shiftIds, ['morning']);
    expect(state().canUndo, isTrue);
    var saved = false;
    controller().pendingWrites.then((_) => saved = true);
    for (var i = 0; i < 200 && !saved; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(saved, isTrue, reason: 'the committed stroke reaches the file');
    expect(state().saveErrors, 0);
    final painted = state().schedule;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await db.close();
      db = await open();
    });
    await mount();
    final reopened = state().schedule;
    expect(reopened.entries, painted.entries);
    expect(reopened.runs, painted.runs);
    expect(reopened.resolve(grey).shiftIds, before.resolve(grey).shiftIds);
    expect(reopened.resolve(target).shiftIds, ['morning']);
    for (var day = 5; day <= 11; day++) {
      expect(reopened.resolve(CivilDate(2026, 10, day)).shiftIds, [
        'afternoon',
      ]);
    }
    expect(tester.takeException(), isNull);
  });
}
