import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cuadrante/features/backup/application/backup_providers.dart';
import 'package:cuadrante/features/backup/data/backup_repository.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/auto_backup_policy.dart';
import 'package:cuadrante/features/backup/domain/backup_codec.dart';
import 'package:cuadrante/features/backup/domain/canonical_json.dart';
import 'package:cuadrante/features/backup/domain/schedule_fingerprint.dart';
import 'package:cuadrante/features/calendar/presentation/month_screen.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../support/qa_core.dart';
import '../support/qa_harness.dart';

/// Scenarios Q65 to Q69: the backup screens (Ajustes > Copia de seguridad,
/// release 0.4.0) on the phone, with the real file system, the real database
/// file and the real platform channel. The share sheet and the file picker
/// are the only fakes: they open system screens a test cannot drive. The
/// registry lists [backupUiScenarios].
final List<QaScenario> backupUiScenarios = [
  qaBackupFileRoundTrip, // Q65
  qaBackupNewerFile, // Q66
  qaBackupDamagedFile, // Q67
  qaBackupUndoRestore, // Q68
  qaBackupAutoCopy, // Q69
];

const _oct30 = CivilDate(2026, 10, 30);
const _oct27 = CivilDate(2026, 10, 27);

// ---- helpers ---------------------------------------------------------------

/// What every scenario of this file needs around the app: a scratch folder
/// for the copies (never the real Application Support one), and the share
/// sheet and the file picker in the hands of the test.
class _Env {
  _Env(this.qa);

  final QaContext qa;
  late final Directory backups;

  /// Every file the app handed to the share sheet.
  final List<({Uint8List bytes, String fileName})> shared = [];

  /// What "Importar archivo" gets from the picker.
  IncomingFile? picked;

  AutoBackupPolicy policy = const AutoBackupPolicy();

