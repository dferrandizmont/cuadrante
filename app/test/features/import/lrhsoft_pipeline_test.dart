import 'dart:io';

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:cuadrante/core/theme/shift_palette.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/import/data/lrhsoft_reader.dart';
import 'package:cuadrante/features/import/domain/event_grouping.dart';
import 'package:cuadrante/features/import/domain/import_models.dart';
import 'package:cuadrante/features/import/domain/import_plan.dart';
import 'package:cuadrante/features/import/domain/lrhsoft_backup.dart';
import 'package:cuadrante/features/import/domain/mapping_suggestions.dart';
import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'import_support.dart';
import 'lrhsoft_support.dart';

const _nov9 = CivilDate(2026, 11, 9);
const _nov19 = CivilDate(2026, 11, 19);
const _wide = ImportRange(CivilDate(2026, 1, 1), CivilDate(2026, 12, 31));

LrhsoftBackup _backup(List<ShifterDay> days) =>
    readLrhsoftBackup(buildShifter(types: sampleTypes, days: days));

EventGroup _group(LrhsoftBackup backup, String key) =>
    groupEvents(expandLrhsoft(backup, _wide).occurrences)
        .firstWhere((g) => g.key == key);

void main() {
  group('from a backup to occurrences', () {
    test('a shift with times is a timed occurrence; Libre is all day', () {
      final backup = _backup([
        ShifterDay(shifterDate(2026, 11, 9), t1: 7),
        ShifterDay(shifterDate(2026, 11, 14), t1: 3),
        ShifterDay(shifterDate(2026, 11, 16), t1: 5),
        ShifterDay(shifterDate(2026, 11, 17), t1: 4),
      ]);
      final out = expandLrhsoft(backup, _wide).occurrences;
      expect(out, hasLength(4));
      final byTitle = {for (final o in out) o.title: o};

      final morning = byTitle['Mañana']!;
      expect(morning.date, _nov9);
      expect((morning.startMinute, morning.endMinute), (420, 900));
      expect(morning.allDay, isFalse);
      expect(morning.codeHint, 'Mor.');
      expect(morning.colorValue, 0xFFFFF699);

      expect(byTitle['Libre']!.allDay, isTrue);
      expect(byTitle['Libre']!.startMinute, isNull);

      // A night that crosses midnight belongs to the day it starts.
      final night = byTitle['Noche']!;
      expect(night.date, const CivilDate(2026, 11, 16));
      expect((night.startMinute, night.endMinute), (23 * 60, 7 * 60));

      final split = byTitle['Partido']!;
      expect((split.segment2StartMinute, split.segment2EndMinute), (960, 1200));
    });

    test('a day with two shifts gives two occurrences, in the file order', () {
      final backup = _backup([
        ShifterDay(shifterDate(2026, 11, 19), t1: 7, t2: 6),
      ]);
      final out = expandLrhsoft(backup, _wide).occurrences;
      expect(out.map((o) => o.title), ['Mañana', 'Tarde']);
      expect(out.every((o) => o.date == _nov19), isTrue);
    });

    test('only the days inside the range, with their notes', () {
      final backup = _backup([
        ShifterDay(shifterDate(2026, 11, 9), t1: 7, note: '<p>uno</p>'),
        ShifterDay(shifterDate(2026, 11, 10), note: 'solo nota'),
        ShifterDay(shifterDate(2027, 1, 5), t1: 7, note: 'fuera'),
      ]);
      final out = expandLrhsoft(
        backup,
        const ImportRange(CivilDate(2026, 11, 1), CivilDate(2026, 11, 30)),
      );
      expect(out.occurrences, hasLength(1));
      expect(out.notes, {
        _nov9: 'uno',
        const CivilDate(2026, 11, 10): 'solo nota',
      });
    });

    test('two types with the same name stay apart', () {
      final backup = readLrhsoftBackup(
        buildShifter(
          types: const [
            ShifterType(
              1,
              'Mañana',
              abbreviation: 'M1',
              start: '07:00',
              end: '15:00',
            ),
            ShifterType(
              2,
              'MAÑANA',
              abbreviation: 'M2',
              start: '08:00',
              end: '16:00',
            ),
            ShifterType(3, ' ', abbreviation: 'X'),
            ShifterType(4, ''),
          ],
          days: [
            ShifterDay(shifterDate(2026, 11, 9), t1: 1, t2: 2),
            ShifterDay(shifterDate(2026, 11, 10), t1: 3, t2: 4),
          ],
        ),
      );
      final titles = lrhsoftTitles(backup);
      expect(titles[1], 'Mañana');
      expect(titles[2], 'MAÑANA (M2)');
      expect(titles[3], 'X');
      expect(titles[4], 'Turno 4');
      final groups = groupEvents(expandLrhsoft(backup, _wide).occurrences);
      expect(groups, hasLength(4));
    });

    test('the default range runs from the first to the last day', () {
      final backup = _backup([
        ShifterDay(shifterDate(2026, 10, 9), t1: 7),
        ShifterDay(shifterDate(2026, 11, 19), t1: 7),
      ]);
      expect(
        lrhsoftDefaultRange(backup, const CivilDate(2026, 10, 19)),
        const ImportRange(CivilDate(2026, 10, 9), CivilDate(2026, 11, 19)),
      );
    });
  });

  group('the type a group becomes', () {
    final backup = _backup([
      ShifterDay(shifterDate(2026, 11, 9), t1: 7),
      ShifterDay(shifterDate(2026, 11, 10), t1: 4),
      ShifterDay(shifterDate(2026, 11, 11), t1: 3),
      ShifterDay(shifterDate(2026, 11, 12), t1: 8),
    ]);

    ShiftTypeDraft draftOf(
      String key, {
      List<ShiftType> existing = const [],
      List<ShiftTypeDraft> alsoTaken = const [],
    }) => draftFromGroup(
      _group(backup, key),
      existing: existing,
      alsoTaken: alsoTaken,
      palette: [for (final c in ShiftPalette.editorChoices) c.toARGB32()],
      keepSourceColor: true,
    );

    test('name, code from the abbreviation, colour and times', () {
      final draft = draftOf('manana');
      expect(draft.name, 'Mañana');
      expect(draft.code, 'Mor');
      expect(draft.colorValue, 0xFFFFF699);
      expect(draft.hasTimes, isTrue);
      expect((draft.startMinute, draft.endMinute), (420, 900));
      expect(draft.category, ShiftCategory.work);
      expect(draft.validate(), isEmpty);
    });

    test('a split shift keeps both segments', () {
      final draft = draftOf('partido');
      expect((draft.startMinute, draft.endMinute), (600, 840));
      expect(draft.segment2StartMinute, 960);
      expect(draft.segment2DurationMinutes, 240);
      expect(draft.segment2EndMinute, 1200);
      expect(draft.validate(), isEmpty);
      final type = draft.toShiftType('x');
      expect(type.hasSegment2, isTrue);
      expect(type.scheduledMinutes, 480);
    });

    test('«Mor./Aft.» is MA, and a code that is taken gives way', () {
      final draft = draftOf('partido');
      expect(draft.code, 'MA');
      expect(draft.code.length, lessThanOrEqualTo(maxShiftCodeLength));
      // Taken by another type of the same import: the first letters of the
      // name take over.
      final other = draftOf('partido', alsoTaken: [draft]);
      expect(other.code, 'P');
      expect(
        draftOf(
          'manana',
          existing: const [
            ShiftType(
              id: 'x',
              code: 'MOR',
              name: 'Otro',
              colorValue: 0xFF000001,
              category: ShiftCategory.work,
            ),
          ],
        ).code,
        'M',
      );
    });

    test('Libre has no times, is a rest, and keeps its grey', () {
      final draft = draftOf('libre');
      expect(draft.hasTimes, isFalse);
      expect(draft.category, ShiftCategory.rest);
      expect(draft.code, 'Fre');
      // Not the exact grey that turns a type into the special «Libre».
      expect(draft.colorValue, isNot(ShiftPalette.rest.toARGB32()));
      expect(draft.colorValue & 0xFF000000, 0xFF000000);
    });

    test('a colour already used is kept: free colours are allowed', () {
      final used = ShiftType(
        id: 'u',
        code: 'U',
        name: 'Usado',
        colorValue: 0xFFFFF699,
        category: ShiftCategory.work,
      );
      expect(draftOf('manana', existing: [used]).colorValue, 0xFFFFF699);
    });

    test('abbreviations to codes', () {
      String code(String hint, [String name = 'Nombre']) =>
          suggestCodeFromAbbreviation(hint, name, const []);
      expect(code('N'), 'N');
      expect(code('GM'), 'GM');
      expect(code('Mor.'), 'Mor');
      expect(code('Bday.'), 'Bda');
      expect(code('Mor./Aft.'), 'MA');
      expect(code('Free Time'), 'FT');
      expect(code('A/B/C/D'), 'ABC');
      expect(code('...'), 'N', reason: 'nothing usable: from the name');
      expect(code('', 'Guardia'), 'G');
    });
  });

  group('known titles map to the types you have', () {
    ShiftType? suggestion(String title, [int days = 5]) {
      final group = EventGroup(
        key: normalizeTitle(title),
        title: title,
        count: days,
        timedCount: 0,
        allDayCount: days,
        sampleDates: const [],
      );
      return suggestMapping(group, baseTypes)?.type;
    }

    test('«Libre», «Descanso», «Free», «Day off» are the Libre type', () {
      for (final title in [
        'Libre',
        'Descanso',
        'Free',
        'Free Time',
        'Day off',
        'Día libre',
      ]) {
        expect(suggestion(title)?.id, 'rest', reason: title);
      }
    });

    test('other words are not guessed', () {
      expect(suggestion('Partido'), isNull);
      expect(suggestion('Birthday'), isNull);
      expect(suggestion('Dentista'), isNull);
    });
  });

  group('notes in the plan', () {
    ImportPlan plan({
      Schedule? schedule,
      Map<CivilDate, String> notes = const {},
      List<EventOccurrence> occurrences = const [],
      ConflictPolicy policy = ConflictPolicy.replace,
    }) => buildImportPlan(
      schedule: schedule ?? emptySchedule(),
      occurrences: occurrences,
      mappings: {'manana': const MapToType('morning')},
      policy: policy,
      notes: notes,
    );

    test('a note on a day with a shift is written with it', () {
      final result = plan(
        occurrences: [timed('Mañana', _nov9, 6, 14)],
        notes: {_nov9: 'Llevar informe'},
      );
      expect(result.written, 1);
      expect(result.notesWritten, 1);
      final day = result.result.entries[_nov9]!;
      expect(day.shiftTypeIds, ['morning']);
      expect(day.note, 'Llevar informe');
    });

    test('a note on a day with no shift is still written', () {
      final result = plan(notes: {_nov9: 'Solo una nota'});
      expect(result.written, 1);
      final day = result.result.entries[_nov9]!;
      expect(day.shiftTypeIds, isNull);
      expect(day.note, 'Solo una nota');
    });

    test('the same note again changes nothing (no duplicates)', () {
      final first = plan(
        occurrences: [timed('Mañana', _nov9, 6, 14)],
        notes: {_nov9: 'Llevar informe'},
      );
      final second = plan(
        schedule: first.result,
        occurrences: [timed('Mañana', _nov9, 6, 14)],
        notes: {_nov9: 'Llevar informe'},
      );
      expect(second.isEmpty, isTrue);
      expect(second.written, 0);
      expect(second.unchanged, 1);
    });

    test('a different note of yours is kept and the new one goes under it', () {
      final mine = emptySchedule(
        entries: {_nov9: const DayEntry(date: _nov9, note: 'Mía')},
      );
      final result = plan(schedule: mine, notes: {_nov9: 'De LRHSoft'});
      expect(result.result.entries[_nov9]!.note, 'Mía\nDe LRHSoft');
      expect(result.notesWritten, 1);
    });

    test(
      '«Mantener lo mío» leaves your note and fills only the empty ones',
      () {
        final mine = emptySchedule(
          entries: {_nov9: const DayEntry(date: _nov9, note: 'Mía')},
        );
        final result = plan(
          schedule: mine,
          notes: {_nov9: 'De LRHSoft', _nov19: 'Nueva'},
          policy: ConflictPolicy.keep,
        );
        expect(result.result.entries[_nov9]!.note, 'Mía');
        expect(result.result.entries[_nov19]!.note, 'Nueva');
        expect(result.written, 1);
      },
    );

    test('a note and a shift on an empty day are one entry', () {
      final result = plan(
        occurrences: [timed('Mañana', _nov9, 6, 14)],
        notes: {_nov9: 'Nota'},
      );
      expect(result.written, 1);
      expect(result.result.entries[_nov9]!.note, 'Nota');
      expect(result.result.entries[_nov9]!.shiftTypeIds, ['morning']);
    });
  });

  group('the size limits of the picker', () {
    late Directory cache;

    setUp(() => cache = Directory.systemTemp.createTempSync('lrh_picker_'));
    tearDown(() => cache.deleteSync(recursive: true));

    Future<PickedImportFile> pick(String name, List<int> bytes) {
      final file = File('${cache.path}/$name')..writeAsBytesSync(bytes);
      return readPickedFile(XFile(file.path), cacheDir: () async => cache);
    }

    test('a backup may be bigger than 5 MB (photos inside)', () async {
      final big = [
        ...sqliteHeader.codeUnits,
        ...List.filled(maxImportFileBytes + 1, 0),
      ];
      final picked = await pick('copia.Shifter', big);
      expect(picked.problem, isNull);
      expect(picked.bytes, hasLength(big.length));
      expect(picked.kind, ImportFileKind.lrhsoft);
    });

    test('anything else over 5 MB is still too big', () async {
      final picked = await pick(
        'enorme.csv',
        List.filled(maxImportFileBytes + 1, 65),
      );
      expect(picked.problem, ImportProblem.fileTooLarge);
    });

    test(
      'a backup over 50 MB is too complex, and its copy is deleted',
      () async {
        final file = File('${cache.path}/gigante.Shifter')
          ..writeAsBytesSync([
            ...sqliteHeader.codeUnits,
            ...List.filled(maxLrhsoftFileBytes, 0),
          ]);
        final picked = await readPickedFile(
          XFile(file.path),
          cacheDir: () async => cache,
        );
        expect(picked.problem, ImportProblem.tooComplex);
        expect(file.existsSync(), isFalse);
      },
    );
  });
}
