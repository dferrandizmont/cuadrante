// Builds build/qa/report.md from the log of the QA battery.
//
//   dart tool/qa/report.dart --log build/qa/integration.log --out build/qa \
//     --flutter-exit 0 --duration 321 --device "emulator-5580 (...)" --avd Mochila_Phone
//
// The tests print machine-readable lines (support/qa_core.dart):
//   QA_START|id|title            QA_RESULT|id|PASS|ms|        QA_RESULT|id|FAIL|ms|message
//   QA_TRACE|id|stack            QA_SHOT|id|name              QA_METRIC|id|name|value
//   QA_NOTE|id|text
// Extra options:
//   --extra-log <file>  more QA_* lines (U02, from tool/qa/upgrade_android.sh) merged into the report
//   --append 1          the report already exists (a battery ran earlier): only add the rows of
//                       --extra-log to it (a standalone U02 run)
// Exit code: 0 when at least one scenario ran and all passed, 1 otherwise.
import 'dart:convert';
import 'dart:io';

class _Scenario {
  _Scenario(this.id, this.title);
  final String id;
  final String title;
  String? status; // PASS | FAIL
  int ms = 0;
  String message = '';
  String trace = '';
  final metrics = <String, String>{};
  final notes = <String>[];
}

void main(List<String> args) {
  final opts = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    opts[args[i].replaceFirst('--', '')] = args[i + 1];
  }
  final out = Directory(opts['out']!);
  final flutterExit = int.tryParse(opts['flutter-exit'] ?? '') ?? 1;
  final duration = int.tryParse(opts['duration'] ?? '') ?? 0;

  List<String> readLines(String? path) => path != null && File(path).existsSync()
      ? utf8.decode(File(path).readAsBytesSync(), allowMalformed: true).split(RegExp(r'\r?\n'))
      : <String>[];
  final extraLines = readLines(opts['extra-log']);
  if (opts['append'] == '1' && File('${out.path}/report.md').existsSync()) {
    _appendToReport(File('${out.path}/report.md'), out, extraLines);
    return;
  }
  final lines = [...readLines(opts['log']), ...extraLines];
  final scenarios = <String, _Scenario>{};
  final order = <String>[];
  final shotNames = <String>[];
  _parse(lines, scenarios, order, shotNames);

  final shotsDir = Directory('${out.path}/shots');
  final available = shotsDir.existsSync()
      ? [
          for (final f in shotsDir.listSync().whereType<File>())
            f.uri.pathSegments.last,
        ]
      : <String>[];
  String shotsOf(String id) {
    final mine = [
      for (final f in available)
        if (f.endsWith('.png') && (f == '$id.png' || f.startsWith('${id}_')))
          f,
    ]..sort();
    if (mine.isEmpty) return '—';
    return mine
        .map((f) => '[${f.substring(0, f.length - 4)}](shots/$f)')
        .join(' ');
  }

  var passed = 0;
  final failed = <_Scenario>[];
  for (final id in order) {
    final s = scenarios[id]!;
    if (s.status == 'PASS') {
      passed++;
    } else {
      failed.add(s);
    }
  }
  final total = order.length;
  final ok = total > 0 && failed.isEmpty && flutterExit == 0;

  final b = StringBuffer()
    ..writeln('# Informe de la batería QA — Cuadrante')
    ..writeln()
    ..writeln('- Resultado: **${ok ? 'TODO EN VERDE' : 'HAY FALLOS'}** '
        '($passed/$total escenarios)')
    ..writeln('- Fecha: ${DateTime.now().toIso8601String().split('.').first}')
    ..writeln('- Dispositivo: ${opts['device'] ?? '?'} (AVD ${opts['avd'] ?? '?'}'
        '${opts['started-emulator'] == '1' ? ', arrancado por esta ejecución' : ', ya estaba en marcha'})')
    ..writeln('- Duración total: ${_fmt(duration * 1000)} (`flutter test` terminó con código $flutterExit)');
  if ((opts['only'] ?? '').isNotEmpty) {
    b.writeln('- Ejecución parcial: solo `${opts['only']}` — **no vale como batería completa de release**');
  }
  if ((opts['skip'] ?? '').isNotEmpty) {
    b.writeln('- Omitidos: `${opts['skip']}` — **no vale como batería completa de release**');
  }
  b
    ..writeln()
    ..writeln('| id | título | resultado | duración | captura |')
    ..writeln('|---|---|:---:|---:|---|');
  for (final id in order) {
    final s = scenarios[id]!;
    final mark = s.status == 'PASS' ? '✔' : '✘';
    final title = s.title.replaceAll('|', '/');
    b.writeln('| ${s.id} | $title | $mark | ${_fmt(s.ms)} | ${shotsOf(s.id)} |');
  }

  final withMetrics = [for (final id in order) if (scenarios[id]!.metrics.isNotEmpty || scenarios[id]!.notes.isNotEmpty) scenarios[id]!];
  if (withMetrics.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Mediciones');
    for (final s in withMetrics) {
      for (final e in s.metrics.entries) {
        b.writeln('- ${s.id} · ${e.key}: ${e.value}');
      }
      for (final n in s.notes) {
        b.writeln('- ${s.id} · nota: $n');
      }
    }
  }

  if (failed.isNotEmpty || total == 0 || flutterExit != 0) {
    b
      ..writeln()
      ..writeln('## Fallos');
    if (total == 0) {
      b.writeln('- No se ejecutó ningún escenario (¿falló la compilación o el arranque?). '
          'Mira `integration.log`.');
    }
    for (final s in failed) {
      b
        ..writeln()
        ..writeln('### ${s.id} — ${s.title}')
        ..writeln()
        ..writeln(s.status == null
            ? 'Sin resultado: la app se cerró o se agotó el tiempo.'
            : '```\n${s.message.replaceAll(' // ', '\n')}\n```');
      if (s.trace.isNotEmpty) {
        b.writeln('\nPila:\n```\n${s.trace.replaceAll(' // ', '\n')}\n```');
      }
    }
    if (total > 0 && failed.isEmpty && flutterExit != 0) {
      b.writeln('\n`flutter test` salió con código $flutterExit aunque todos los escenarios pasaron: revisa `integration.log`.');
    }
  }
  b
    ..writeln()
    ..writeln('Registro completo: `integration.log`.');

  File('${out.path}/report.md').writeAsStringSync(b.toString());
  stdout.writeln(b.toString().split('\n').takeWhile((l) => !l.startsWith('## ')).join('\n'));
  exit(ok ? 0 : 1);
}

String _fmt(int ms) {
  if (ms < 1000) return '$ms ms';
  final s = ms / 1000;
  if (s < 120) return '${s.toStringAsFixed(1)} s';
  return '${s ~/ 60} min ${(s % 60).round()} s';
}

final _marker = RegExp(r'QA_(START|RESULT|TRACE|SHOT_FAILED|SHOT|METRIC|NOTE)\|(.*)$');

void _parse(
  List<String> lines,
  Map<String, _Scenario> scenarios,
  List<String> order,
  List<String> shotNames,
) {
  for (final raw in lines) {
    final m = _marker.firstMatch(raw);
    if (m == null) continue;
    final kind = m.group(1)!;
    final fields = m.group(2)!.trimRight().split('|');
    final id = fields.first;
    switch (kind) {
      case 'START':
        scenarios.putIfAbsent(id, () {
          order.add(id);
          return _Scenario(id, fields.skip(1).join('|'));
        });
      case 'RESULT':
        final s = scenarios[id];
        if (s == null) break;
        s.status = fields[1];
        s.ms = int.tryParse(fields[2]) ?? 0;
        s.message = fields.skip(3).join('|');
      case 'TRACE':
        scenarios[id]?.trace = fields.skip(1).join('|');
      case 'SHOT':
        if (fields.length > 1) shotNames.add(fields[1]);
      case 'METRIC':
        if (fields.length > 2) scenarios[id]?.metrics[fields[1]] = fields.skip(2).join('|');
      case 'NOTE':
        scenarios[id]?.notes.add(fields.skip(1).join('|'));
    }
  }
}

/// Adds the scenarios of [extra] (U02) as rows to the report of an earlier run.
void _appendToReport(File report, Directory out, List<String> extra) {
  final scenarios = <String, _Scenario>{};
  final order = <String>[];
  _parse(extra, scenarios, order, <String>[]);
  if (order.isEmpty) {
    stdout.writeln('No QA_* lines to add to the report.');
    exit(1);
  }
  final shotsDir = Directory('${out.path}/shots');
  final available = shotsDir.existsSync()
      ? ([for (final f in shotsDir.listSync().whereType<File>()) f.uri.pathSegments.last]..sort())
      : <String>[];
  var lines = report.readAsStringSync().split('\n');
  for (final id in order) {
    lines.removeWhere(
      (l) => l.startsWith('| $id |') || l.startsWith('- $id · ') || l.startsWith('### $id '),
    );
  }
  // The table: its last row.
  var last = lines.lastIndexWhere((l) => l.startsWith('| ') || l.startsWith('|---'));
  if (last < 0) last = lines.length - 1;
  final rows = <String>[];
  for (final id in order) {
    final s = scenarios[id]!;
    final shots = [
      for (final f in available)
        if (f.endsWith('.png') && (f == '$id.png' || f.startsWith('${id}_')))
          '[${f.substring(0, f.length - 4)}](shots/$f)',
    ].join(' ');
    rows.add(
      '| $id | ${s.title.replaceAll('|', '/')} | ${s.status == 'PASS' ? '✔' : '✘'} | '
      '${_fmt(s.ms)} | ${shots.isEmpty ? '—' : shots} |',
    );
  }
  lines.insertAll(last + 1, rows);

  final measures = <String>[
    for (final id in order) ...[
      for (final e in scenarios[id]!.metrics.entries) '- $id · ${e.key}: ${e.value}',
      for (final n in scenarios[id]!.notes) '- $id · nota: $n',
    ],
  ];
  if (measures.isNotEmpty) {
    final at = lines.indexOf('## Mediciones');
    if (at < 0) {
      final end = lines.indexWhere((l) => l.startsWith('## Fallos') || l.startsWith('Registro completo'));
      lines.insertAll(end < 0 ? lines.length : end, ['## Mediciones', '', ...measures, '']);
    } else {
      var e = at + 1;
      while (e < lines.length && !lines[e].startsWith('## ') && !lines[e].startsWith('Registro completo')) {
        e++;
      }
      while (e > at + 1 && lines[e - 1].trim().isEmpty) {
        e--;
      }
      lines.insertAll(e, measures);
    }
  }
  final failed = [for (final id in order) if (scenarios[id]!.status != 'PASS') scenarios[id]!];
  if (failed.isNotEmpty) {
    final end = lines.indexWhere((l) => l.startsWith('Registro completo'));
    lines.insertAll(end < 0 ? lines.length : end, [
      if (!lines.contains('## Fallos')) ...['## Fallos', ''],
      for (final s in failed) ...[
        '### ${s.id} — ${s.title}',
        '',
        '```',
        s.status == null ? 'Sin resultado.' : s.message.replaceAll(' // ', '\n'),
        '```',
        '',
      ],
    ]);
  }

  // Counts and verdict in the header.
  final tableRows = lines.where((l) => RegExp(r'^\| [A-Z]\d+ \|').hasMatch(l)).toList();
  final passed = tableRows.where((l) => l.contains('| ✔ |')).length;
  lines = [
    for (final l in lines)
      if (l.startsWith('- Resultado:'))
        '- Resultado: **${passed == tableRows.length && l.contains('TODO EN VERDE') ? 'TODO EN VERDE' : 'HAY FALLOS'}** '
            '($passed/${tableRows.length} escenarios)'
      else
        l,
  ];
  report.writeAsStringSync(lines.join('\n'));
  stdout.writeln(rows.join('\n'));
  exit(failed.isEmpty ? 0 : 1);
}
