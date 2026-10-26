import 'package:cuadrante/features/holidays/domain/holiday.dart';
import 'package:cuadrante/features/holidays/domain/holiday_calendar.dart';
import 'package:cuadrante/features/holidays/domain/holiday_entry.dart';
import 'package:cuadrante/features/schedule/domain/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundle_support.dart';

// Real cases from the shipped bundle (Mochila's BOE / DOGC / BOCM data), read
// the way `officialCalendar` in mochila-app/backend/src/calendars/official.ts
// combines them.

const _year2026 = (CivilDate(2026, 1, 1), CivilDate(2026, 12, 31));
const _year2027 = (CivilDate(2027, 1, 1), CivilDate(2027, 12, 31));

String _line(Holiday h) => '${h.date.toIso()} ${h.scope.name} ${h.name}';

void main() {
  late List<HolidayEntry> entries;

  setUpAll(() async => entries = await shippedEntries());

  HolidayCalendar calendar({String? region, String? municipality}) =>
      HolidayCalendar(
        entries,
        regionCode: region,
        municipalityCode: municipality,
      );

  List<String> lines(HolidayCalendar c, (CivilDate, CivilDate) range) => [
    for (final h in c.list(range.$1, range.$2)) _line(h),
  ];

  group('national only (no region chosen)', () {
    test('2026: the seven fixed national days', () {
      expect(lines(calendar(), _year2026), [
        '2026-01-01 national Año Nuevo',
        '2026-04-03 national Viernes Santo',
        '2026-05-01 national Fiesta del Trabajo',
        '2026-08-15 national Asunción de la Virgen',
        '2026-10-12 national Fiesta Nacional de España',
        '2026-12-08 national Inmaculada Concepción',
        '2026-12-25 national Natividad del Señor',
      ]);
    });

    test('2027 is bundled too', () {
      final days = calendar().list(_year2027.$1, _year2027.$2);
      expect(days, hasLength(8));
      expect(days.map((h) => h.date.toIso()), contains('2027-03-26'));
    });

    test('a municipality without a region shows nothing local', () {
      expect(
        calendar(municipality: '08019').list(_year2026.$1, _year2026.$2),
        hasLength(7),
      );
    });

    test('a year with no data is empty, not an error', () {
      expect(
        calendar().list(
          const CivilDate(2030, 1, 1),
          const CivilDate(2030, 12, 31),
        ),
        isEmpty,
      );
    });
  });

  group('regional files: kept and replaced national days', () {
    test(
      'Catalunya 2026 keeps Epiphany, adds its own, has no Holy Thursday',
      () {
        final ct = calendar(region: 'ES-CT');
        expect(lines(ct, _year2026), [
          '2026-01-01 national Año Nuevo',
          '2026-01-06 national Epifanía del Señor', // national-optional, kept
          '2026-04-03 national Viernes Santo',
          '2026-04-06 regional Lunes de Pascua',
          '2026-05-01 national Fiesta del Trabajo',
          '2026-06-24 regional San Juan',
          '2026-08-15 national Asunción de la Virgen',
          '2026-09-11 regional Diada Nacional de Cataluña',
          '2026-10-12 national Fiesta Nacional de España',
          '2026-12-08 national Inmaculada Concepción',
          '2026-12-25 national Natividad del Señor',
          '2026-12-26 regional San Esteban',
        ]);
        // Holy Thursday is a replaceable national day: Catalunya replaced it
        // with Easter Monday, Madrid kept it.
        expect(ct.on(const CivilDate(2026, 4, 2)), isNull);
        expect(
          calendar(region: 'ES-MD').on(const CivilDate(2026, 4, 2)),
          const Holiday(
            date: CivilDate(2026, 4, 2),
            name: 'Jueves Santo',
            scope: HolidayScope.national,
          ),
        );
      },
    );

    test('Madrid 2026 adds its day and moves All Saints to Monday', () {
      final md = calendar(region: 'ES-MD');
      expect(md.on(const CivilDate(2026, 5, 2))?.scope, HolidayScope.regional);
      expect(
        md.on(const CivilDate(2026, 5, 2))?.name,
        contains('Comunidad de Madrid'),
      );
      expect(md.on(const CivilDate(2026, 11, 2))?.scope, HolidayScope.national);
      // Nov 1 2026 is a Sunday: nobody lists it.
      expect(md.on(const CivilDate(2026, 11, 1)), isNull);
    });

    test('the region code is case-insensitive; an unknown one is ignored', () {
      expect(
        lines(calendar(region: 'es-ct'), _year2026),
        lines(calendar(region: 'ES-CT'), _year2026),
      );
      expect(
        lines(calendar(region: 'ES-XX'), _year2026),
        lines(calendar(), _year2026),
      );
    });

    test(
      'every region has national-optional or regional days for both years',
      () {
        final regions = {
          for (final e in entries)
            if (e.regionCode != null) e.regionCode!,
        };
        expect(regions, hasLength(19));
        for (final region in regions) {
          for (final year in [_year2026, _year2027]) {
            expect(
              calendar(region: region).list(year.$1, year.$2).length,
              greaterThan(8),
              reason: '$region ${year.$1.year}',
            );
          }
        }
      },
    );
  });

  group('local holidays', () {
    test('Barcelona (08019) 2026: two locals on top of Catalunya', () {
      final bcn = calendar(region: 'ES-CT', municipality: '08019');
      final locals = bcn
          .list(_year2026.$1, _year2026.$2)
          .where((h) => h.scope == HolidayScope.local);
      expect(locals.map(_line), [
        '2026-05-25 local Fiesta local',
        '2026-09-24 local Fiesta local',
      ]);
      expect(
        bcn.list(_year2026.$1, _year2026.$2),
        hasLength(
          calendar(region: 'ES-CT').list(_year2026.$1, _year2026.$2).length + 2,
        ),
      );
      expect(bcn.on(const CivilDate(2026, 9, 24))?.scope, HolidayScope.local);
    });

    test('a Madrid municipality: Madrid city and Alcalá de Henares', () {
      final madrid = calendar(region: 'ES-MD', municipality: '28079');
      expect(
        madrid.on(const CivilDate(2026, 5, 15))?.scope,
        HolidayScope.local,
      );
      expect(
        madrid.on(const CivilDate(2026, 11, 9))?.scope,
        HolidayScope.local,
      );
      final alcala = calendar(region: 'ES-MD', municipality: '28005');
      expect(alcala.on(const CivilDate(2026, 8, 6))?.scope, HolidayScope.local);
      expect(
        alcala.on(const CivilDate(2026, 10, 9))?.scope,
        HolidayScope.local,
      );
      // Madrid's locals are not Alcalá's.
      expect(alcala.on(const CivilDate(2026, 5, 15)), isNull);
    });

    test('a village keeps the name of its pedanía (Madrid, El Boalo)', () {
      final boalo = calendar(region: 'ES-MD', municipality: '28023');
      expect(
        boalo.on(const CivilDate(2026, 1, 20))?.name,
        'Fiesta local (El Boalo)',
      );
    });

    test('Murcia: local holidays of the school calendar, by year', () {
      final abanilla = calendar(region: 'ES-MC', municipality: '30001');
      expect(
        abanilla.on(const CivilDate(2026, 9, 14))?.scope,
        HolidayScope.local,
      );
      expect(
        abanilla.on(const CivilDate(2027, 5, 3))?.scope,
        HolidayScope.local,
      );
    });

    test('a region with nothing local: the municipality changes nothing', () {
      final sevilla = calendar(region: 'ES-AN', municipality: '41091');
      expect(
        lines(sevilla, _year2026),
        lines(calendar(region: 'ES-AN'), _year2026),
      );
    });

    test('a municipality of another region never applies', () {
      final wrong = calendar(region: 'ES-MD', municipality: '08019');
      expect(wrong.on(const CivilDate(2026, 5, 25)), isNull);
    });

    test('2027 locals are not published yet: nothing, not an error', () {
      final bcn = calendar(region: 'ES-CT', municipality: '08019');
      expect(
        bcn
            .list(_year2027.$1, _year2027.$2)
            .where((h) => h.scope == HolidayScope.local),
        isEmpty,
      );
    });
  });

  group('priority on one day', () {
    HolidayEntry entry(
      HolidayScope scope,
      String name, {
      HolidaySource source = HolidaySource.bundled,
      String? region,
      String? municipality,
    }) => HolidayEntry(
      date: const CivilDate(2026, 12, 26),
      scope: scope,
      name: name,
      regionCode: region,
      municipalityCode: municipality,
      source: source,
    );

    final rows = [
      entry(HolidayScope.national, 'nacional'),
      entry(HolidayScope.regional, 'autonómico', region: 'ES-CT'),
      entry(
        HolidayScope.local,
        'local',
        region: 'ES-CT',
        municipality: '08019',
      ),
    ];
    const day = CivilDate(2026, 12, 26);

    test('local > regional > national', () {
      HolidayCalendar c({String? municipality}) => HolidayCalendar(
        rows,
        regionCode: 'ES-CT',
        municipalityCode: municipality,
      );
      expect(c(municipality: '08019').on(day)?.name, 'local');
      expect(c().on(day)?.name, 'autonómico');
      expect(HolidayCalendar(rows).on(day)?.name, 'nacional');
      // list() keeps all three, in the order of officialCalendar.
      expect(c(municipality: '08019').list(day, day).map((h) => h.name), [
        'nacional',
        'autonómico',
        'local',
      ]);
    });

    test('a holiday the user added wins over everything, in any place', () {
      final withUser = [
        ...rows,
        entry(HolidayScope.local, 'mío', source: HolidaySource.user),
      ];
      for (final c in [
        HolidayCalendar(withUser),
        HolidayCalendar(withUser, regionCode: 'ES-CT'),
        HolidayCalendar(
          withUser,
          regionCode: 'ES-CT',
          municipalityCode: '08019',
        ),
      ]) {
        final h = c.on(day)!;
        expect(h.name, 'mío');
        expect(h.isUserAdded, isTrue);
      }
    });

    test('a remote row replaces a bundled one of the same scope', () {
      final c = HolidayCalendar([
        entry(HolidayScope.national, 'incluido'),
        entry(
          HolidayScope.national,
          'descargado',
          source: HolidaySource.remote,
        ),
      ]);
      expect(c.on(day)?.name, 'descargado');
    });

    test('the result does not depend on the order of the rows', () {
      expect(
        HolidayCalendar(rows.reversed, regionCode: 'ES-CT').on(day),
        HolidayCalendar(rows, regionCode: 'ES-CT').on(day),
      );
    });

    test('between() returns days in order and respects the range', () {
      final map = calendar(region: 'ES-CT')
          .between(const CivilDate(2026, 4, 1), const CivilDate(2026, 6, 30));
      expect(map.keys.map((d) => d.toIso()), [
        '2026-04-03',
        '2026-04-06',
        '2026-05-01',
        '2026-06-24',
      ]);
    });
  });
}
