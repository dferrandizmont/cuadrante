import 'package:cuadrante/features/calendar_export/data/calendar_exporter.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/calendar_export/domain/export_events.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';
import '../import/import_support.dart';

const _from = CivilDate(2026, 10, 19); // Monday
const _to = CivilDate(2026, 10, 25);

/// M N L L T T L over the week from the 19th, plus a day with two shifts.
Schedule weekSchedule() {
  final pattern = Pattern(
    id: 'p',
    name: 'ciclo',
    steps: const [
      ['morning'],
      ['night'],
      ['rest'],
      [],
      ['afternoon'],
      ['afternoon', 'night'],
      ['rest'],
    ],
  );
  return emptySchedule(
    patterns: [pattern],
    runs: [PatternRun(id: 'r', patternId: 'p', startDate: _from, seq: 1)],
  );
}

List<ExportEvent> build({bool includeRest = false}) => buildExportEvents(
  weekSchedule(),
  calendarId: 'main',
  from: _from,
  to: _to,
  includeRest: includeRest,
);

void main() {
  group('building the events', () {
    test('one event per shift, timed with the wall clock', () {
      final events = build();
      // Rest days (Libre) and the empty day are left out by default.
      expect(events.map((e) => e.title), [
        'Mañana · M',
        'Noche · N',
        'Tarde · T',
        'Tarde · T',
        'Noche · N',
      ]);
      final morning = events.first;
      expect(morning.start, DateTime(2026, 10, 19, 6));
      expect(morning.end, DateTime(2026, 10, 19, 14));
      expect(morning.allDay, isFalse);
    });

    test('a night shift ends on the next day', () {
      final nightEvent = build()[1];
      expect(nightEvent.start, DateTime(2026, 10, 20, 22));
      expect(nightEvent.end, DateTime(2026, 10, 21, 6));
    });

    test('a 24 h shift ends the next day at the same time', () {
      const guard = ShiftType(
        id: 'guard',
        code: 'G',
        name: 'Guardia 24 h',
        colorValue: 0xFFE5484D,
        category: ShiftCategory.work,
        startMinute: 8 * 60,
        endMinute: 8 * 60,
      );
      final schedule = Schedule(
        shiftTypes: [guard],
        entries: {
          _from: DayEntry(date: _from, shiftTypeIds: const ['guard']),
        },
      );
      final e = buildExportEvents(
        schedule,
        calendarId: 'main',
        from: _from,
        to: _from,
      ).single;
      expect(e.start, DateTime(2026, 10, 19, 8));
      expect(e.end, DateTime(2026, 10, 20, 8));
    });

    test('shifts without hours are all-day events', () {
      final events = build(includeRest: true);
      final libre = events.firstWhere((e) => e.title == 'Libre · L');
      expect(libre.allDay, isTrue);
      expect(libre.start, DateTime(2026, 10, 21));
      expect(libre.end, DateTime(2026, 10, 22));
      expect(events.where((e) => e.title == 'Libre · L'), hasLength(2));
    });

    test('a day with two shifts gives two events with their own tags', () {
      final events = build();
      final day = events.where((e) => e.date == const CivilDate(2026, 10, 24));
      expect(day.map((e) => e.tag), [
        'cuadrante:v1:main:2026-10-24:afternoon:0',
        'cuadrante:v1:main:2026-10-24:night:1',
      ]);
    });

    test('the description carries the tag and it parses back', () {
      final e = build().first;
      expect(e.description, contains('cuadrante:v1:main:2026-10-19:morning:0'));
      final tag = ExportTag.parse(e.description)!;
      expect(tag.calendarId, 'main');
      expect(tag.date, _from);
      expect(tag.typeId, 'morning');
      expect(tag.index, 0);
      expect(ExportTag.parse('Mi cita con el dentista'), isNull);
      expect(ExportTag.parse(null), isNull);
      expect(ExportTag.parse('cuadrante:v1:roto'), isNull);
    });

    test('events exported before the rename to Turnly are still ours', () {
      final e = build().first;
      expect(e.description, startsWith('Creado con Turnly\n'));
      final legacy = e.description.replaceFirst(
        'Creado con Turnly',
        'Creado con Cuadrante',
      );
      expect(ExportTag.parse(legacy)?.typeId, 'morning');
      final other = e.description.replaceFirst(
        'Creado con Turnly',
        'Creado con',
      );
      expect(ExportTag.parse(other), isNull);
    });

    test('the range is cut to a year and a reversed range is empty', () {
      final schedule = emptySchedule(
        entries: {
          for (var i = 0; i < 400; i++)
            _from.addDays(i): DayEntry(
              date: _from.addDays(i),
              shiftTypeIds: const ['morning'],
            ),
        },
      );
      expect(
        buildExportEvents(
          schedule,
          calendarId: 'main',
          from: _from,
          to: _from.addDays(399),
        ),
        hasLength(maxExportDays),
      );
      expect(
        buildExportEvents(schedule, calendarId: 'main', from: _to, to: _from),
        isEmpty,
      );
    });
  });

  group('exporting', () {
    late FakeDeviceCalendar phone;
    late CalendarExporter exporter;

    Future<ExportResult> run(
      ExportTarget target, {
      Schedule? schedule,
      CivilDate from = _from,
      CivilDate to = _to,
      bool includeRest = false,
      String appCalendarId = 'main',
    }) => exporter.export(
      schedule: schedule ?? weekSchedule(),
      appCalendarId: appCalendarId,
      target: target,
      from: from,
      to: to,
      includeRest: includeRest,
    );

    setUp(() {
      phone = FakeDeviceCalendar();
      exporter = CalendarExporter(phone);
    });

    test('creates the calendar «Turnly» and writes the events', () async {
      final result = await run(const NewCalendar(colorValue: 0xFF4B4FD1));
      expect(phone.createdCalendars, 1);
      expect(phone.allCalendars.single.name, 'Turnly');
      expect(result.calendarCreated, isTrue);
      expect(result.created, 5);
      expect(result.removed, 0);
      expect(result.unchanged, 0);
      expect(result.failed, 0);
      expect(phone.eventsOf(result.deviceCalendarId), hasLength(5));
    });

    test('exporting twice does not duplicate anything', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      final before = phone.eventsOf(id).map((e) => e.title).toList()..sort();

      final second = await run(ExistingCalendar(id));
      expect(second.created, 0);
      expect(second.removed, 0);
      expect(second.unchanged, 5);
      expect(phone.eventsOf(id), hasLength(5));
      expect(phone.eventsOf(id).map((e) => e.title).toList()..sort(), before);

      final third = await run(ExistingCalendar(id));
      expect(third.created, 0);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test('a change in the schedule replaces only what changed', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      // The 19th becomes a Tarde.
      final changed = weekSchedule().copyWith(
        entries: {
          _from: DayEntry(date: _from, shiftTypeIds: const ['afternoon']),
        },
      );
      final result = await run(ExistingCalendar(id), schedule: changed);
      expect(result.removed, 1);
      expect(result.created, 1);
      expect(result.unchanged, 4);
      final titles = phone.eventsOf(id).map((e) => e.title).toList();
      expect(titles, hasLength(5));
      expect(titles, isNot(contains('Mañana · M')));
    });

    test(
      'a shorter range removes the events of the days left out only',
      () async {
        final first = await run(const NewCalendar());
        final id = first.deviceCalendarId;
        final result = await run(
          ExistingCalendar(id),
          from: _from,
          to: _from.addDays(2),
        );
        // Days 22..25 are outside the new range: their events stay.
        expect(result.removed, 0);
        expect(phone.eventsOf(id), hasLength(5));
      },
    );

    test('a longer range adds only the new days', () async {
      final first = await run(const NewCalendar(), to: _from.addDays(2));
      final id = first.deviceCalendarId;
      expect(phone.eventsOf(id), hasLength(2));
      final second = await run(ExistingCalendar(id));
      expect(second.created, 3);
      expect(second.unchanged, 2);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test('never touches events that are not ours', () async {
      final id = phone.addCalendar('Personal');
      final mine = phone.addSimpleEvent(
        id,
        'Dentista',
        DateTime(2026, 10, 19, 9),
        DateTime(2026, 10, 19, 10),
        description: 'Revisión anual',
      );
      // An export of another Cuadrante calendar into the same phone calendar.
      final other = phone.addSimpleEvent(
        id,
        'Mañana · M',
        DateTime(2026, 10, 19, 6),
        DateTime(2026, 10, 19, 14),
        description:
            'Creado con Cuadrante\n'
            '${exportTag('pareja', _from, 'morning', 0)}',
      );
      await run(ExistingCalendar(id));
      await run(ExistingCalendar(id));
      final ids = phone.eventsOf(id).map((e) => e.instanceId).toSet();
      expect(ids, containsAll([mine, other]));
      // 2 foreign + 5 ours.
      expect(phone.eventsOf(id), hasLength(7));
    });

    test('a repeated copy of an event is cleaned up', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      final dup = phone.eventsOf(id).first;
      phone.addSimpleEvent(
        id,
        dup.title,
        dup.start,
        dup.end,
        description: dup.description,
      );
      expect(phone.eventsOf(id), hasLength(6));
      final result = await run(ExistingCalendar(id));
      expect(result.removed, 1);
      expect(result.created, 0);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test('including the days off changes the set, then switching it off removes them', () async {
      final first = await run(const NewCalendar(), includeRest: true);
      final id = first.deviceCalendarId;
      expect(phone.eventsOf(id), hasLength(7));
      final result = await run(ExistingCalendar(id));
      expect(result.removed, 2);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test(
      'failures on single events are counted and the rest goes on',
      () async {
        final id = phone.addCalendar('Personal');
        phone.failCreatingTitles.add('Noche · N');
        final result = await run(ExistingCalendar(id));
        expect(result.failed, 2);
        expect(result.created, 3);
        expect(result.hasFailures, isTrue);
        // The next export fills the gap without duplicating.
        phone.failCreatingTitles.clear();
        final again = await run(ExistingCalendar(id));
        expect(again.created, 2);
        expect(again.unchanged, 3);
        expect(phone.eventsOf(id), hasLength(5));
      },
    );

    test('a failed deletion is counted and does not duplicate', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      final stuck = phone.eventsOf(id).first.instanceId;
      phone.failDeleting.add(stuck);
      final changed = weekSchedule().copyWith(
        entries: {
          _from: DayEntry(date: _from, shiftTypeIds: const ['afternoon']),
        },
      );
      final result = await run(ExistingCalendar(id), schedule: changed);
      expect(result.failed, 1);
      phone.failDeleting.clear();
      final repaired = await run(ExistingCalendar(id), schedule: changed);
      expect(repaired.removed, 1);
      expect(phone.eventsOf(id), hasLength(5));
    });

    test('progress goes from 1 to the total', () async {
      final seen = <(int, int)>[];
      await exporter.export(
        schedule: weekSchedule(),
        appCalendarId: 'main',
        target: const NewCalendar(),
        from: _from,
        to: _to,
        includeRest: false,
        onProgress: (done, total) => seen.add((done, total)),
      );
      expect(seen.first, (1, 5));
      expect(seen.last, (5, 5));
    });

    test('preview counts what an export would do and writes nothing', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      final plan = await exporter.preview(
        schedule: weekSchedule(),
        appCalendarId: 'main',
        deviceCalendarId: id,
        from: _from,
        to: _to,
        includeRest: false,
      );
      expect(plan.isNoop, isTrue);
      expect(plan.unchanged, 5);
      final fresh = await exporter.preview(
        schedule: weekSchedule(),
        appCalendarId: 'main',
        deviceCalendarId: null,
        from: _from,
        to: _to,
        includeRest: false,
      );
      expect(fresh.toCreate, hasLength(5));
      expect(phone.eventsOf(id), hasLength(5));
    });

    test('writableCalendars leaves out read-only and hidden ones', () async {
      phone.addCalendar('Personal');
      phone.addCalendar('Festivos', readOnly: true);
      phone.addCalendar('Oculto', hidden: true);
      final names = (await exporter.writableCalendars()).map((c) => c.name);
      expect(names, ['Personal']);
    });
  });

  group('permission', () {
    test('without full access nothing is written', () async {
      for (final access in [
        CalendarAccess.denied,
        CalendarAccess.restricted,
        CalendarAccess.notDetermined,
        CalendarAccess.writeOnly,
      ]) {
        final phone = FakeDeviceCalendar(access: access);
        await expectLater(
          CalendarExporter(phone).export(
            schedule: weekSchedule(),
            appCalendarId: 'main',
            target: const NewCalendar(),
            from: _from,
            to: _to,
            includeRest: false,
          ),
          throwsA(
            isA<CalendarApiException>().having(
              (e) => e.error,
              'error',
              CalendarApiError.permissionDenied,
            ),
          ),
          reason: access.name,
        );
        expect(phone.createdCalendars, 0);
        expect(phone.createdEvents, 0);
      }
    });

    test('the permission going away in the middle stops the export', () async {
      final phone = FakeDeviceCalendar();
      final id = phone.addCalendar('Personal');
      var calls = 0;
      final exporter = CalendarExporter(phone);
      await expectLater(
        exporter.export(
          schedule: weekSchedule(),
          appCalendarId: 'main',
          target: ExistingCalendar(id),
          from: _from,
          to: _to,
          includeRest: false,
          onProgress: (done, total) {
            if (++calls == 2) {
              phone.failNext = CalendarApiError.permissionDenied;
            }
          },
        ),
        throwsA(isA<CalendarApiException>()),
      );
      expect(phone.createdEvents, 2);
    });
  });
}
