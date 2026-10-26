import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../schedule/domain/schedule_domain.dart';
import '../domain/free_color.dart';
import 'shift_type_preview.dart';

/// «Más colores»: the free colour picker of the shift editor. Hue,
/// saturation and lightness sliders plus a hex field, with the cell of the
/// shift in the light and the dark theme as a live preview (the ink of the
/// code is derived by `ShiftSwatch`, always with AA contrast, and the preview
/// prints the ratio).
///
/// Returns the chosen ARGB value, or `null` when dismissed. [shift] is the
/// shift being edited (its code, name and category are what the preview
/// shows); [initial] the colour the picker starts on.
Future<int?> showShiftColorPicker(
  BuildContext context, {
  required ShiftType shift,
  required int initial,
}) => showAppSheet<int>(
  context: context,
  padded: true,
  builder: (_) => ShiftColorPickerSheet(shift: shift, initial: initial),
);

class ShiftColorPickerSheet extends StatefulWidget {
  const ShiftColorPickerSheet({
    super.key,
    required this.shift,
    required this.initial,
  });

  final ShiftType shift;
  final int initial;

  @override
  State<ShiftColorPickerSheet> createState() => _ShiftColorPickerSheetState();
}

class _ShiftColorPickerSheetState extends State<ShiftColorPickerSheet> {
  late int _color;
  late HSLColor _hsl;
  final _hex = TextEditingController();
  bool _hexValid = true;

  @override
  void initState() {
    super.initState();
    _color = FreeColor.normalize(widget.initial);
    _hsl = FreeColor.toHsl(_color);
    _hex.text = FreeColor.toHex(_color);
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  /// A slider moved: the colour follows and the hex text is rewritten.
  void _fromSliders({double? hue, double? saturation, double? lightness}) {
    final next = HSLColor.fromAHSL(
      1,
      hue ?? _hsl.hue,
      saturation ?? _hsl.saturation,
      lightness ?? _hsl.lightness,
    );
    setState(() {
      _hsl = next;
      _color = FreeColor.fromHsl(next.hue, next.saturation, next.lightness);
      _hex.text = FreeColor.toHex(_color);
      _hexValid = true;
    });
  }

  /// The hex field was edited: a valid text moves the sliders (the text
  /// itself is left alone while the user types).
  void _fromHex(String text) {
    final parsed = FreeColor.parseHex(text);
    setState(() {
      _hexValid = parsed != null;
      if (parsed != null) {
        _color = parsed;
        _hsl = FreeColor.toHsl(parsed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.shiftTypesColorPickerTitle, style: type.headline),
        ),
        const SizedBox(height: Sp.xs),
        Text(
          l10n.shiftTypesColorPickerHelp,
          style: type.meta.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: Sp.m),
        ShiftTypePreview(shift: widget.shift.copyWith(colorValue: _color)),
        const SizedBox(height: Sp.m),
        _SliderRow(
          sliderKey: 'color-hue',
          label: l10n.shiftTypesColorHue,
          value: _hsl.hue,
          max: 360,
          shown: '${_hsl.hue.round()}°',
          spoken: l10n.shiftTypesColorHueSpoken(_hsl.hue.round()),
          onChanged: (v) => _fromSliders(hue: v),
        ),
        _SliderRow(
          sliderKey: 'color-saturation',
          label: l10n.shiftTypesColorSaturation,
          value: _hsl.saturation,
          max: 1,
          shown: '${(_hsl.saturation * 100).round()} %',
          spoken: l10n.shiftTypesColorPercentSpoken(
            (_hsl.saturation * 100).round(),
          ),
          onChanged: (v) => _fromSliders(saturation: v),
        ),
        _SliderRow(
          sliderKey: 'color-lightness',
          label: l10n.shiftTypesColorLightness,
          value: _hsl.lightness,
          max: 1,
          shown: '${(_hsl.lightness * 100).round()} %',
          spoken: l10n.shiftTypesColorPercentSpoken(
            (_hsl.lightness * 100).round(),
          ),
          onChanged: (v) => _fromSliders(lightness: v),
        ),
        const SizedBox(height: Sp.s),
        LabeledField(
          label: l10n.shiftTypesColorHexLabel,
          child: TextField(
            key: const ValueKey('color-hex'),
            controller: _hex,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              errorText: _hexValid ? null : l10n.shiftTypesColorHexError,
            ),
            onChanged: _fromHex,
          ),
        ),
        const SizedBox(height: Sp.l),
        PrimaryButton(
          key: const ValueKey('color-use'),
          label: l10n.shiftTypesColorUse,
          onPressed: _hexValid ? () => Navigator.pop(context, _color) : null,
        ),
        const SizedBox(height: Sp.s),
        SecondaryButton(
          key: const ValueKey('color-cancel'),
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// A label with its value on the right and a slider below.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.max,
    required this.shown,
    required this.spoken,
    required this.onChanged,
  });

  final String sliderKey;
  final String label;
  final double value;
  final double max;
  final String shown;
  final String spoken;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(child: Text(label, style: type.meta)),
              Text(
                shown,
                key: ValueKey('$sliderKey-value'),
                style: AppTypography.tabular(type.meta),
              ),
            ],
          ),
        ),
        MergeSemantics(
          child: Semantics(
            label: label,
            child: Slider(
              key: ValueKey(sliderKey),
              min: 0,
              max: max,
              value: value.clamp(0, max).toDouble(),
              semanticFormatterCallback: (_) => spoken,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
