import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// JSON with sorted object keys and no whitespace, so the same value always
/// produces the same text (and the same bytes, and the same hash).
///
/// Accepts what `jsonDecode` produces: `null`, `bool`, `int`, finite
/// `double`, `String`, `List` and `Map<String, Object?>`. Lists keep their
/// order; maps are sorted by key (UTF-16 code unit order). Strings are
/// written as `jsonEncode` does: control characters escaped, everything else
/// (emojis included) as plain characters.
String canonicalJson(Object? value) {
  final out = StringBuffer();
  _write(out, value);
  return out.toString();
}

/// UTF-8 bytes of [canonicalJson].
Uint8List canonicalJsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(canonicalJson(value)));

/// Lowercase hex SHA-256 of [bytes].
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

void _write(StringBuffer out, Object? value) {
  switch (value) {
    case null || bool():
      out.write(jsonEncode(value));
    case int():
      out.write(value);
    case double():
      if (!value.isFinite) {
        throw ArgumentError.value(value, 'value', 'not representable in JSON');
      }
      out.write(jsonEncode(value));
    case String():
      out.write(jsonEncode(value));
    case List():
      out.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) out.write(',');
        _write(out, value[i]);
      }
      out.write(']');
    case Map():
      final keys = [for (final k in value.keys) k as String]..sort();
      out.write('{');
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) out.write(',');
        out.write(jsonEncode(keys[i]));
        out.write(':');
        _write(out, value[keys[i]]);
      }
      out.write('}');
    default:
      throw ArgumentError.value(
        value,
        'value',
        'not a JSON value (${value.runtimeType})',
      );
  }
}
