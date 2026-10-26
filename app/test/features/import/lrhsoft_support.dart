import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// `tablaTurnos` and `dias` as LRHSoft 2.0.7.8 creates them (copied from a
/// real backup).
const String shifterTypesTable =
    'CREATE TABLE tablaTurnos (_id INTEGER PRIMARY KEY, texto TEXT, '
    'horaAlarma TEXT, alarma INTEGER, alarmaDiaAntes INTEGER, color INTEGER, '
    'colorTexto INTEGER, codigoSecuencial INTEGER, textSize REAL, '
    'horaAlarma2 TEXT, alarma2 INTEGER, alarma2DiaAntes INTEGER, '
    'sonido1 TEXT, sonido2 TEXT, abreviatura TEXT, horaInicio1 TEXT, '
    'horaFinal1 TEXT, horaInicio2 TEXT, horaFinal2 TEXT, turnoPartido INTEGER, '
    'realizarAccion TEXT, ingresosHora INTEGER, ingresoHoraExtra INTEGER, '
    'tiempoDescanso INTEGER, tiempoTurno INTEGER, '
    'calcularTiempoTurnoManual INTEGER)';

const String shifterDaysTable =
    'CREATE TABLE dias (fecha INTEGER PRIMARY KEY, turno1 INTEGER, '
    'turno2 INTEGER, alarma1 INTEGER, alarma2 INTEGER, notas TEXT, '
    'notificacion INTEGER, hora INTEGER, alarma1T2 INTEGER, alarma2T2 INTEGER, '
    'sonido TEXT, notificacionDiaAntes INTEGER, notificacion2 INTEGER, '
    'notificacion2DiaAntes INTEGER, hora2 INTEGER, sonido2 TEXT, '
    'instruccionesDibujo TEXT, foto BLOB, horasExtraT1 INTEGER, '
    'horasExtraT2 INTEGER, ingresoExtra INTEGER, salidaAnticipadaT1 INTEGER, '
    'salidaAnticipadaT2 INTEGER, icono INTEGER, horasExtraT1Acumula INTEGER, '
    'horasExtraT2Acumula INTEGER)';

/// A shift type row of a test backup.
class ShifterType {
  const ShifterType(
    this.id,
    this.name, {
    this.abbreviation,
    this.color = -2407,
    this.start = '00:00',
    this.end = '00:00',
    this.start2 = '00:00',
    this.end2 = '00:00',
    this.split = 0,
  });

  final int id;
  final String name;
  final String? abbreviation;
  final int color;
  final String start;
  final String end;
  final String start2;
  final String end2;
  final int split;
}

/// A day row of a test backup. [date] is the **raw** number of the file
/// (month counted from 0).
class ShifterDay {
  const ShifterDay(this.date, {this.t1, this.t2, this.note});

  final int date;
  final int? t1;
  final int? t2;
  final String? note;
}

/// The bytes of an LRHSoft backup built in a temp folder with `sqlite3`.
///
/// [build] runs against the open database before it is closed, to make odd
/// files (a view called `dias`, missing tables...).
Uint8List buildShifter({
  List<ShifterType> types = const [],
  List<ShifterDay> days = const [],
  String typesTable = shifterTypesTable,
  String daysTable = shifterDaysTable,
  void Function(Database db)? build,
}) {
  final dir = Directory.systemTemp.createTempSync('shifter_fixture_');
  try {
    final file = File(p.join(dir.path, 'fixture.Shifter'));
    final db = sqlite3.open(file.path);
    try {
      if (build != null) {
        build(db);
      } else {
        db.execute(typesTable);
        db.execute(daysTable);
        db.execute('BEGIN');
        for (final t in types) {
          // Only the columns this version of the table has.
          final values = <String, Object?>{
            '_id': t.id,
            'texto': t.name,
            'abreviatura': t.abbreviation,
            'color': t.color,
            'horaInicio1': t.start,
            'horaFinal1': t.end,
            'horaInicio2': t.start2,
            'horaFinal2': t.end2,
            'turnoPartido': t.split,
          }..removeWhere((column, _) => !typesTable.contains(column));
          db.execute(
            'INSERT INTO tablaTurnos (${values.keys.join(', ')}) '
            'VALUES (${List.filled(values.length, '?').join(', ')})',
            values.values.toList(),
          );
        }
        for (final d in days) {
          final values = <String, Object?>{
            'fecha': d.date,
            'turno1': d.t1,
            'turno2': d.t2,
            'notas': d.note,
          }..removeWhere((column, _) => !daysTable.contains(column));
          db.execute(
            'INSERT INTO dias (${values.keys.join(', ')}) '
            'VALUES (${List.filled(values.length, '?').join(', ')})',
            values.values.toList(),
          );
        }
        db.execute('COMMIT');
      }
    } finally {
      db.close();
    }
    return file.readAsBytesSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

/// The raw `fecha` of LRHSoft for a real calendar date: the month counted
/// from 0, so 9 October 2026 is 20260909.
int shifterDate(int year, int month, int day) =>
    year * 10000 + (month - 1) * 100 + day;

/// The shift types the tests use, like the ones of the real backup.
const List<ShifterType> sampleTypes = [
  ShifterType(3, 'Libre', abbreviation: 'Free', color: -3675698),
  ShifterType(
    4,
    'Partido',
    abbreviation: 'Mor./Aft.',
    color: -1983764,
    start: '10:00',
    end: '14:00',
    start2: '16:00',
    end2: '20:00',
    split: 1,
  ),
  ShifterType(
    5,
    'Noche',
    abbreviation: 'N',
    color: -8729144,
    start: '23:00',
    end: '07:00',
  ),
  ShifterType(
    6,
    'Tarde',
    abbreviation: 'Aft.',
    color: -746814,
    start: '15:00',
    end: '23:00',
  ),
  ShifterType(
    7,
    'Mañana',
    abbreviation: 'Mor.',
    color: -2407,
    start: '07:00',
    end: '15:00',
  ),
  ShifterType(
    8,
    'Guardia Médica',
    abbreviation: 'GM',
    color: -15002524,
    start: '08:00',
    end: '20:00',
    // Second times without the split flag: they are not a segment.
    start2: '15:00',
    end2: '15:00',
  ),
];
