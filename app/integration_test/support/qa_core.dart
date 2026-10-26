import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Comma-separated scenario ids to run (`--dart-define=QA_ONLY=Q02,Q03`).
const String kQaOnly = String.fromEnvironment('QA_ONLY');

/// Comma-separated scenario ids to leave out (`--dart-define=QA_SKIP=Q13`).
const String kQaSkip = String.fromEnvironment('QA_SKIP');

/// One scenario of the battery: a stable id (`Q01`), a Spanish title and a
/// body. Add it to `scenarios/registry.dart` (docs/qa.md, "Cómo añadir un
/// escenario").
class QaScenario {
  const QaScenario(
    this.id,
    this.title,
    this.body, {
    this.timeout = const Duration(minutes: 3),
  });

  final String id;
  final String title;
  final Future<void> Function(QaContext qa) body;
  final Duration timeout;
}

/// What a scenario body gets: the tester plus the QA services (screenshots,
/// metrics, the captured Flutter errors).
class QaContext {
  QaContext(this.scenario, this.tester, this.binding);

  final QaScenario scenario;
  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;

  /// Every error that went through `FlutterError.onError` during the
  /// scenario (layout overflows, build errors, failed assertions in
  /// widgets). The runner fails the scenario if any is left at the end.
  final List<FlutterErrorDetails> errors = [];

  bool _surfaceConverted = false;

  String get id => scenario.id;

  /// Takes the screenshot `<id>.png` (or `<id>_<suffix>.png`) with
  /// `IntegrationTestWidgetsFlutterBinding.takeScreenshot`, saves it in the
  /// device cache (`qa_shots/`) and prints `QA_SHOT|...`. `run_android.sh`
  /// pulls the files into `build/qa/shots/` while the app is still installed.
  Future<void> shot([String? suffix]) async {
    final name = suffix == null ? id : '${id}_$suffix';
    try {
      if (Platform.isAndroid && !_surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        _surfaceConverted = true;
      }
      // A frame must be on the screen before the capture.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final bytes = await binding.takeScreenshot(name);
      final dir = Directory(
        p.join((await getTemporaryDirectory()).path, 'qa_shots'),
      );
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, '$name.png'));
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('QA_SHOT|$id|$name');
      // run_android.sh pulls the file and deletes it from the device: wait for
      // that (up to a few seconds) so the app is never torn down before it.
      await tester.runAsync(() async {
        final end = DateTime.now().add(const Duration(seconds: 6));
        while (file.existsSync() && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      });
    } catch (error) {
      // A screenshot must never decide the result of a scenario.
      // ignore: avoid_print
      print('QA_SHOT_FAILED|$id|$name|$error');
    }
  }

  /// A measured value that goes into the report (`QA_METRIC|id|name|value`).
  void metric(String name, Object value) {
    // ignore: avoid_print
    print('QA_METRIC|$id|$name|$value');
  }

  /// Free text for the report (`QA_NOTE|id|text`).
  void note(String text) {
    // ignore: avoid_print
    print('QA_NOTE|$id|${text.replaceAll('\n', ' // ')}');
  }

  /// Fails if a Flutter error was reported since the last call (and clears
  /// the list). Scenarios that care about a precise moment (text scale
  /// changes) call it themselves; the runner calls it at the end.
  void expectNoFlutterErrors([String? where]) {
    if (errors.isEmpty) return;
    final summary = errors
        .map((e) => e.exceptionAsString().split('\n').first)
        .toSet()
        .take(4)
        .join(' // ');
    final count = errors.length;
    errors.clear();
    throw TestFailure(
      '$count error(es) de Flutter${where == null ? '' : ' ($where)'}: '
      '$summary',
    );
  }
}

/// Registers [scenarios] as `testWidgets`, honouring `QA_ONLY` / `QA_SKIP`.
/// Prints the machine-readable lines `run_android.sh` parses:
/// `QA_START|id|title`, `QA_RESULT|id|PASS|ms|` and
/// `QA_RESULT|id|FAIL|ms|message`.
void registerQaScenarios(
  IntegrationTestWidgetsFlutterBinding binding,
  List<QaScenario> scenarios,
) {
  final only = kQaOnly
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty);
  final skip = kQaSkip
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty);
  for (final scenario in scenarios) {
    if (only.isNotEmpty && !only.contains(scenario.id)) continue;
    if (skip.contains(scenario.id)) continue;
    testWidgets(
      '${scenario.id} ${scenario.title}',
      (tester) => _run(binding, scenario, tester),
      timeout: Timeout(scenario.timeout),
    );
  }
}

Future<void> _run(
  IntegrationTestWidgetsFlutterBinding binding,
  QaScenario scenario,
  WidgetTester tester,
) async {
  final qa = QaContext(scenario, tester, binding);
  final stopwatch = Stopwatch()..start();
  // ignore: avoid_print
  print('QA_START|${scenario.id}|${scenario.title}');

  final previousOnError = FlutterError.onError;
  FlutterError.onError = qa.errors.add;
  try {
    await scenario.body(qa);
    qa.expectNoFlutterErrors('al terminar');
    // ignore: avoid_print
    print('QA_RESULT|${scenario.id}|PASS|${stopwatch.elapsedMilliseconds}|');
  } catch (error, stack) {
    final message = error.toString().replaceAll('\n', ' // ');
    await qa.shot('FALLO');
    // ignore: avoid_print
    print(
      'QA_RESULT|${scenario.id}|FAIL|${stopwatch.elapsedMilliseconds}|$message',
    );
    // ignore: avoid_print
    print(
      'QA_TRACE|${scenario.id}|'
      '${stack.toString().split('\n').take(8).join(' // ')}',
    );
    rethrow;
  } finally {
    FlutterError.onError = previousOnError;
  }
}
