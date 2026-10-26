import 'package:flutter_test/flutter_test.dart';

import '../../../tool/qa/ui.dart' as ui;

ui.Node node(String label, {String bounds = '[37,578][181,746]'}) =>
    ui.Node({'content-desc': label, 'bounds': bounds});

void main() {
  test('U02 skips grey neighbours and occupied days, using current bounds', () {
    final october = node(
      'jueves 1 de octubre, sin turno',
      bounds: '[468,578][612,746]',
    );
    final chosen = ui.paintableDay([
      node('Octubre, elegir mes'),
      node('lunes 28 de septiembre, sin turno'),
      node('martes 29 de septiembre, sin turno'),
      october,
      node('lunes 5 de octubre, Tarde de 14:00 a 22:00'),
      node('domingo 1 de noviembre, sin turno'),
    ]);
    expect(chosen, same(october));
    expect([chosen!.cx, chosen.cy], [540, 662]);
  });

  test('today is eligible; another month and invisible days are not', () {
    final today = node('lunes 26 de octubre, hoy, sin turno');
    expect(
      ui.paintableDay([
        node('Octubre, elegir mes'),
        node('jueves 1 de octubre, sin turno', bounds: '[0,0][0,0]'),
        today,
      ]),
      same(today),
    );
    expect(ui.paintableDay([node('Noviembre, elegir mes'), today]), isNull);
    expect(ui.paintableDay([today]), isNull);
  });
}
