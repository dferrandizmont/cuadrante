import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/features/shift_types/domain/shift_type_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every translation has exactly the keys of the Spanish template, the same
/// placeholders in each text and valid ICU (balanced braces, plural/select
/// with an `other` case), so a missing or broken text is caught here and not
/// on a phone.
void main() {
  final dir = Directory('lib/l10n');
  final files = {
    for (final f in dir.listSync().whereType<File>())
      if (RegExp(r'app_(\w+)\.arb$').firstMatch(f.path) case final m?)
        m.group(1)!: jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  };
  final template = files['es']!;
  Iterable<String> texts(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@'));

  test('the languages of the selector have their file', () {
    expect(files.keys.toSet(), containsAll(['es', 'en', 'ca', 'gl', 'eu']));
  });

  test('the template itself is valid ICU', () {
    for (final key in texts(template)) {
      expect(
        () => parseIcu(template[key] as String),
        returnsNormally,
        reason: 'es: $key',
      );
    }
  });

  for (final MapEntry(key: lang, value: arb) in files.entries) {
    if (lang == 'es') continue;
    group('app_$lang.arb', () {
      test('says its locale', () => expect(arb['@@locale'], lang));

      test('has exactly the keys of app_es.arb', () {
        final want = texts(template).toSet();
        final got = texts(arb).toSet();
        expect(want.difference(got), isEmpty, reason: 'missing');
        expect(got.difference(want), isEmpty, reason: 'extra');
      });

      test('every text is valid ICU with the placeholders of Spanish', () {
        for (final key in texts(template)) {
          final text = arb[key];
          expect(text, isA<String>(), reason: '$lang: $key');
          final want = parseIcu(template[key] as String);
          late Set<String> got;
          expect(
            () => got = parseIcu(text as String),
            returnsNormally,
            reason: '$lang: $key is not valid ICU: $text',
          );
          expect(got, want, reason: '$lang: $key placeholders');
          expect(
            (text as String).trim(),
            isNotEmpty,
            reason: '$lang: $key is empty',
          );
        }
      });

      test('the widget lists have 7, 7 and 12 items', () {
        List<String> list(String key) => (arb[key] as String).split(',');
        expect(list('widgetWeekdaysShort'), hasLength(7));
        expect(list('widgetWeekdayHeaders'), hasLength(7));
        expect(list('widgetMonthNames'), hasLength(12));
      });

      test('the template codes are valid and different', () {
        final codes = [
          for (final key in texts(arb))
            if (key.startsWith('catalogShift') && key.endsWith('Code'))
              arb[key] as String,
        ];
        expect(codes, hasLength(11));
        for (final code in codes) {
          expect(sanitizeShiftCode(code), code, reason: '$lang: «$code»');
        }
        expect(codes.toSet(), hasLength(codes.length), reason: '$lang codes');
      });

      if (lang == 'ca' || lang == 'en') {
        test('uses the typographic apostrophe', () {
          for (final key in texts(arb)) {
            expect(
              arb[key] as String,
              isNot(contains("'")),
              reason: '$lang: $key',
            );
          }
        });
      }
    });
  }
}

/// The argument names of an ICU message (`{name}`, and the variable of a
/// `plural`/`select`, with those of its cases). Throws [FormatException] if
/// the message is not valid.
Set<String> parseIcu(String text) {
  final parser = _Icu(text);
  final names = parser.message(topLevel: true);
  if (parser.i != text.length) {
    throw FormatException('Unexpected «}»', text, parser.i);
  }
  return names;
}

class _Icu {
  _Icu(this.s);

  final String s;
  int i = 0;

  Set<String> message({bool topLevel = false}) {
    final names = <String>{};
    while (i < s.length) {
      final c = s[i];
      if (c == '{') {
        i++;
        names.addAll(argument());
      } else if (c == '}') {
        if (topLevel) throw FormatException('Unbalanced «}»', s, i);
        return names;
      } else {
        i++;
      }
    }
    if (!topLevel) throw FormatException('Unclosed «{»', s, i);
    return names;
  }

  Set<String> argument() {
    final name = word();
    if (name.isEmpty) throw FormatException('Empty argument', s, i);
    skipSpaces();
    if (peek('}')) {
      i++;
      return {name};
    }
    expect(',');
    final type = word();
    if (type != 'plural' && type != 'select') {
      throw FormatException('Unknown type «$type»', s, i);
    }
    skipSpaces();
    expect(',');
    final names = {name};
    final cases = <String>{};
    while (true) {
      skipSpaces();
      if (peek('}')) {
        i++;
        break;
      }
      final selector = word(allowEquals: true);
      if (selector.isEmpty) throw FormatException('Empty case', s, i);
      if (type == 'plural' &&
          !RegExp(r'^(=\d+|zero|one|two|few|many|other)$').hasMatch(selector)) {
        throw FormatException('Bad plural case «$selector»', s, i);
      }
      if (!cases.add(selector)) {
        throw FormatException('Repeated case «$selector»', s, i);
      }
      skipSpaces();
      expect('{');
      names.addAll(message());
      expect('}');
    }
    if (!cases.contains('other')) {
      throw FormatException('No «other» case', s, i);
    }
    return names;
  }

  String word({bool allowEquals = false}) {
    skipSpaces();
    final start = i;
    while (i < s.length &&
        RegExp(allowEquals ? r'[\w=]' : r'\w').hasMatch(s[i])) {
      i++;
    }
    return s.substring(start, i);
  }

  void skipSpaces() {
    while (i < s.length && s[i].trim().isEmpty) {
      i++;
    }
  }

  bool peek(String c) => i < s.length && s[i] == c;

  void expect(String c) {
    skipSpaces();
    if (!peek(c)) throw FormatException('Expected «$c»', s, i);
    i++;
  }
}
