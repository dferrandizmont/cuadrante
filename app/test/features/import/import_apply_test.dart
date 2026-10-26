import 'dart:isolate';
import 'dart:typed_data';

import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/calendar_export/data/plugin_device_calendar_api.dart';
import 'package:cuadrante/features/import/domain/event_grouping.dart';
import 'package:cuadrante/features/import/domain/ics_expansion.dart';
import 'package:cuadrante/features/import/domain/ics_parser.dart';
import 'package:cuadrante/features/import/domain/import_files.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/import_plan.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_storage.dart';
import 'import_support.dart';

final _now = DateTime(2026, 10, 19, 12);
const _d = CivilDate(2026, 11, 2);

class _FailSecondTypeDeletion extends ScheduleRepository {
  _FailSecondTypeDeletion(super.db);

  @override
  Future<bool> deleteShiftTypeIfUnused(String id) {
    if (id == 'imported-2') throw StateError('Deletion failed');
    return super.deleteShiftTypeIfUnused(id);
  }
}

/// `ScheduleController.applyPlanned` with an import plan, against a real
/// database: ONE undo step, the new shift types saved in the same
/// transaction, and what is stored always matches the screen.
void main() {
  late TestStorage storage;
  late ProviderContainer container;

  ScheduleController controller() =>
      container.read(scheduleControllerProvider.notifier);
  ScheduleState state() => container.read(scheduleControllerProvider);
  Schedule schedule() => state().schedule;
  String ids(CivilDate d) => schedule().resolve(d).shiftIds.join('+');

  setUp(() async {
    storage = await TestStorage.open(now: _now);
    addTearDown(storage.close);
    container = ProviderContainer(
      overrides: [
        ...storage.overrides,
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(() async {
      try {
        await controller().pendingWrites;
      } catch (_) {}
      container.dispose();
    });
  });

  ({ScheduleChange change, List<ShiftType> newTypes}) planFor(
    Schedule current,
    List<EventOccurrence> events,
    Map<String, GroupMapping> mappings, {
    ConflictPolicy policy = ConflictPolicy.replace,
  }) {
    final plan = buildImportPlan(
      schedule: current,
      occurrences: events,
      mappings: mappings,
      policy: policy,
    );
    return (change: plan.change, newTypes: plan.newTypes);
  }

  final events = [
    for (var i = 0; i < 5; i++) timed('Refuerzo', _d.addDays(i), 9, 17),
    timed('Mañana', _d.addDays(7), 6, 14),
  ];
  final mappings = <String, GroupMapping>{
    'refuerzo': CreateType(
      'imported-1',
      const ShiftTypeDraft(
        code: 'R',
        name: 'Refuerzo',
        colorValue: 0xFF123456,
        startMinute: 9 * 60,
        endMinute: 17 * 60,
      ),
    ),
    'manana': const MapToType('morning'),
  };

  test(
    'is ONE undo step, with the new type, and everything is stored',
    () async {
      await controller().pendingWrites;
      final before = await dumpTables(storage.database);
      final entriesBefore = schedule().entries;

      final step = controller().applyPlanned(
        (current) => planFor(current, events, mappings),
      );
      expect(step, isNotNull);
      expect(ids(_d), 'imported-1');
      expect(ids(_d.addDays(4)), 'imported-1');
      expect(ids(_d.addDays(7)), 'morning');
      expect(schedule().shiftTypeById('imported-1')!.name, 'Refuerzo');
      expect(state().palette.map((t) => t.id), contains('imported-1'));
      expect(state().canUndo, isTrue);

      await controller().pendingWrites;
      final after = await dumpTables(storage.database);
      expect(
        after['shift_types']!.where((r) => r['id'] == 'imported-1'),
        hasLength(1),
      );
      expect(
        after['day_entries']!.where(
          (r) => (r['shift_type_ids'] as String?) == '["imported-1"]',
        ),
        hasLength(5),
      );

      // One undo gives back the days (the new type stays, like any type).
      controller().undo();
      expect(schedule().entries, entriesBefore);
      expect(state().canUndo, isFalse);
      await controller().pendingWrites;
      final undone = await dumpTables(storage.database);
      expect(undone['day_entries'], before['day_entries']);
      expect(undone['pattern_runs'], before['pattern_runs']);

      // And redo applies it again.
      controller().redo();
      expect(ids(_d), 'imported-1');
      await controller().pendingWrites;
      expect(
        (await dumpTables(storage.database))['day_entries'],
        after['day_entries'],
      );
    },
  );

  test(
    'undoIfLast takes back the import only while it is the last step',
    () async {
      final step = controller().applyPlanned(
        (current) => planFor(current, events, mappings),
      )!;
      controller().setNote(_d.addDays(20), 'otra cosa');
      expect(controller().undoIfLast(step), isFalse);
      expect(ids(_d), 'imported-1', reason: 'left alone');
    },
  );

  test(
    'undoImport removes unused types and makes only that step non-redoable',
    () async {
      final before = schedule().entries;
      final step = controller().applyPlanned(
        (current) => planFor(current, events, mappings),
      )!;
      final result = await controller().undoImport(step, ['imported-1']);
      expect(result.undone, isTrue);
      expect(result.keptTypes, isEmpty);
      expect(state().canRedo, isFalse);
      expect(schedule().shiftTypeById('imported-1'), isNull);
      controller().redo();
      await controller().pendingWrites;
      expect(schedule().entries, before);
      final stored = (await storage.repository.load(state().calendarId))
          .schedule;
      expect(stored.entries, before);
      expect(stored.shiftTypeById('imported-1'), isNull);
      for (final entry in stored.entries.values) {
        for (final id in entry.shiftTypeIds ?? <String>[]) {
          expect(stored.shiftTypeById(id), isNotNull);
        }
      }
    },
  );

  test(
    'undoImport keeps redo when all imported types are still used',
    () async {
      final step = controller().applyPlanned(
        (current) => planFor(current, events, mappings),
      )!;
      await controller().pendingWrites;
      // A shared rotation keeps the imported type even after its days go away.
      await storage.repository.savePattern(
        const Pattern(
          id: 'uses-import',
          name: 'Refuerzo',
          steps: [
            ['imported-1'],
          ],
        ),
      );
      final result = await controller().undoImport(step, ['imported-1']);
      expect(result.undone, isTrue);
      expect(result.keptTypes, ['Refuerzo']);
      expect(state().canRedo, isTrue);
      controller().redo();
      await controller().pendingWrites;
      expect(ids(_d), 'imported-1');
      final stored = (await storage.repository.load(state().calendarId))
          .schedule;
      expect(stored.resolve(_d).shiftIds, ['imported-1']);
      expect(stored.shiftTypeById('imported-1'), isNotNull);
      expect(state().saveErrors, 0);
    },
  );

  test(
    'a later deletion failure cannot leave a removed type redoable',
    () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          ...storage.overrides,
          scheduleRepositoryProvider.overrideWithValue(
            _FailSecondTypeDeletion(storage.database),
          ),
          clockProvider.overrideWithValue(() => _now),
        ],
      );
      final step = controller().applyPlanned(
        (current) => planFor(
          current,
          [...events, timed('Apoyo', _d.addDays(8), 9, 17)],
          {
            ...mappings,
            'apoyo': CreateType(
              'imported-2',
              const ShiftTypeDraft(
                code: 'A',
                name: 'Apoyo',
                colorValue: 0xFF123456,
                startMinute: 540,
                endMinute: 1020,
              ),
            ),
          },
        ),
      )!;
      await expectLater(
        controller().undoImport(step, ['imported-1', 'imported-2']),
        throwsStateError,
      );
      expect(state().canRedo, isFalse);
      expect(schedule().shiftTypeById('imported-1'), isNull);
      expect(schedule().shiftTypeById('imported-2'), isNotNull);
      controller().redo();
      await controller().pendingWrites;
      final stored = (await storage.repository.load(state().calendarId))
          .schedule;
      expect(stored.entries, schedule().entries);
      expect(stored.shiftTypeById('imported-1'), isNull);
      expect(stored.resolve(_d).shiftIds, isNot(contains('imported-1')));
      expect(state().saveErrors, 0);
    },
  );

  test('an empty plan changes and records nothing', () async {
    final step = controller().applyPlanned(
      (current) => planFor(current, [timed('Nada', _d, 9, 17)], mappings),
    );
    expect(step, isNull);
    expect(state().canUndo, isFalse);
  });

  test('the plan is computed against the schedule as it is NOW', () async {
    Schedule? seen;
    controller().beginStroke(const PaintTool.replace('night'));
    controller().paintDay(_d);
    controller().applyPlanned((current) {
      seen = current;
      return planFor(current, events, mappings);
    });
    // The open stroke was closed first, so the plan saw the painted day.
    expect(seen!.resolve(_d).shiftIds, ['night']);
    expect(controller().strokeActive, isFalse);
    expect(ids(_d), 'imported-1');
    controller().undo();
    expect(ids(_d), 'night', reason: 'the stroke is its own step');
    controller().undo();
    expect(ids(_d), isNot('night'));
  });

  test('a write that fails is reported to the screen, not thrown', () async {
    await controller().pendingWrites;
    await storage.database.close();
    final step = controller().applyPlanned(
      (current) => planFor(current, events, mappings),
    );
    expect(step, isNotNull, reason: 'the screen shows it at once');
    await controller().pendingWrites;
    expect(state().saveErrors, 1);
    expect(
      state().canUndo,
      isFalse,
      reason: 'history dropped with the recovery',
    );
  });

  group('in a background isolate', () {
    final ics = Uint8List.fromList(
      '''BEGIN:VCALENDAR\r
BEGIN:VEVENT\r
UID:a\r
DTSTART;TZID=Europe/Madrid:20261102T060000\r
DTEND;TZID=Europe/Madrid:20261102T140000\r
RRULE:FREQ=DAILY;COUNT=10;INTERVAL=2\r
EXDATE;TZID=Europe/Madrid:20261104T060000\r
SUMMARY:Mañana\r
END:VEVENT\r
END:VCALENDAR\r
'''
          .codeUnits,
    );

    test('the document, the expansion and the table cross isolates', () async {
      final document = await Isolate.run(() => readIcsFile(ics));
      expect(document, isA<IcsDocument>());
      final range = ImportRange(_d, _d.addDays(60));
      final expansion = await Isolate.run(
        () => expandIcs(document, range, targetZone: 'Europe/Madrid'),
      );
      expect(expansion.occurrences.map((o) => o.date.toIso()), [
        '2026-11-02',
        '2026-11-06',
        '2026-11-08',
        '2026-11-10',
        '2026-11-12',
        '2026-11-14',
        '2026-11-16',
        '2026-11-18',
        '2026-11-20',
      ]);

      final csv = Uint8List.fromList('fecha,turno\n02/11/2026,M\n'.codeUnits);
      final table = await Isolate.run(() => readCsvFile(csv));
      expect(table.rows, hasLength(2));
    });

    test('the time-zone database loads inside the isolate', () async {
      final text = Uint8List.fromList(
        'BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nUID:z\r\n'
                'DTSTART:20261120T210000Z\r\nDTEND:20261121T050000Z\r\n'
                'SUMMARY:Noche\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n'
            .codeUnits,
      );
      final document = readIcsFile(text);
      final range = ImportRange(_d, _d.addDays(60));
      final expansion = await Isolate.run(
        () => expandIcs(document, range, targetZone: 'Europe/Madrid'),
      );
      final o = expansion.occurrences.single;
      // 21:00Z in November is 22:00 in Madrid (CET).
      expect(o.date, const CivilDate(2026, 11, 20));
      expect(o.startMinute, 22 * 60);
      expect(o.endMinute, 6 * 60);
    });

    test('a typed error crosses the isolate as the same error', () async {
      await expectLater(
        Isolate.run(
          () =>
              readIcsFile(Uint8List.fromList('no es un calendario'.codeUnits)),
        ),
        throwsA(
          isA<ImportException>().having(
            (e) => e.problem,
            'problem',
            ImportProblem.notCalendarFile,
          ),
        ),
      );
    });

    test('a big file is parsed without blocking for long', () async {
      final text = StringBuffer('BEGIN:VCALENDAR\r\n');
      for (var i = 0; i < 20000; i++) {
        final d = const CivilDate(2020, 1, 1).addDays(i % 2000);
        final compact = d.toIso().replaceAll('-', '');
        text.write(
          'BEGIN:VEVENT\r\nUID:$i\r\nDTSTART;VALUE=DATE:$compact\r\nSUMMARY:Turno $i\r\nEND:VEVENT\r\n',
        );
      }
      text.write('END:VCALENDAR\r\n');
      final bytes = Uint8List.fromList(text.toString().codeUnits);
      expect(bytes.length, lessThan(maxImportFileBytes));
      final watch = Stopwatch()..start();
      final document = await Isolate.run(() => readIcsFile(bytes));
      expect(document.events, hasLength(20000));
      expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
      final expansion = expandIcs(
        document,
        const ImportRange(CivilDate(2020, 1, 1), CivilDate(2025, 12, 31)),
      );
      expect(expansion.truncated, isTrue);
      expect(expansion.occurrences, hasLength(maxImportEvents));
      expect(groupEvents(expansion.occurrences), isNotEmpty);
    });
  });

  test('parseHexColor', () {
    expect(parseHexColor('#1C7ED6'), 0xFF1C7ED6);
    expect(parseHexColor('1c7ed6'), 0xFF1C7ED6);
    expect(parseHexColor('#801C7ED6'), 0x801C7ED6);
    expect(parseHexColor(null), isNull);
    expect(parseHexColor('rojo'), isNull);
    expect(parseHexColor('#12'), isNull);
  });
}
