import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_format.dart';
import 'package:cuadrante/features/holidays/data/holiday_bundle_loader.dart';
import 'package:cuadrante/features/holidays/data/holiday_repository.dart';
import 'package:cuadrante/features/holidays/data/holiday_snapshot.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/holidays/domain/holiday_place.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart' show openMemoryDatabase;
import 'bundle_support.dart';

const _manifest = 'assets/holidays/manifest.json';

/// The shipped bundle with a different `bundleVersion` (and optionally an
/// extra national day in 2026), hashes kept consistent.
MemoryAssetBundle _newerBundle({bool extraDay = false}) {
  final bundle = shippedBundle();
  if (extraDay) {
    const path = 'assets/holidays/2026/es.json';
    final es = utf8
        .decode(bundle.files[path]!)
        .replaceFirst(
          '"national":[\n',
          '"national":[\n{"date":"2026-03-10","name":"Día nuevo"},\n',
        );
    bundle.files[path] = utf8.encode(es);
  }
  final manifest =
      jsonDecode(utf8.decode(bundle.files[_manifest]!)) as Map<String, Object?>;
  manifest['bundleVersion'] = '2099-01-01.newer';
  if (extraDay) {
    final files = (manifest['files']! as List).cast<Map<String, Object?>>();
    final es = files.firstWhere((f) => f['path'] == '2026/es.json');
    final bytes = bundle.files['assets/holidays/2026/es.json']!;
    es['bytes'] = bytes.length;
    es['sha256'] = _sha(bytes);
  }
  bundle.files[_manifest] = utf8.encode(jsonEncode(manifest));
  return bundle;
}

String _sha(List<int> bytes) => sha256.convert(bytes).toString();

Future<List<Map<String, Object?>>> _rows(AppDatabase db, String where) async =>
    [
      for (final r
          in await db
              .customSelect('SELECT * FROM holidays WHERE $where ORDER BY id')
              .get())
        r.data,
    ];

