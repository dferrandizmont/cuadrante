import 'dart:convert';
import 'dart:typed_data';

import 'csv_parser.dart';
import 'ics_parser.dart';
import 'import_models.dart';

/// The text of a file, whatever the editor that saved it used: UTF-8 (with or
/// without BOM), UTF-16 with a BOM, or, when the bytes are not valid UTF-8,
/// Windows-1252 (what Excel writes for a Spanish CSV). Throws
/// [ImportException] for a file that is too big or looks binary.
String decodeImportBytes(Uint8List bytes) {
  if (bytes.length > maxImportFileBytes) {
    throw const ImportException(ImportProblem.fileTooLarge);
  }
  if (bytes.length >= 2) {
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) return _utf16(bytes, 2, true);
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) return _utf16(bytes, 2, false);
  }
  final probe = bytes.length < 4096 ? bytes.length : 4096;
  for (var i = 0; i < probe; i++) {
    if (bytes[i] == 0) {
      // Text never holds a NUL byte: a picture, a zip, a spreadsheet.
      throw const ImportException(ImportProblem.fileUnreadable);
    }
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return decodeWindows1252(bytes);
  }
}

/// The characters Windows-1252 puts at 0x80-0x9F, where Latin-1 only has
/// control codes (the euro sign, curly quotes, dashes...). Bytes that
/// Windows-1252 leaves undefined stay as they are.
const Map<int, int> _windows1252High = {
  0x80: 0x20AC,
  0x82: 0x201A,
  0x83: 0x0192,
  0x84: 0x201E,
  0x85: 0x2026,
  0x86: 0x2020,
  0x87: 0x2021,
  0x88: 0x02C6,
  0x89: 0x2030,
  0x8A: 0x0160,
  0x8B: 0x2039,
  0x8C: 0x0152,
  0x8E: 0x017D,
  0x91: 0x2018,
  0x92: 0x2019,
  0x93: 0x201C,
  0x94: 0x201D,
  0x95: 0x2022,
  0x96: 0x2013,
  0x97: 0x2014,
  0x98: 0x02DC,
  0x99: 0x2122,
  0x9A: 0x0161,
  0x9B: 0x203A,
  0x9C: 0x0153,
  0x9E: 0x017E,
  0x9F: 0x0178,
};

/// [bytes] read as Windows-1252 (what Excel writes for a Spanish CSV when it
/// is not UTF-8).
String decodeWindows1252(Uint8List bytes) =>
    String.fromCharCodes([for (final b in bytes) _windows1252High[b] ?? b]);

String _utf16(Uint8List bytes, int offset, bool littleEndian) {
  final units = <int>[];
  for (var i = offset; i + 1 < bytes.length; i += 2) {
    units.add(
      littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1],
    );
  }
  return String.fromCharCodes(units);
}

/// Reads an `.ics` file. Runs in a background isolate for big files, so it
/// only takes and returns plain data. Throws [ImportException] and nothing
/// else.
IcsDocument readIcsFile(Uint8List bytes) =>
    _guard(() => parseIcs(decodeImportBytes(bytes)));

/// Reads a CSV file (see [readIcsFile]).
CsvTable readCsvFile(Uint8List bytes) =>
    _guard(() => parseCsv(decodeImportBytes(bytes)));

T _guard<T>(T Function() read) {
  try {
    return read();
  } on ImportException {
    rethrow;
  } catch (_) {
    throw const ImportException(ImportProblem.unknown);
  }
}
