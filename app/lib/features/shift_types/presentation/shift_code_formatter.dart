import 'package:flutter/services.dart';

import '../domain/shift_type_draft.dart';

/// Keeps the code field to what a shift code can be: letters, digits and
/// simple symbols, at most [maxShiftCodeLength] UTF-16 units (not
/// characters: two emojis would pass a character limit and then break the
/// engine and the backup).
class ShiftCodeFormatter extends TextInputFormatter {
  const ShiftCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = sanitizeShiftCode(newValue.text);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset.clamp(0, text.length),
      ),
    );
  }
}
