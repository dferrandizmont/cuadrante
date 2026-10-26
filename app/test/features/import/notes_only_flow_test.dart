import 'package:cuadrante/core/bootstrap/bootstrap.dart' show initializeLocale;
import 'package:cuadrante/features/import/application/import_wizard.dart';
import 'package:cuadrante/features/import/data/import_file_picker.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';
import 'import_ui_support.dart';
import 'lrhsoft_support.dart';

const _first = CivilDate(2026, 11, 9);
const _last = CivilDate(2026, 11, 10);

void main() {
  setUpAll(initializeLocale);

  for (final ignoreShifts in [false, true]) {
    testWidgets(
      ignoreShifts
          ? 'imports notes through the wizard when every shift group is ignored'
          : 'imports a notes-only Shifter range through the whole wizard',
      (tester) async {
        final picker = FakePicker()
          ..next = PickedImportFile.bytes(
            'notas.Shifter',
            buildShifter(
              types: sampleTypes,
              days: [
                ShifterDay(
                  shifterDate(2026, 11, 9),
                  t1: ignoreShifts ? 7 : null,
                  note: 'Revisión',
                ),
                ShifterDay(
                  shifterDate(2026, 11, 10),
                  note: 'Cambio con Marta<br>Confirmar el viernes',
                ),
              ],
            ),
          );
        final app = await openImport(
          tester,
          phone: FakeDeviceCalendar(),
          picker: picker,
        );
        final before = app.schedule.schedule;
        await tapKey(tester, 'import-source-lrhsoft');
        expect(stepOf(tester), 'Paso 2 de 4');
        await tapKey(tester, 'import-next');
        expect(stepOf(tester), 'Paso 3 de 4');
        if (ignoreShifts) {
          await tapKey(tester, 'import-map-manana');
          await tapKey(tester, 'import-pick-ignore');
        } else {
          expect(find.text('2 notas'), findsOneWidget);
        }
        final wizard = app.container.read(importWizardProvider);
        expect(wizard.mappedDays, 0);
        expect(wizard.canContinueFromMapping, isTrue);
        await tapKey(tester, 'import-next');
        expect(stepOf(tester), 'Paso 4 de 4');
        expect(find.text('Se añadirán 2 notas.'), findsOneWidget);
        expect(find.text('Importar 2 notas'), findsOneWidget);
        expect(find.textContaining('Se escribirán'), findsNothing);

        await tapKey(tester, 'import-apply');
        await flush(app);
        expect(
          find.textContaining('Se han importado 2 notas.'),
          findsOneWidget,
        );
        expect(find.textContaining('Se han importado 2 días'), findsNothing);
        final stored = await app.real(
          () => ScheduleRepository(app.database).load(app.schedule.calendarId),
        );
        expect(stored.schedule.entries[_first]?.note, 'Revisión');
        expect(
          stored.schedule.entries[_last]?.note,
          'Cambio con Marta\nConfirmar el viernes',
        );
        for (final date in [_first, _last]) {
          expect(
            stored.schedule.resolve(date).shiftIds,
            before.resolve(date).shiftIds,
            reason:
                'only notes change, including on a day with an ignored shift',
          );
        }
        expect(stored.schedule.shiftTypes, before.shiftTypes);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
