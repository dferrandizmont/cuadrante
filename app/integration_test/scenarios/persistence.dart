import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/application/backup_service.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/data/local_file_backup_store.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

const _oct26 = CivilDate(2026, 10, 26);
const _oct27 = CivilDate(2026, 10, 27);
const _oct28 = CivilDate(2026, 10, 28);
const _oct29 = CivilDate(2026, 10, 29);
const _oct30 = CivilDate(2026, 10, 30);

/// Q06.
const qaPersistence = QaScenario(
  'Q06',
  'Persistencia: cerrar y abrir la app',
  _persistence,
);

Future<void> _persistence(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);

  await enterPaintMode(t);
  await t.tapAndSettle(tool('afternoon'));
  await t.tapAndSettle(cell(_oct30));
  await t.tapAndSettle(tool('night'));
  // The stroke stays inside the month that is being edited: the grey days of
  // the neighbouring months are skipped (H-T24-12).
  await t.dragAcross([cell(_oct27), cell(_oct28), cell(_oct29)]);
  await t.tapAndSettle(find.byKey(const ValueKey('tool-eraser')));
  await t.tapAndSettle(cell(_oct26));
  await exitPaintMode(t);
  await app.flushWrites();

  final from = qaToday.addDays(-21);
  final before = app.resolved(from, 60);
  final dumpBefore = await app.dumpSchedule();
  expect(before.where((d) => d.contains('|afternoon|')), isNotEmpty);

  // Whole tree gone, connection closed, same file opened again.
  final file = File(p.join(app.dir.path, 'cuadrante.sqlite'));
  await app.restart();
  expect(file.existsSync() && file.lengthSync() > 0, isTrue);

  expect(
    app.resolved(from, 60),
    before,
    reason: '60 días iguales tras reabrir',
  );
  expect(await app.dumpSchedule(), dumpBefore, reason: 'BD idéntica');
  expect(inCell(_oct30, find.text('T')), findsOneWidget);
  expect(inCell(_oct27, find.text('N')), findsOneWidget);
  expect(inCell(_oct26, find.text('M')), findsNothing);
  await qa.shot('reabierto');
}

/// Q12.
const qaBackup = QaScenario(
  'Q12',
  'Copia de seguridad en el dispositivo',
  _backup,
);

Future<void> _backup(QaContext qa) async {
  final t = qa.tester;
  final app = await QaApp.open(qa);
  final safety = Directory(p.join(app.dir.path, 'backups'));
  final repository = BackupRepository(
    app.database,
    safetyDirectory: safety,
    appVersion: 'qa',
    now: () => qaNow.toUtc(),
  );
  final service = BackupService(
    repository: repository,
    store: LocalFileBackupStore(Directory(p.join(app.dir.path, 'store'))),
    appVersion: 'qa',
    now: () => qaNow.toUtc(),
  );
  final window = defaultFingerprintWindow(qaToday);
  Future<ScheduleFingerprint> fingerprint() async => scheduleFingerprint(
    (await t.runAsync(repository.readAll))!,
    from: window.from,
    to: window.to,
  );

  final original = await fingerprint();
  final exported = (await t.runAsync(service.exportBytes))!;
  expect(exported.length, greaterThan(100));
  final dayBefore = idsOn(app.schedule, _oct30);

  // Alter the data (paint) and wipe the rotation behind the app's back.
  await enterPaintMode(t);
  await t.tapAndSettle(tool('night'));
  await t.dragAcross([cell(_oct30), cell(const CivilDate(2026, 10, 31))]);
  await exitPaintMode(t);
  await app.flushWrites();
  await t.runAsync(
    () => app.database.customStatement('DELETE FROM pattern_runs'),
  );
  await t.runAsync(app.scheduleController.reload);
  await t.settle();
  expect(await fingerprint(), isNot(original), reason: 'los datos cambiaron');
  expect(idsOn(app.schedule, qaToday), '', reason: 'sin rotación, hoy vacío');

  // Restore: same fingerprint (entities and 730 resolved days).
  final pending = (await t.runAsync(() => service.inspect(exported)))!;
  expect(pending.file.appVersion, 'qa');
  await t.runAsync(
    () => app.scheduleController.runExclusive(() => service.restore(pending)),
  );
  await t.runAsync(app.scheduleController.reload);
  await t.settle();
  final restored = await fingerprint();
  expect(restored.digest, original.digest, reason: 'huella tras restaurar');
  expect(restored.firstDayDifferingFrom(original), isNull);
  expect(idsOn(app.schedule, _oct30), dayBefore);
  expect(inCell(qaToday, find.text('N')), findsOneWidget);
  final safetyCopies = safety.existsSync()
      ? safety.listSync().map((f) => p.basename(f.path)).toList()
      : <String>[];
  expect(
    safetyCopies.where((n) => n.startsWith('pre-restore')),
    isNotEmpty,
    reason: 'la restauración guarda antes una copia de seguridad',
  );
  await qa.shot('restaurado');

  // Damaged files are refused and the data stays as it was.
  final flipped = Uint8List.fromList(exported);
  flipped[flipped.length ~/ 2] ^= 0xFF;
  final truncated = Uint8List.sublistView(exported, 0, exported.length ~/ 2);
  final notOurs = Uint8List.fromList(List<int>.generate(64, (i) => i));
  for (final (name, bytes) in [
    ('un byte cambiado', flipped),
    ('truncado', truncated),
    ('no es un .cuadrante', notOurs),
  ]) {
    // `runAsync` swallows exceptions (it reports them to FlutterError and
    // returns null): catch inside, so the type of the error can be checked.
    final error = await t.runAsync<Object?>(() async {
      try {
        await service.inspect(bytes);
        return null;
      } on Object catch (e) {
        return e;
      }
    });
    expect(
      error,
      isA<BackupException>(),
      reason: 'archivo dañado ($name) debe rechazarse',
    );
  }
  expect(
    (await fingerprint()).digest,
    original.digest,
    reason: 'datos intactos',
  );
  expect(idsOn(app.schedule, _oct30), dayBefore);
}
