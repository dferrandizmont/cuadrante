// Reads a `uiautomator dump` of the app (the Flutter semantics tree shows up as
// `content-desc`/`text`) for tool/qa/upgrade_android.sh. No coordinates are
// hard-coded anywhere: the script asks this tool where things are.
//
//   dart tool/qa/ui.dart node <dump.xml> <regex>   centre "x y" of the first node whose
//                                                   content-desc or text matches; exit 1 if none
//   dart tool/qa/ui.dart days <dump.xml>            one line per day cell: "x y|<label>"
//   dart tool/qa/ui.dart week <dump.xml>            "x1 y x2 y" from the first to the last cell
//                                                   of a full row of 7 days (a drag paints it)
//   dart tool/qa/ui.dart package <dump.xml> <pkg>   exit 0 if the dump is of that package
//
// Day cells are recognised by their semantics label, "jueves 22 de octubre ..."
// (`daySemanticsLabel`): weekday, number, "de", month.
import 'dart:convert';
import 'dart:io';

final _dayLabel = RegExp(
  r'^(lunes|martes|miércoles|jueves|viernes|sábado|domingo) \d{1,2} de [a-záéíóúñ]+',
  caseSensitive: false,
);

class Node {
  Node(this.attrs);
  final Map<String, String> attrs;
  String get desc => attrs['content-desc'] ?? '';
  String get text => attrs['text'] ?? '';
  List<int> get bounds {
    final m = RegExp(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
        .firstMatch(attrs['bounds'] ?? '');
    if (m == null) return const [0, 0, 0, 0];
    return [for (var i = 1; i <= 4; i++) int.parse(m.group(i)!)];
  }

  int get cx => (bounds[0] + bounds[2]) ~/ 2;
  int get cy => (bounds[1] + bounds[3]) ~/ 2;
  bool get visible => bounds[2] > bounds[0] && bounds[3] > bounds[1];
}

String _unescape(String s) => s
    .replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    )
    .replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m[1]!)),
    )
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

List<Node> parse(String path) {
  final xml = utf8.decode(File(path).readAsBytesSync(), allowMalformed: true);
  final attr = RegExp(r'([\w:-]+)="([^"]*)"');
  return [
    for (final m in RegExp(r'<node\b[^>]*>').allMatches(xml))
      Node({
        for (final a in attr.allMatches(m.group(0)!)) a[1]!: _unescape(a[2]!),
      }),
  ];
}

bool _isDay(Node n) => _dayLabel.hasMatch(n.desc) && n.visible;

/// An empty day in the displayed month, never a grey neighbour. MonthGrid
/// deliberately ignores paint gestures on those neighbours (H-T24-12).
Node? paintableDay(List<Node> nodes) {
  const months =
      'enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre';
  final title = RegExp('^($months), elegir mes\$', caseSensitive: false);
  final month = nodes
      .where((n) => n.visible && title.hasMatch(n.desc))
      .firstOrNull;
  if (month == null) return null;
  final name = title.firstMatch(month.desc)![1]!.toLowerCase();
  return nodes
      .where(
        (n) =>
            _isDay(n) &&
            n.desc.toLowerCase().contains(' de $name,') &&
            n.desc.contains(', sin turno'),
      )
      .firstOrNull;
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: ui.dart node|days|week|package <dump.xml> [arg]');
    exit(64);
  }
  final nodes = parse(args[1]);
  switch (args[0]) {
    case 'paintable-day':
      final day = paintableDay(nodes);
      if (day == null) exit(1);
      stdout.writeln(
        '${day.cx} ${day.cy}|${day.desc.split(', sin turno').first}',
      );
    case 'node':
      final re = RegExp(args[2]);
      for (final n in nodes) {
        if (n.visible && (re.hasMatch(n.desc) || re.hasMatch(n.text))) {
          stdout.writeln('${n.cx} ${n.cy}');
          return;
        }
      }
      exit(1);
    case 'days':
      for (final n in nodes.where(_isDay)) {
        stdout.writeln('${n.cx} ${n.cy}|${n.desc.replaceAll('\n', ' ')}');
      }
    case 'week':
      final days = nodes.where(_isDay).toList();
      final rows = <List<Node>>[];
      for (final d in days) {
        final row = rows.where((r) => (r.first.cy - d.cy).abs() < 12);
        if (row.isEmpty) {
          rows.add([d]);
        } else {
          row.first.add(d);
        }
      }
      final full = [
        for (final r in rows)
          if (r.length == 7) (r..sort((a, b) => a.cx.compareTo(b.cx))),
      ]..sort((a, b) => a.first.cy.compareTo(b.first.cy));
      if (full.isEmpty) exit(1);
      // The second full row: clear of the header and of the paint bar.
      final row = full.length > 1 ? full[1] : full.first;
      stdout.writeln(
        '${row.first.cx} ${row.first.cy} ${row.last.cx} ${row.last.cy}',
      );
    case 'package':
      exit(nodes.any((n) => n.attrs['package'] == args[2]) ? 0 : 1);
    default:
      stderr.writeln('unknown command ${args[0]}');
      exit(64);
  }
}