  Future<void> prepare() async {
    backups = (await qa.tester.runAsync(() async {
      final base = await getTemporaryDirectory();
      return Directory(
        p.join(
          base.path,
          'qa-${qa.id}-backups-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
    }))!;
    addTearDown(() {
      if (backups.existsSync()) backups.deleteSync(recursive: true);
    });
  }

  List<Override> get overrides => [
    backupDirectoryProvider.overrideWith((ref) async => backups),
    backupSharerProvider.overrideWithValue(
      (bytes, fileName) async => shared.add((bytes: bytes, fileName: fileName)),
    ),
    backupFilePickerProvider.overrideWithValue(() async => picked),
    autoBackupPolicyProvider.overrideWithValue(policy),
  ];

  List<String> files(String prefix) => backups.existsSync()
      ? ([
          for (final f in backups.listSync())
            if (p.basename(f.path).startsWith(prefix)) p.basename(f.path),
        ]..sort())
      : <String>[];

  /// The fingerprint of what the phone holds (entities and 730 resolved days
  /// of every calendar): the comparison of the restore matrix.
  Future<String> digest(QaApp app) async {
    final repository = BackupRepository(
      app.database,
      safetyDirectory: backups,
      appVersion: 'qa',
      now: () => qaNow.toUtc(),
    );
    final data = (await qa.tester.runAsync(repository.readAll))!;
    final window = defaultFingerprintWindow(qaToday);
    return scheduleFingerprint(data, from: window.from, to: window.to).digest;
  }

  Future<QaApp> open() async {
    await prepare();
    return QaApp.open(qa, overrides: overrides);
  }
}

Future<void> _openBackup(WidgetTester t) async {
  await t.tapAndSettle(
    find.byTooltip('Abrir ajustes'),
    reason: 'botón Ajustes',
  );
  await t.tapAndSettle(find.byKey(const ValueKey('settings-backup')));
  await t.waitFor(
    find.byKey(const ValueKey('backup-status')),
    reason: 'pantalla Copia de seguridad',
  );
  await _dismissSnackBars(t);
}

/// A «Copia hecha» left from an earlier step sits over the bottom rows of the
/// list (the last «Restaurar esta»): it is closed before tapping anything.
Future<void> _dismissSnackBars(WidgetTester t) async {
  final messenger = find.byType(ScaffoldMessenger);
  if (messenger.evaluate().isEmpty) return;
  t.state<ScaffoldMessengerState>(messenger.first).hideCurrentSnackBar();
  await t.settle();
}

Future<void> _home(WidgetTester t) async {
  for (var i = 0; i < 4 && find.byType(BackButton).evaluate().isNotEmpty; i++) {
    await t.tapAndSettle(find.byType(BackButton).last, reason: 'flecha atrás');
  }
  expect(find.byType(MonthScreen), findsOneWidget);
}

Finder _key(String k) => find.byKey(ValueKey(k));

/// "Importar archivo" with [bytes]: the preview (or the refusal) shows up.
Future<void> _import(WidgetTester t, _Env env, Uint8List bytes) async {
  env.picked = IncomingFile.bytes(bytes);
  await t.tapAndSettle(_key('backup-import'));
  await t.waitFor(
    find.byWidgetPredicate(
      (w) =>
          w.key == const ValueKey('restore-preview') ||
          w.key == const ValueKey('restore-unusable'),
    ),
    reason: 'vista previa o rechazo',
  );
}

/// Confirms the preview that is on screen and waits for the result.
Future<void> _confirmRestore(WidgetTester t) async {
  await t.tapAndSettle(_key('restore-confirm'));
  await t.waitFor(_key('restore-done'), reason: 'restauración terminada');
}

/// Waits (real time) for a file starting with [prefix] to appear.
Future<List<String>> _waitForFiles(
  QaContext qa,
  _Env env,
  String prefix, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await qa.tester.pump(const Duration(milliseconds: 200));
    final found = env.files(prefix);
    if (found.isNotEmpty) return found;
  }
  throw TestFailure('Ningún archivo $prefix* en ${env.backups.path}');
}

/// Paints [days] with the night shift, through the real controls.
Future<void> _paintNights(
  WidgetTester t,
  QaApp app,
  List<CivilDate> days,
) async {
  await enterPaintMode(t);
  await t.tapAndSettle(tool('night'));
  for (final day in days) {
    await t.tapAndSettle(cell(day));
  }
  await exitPaintMode(t);
  await app.flushWrites();
}

// ---- Q65 ---------------------------------------------------------------------

/// Q65.
const qaBackupFileRoundTrip = QaScenario(
  'Q65',
  'Copia: exportar, vaciar e importar da la misma huella (R4)',
  _fileRoundTrip,
);

Future<void> _fileRoundTrip(QaContext qa) async {
  final t = qa.tester;
  final env = _Env(qa);
  final app = await env.open();
  final original = await env.digest(app);
  final dayBefore = idsOn(app.schedule, qaToday);

  await _openBackup(t);
  // The line about the system backup is there (the real channel answers).
  if (Platform.isAndroid) {
    expect(find.textContaining('Copia del sistema de Android'), findsOneWidget);
  }
  await qa.shot('pantalla');

  // Export: the share sheet gets a real .cuadrante named for today.
  await t.tapAndSettle(_key('backup-export'));
  await t.waitFor(_key('backup-export'));
  expect(env.shared, hasLength(1), reason: 'se entregó un archivo');
  final exported = env.shared.single;
  // Named for today plus the time, so two exports never share a file.
  expect(
    exported.fileName,
    matches(RegExp(r'^turnly-2026-10-19-\d{6}\.turnly$')),
  );
  expect(const BackupCodec().decode(exported.bytes).data.calendars, isNotEmpty);
  await _home(t);

  // Wipe the schedule behind the app's back.
  await t.runAsync(() async {
    await app.database.customStatement('DELETE FROM day_entries');
    await app.database.customStatement('DELETE FROM pattern_runs');
  });
  await t.runAsync(app.scheduleController.reload);
  await t.settle();
  expect(await env.digest(app), isNot(original), reason: 'datos vaciados');
  expect(idsOn(app.schedule, qaToday), '', reason: 'sin rotación, hoy vacío');

  // Import it again: preview, then the one confirmation.
  await _openBackup(t);
  await _import(t, env, exported.bytes);
  expect(
    find.text('Esto sustituye lo que tienes ahora; antes guardamos una copia.'),
    findsOneWidget,
  );
  await qa.shot('vista_previa');
  await _confirmRestore(t);
  await qa.shot('restaurado');

  expect(await env.digest(app), original, reason: 'misma huella (R4)');
  expect(env.files('pre-restore-'), hasLength(1), reason: 'copia previa');
  await t.tapAndSettle(find.text('Ver mi calendario'));
  expect(find.byType(MonthScreen), findsOneWidget);
  expect(idsOn(app.schedule, qaToday), dayBefore);
  expect(inCell(qaToday, find.text('N')), findsOneWidget);
}

// ---- Q66 ---------------------------------------------------------------------

/// A well-formed envelope as the canonical gzip a `.cuadrante` is.
Uint8List _envelope(Map<String, Object?> map) => Uint8List.fromList(
  GZipCodec(level: 9).encode(utf8.encode(canonicalJson(map))),
);

/// Q66.
const qaBackupNewerFile = QaScenario(
  'Q66',
  'Copia: archivo de una versión más nueva, rechazado sin tocar nada (R6)',
  _newerFile,
);

Future<void> _newerFile(QaContext qa) async {
  final t = qa.tester;
  final env = _Env(qa);
  final app = await env.open();
  final original = await env.digest(app);
  final dumpBefore = await app.dumpSchedule();

  final newer = _envelope({
    'format': 'cuadrante',
    'schemaVersion': BackupCodec.supportedSchemaVersion + 1,
    'appVersion': '9.9.9',
    'exportedAt': '2030-01-01T00:00:00Z',
    'data': {'calendars': <Object?>[]},
    'checksum': 'blake3:nothing',
  });

  await _openBackup(t);
  await _import(t, env, newer);

  expect(_key('restore-unusable'), findsOneWidget);
  expect(
    find.text(
      'Este archivo es de una versión más nueva de Cuadrante: actualiza la '
      'app.',
    ),
    findsOneWidget,
  );
  expect(
    find.text('No hemos cambiado nada: tus datos siguen como estaban.'),
    findsOneWidget,
  );
  expect(_key('restore-confirm'), findsNothing, reason: 'nada que confirmar');
  await qa.shot('rechazado');

  expect(await env.digest(app), original, reason: 'huella intacta');
  expect(await app.dumpSchedule(), dumpBefore, reason: 'BD intacta');
  expect(env.files('pre-restore-'), isEmpty, reason: 'ni copia previa');

  // "Volver" is back on the copies.
  await t.tapAndSettle(find.text('Volver'));
  expect(_key('backup-status'), findsOneWidget);
}

// ---- Q67 ---------------------------------------------------------------------

/// Q67.
const qaBackupDamagedFile = QaScenario(
  'Q67',
  'Copia: archivo dañado o cortado, rechazado sin tocar nada (R7)',
  _damagedFile,
);

Future<void> _damagedFile(QaContext qa) async {
  final t = qa.tester;
  final env = _Env(qa);
  final app = await env.open();
  final original = await env.digest(app);
  final dumpBefore = await app.dumpSchedule();

  // A real backup, then damaged in the three ways of the matrix.
  await _openBackup(t);
  await t.tapAndSettle(_key('backup-export'));
  await t.waitFor(_key('backup-export'));
  final good = env.shared.single.bytes;
  final truncated = Uint8List.sublistView(good, 0, good.length ~/ 2);
  final flipped = Uint8List.fromList(good)..[good.length ~/ 2] ^= 0xFF;
  final notOurs = Uint8List.fromList(List<int>.generate(64, (i) => i));

  for (final (name, bytes, message) in [
    (
      'cortado',
      truncated,
      'El archivo está dañado o incompleto y no se puede usar.',
    ),
    (
      'un byte cambiado',
      flipped,
      'El archivo está dañado o incompleto y no se puede usar.',
    ),
    (
      'no es un .cuadrante',
      notOurs,
      'Este archivo no es una copia de Cuadrante.',
    ),
  ]) {
    await _import(t, env, bytes);
    expect(_key('restore-unusable'), findsOneWidget, reason: name);
    expect(find.text(message), findsOneWidget, reason: name);
    expect(
      find.text('No hemos cambiado nada: tus datos siguen como estaban.'),
      findsOneWidget,
      reason: name,
    );
    expect(_key('restore-confirm'), findsNothing, reason: name);
    if (name == 'cortado') await qa.shot('rechazado');

    expect(await env.digest(app), original, reason: 'huella intacta ($name)');
    expect(await app.dumpSchedule(), dumpBefore, reason: 'BD intacta ($name)');
    expect(env.files('pre-restore-'), isEmpty, reason: 'sin copia previa');
    await t.tapAndSettle(find.text('Volver'));
    expect(_key('backup-status'), findsOneWidget);
  }

  // The undamaged file still imports (the refusals did not break anything).
  await _import(t, env, good);
  expect(_key('restore-preview'), findsOneWidget);
}

// ---- Q68 ---------------------------------------------------------------------

/// Q68.
const qaBackupUndoRestore = QaScenario(
  'Q68',
  'Copia: restaurar y «Volver a como estaba» desde la copia previa',
  _undoRestore,
);

Future<void> _undoRestore(QaContext qa) async {
  final t = qa.tester;
  final env = _Env(qa);
  final app = await env.open();
  final f0 = await env.digest(app);

  // A copy of the data as it is now...
  await _openBackup(t);
  await t.tapAndSettle(_key('backup-now'));
  await _waitForFiles(qa, env, 'cuadrante-');
  await t.waitFor(find.textContaining('Hoy a las 18:20'));
  await _dismissSnackBars(t);
  await _home(t);

  // ...then the user keeps working: two nights painted.
  await _paintNights(t, app, [_oct30, _oct27]);
  expect(inCell(_oct30, find.text('N')), findsOneWidget);
  final f1 = await env.digest(app);
  expect(f1, isNot(f0), reason: 'los turnos pintados cambian la huella');

  // Restore the earlier copy from the list.
  await _openBackup(t);
  final copy = env.files('cuadrante-').single;
  await t.tapAndSettle(_key('backup-restore-$copy'));
  await t.waitFor(_key('restore-preview'));
  expect(
    t.widget<Text>(_key('restore-origin')).data,
    'COPIA DE ESTE DISPOSITIVO',
  );
  await _confirmRestore(t);
  expect(await env.digest(app), f0, reason: 'vuelve a la copia anterior');
  expect(env.files('pre-restore-'), hasLength(1));
  await qa.shot('restaurado');

  // "Volver a como estaba": the safety copy brings back the painted nights.
  expect(find.text('Volver a como estaba'), findsOneWidget);
  await t.tapAndSettle(find.text('Volver a como estaba'));
  await t.waitFor(_key('restore-preview'));
  expect(find.text('COPIA DE JUSTO ANTES DE RESTAURAR'), findsOneWidget);
  await _confirmRestore(t);
  expect(await env.digest(app), f1, reason: 'como estaba antes de restaurar');

  await t.tapAndSettle(find.text('Ver mi calendario'));
  expect(inCell(_oct30, find.text('N')), findsOneWidget);
  expect(inCell(_oct27, find.text('N')), findsOneWidget);
  await qa.shot('como_estaba');
}

// ---- Q69 ---------------------------------------------------------------------

/// Q69.
const qaBackupAutoCopy = QaScenario(
  'Q69',
  'Copia: la copia automática aparece tras pintar',
  _autoCopy,
);

Future<void> _autoCopy(QaContext qa) async {
  final t = qa.tester;
  final env = _Env(qa)
    // The same rules, a hundredth of the waits.
    ..policy = const AutoBackupPolicy(
      debounce: Duration(seconds: 2),
      maxDebounce: Duration(seconds: 6),
    );
  final app = await env.open();
  expect(env.files('cuadrante-'), isEmpty, reason: 'ninguna copia al empezar');

  await _paintNights(t, app, [_oct30]);

  // Nobody pressed anything: a copy shows up by itself.
  final names = await _waitForFiles(qa, env, 'cuadrante-');
  expect(names, hasLength(1));
  final bytes = await t.runAsync(
    () => File(p.join(env.backups.path, names.single)).readAsBytes(),
  );
  final file = const BackupCodec().decode(bytes!);
  expect(
    file.data.dayEntries.where((e) => e.date == _oct30),
    isNotEmpty,
    reason: 'la copia incluye lo que se acaba de pintar',
  );

  // And the screen tells it as it is.
  await _openBackup(t);
  await t.waitFor(find.textContaining('Hoy a las 18:20'));
  expect(find.text('En este dispositivo'), findsOneWidget);
  await t.waitFor(find.textContaining('Copia del dispositivo'));
  await t.ensureVisible(find.textContaining('Copia del dispositivo').first);
  await t.settle();
  expect(find.textContaining('Copia del dispositivo'), findsOneWidget);
  expect(_key('backup-failed-title'), findsNothing);
  await qa.shot('copia_automatica');
}
