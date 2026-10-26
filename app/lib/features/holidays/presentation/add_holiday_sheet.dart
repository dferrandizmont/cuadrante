import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../schedule/domain/civil_date.dart';
import '../domain/holiday.dart';
import 'holiday_pickers.dart';

/// A local holiday the person is adding: the day and its name.
class NewLocalHoliday {
  const NewLocalHoliday(this.date, this.name);

  final CivilDate date;
  final String name;
}

/// «Añadir festivo local»: one sheet with the calendar and the name
/// (prefilled «Fiesta local», editable). Pick the day, press «Guardar».
/// Returns the holiday, or null if the sheet was dismissed.
Future<NewLocalHoliday?> showAddHolidaySheet(
  BuildContext context, {
  required CivilDate initial,
  required CivilDate first,
  required CivilDate last,
}) {
  return showAppSheet<NewLocalHoliday>(
    context: context,
    padded: true,
    builder: (ctx) => _AddHolidaySheet(
      initial: initial,
      first: first,
      last: last,
      defaultName: ctx.l10n.holidaysSettingsAddDefaultName,
    ),
  );
}

class _AddHolidaySheet extends StatefulWidget {
  const _AddHolidaySheet({
    required this.initial,
    required this.first,
    required this.last,
    required this.defaultName,
  });

  final CivilDate initial;
  final CivilDate first;
  final CivilDate last;
  final String defaultName;

  @override
  State<_AddHolidaySheet> createState() => _AddHolidaySheetState();
}

class _AddHolidaySheetState extends State<_AddHolidaySheet> {
  late final _name = TextEditingController(text: widget.defaultName);
  late CivilDate _date = widget.initial;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static DateTime _dt(CivilDate d) => DateTime(d.year, d.month, d.day);

  void _save() {
    final typed = _name.text.trim();
    Navigator.pop(
      context,
      NewLocalHoliday(_date, typed.isEmpty ? widget.defaultName : typed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerSheetTitle(l10n.holidaysSettingsAdd),
        CalendarDatePicker(
          key: const ValueKey('holiday-date-picker'),
          initialDate: _dt(widget.initial),
          firstDate: _dt(widget.first),
          lastDate: _dt(widget.last),
          onDateChanged: (picked) =>
              setState(() => _date = CivilDate.fromDateTime(picked)),
        ),
        const SizedBox(height: Sp.s),
        TextField(
          key: const ValueKey('holiday-name-field'),
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          maxLength: maxHolidayNameLength,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n.holidaysSettingsAddName,
            counterText: '',
          ),
        ),
        const SizedBox(height: Sp.l),
        PrimaryButton(
          key: const ValueKey('holiday-save'),
          label: l10n.save,
          onPressed: _save,
        ),
      ],
    );
  }
}
