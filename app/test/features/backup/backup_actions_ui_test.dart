import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/backup/presentation/verification_result_card.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../support/app_harness.dart';
import 'backup_test_support.dart';
import 'backup_ui_support.dart';
import 'golden_dataset.dart';
import 'golden_dataset_v2.dart';

/// The buttons of Ajustes > Copia de seguridad other than restoring:
/// export, the file picker, "Probar restauración", and the automatic copies
/// that follow the user's changes.
void main() {
  setUpAll(initializeLocale);

  Finder key(String k) => find.byKey(ValueKey(k));

  group('Exportar archivo', () {
    testWidgets('hands a decodable .turnly with today\'s date to the '
        'share sheet', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();

      await tapIo(tester, key('backup-export'));

      expect(h.shared, hasLength(1));
      final shared = h.shared.single;
      expect(shared.fileName, 'turnly-2026-10-19-120000.turnly');
      // It is a real backup of what the phone holds.
      final file = const BackupCodec().decode(shared.bytes);
      final live = await app.real(
        () => makeRepository(app.database, h.backups).readAll(),
      );
      expect(file.data.toJson(), live.toJson());
      expect(file.data.calendars.map((c) => c.name), ['Mi cuadrante']);
      // Exporting writes nothing on the phone.
      expect(h.files, isEmpty);
    });

    testWidgets('exports what is there now, not what was there before', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      await app.real(() => addSecondCalendar(app.database));

      await tapIo(tester, key('backup-export'));

      final file = const BackupCodec().decode(h.shared.single.bytes);
      expect(file.data.calendars.map((c) => c.name).toSet(), {
        'Mi cuadrante',
        'Pareja',
      });
    });

    testWidgets('a share sheet that fails says so', (tester) async {
      final h = BackupUiHarness(tester);
      h.shareImpl = (bytes, name) async =>
          throw const FileSystemException('nope');
      await h.open();
      await tapIo(
        tester,
        key('backup-export'),
        until: find.text('No se ha podido exportar el archivo.'),
      );
    });
  });

  group('Importar archivo', () {
    testWidgets('a picker that fails says so', (tester) async {
      final h = BackupUiHarness(tester);
      h.pickImpl = () async => throw StateError('picker');
      await h.open();
      await tapIo(
        tester,
        key('backup-import'),
        until: find.text('No se ha podido leer el archivo.'),
      );
      expect(key('restore-preview'), findsNothing);
    });
  });

  group('Probar restauración', () {
    testWidgets('without a copy there is nothing to test', (tester) async {
      final h = BackupUiHarness(tester);
      await h.open();
      await tapIo(
        tester,
        key('backup-verify'),
        until: key('backup-verify-result'),
      );
      expect(
        find.text('Todavía no hay ninguna copia que probar. Haz una primero.'),
        findsOneWidget,
      );
    });

    testWidgets('a fresh copy is complete and the same as the phone', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      await h.open();
      await tapIo(
        tester,
        key('backup-now'),
        until: find.textContaining('Copia del dispositivo'),
      );

      await tapIo(
        tester,
        key('backup-verify'),
        until: find.textContaining('La copia está completa'),
      );
      expect(
        find.text('La copia está completa: 730 días comprobados'),
        findsOneWidget,
      );
      expect(find.text('Es idéntica a lo que tienes ahora.'), findsOneWidget);
      expect(key('backup-verify-result'), findsOneWidget);
    });

    testWidgets('a copy older than the data is still complete, and says '
        'where they differ', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      await tapIo(
        tester,
        key('backup-now'),
        until: find.textContaining('Copia del dispositivo'),
      );
      await app.real(() => addSecondCalendar(app.database));

      await tapIo(
        tester,
        key('backup-verify'),
        until: find.textContaining('La copia está completa'),
      );
      expect(
        find.text('La copia está completa: 730 días comprobados'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Es anterior a lo que tienes ahora (el primer día que cambia es',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Es normal si has hecho cambios después.'),
        findsOneWidget,
      );
    });

    testWidgets('a copy that cannot be read is reported, not hidden', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      await h.open();
      // The newest copy is damaged.
      h.backups.createSync(recursive: true);
      File(
        p.join(h.backups.path, 'turnly-29990101-000000.turnly'),
      ).writeAsBytesSync(Uint8List.fromList(List<int>.generate(64, (i) => i)));
      await h.tester.runAsync(() async {});

      await tapIo(
        tester,
        key('backup-verify'),
        until: find.textContaining('No se ha podido probar la copia.'),
      );
      expect(
        find.text(
          'No se ha podido probar la copia. Este archivo no es una copia de '
          'Turnly.',
        ),
        findsOneWidget,
      );
    });
  });

  group('the result card', () {
    final window = defaultFingerprintWindow(const CivilDate(2026, 10, 19));
    final fingerprintV1 = scheduleFingerprint(
      buildGoldenBackupData(),
      from: window.from,
      to: window.to,
    );
    final fingerprintV2 = scheduleFingerprint(
      buildGoldenBackupDataV2(),
      from: window.from,
      to: window.to,
    );

    Future<void> show(WidgetTester tester, RestoreVerification? result) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('es'),
            supportedLocales: const [Locale('es')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: VerificationResultCard(result: result)),
          ),
        );

    testWidgets('mismatch names the first different day', (tester) async {
      final first = fingerprintV1.firstDayDifferingFrom(fingerprintV2);
      expect(first, isNotNull);
      await show(
        tester,
        VerificationMismatch(
          expected: fingerprintV1,
          actual: fingerprintV2,
          firstDifferingDay: first,
        ),
      );
      expect(
        find.textContaining(
          'La copia no se reconstruye igual. Primer día distinto: ',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Haz una copia nueva y avísanos.'),
        findsOneWidget,
      );
      expect(find.textContaining('La copia está completa'), findsNothing);
    });

    testWidgets('mismatch without a day: only stored data differs', (
      tester,
    ) async {
      await show(
        tester,
        VerificationMismatch(expected: fingerprintV1, actual: fingerprintV2),
      );
      expect(
        find.textContaining('los datos guardados no coinciden'),
        findsOneWidget,
      );
    });

    testWidgets('a failure to read the file', (tester) async {
      await show(tester, const VerificationFailed(CorruptBackup('truncated')));
      expect(
        find.text(
          'No se ha podido probar la copia. El archivo está dañado o '
          'incompleto y no se puede usar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failure of the dry run itself', (tester) async {
      await show(tester, VerificationFailed(StateError('scratch')));
      expect(
        find.text(
          'No se ha podido probar la copia. No se ha podido leer el '
          'archivo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a pass that matches the phone', (tester) async {
      await show(
        tester,
        VerificationPassed(fingerprint: fingerprintV1, matchesLive: true),
      );
      expect(
        find.text('La copia está completa: 730 días comprobados'),
        findsOneWidget,
      );
      expect(find.text('Es idéntica a lo que tienes ahora.'), findsOneWidget);
    });

    testWidgets('a pass older than the phone without a differing day', (
      tester,
    ) async {
      await show(
        tester,
        VerificationPassed(fingerprint: fingerprintV1, matchesLive: false),
      );
      expect(
        find.text(
          'Es anterior a lo que tienes ahora. Es normal si has hecho '
          'cambios después.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('nothing to test', (tester) async {
      await show(tester, null);
      expect(
        find.text('Todavía no hay ninguna copia que probar. Haz una primero.'),
        findsOneWidget,
      );
    });
  });

  group('automatic copies', () {
    testWidgets('a change is copied 10 s later, without the user doing '
        'anything', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      await pumpIo(tester);
      expect(h.filesStartingWith('turnly-'), isEmpty);

      await app.real(() => addSecondCalendar(app.database));
      // Not before the debounce (the pumps of the helper add a fraction of a
      // second)...
      await tester.pump(const Duration(seconds: 9));
      await pumpIo(tester);
      expect(h.filesStartingWith('turnly-'), isEmpty);
      expect(
        find.text('Hay cambios nuevos: la copia se hará en unos segundos.'),
        findsOneWidget,
      );

      // ...and then on its own, listed on the screen.
      await tester.pump(const Duration(seconds: 1));
      await pumpIo(tester, until: find.textContaining('Copia del dispositivo'));
      final names = h.filesStartingWith('turnly-');
      expect(names, hasLength(1));
      final file = const BackupCodec().decode(
        File(p.join(h.backups.path, names.single)).readAsBytesSync(),
      );
      expect(file.data.calendars.map((c) => c.name).toSet(), {
        'Mi cuadrante',
        'Pareja',
      });
      expect(find.textContaining('Hoy a las 12:00'), findsWidgets);
    });

    testWidgets('a change soon after a copy says when the next one comes, not '
        '«unos segundos» (H-T13-1)', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      await app.real(() => addSecondCalendar(app.database));
      await tester.pump(const Duration(seconds: 11));
      await pumpIo(tester, until: find.textContaining('Copia del dispositivo'));

      await app.real(() => addSecondCalendar(app.database, name: 'Otro'));
      await tester.pump(const Duration(seconds: 1));
      await pumpIo(tester);
      expect(
        find.textContaining('la próxima copia se hará hacia las 12:15'),
        findsOneWidget,
      );
      expect(find.textContaining('unos segundos'), findsNothing);
      // Nothing is copied before the spacing is over.
      await tester.pump(const Duration(minutes: 5));
      await pumpIo(tester);
      expect(h.filesStartingWith('turnly-'), hasLength(1));
      await tester.pump(const Duration(minutes: 11));
      await pumpIo(tester, rounds: 40);
      await pumpIo(tester, rounds: 40);
      expect(h.filesStartingWith('turnly-'), hasLength(2));
    });

    testWidgets('a burst of changes makes one copy', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();

      await app.real(() => addSecondCalendar(app.database, name: 'Uno'));
      await tester.pump(const Duration(seconds: 6));
      await app.real(
        () => ScheduleRepository(app.database, now: () => harnessNow).apply(
          mainCalendarId,
          ScheduleChange(
            patch: EntriesPatch({
              harnessToday.addDays(1): EntryChange(
                null,
                DayEntry(
                  date: harnessToday.addDays(1),
                  shiftTypeIds: const ['vacation'],
                ),
              ),
            }),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 6));
      await pumpIo(tester);
      expect(h.filesStartingWith('turnly-'), isEmpty);

      await tester.pump(const Duration(seconds: 5));
      await pumpIo(tester, until: find.textContaining('Copia del dispositivo'));
      await tester.pump(const Duration(minutes: 20));
      await pumpIo(tester);
      final names = h.filesStartingWith('turnly-');
      expect(names, hasLength(1));
      final file = const BackupCodec().decode(
        File(p.join(h.backups.path, names.single)).readAsBytesSync(),
      );
      // Both changes are in the one copy.
      expect(file.data.calendars.map((c) => c.name).toSet(), {
        'Mi cuadrante',
        'Uno',
      });
      expect(
        file.data.dayEntries.where(
          (e) =>
              e.calendarId == mainCalendarId &&
              e.date == harnessToday.addDays(1),
        ),
        isNotEmpty,
      );
    });

    testWidgets('the switch turns them off (and the choice is stored), '
        'and on again', (tester) async {
      final h = BackupUiHarness(tester);
      final app = await h.open();
      final toggle = key('backup-auto-switch');
      expect(tester.widget<Switch>(toggle).value, isTrue);
      expect(
        find.textContaining('Guardamos las 7 últimas y una por día'),
        findsOneWidget,
      );

      await tapIo(tester, toggle);
      expect(tester.widget<Switch>(toggle).value, isFalse);
      expect(
        find.text('Desactivadas: solo se copia cuando tú lo pides.'),
        findsOneWidget,
      );
      final stored = await app.real(
        () => app.database
            .customSelect(
              "SELECT value FROM settings WHERE key = 'backup.auto'",
            )
            .get(),
      );
      expect(stored.single.read<String>('value'), 'false');

      // A change with the switch off is not copied.
      await app.real(() => addSecondCalendar(app.database));
      await tester.pump(const Duration(minutes: 5));
      await pumpIo(tester);
      expect(h.filesStartingWith('turnly-'), isEmpty);

      // On again: the changes made meanwhile get their copy.
      await tapIo(tester, toggle);
      expect(tester.widget<Switch>(toggle).value, isTrue);
      await tester.pump(const Duration(seconds: 10));
      await pumpIo(tester, until: find.textContaining('Copia del dispositivo'));
      expect(h.filesStartingWith('turnly-'), hasLength(1));
    });

    testWidgets('"Hacer copia ahora" works with the switch off', (
      tester,
    ) async {
      final h = BackupUiHarness(tester);
      await h.open();
      await tapIo(tester, key('backup-auto-switch'));
      await tapIo(
        tester,
        key('backup-now'),
        until: find.textContaining('Copia del dispositivo'),
      );
      expect(h.filesStartingWith('turnly-'), hasLength(1));
    });
  });
}
