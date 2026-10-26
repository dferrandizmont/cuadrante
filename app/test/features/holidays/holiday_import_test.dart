import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/data/holiday_repository.dart';
import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/holidays/domain/holiday_calendar.dart';
import 'package:cuadrante/features/holidays/domain/holiday_entry.dart';
import 'package:cuadrante/features/holidays/domain/holiday_import.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart' show openMemoryDatabase;

const _range = ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 12, 31));
const _day = CivilDate(2026, 5, 1);

RawEvent _event(
  String title, {
  CivilDate start = _day,
  CivilDate? end,
  bool allDay = true,
}) => RawEvent(
  title: title,
  startDate: start,
  endDate: end,
  allDay: allDay,
  startMinute: allDay ? null : 480,
);

HolidayImportPlan _plan(
  Iterable<RawEvent> events, {
  ImportRange range = _range,
  HolidayCalendar? existing,
  String fallback = 'Festivo',
}) => buildHolidayImportPlan(
  events,
  range,
  existing ?? HolidayCalendar.empty,
  fallbackName: fallback,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('holiday import preview', () {
    test('only all-day events, exclusive end and empty-name fallback', () {
      final plan = _plan([
        _event('   ', end: _day.addDays(2)),
        _event('Trabajo', allDay: false),
        _event('Pasado', start: const CivilDate(2025, 1, 1)),
      ], fallback: ' Festa local ');

      expect(plan.rows.map((r) => r.date), [_day, _day.addDays(1)]);
      expect(plan.rows.map((r) => r.name), ['Festa local', 'Festa local']);
      expect(plan.toAdd, hasLength(2));
      expect(plan.ignoredTimed, 1);
      expect(plan.cappedEvents, 0);
    });

    test('absent, equal and reversed ends are single-day events', () {
      for (final end in [null, _day, _day.addDays(-1)]) {
        expect(_plan([_event('Fiesta', end: end)]).rows.single.date, _day);
      }
    });

    test(
      'timed events starting before the range still count when overlapping',
      () {
        final plan = _plan([
          const RawEvent(
            title: 'Turno',
            startDate: CivilDate(2025, 12, 31),
            startMinute: 1380,
            endDate: CivilDate(2026, 1, 2),
            endMinute: 60,
          ),
          const RawEvent(
            title: 'Acaba antes',
            startDate: CivilDate(2025, 12, 31),
            startMinute: 1380,
            endDate: CivilDate(2026, 1, 1),
            endMinute: 0,
          ),
        ]);
        expect(plan.rows, isEmpty);
        expect(plan.ignoredTimed, 1);
      },
    );

    test('31-day cap precedes range intersection, even after the cap', () {
      final long = _event(
        'Vacaciones',
        start: const CivilDate(2026, 1, 1),
        end: const CivilDate(2026, 4, 1),
      );
      final tail = _plan(
        [long],
        range: const ImportRange(
          CivilDate(2026, 1, 25),
          CivilDate(2026, 2, 10),
        ),
      );
      expect(tail.rows, hasLength(7));
      expect(tail.rows.first.date, const CivilDate(2026, 1, 25));
      expect(tail.rows.last.date, const CivilDate(2026, 1, 31));
      expect(tail.cappedEvents, 1);

      final after = _plan(
        [long],
        range: const ImportRange(CivilDate(2026, 2, 1), CivilDate(2026, 2, 10)),
      );
      expect(after.rows, isEmpty);
      expect(after.cappedEvents, 1);
      expect(_plan([long]).rows, hasLength(maxHolidayImportSpanDays));
    });

    test('date and folded name deduplicate, different names skip that day', () {
      final source = [
        _event('Zeta'),
        _event('san-juan'),
        _event('SÁN JUAN'),
        _event('Primero', start: _day.addDays(-1)),
      ];
      final plan = _plan(source);
      final reversed = _plan(source.reversed);
      expect(plan.rows.map((r) => (r.date, r.name, r.skipped)), [
        (_day.addDays(-1), 'Primero', false),
        (_day, 'SÁN JUAN', false),
        (_day, 'Zeta', true),
      ]);
      expect(
        reversed.rows.map((r) => (r.date, r.name, r.skipped)),
        plan.rows.map((r) => (r.date, r.name, r.skipped)),
      );
    });

    test('any applicable bundled, remote or user holiday blocks a day', () {
      final entries = [
        HolidayEntry(date: _day, scope: HolidayScope.national, name: 'Oficial'),
        HolidayEntry(
          date: _day.addDays(1),
          scope: HolidayScope.local,
          name: 'Propio',
          source: HolidaySource.user,
        ),
        HolidayEntry(
          date: _day.addDays(2),
          scope: HolidayScope.regional,
          name: 'Otra comunidad',
          regionCode: 'ES-CT',
        ),
        HolidayEntry(
          date: _day.addDays(3),
          scope: HolidayScope.national,
          name: 'Descargado',
          source: HolidaySource.remote,
        ),
      ];
      final plan = _plan([
        _event('Importado', end: _day.addDays(4)),
      ], existing: HolidayCalendar(entries));
      expect(plan.rows.map((r) => r.skipped), [true, true, false, true]);
      expect(plan.toAdd.single.date, _day.addDays(2));
    });

    test('trim and Unicode clipping preserve complete graphemes', () {
      const cluster = '👩🏽‍⚕️';
      final title = '${'a' * 59}$cluster${'e\u0301' * 4}';
      final name = _plan([_event('  $title  ')]).rows.single.name;
      expect(name.characters.length, maxHolidayNameLength);
      expect(name, '${'a' * 59}$cluster');
      expect(
        _plan([
          _event(''),
        ], fallback: 'e\u0301' * 61).rows.single.name.characters.length,
        maxHolidayNameLength,
      );
    });

    test('huge combining graphemes also have a hard UTF-16 bound', () {
      final hostile = 'a${'\u0301' * 1000000}';
      final name = _plan([_event(hostile)]).rows.single.name;
      expect(name.length, lessThanOrEqualTo(maxImportTitleLength));
      expect(name.characters.length, 1);
      final beforeSurrogate = 'a${'\u0301' * 118}';
      expect(clipHolidayImportName('$beforeSurrogate😀'), beforeSurrogate);
    });

    test('the reader limit of repeated long events is deduplicated early', () {
      final plan = _plan(
        List.generate(
          maxImportEvents,
          (_) => _event('Fiesta', end: _day.addDays(maxHolidayImportSpanDays)),
        ),
      );
      expect(plan.rows, hasLength(maxHolidayImportSpanDays));
      expect(plan.toAdd, hasLength(maxHolidayImportSpanDays));
    });
  });

  group('holiday import persistence', () {
    late AppDatabase db;
    late HolidayRepository repository;

    setUp(() {
      db = openMemoryDatabase();
      repository = HolidayRepository(db);
    });
    tearDown(() => db.close());

    Future<void> official(CivilDate date, {String? region}) =>
        db.customStatement(
          'INSERT INTO holidays (date, scope, name, source, region_code) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            date.toIso(),
            region == null ? 'national' : 'regional',
            'Oficial',
            'bundled',
            region,
          ],
        );

    test(
      'revalidates new conflicts and place since preview; reimport is safe',
      () async {
        await official(_day.addDays(1), region: 'ES-CT');
        final snapshot = await repository.loadSnapshot();
        final preview = _plan([
          _event('Importado', end: _day.addDays(4)),
        ], existing: snapshot.calendar);
        expect(preview.toAdd, hasLength(4));

        await repository.savePlace(regionCode: 'ES-CT');
        await official(_day);
        await repository.addUserHoliday(date: _day.addDays(2), name: 'Manual');
        final receipt = await repository.importUserHolidays(preview.rows);
        expect(receipt.count, 1);
        expect((await repository.userHolidays()).map((h) => h.name), [
          'Manual',
          'Importado',
        ]);
        final imported = (await repository.userHolidays()).last;
        expect(imported.date, _day.addDays(3));
        expect(imported.scope, HolidayScope.local);
        expect(imported.source, HolidaySource.user);
        expect((await repository.importUserHolidays(preview.rows)).count, 0);
        expect(await db.select(db.holidays).get(), hasLength(4));
      },
    );

    test(
      'skipped rows and repeated dates cannot replace any holiday',
      () async {
        final receipt = await repository.importUserHolidays([
          HolidayImportRow(date: _day, name: 'Omitido', skipped: true),
          HolidayImportRow(date: _day.addDays(1), name: 'Primero'),
          HolidayImportRow(date: _day.addDays(1), name: 'Segundo'),
        ]);
        expect(receipt.count, 1);
        expect((await repository.userHolidays()).single.name, 'Primero');
      },
    );

    test(
      'repository also trims and clips names at the persistence boundary',
      () async {
        await repository.importUserHolidays([
          HolidayImportRow(date: _day, name: '  ${'e\u0301' * 61}  '),
        ]);
        expect((await repository.userHolidays()).single.name, 'e\u0301' * 60);
        await repository.importUserHolidays([
          HolidayImportRow(
            date: _day.addDays(1),
            name: 'a${'\u0301' * 1000000}',
          ),
        ]);
        expect(
          (await repository.userHolidays()).last.name.length,
          lessThanOrEqualTo(maxImportTitleLength),
        );
      },
    );

    test(
      'undo only its ids, retaining official and later manual replacements',
      () async {
        final first = await repository.importUserHolidays([
          HolidayImportRow(date: _day, name: 'Uno'),
          HolidayImportRow(date: _day.addDays(1), name: 'Dos'),
        ]);
        await repository.addUserHoliday(date: _day, name: 'Reemplazo');
        final second = await repository.importUserHolidays([
          HolidayImportRow(date: _day.addDays(2), name: 'Otra importación'),
        ]);
        await official(_day.addDays(1));
        await repository.undoImportedHolidays(first);
        await repository.undoImportedHolidays(first);

        expect((await repository.userHolidays()).map((h) => h.name), [
          'Reemplazo',
          'Otra importación',
        ]);
        expect(
          (await repository.loadSnapshot()).calendar.on(_day.addDays(1))?.name,
          'Oficial',
        );
        await repository.undoImportedHolidays(second);
        expect((await repository.userHolidays()).single.name, 'Reemplazo');
      },
    );

    test(
      'an insertion error rolls back earlier rows and preserves old data',
      () async {
        await repository.addUserHoliday(
          date: _day.addDays(-1),
          name: 'Existente',
        );
        await db.customStatement(
          'CREATE TRIGGER reject_import BEFORE INSERT ON holidays '
          "WHEN NEW.name = 'Falla' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
        );
        await expectLater(
          repository.importUserHolidays([
            HolidayImportRow(date: _day, name: 'Válido'),
            HolidayImportRow(date: _day.addDays(1), name: 'Falla'),
          ]),
          throwsA(isA<Exception>()),
        );
        expect((await repository.userHolidays()).single.name, 'Existente');
      },
    );

    test(
      'controller reloads the calendar after import and exact undo',
      () async {
        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);
        final controller = container.read(holidayControllerProvider.notifier);
        await controller.reload();
        final receipt = await controller.importUserHolidays([
          const HolidayImportRow(date: _day, name: 'Importado'),
        ]);
        expect(receipt.count, 1);
        expect(container.read(holidaysProvider)[_day]?.name, 'Importado');
        await controller.undoImportedHolidays(receipt);
        expect(container.read(holidaysProvider)[_day], isNull);
      },
    );
  });
}
