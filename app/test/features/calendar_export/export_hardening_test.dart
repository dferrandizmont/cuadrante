import 'package:cuadrante/features/calendar_export/data/calendar_exporter.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:cuadrante/features/calendar_export/domain/export_events.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';
import '../import/import_support.dart';

const _from = CivilDate(2026, 10, 19);
const _to = CivilDate(2026, 10, 25);

const _sick = ShiftType(
  id: 'sick',
  code: 'B',
  name: 'Baja médica',
  colorValue: 0xFF8E8E93,
  category: ShiftCategory.absence,
);
const _vacation = ShiftType(
  id: 'vacation',
  code: 'V',
  name: 'Vacaciones',
  colorValue: 0xFF30B0C7,
  category: ShiftCategory.absence,
);

Schedule scheduleOf(
  Map<CivilDate, List<String>> days, {
  List<ShiftType> extra = const [],
}) => Schedule(
  shiftTypes: [...baseTypes, ...extra],
  entries: {
    for (final e in days.entries)
      e.key: DayEntry(date: e.key, shiftTypeIds: e.value),
  },
);

String descriptionOf(String typeId, {String calendar = 'main'}) =>
    '$exportMarkerLine\n${exportTag(calendar, _from, typeId, 0)}';

void main() {
  group('absences stay on the phone unless asked', () {
    final schedule = scheduleOf(
      {
        _from: ['morning'],
        _from.addDays(1): ['sick'],
        _from.addDays(2): ['vacation'],
      },
      extra: [_sick, _vacation],
    );

    test('they are not exported by default', () {
      final events = buildExportEvents(
        schedule,
        calendarId: 'main',
        from: _from,
        to: _to,
      );
      expect(events.map((e) => e.shiftTypeId), ['morning']);
    });

    test('with the option on, they are', () {
      final events = buildExportEvents(
        schedule,
        calendarId: 'main',
        from: _from,
        to: _to,
        includeAbsences: true,
      );
      expect(events.map((e) => e.shiftTypeId), ['morning', 'sick', 'vacation']);
    });

    test('an export without the option never writes a sick leave', () async {
      final phone = FakeDeviceCalendar();
      final result = await CalendarExporter(phone).export(
        schedule: schedule,
        appCalendarId: 'main',
        target: const NewCalendar(),
        from: _from,
        to: _to,
        includeRest: true,
      );
      expect(result.created, 1);
      for (final e in phone.allEvents) {
        expect(e.title, isNot(contains('Baja')));
        expect(e.description ?? '', isNot(contains('sick')));
      }
    });

    test('switching the option off removes what it had written', () async {
      final phone = FakeDeviceCalendar();
      final exporter = CalendarExporter(phone);
      final first = await exporter.export(
        schedule: schedule,
        appCalendarId: 'main',
        target: const NewCalendar(),
        from: _from,
        to: _to,
        includeRest: false,
        includeAbsences: true,
      );
      expect(phone.eventsOf(first.deviceCalendarId), hasLength(3));
      final second = await exporter.export(
        schedule: schedule,
        appCalendarId: 'main',
        target: ExistingCalendar(first.deviceCalendarId),
        from: _from,
        to: _to,
        includeRest: false,
      );
      expect(second.removed, 2);
      expect(phone.eventsOf(first.deviceCalendarId), hasLength(1));
    });

    test('preview follows the option', () async {
      final phone = FakeDeviceCalendar();
      final exporter = CalendarExporter(phone);
      Future<int> count({required bool absences}) async =>
          (await exporter.preview(
            schedule: schedule,
            appCalendarId: 'main',
            deviceCalendarId: null,
            from: _from,
            to: _to,
            includeRest: false,
            includeAbsences: absences,
          )).toCreate.length;
      expect(await count(absences: false), 1);
      expect(await count(absences: true), 3);
    });
  });

  group('a calendar that syncs', () {
    DeviceCalendarInfo calendar(String? type) =>
        DeviceCalendarInfo(id: 'c', name: 'x', accountType: type);

    test('Google, CalDAV, iCloud and Exchange accounts are synced', () {
      for (final type in ['com.google', 'CalDAV', 'exchange', 'calDav']) {
        expect(calendar(type).isSynced, isTrue, reason: type);
      }
    });

    test('local calendars and unknown ones are not', () {
      for (final type in ['local', 'LOCAL', ' Local ', '', null]) {
        expect(calendar(type).isSynced, isFalse, reason: '$type');
      }
    });
  });

  group('whose event is it', () {
    final desired = buildExportEvents(
      scheduleOf({
        _from: ['morning'],
      }),
      calendarId: 'main',
      from: _from,
      to: _to,
    );

    ExportPlan plan(List<DeviceEvent> existing, {String device = 'cal-1'}) =>
        planExport(
          desired: desired,
          existing: existing,
          deviceCalendarId: device,
          calendarId: 'main',
          from: _from,
          to: _to,
        );

    DeviceEvent event(
      String id, {
      required String? description,
      String calendar = 'cal-1',
      String title = 'x',
    }) => DeviceEvent(
      instanceId: id,
      calendarId: calendar,
      title: title,
      description: description,
      start: DateTime(2026, 10, 19, 9),
      end: DateTime(2026, 10, 19, 10),
    );

    test('a tag quoted in the middle of a line is not ours', () {
      for (final text in [
        '$exportMarkerLine\nmira: ${exportTag('main', _from, 'x', 0)}',
        '$exportMarkerLine\n${exportTag('main', _from, 'x', 0)} y más',
        'Mi cita ${exportTag('main', _from, 'x', 0)}',
      ]) {
        expect(ExportTag.parse(text), isNull, reason: text);
        expect(plan([event('e', description: text)]).toDelete, isEmpty);
      }
    });

    test('a tag line under another first line is not ours', () {
      final text = 'Reunión de equipo\n${exportTag('main', _from, 'x', 0)}';
      expect(ExportTag.parse(text), isNull);
      expect(plan([event('e', description: text)]).toDelete, isEmpty);
      // The tag line alone, with no marker, is not ours either.
      expect(ExportTag.parse(exportTag('main', _from, 'x', 0)), isNull);
    });

    test('the marker line and the tag line are ours, with any line end', () {
      final tag = exportTag('main', _from, 'x', 0);
      for (final text in [
        '$exportMarkerLine\n$tag',
        '$exportMarkerLine\r\n$tag',
        '$exportMarkerLine\n$tag\nuna nota más',
      ]) {
        expect(ExportTag.parse(text), isNotNull, reason: text);
      }
    });

    test('an event of another phone calendar is never deleted', () {
      final foreign = event(
        'e',
        description: descriptionOf('x'),
        calendar: 'cal-2',
      );
      final p = plan([foreign]);
      expect(p.toDelete, isEmpty);
      // And a copy in the chosen calendar is.
      final mine = event('f', description: descriptionOf('x'));
      expect(plan([foreign, mine]).toDelete.map((e) => e.instanceId), ['f']);
    });

    test('the type of a tag does not have to exist any more', () {
      final gone = event('e', description: descriptionOf('tipo-borrado'));
      expect(plan([gone]).toDelete, [gone]);
    });
  });

  group('re-exporting', () {
    late FakeDeviceCalendar phone;
    late CalendarExporter exporter;
    final schedule = scheduleOf({
      _from: ['morning'],
      _from.addDays(1): ['night'],
    });

    Future<ExportResult> run(
      ExportTarget target, {
      Schedule? withSchedule,
      CivilDate from = _from,
      CivilDate to = _to,
    }) => exporter.export(
      schedule: withSchedule ?? schedule,
      appCalendarId: 'main',
      target: target,
      from: from,
      to: to,
      includeRest: false,
    );

    setUp(() {
      phone = FakeDeviceCalendar();
      exporter = CalendarExporter(phone);
    });

    test(
      'an event the user moved to another day is replaced, not copied',
      () async {
        final first = await run(const NewCalendar());
        final id = first.deviceCalendarId;
        final morning = phone
            .eventsOf(id)
            .firstWhere((e) => e.title == 'Mañana · M');
        // Dragged from 19 Oct to 5 Nov, outside the exported dates.
        await phone.deleteEvent(morning.instanceId);
        phone.addSimpleEvent(
          id,
          morning.title,
          DateTime(2026, 11, 5, 6),
          DateTime(2026, 11, 5, 14),
          description: morning.description,
        );
        expect(phone.eventsOf(id), hasLength(2));

        final second = await run(ExistingCalendar(id));
        // The moved copy is removed and the shift is written where it belongs.
        expect(second.removed, 1);
        expect(second.created, 1);
        final titles = phone.eventsOf(id).map((e) => e.title).toList()..sort();
        expect(titles, ['Mañana · M', 'Noche · N']);
        final back = phone
            .eventsOf(id)
            .firstWhere((e) => e.title == 'Mañana · M');
        expect(back.start, DateTime(2026, 10, 19, 6));
      },
    );

    test('an event whose tag is outside the dates is left alone even if it sits inside', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      // A copy tagged for a day we do not export now, sitting on the 20th.
      phone.addSimpleEvent(
        id,
        'Mañana · M',
        DateTime(2026, 10, 20, 6),
        DateTime(2026, 10, 20, 14),
        description:
            '$exportMarkerLine\n'
            '${exportTag('main', const CivilDate(2026, 12, 1), 'morning', 0)}',
      );
      final second = await run(ExistingCalendar(id));
      expect(second.removed, 0);
      expect(phone.eventsOf(id), hasLength(3));
    });

    test(
      'ids with a colon or a blank still round-trip and never duplicate',
      () async {
        const odd = ShiftType(
          id: 'night:x y',
          code: 'N',
          name: 'Noche rara',
          colorValue: 0xFF4B4FD1,
          category: ShiftCategory.work,
          startMinute: 22 * 60,
          endMinute: 6 * 60,
        );
        final s = Schedule(
          shiftTypes: const [odd],
          entries: {
            _from: DayEntry(date: _from, shiftTypeIds: const ['night:x y']),
          },
        );
        final event = buildExportEvents(
          s,
          calendarId: 'cal 1:b',
          from: _from,
          to: _to,
        ).single;
        final tag = ExportTag.parse(event.description)!;
        expect(tag.typeId, 'night:x y');
        expect(tag.calendarId, 'cal 1:b');
        expect(tag.key, event.tag);

        Future<ExportResult> runOdd(ExportTarget target) => exporter.export(
          schedule: s,
          appCalendarId: 'cal 1:b',
          target: target,
          from: _from,
          to: _to,
          includeRest: false,
        );
        final first = await runOdd(const NewCalendar());
        final id = first.deviceCalendarId;
        final second = await runOdd(ExistingCalendar(id));
        expect(second.created, 0);
        expect(second.removed, 0);
        expect(second.unchanged, 1);
        expect(phone.eventsOf(id), hasLength(1));
      },
    );

    test('ids Cuadrante makes are written as they are', () {
      expect(
        exportTag('main', _from, 'morning', 0),
        'cuadrante:v1:main:2026-10-19:morning:0',
      );
      expect(
        exportTag('3f2b-AA_1.x~', _from, 'b9e-1', 2),
        'cuadrante:v1:3f2b-AA_1.x~:2026-10-19:b9e-1:2',
      );
    });

    test('a failed deletion does not get its replacement written', () async {
      final first = await run(const NewCalendar());
      final id = first.deviceCalendarId;
      // The Mañana changes hours: same tag, other moments, so it is a
      // delete and a create of the same shift.
      const longer = ShiftType(
        id: 'morning',
        code: 'M',
        name: 'Mañana',
        colorValue: 0xFFF5A524,
        category: ShiftCategory.work,
        startMinute: 6 * 60,
        endMinute: 15 * 60,
      );
      final edited = Schedule(
        shiftTypes: [longer, ...baseTypes.skip(1)],
        entries: schedule.entries,
      );
      final stuck = phone
          .eventsOf(id)
          .firstWhere((e) => e.title == 'Mañana · M')
          .instanceId;
      phone.failDeleting.add(stuck);
      final broken = await run(ExistingCalendar(id), withSchedule: edited);
      // The delete and the skipped create both count as failed.
      expect(broken.failed, 2);
      expect(broken.created, 0);
      expect(phone.eventsOf(id), hasLength(2), reason: 'no second copy');

      phone.failDeleting.clear();
      final repaired = await run(ExistingCalendar(id), withSchedule: edited);
      expect(repaired.failed, 0);
      expect(repaired.removed, 1);
      expect(repaired.created, 1);
      expect(phone.eventsOf(id), hasLength(2));
      final morning = phone
          .eventsOf(id)
          .firstWhere((e) => e.title == 'Mañana · M');
      expect(morning.end, DateTime(2026, 10, 19, 15));
    });
  });
}