Future<int> _count(AppDatabase db, [String where = '1=1']) async =>
    (await _rows(db, where)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HolidayRepository repo;
  late HolidayBundleLoader loader;

  setUp(() {
    db = openMemoryDatabase();
    repo = HolidayRepository(db);
    loader = HolidayBundleLoader(bundle: shippedBundle());
  });
  tearDown(() => db.close());

  group('refreshBundled', () {
    test('fills the table from the bundle and stores the version', () async {
      expect(await repo.refreshBundled(loader), isTrue);

      final manifest = await loader.readManifest();
      final bundle = await loader.load(manifest: manifest);
      expect(await _count(db, "source = 'bundled'"), bundle.entries.length);
      expect(await _count(db, "source <> 'bundled'"), 0);
      final version = await db
          .customSelect(
            "SELECT value FROM settings WHERE key = 'holidays.bundleVersion'",
          )
          .getSingle();
      expect(jsonDecode(version.read<String>('value')), manifest.bundleVersion);
      // National rows have no region; a regional one has; a local one both.
      expect(
        await _count(db, "scope = 'national' AND region_code IS NULL"),
        15,
      );
      expect(
        await _rows(db, "municipality_code = '08019' AND date = '2026-05-25'"),
        hasLength(1),
      );
    });

    test('skips when the version is unchanged', () async {
      await repo.refreshBundled(loader);
      final before = await _rows(db, '1=1');

      expect(await repo.refreshBundled(loader), isFalse);
      // Not even the bundle files are read: a broken one cannot hurt.
      final broken = HolidayBundleLoader(
        bundle: MemoryAssetBundle({
          _manifest: shippedBundleFiles()[_manifest]!,
        }),
      );
      expect(await repo.refreshBundled(broken), isFalse);
      expect(await _rows(db, '1=1'), before);
    });

    test('forcing it is idempotent: same rows, no duplicates', () async {
      await repo.refreshBundled(loader);
      final count = await _count(db);

      expect(await repo.refreshBundled(loader, force: true), isTrue);
      expect(await repo.refreshBundled(loader, force: true), isTrue);
      expect(await _count(db), count);
    });

    test('a new bundleVersion replaces the bundled rows', () async {
      await repo.refreshBundled(loader);
      final count = await _count(db);

      final newer = HolidayBundleLoader(bundle: _newerBundle(extraDay: true));
      expect(await repo.refreshBundled(newer), isTrue);

      expect(await _count(db), count + 1);
      expect(await _count(db, "date = '2026-03-10'"), 1);
      expect(await repo.refreshBundled(newer), isFalse);
    });

    test('never touches user rows, whatever happens', () async {
      await repo.addUserHoliday(
        date: const CivilDate(2026, 7, 7),
        name: 'San Fermín',
      );
      await repo.refreshBundled(loader);
      await repo.refreshBundled(loader, force: true);
      await repo.refreshBundled(
        HolidayBundleLoader(bundle: _newerBundle(extraDay: true)),
      );

      final user = await repo.userHolidays();
      expect(user, hasLength(1));
      expect(user.single.name, 'San Fermín');
      expect(user.single.source, HolidaySource.user);
    });

    test('remote rows are left alone too', () async {
      await db.customStatement(
        'INSERT INTO holidays (date, scope, name, source) '
        "VALUES ('2026-03-03', 'national', 'descargado', 'remote')",
      );
      await repo.refreshBundled(loader);
      expect(await _count(db, "source = 'remote'"), 1);
    });

    test('a bundle that fails its checksum writes nothing', () async {
      await repo.refreshBundled(loader);
      final before = await _rows(db, '1=1');

      final tampered = _newerBundle();
      final bytes = List<int>.of(
        tampered.files['assets/holidays/2026/es.json']!,
      );
      bytes[bytes.indexOf('A'.codeUnitAt(0))] = 'B'.codeUnitAt(0);
      tampered.files['assets/holidays/2026/es.json'] = bytes;

      await expectLater(
        repo.refreshBundled(HolidayBundleLoader(bundle: tampered)),
        throwsA(isA<HolidayBundleException>()),
      );
      expect(await _rows(db, '1=1'), before);
      // The stored version is still the old one: it will try again.
      expect(await repo.refreshBundled(loader), isFalse);
    });

    test('empty bundled rows with a current version are refilled', () async {
      await repo.refreshBundled(loader);
      await db.customStatement("DELETE FROM holidays WHERE source = 'bundled'");
      expect(await repo.refreshBundled(loader), isTrue);
      expect(await _count(db, "source = 'bundled'"), greaterThan(0));
    });
  });

  group('place', () {
    test('nothing chosen by default', () async {
      expect(await repo.loadPlace(), HolidayPlace.none);
    });

    test(
      'is stored in settings holidays.region / holidays.municipality',
      () async {
        await repo.savePlace(regionCode: 'es-ct', municipalityCode: '08019');

        expect(
          await repo.loadPlace(),
          const HolidayPlace(regionCode: 'ES-CT', municipalityCode: '08019'),
        );
        final rows = await db
            .customSelect(
              "SELECT key, value FROM settings WHERE key LIKE 'holidays.%' ORDER BY key",
            )
            .get();
        expect(
          {
            for (final r in rows)
              r.read<String>('key'): r.read<String>('value'),
          },
          {'holidays.municipality': '"08019"', 'holidays.region': '"ES-CT"'},
        );
      },
    );

    test('a municipality alone implies its region; null clears', () async {
      final place = await repo.savePlace(municipalityCode: '28079');
      expect(place.regionCode, 'ES-MD');

      await repo.savePlace();
      expect(await repo.loadPlace(), HolidayPlace.none);
      expect(
        await db
            .customSelect(
              "SELECT * FROM settings WHERE key LIKE 'holidays.region' OR key LIKE 'holidays.municipality'",
            )
            .get(),
        isEmpty,
      );
    });

    test('rejects codes that do not exist or do not match', () async {
      expect(() => repo.savePlace(regionCode: 'ES-XX'), throwsArgumentError);
      expect(
        () => repo.savePlace(municipalityCode: '123'),
        throwsArgumentError,
      );
      expect(
        () => repo.savePlace(regionCode: 'ES-MD', municipalityCode: '08019'),
        throwsArgumentError,
      );
      expect(await repo.loadPlace(), HolidayPlace.none);
    });
  });

  group('entriesFor', () {
    setUp(() => repo.refreshBundled(loader));

    test('no region: only the national file', () async {
      final entries = await repo.entriesFor(HolidayPlace.none);
      expect(entries, hasLength(15));
      expect(entries.every((e) => e.scope == HolidayScope.national), isTrue);
      expect(entries.every((e) => e.regionCode == null), isTrue);
    });

    test('a region and municipality: theirs and nobody else\'s', () async {
      final entries = await repo.entriesFor(
        const HolidayPlace(regionCode: 'ES-CT', municipalityCode: '08019'),
      );
      expect(
        entries.every((e) => e.regionCode == null || e.regionCode == 'ES-CT'),
        isTrue,
      );
      final locals = entries.where((e) => e.scope == HolidayScope.local);
      expect(locals.map((e) => e.municipalityCode).toSet(), {'08019'});
      expect(locals.map((e) => e.date.toIso()), ['2026-05-25', '2026-09-24']);
    });

    test('a region without municipality: no local rows', () async {
      final entries = await repo.entriesFor(
        const HolidayPlace(regionCode: 'ES-MD'),
      );
      expect(entries.where((e) => e.scope == HolidayScope.local), isEmpty);
      expect(entries.where((e) => e.regionCode == 'ES-MD'), isNotEmpty);
    });
  });

  group('user holidays', () {
    const day = CivilDate(2026, 10, 12);

    test('add shows in every place and wins over the official one', () async {
      await repo.refreshBundled(loader);
      await repo.addUserHoliday(date: day, name: '  Mi patrón ');

      for (final place in const [
        HolidayPlace.none,
        HolidayPlace(regionCode: 'ES-CT', municipalityCode: '08019'),
      ]) {
        final snapshot = HolidaySnapshot(
          place: place,
          entries: await repo.entriesFor(place),
        ).calendar;
        final h = snapshot.on(day)!;
        expect(h.name, 'Mi patrón');
        expect(h.isUserAdded, isTrue);
        expect(h.scope, HolidayScope.local);
      }
    });

    test(
      'one per day: adding again replaces; remove brings the official back',
      () async {
        await repo.refreshBundled(loader);
        await repo.addUserHoliday(date: day, name: 'Uno');
        await repo.addUserHoliday(date: day, name: 'Dos');
        expect((await repo.userHolidays()).map((e) => e.name), ['Dos']);

        await repo.removeUserHoliday(day);
        expect(await repo.userHolidays(), isEmpty);
        final back = HolidaySnapshot(
          place: HolidayPlace.none,
          entries: await repo.entriesFor(HolidayPlace.none),
        ).calendar.on(day);
        expect(back?.name, 'Fiesta Nacional de España');
        // Removing never deletes official rows.
        expect(
          await _count(db, "date = '2026-10-12' AND source = 'bundled'"),
          1,
        );
      },
    );

    test('an empty name is refused', () async {
      expect(
        () => repo.addUserHoliday(date: day, name: '   '),
        throwsArgumentError,
      );
    });
  });

  group('providers', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'holidaysProvider follows the chosen place and user holidays',
      () async {
        await repo.refreshBundled(loader);
        final c = container();
        final controller = c.read(holidayControllerProvider.notifier);

        // Built from the database right after the first read.
        expect(c.read(holidaysProvider), isEmpty);
        await controller.reload();
        expect(c.read(holidaysProvider), hasLength(15));
        expect(
          c.read(holidaysProvider)[const CivilDate(2026, 10, 12)]?.name,
          'Fiesta Nacional de España',
        );

        await controller.setPlace(
          regionCode: 'ES-CT',
          municipalityCode: '08019',
        );
        expect(c.read(holidayPlaceProvider).municipalityCode, '08019');
        final holidays = c.read(holidaysProvider);
        expect(
          holidays[const CivilDate(2026, 9, 24)]?.scope,
          HolidayScope.local,
        );
        expect(
          holidays[const CivilDate(2026, 12, 26)]?.scope,
          HolidayScope.regional,
        );

        await controller.addUserHoliday(
          date: const CivilDate(2026, 9, 24),
          name: 'Mío',
        );
        expect(
          c.read(holidaysProvider)[const CivilDate(2026, 9, 24)]?.name,
          'Mío',
        );
        await controller.removeUserHoliday(const CivilDate(2026, 9, 24));
        expect(
          c.read(holidaysProvider)[const CivilDate(2026, 9, 24)]?.scope,
          HolidayScope.local,
        );
      },
    );

    test('the initial snapshot is used as it is, with no reload', () async {
      await repo.refreshBundled(loader);
      await repo.savePlace(regionCode: 'ES-MD');
      final snapshot = await repo.loadSnapshot();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          initialHolidaysProvider.overrideWithValue(snapshot),
        ],
      );
      addTearDown(c.dispose);

      expect(c.read(holidaysProvider), snapshot.byDay);
      expect(c.read(holidayPlaceProvider).regionCode, 'ES-MD');
    });
  });

  group('bootstrapApp', () {
    test(
      'refreshes the bundled holidays and hands the snapshot over',
      () async {
        final boot = await bootstrapApp(
          config: const AppConfig(useDemoData: false),
          database: db,
          holidayLoader: loader,
        );
        expect(boot.holidays.entries, hasLength(15));
        expect(await _count(db, "source = 'bundled'"), greaterThan(15));

        // Second start: nothing to do, same result.
        final again = await bootstrapApp(
          config: const AppConfig(useDemoData: false),
          database: db,
          holidayLoader: loader,
        );
        expect(again.holidays.entries, hasLength(15));
      },
    );

    test('keeps the chosen place across starts', () async {
      await repo.savePlace(regionCode: 'ES-CT', municipalityCode: '08019');
      final boot = await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: db,
        holidayLoader: loader,
      );
      expect(boot.holidays.place.municipalityCode, '08019');
      expect(
        boot.holidays.byDay[const CivilDate(2026, 5, 25)]?.scope,
        HolidayScope.local,
      );
    });

    test('a bundle that cannot be read never blocks start-up', () async {
      final boot = await bootstrapApp(
        config: const AppConfig(useDemoData: false),
        database: db,
        holidayLoader: HolidayBundleLoader(bundle: MemoryAssetBundle({})),
      );
      expect(boot.holidays.entries, isEmpty);
      expect(boot.schedule, isNotNull);
    });
  });
}
