import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/l10n/app_material_localizations.dart';
import 'package:cuadrante/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pickers of the app (H-T01-1 and H-T01-2): the selected day is
/// readable even when it is today, and the two buttons are written the same.
void main() {
  setUpAll(initializeLocale);

  Future<void> openPicker(
    WidgetTester tester, {
    required ThemeData theme,
    required DateTime initial,
    bool time = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          AppMaterialLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => time
                ? showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  )
                : showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  for (final (name, theme, colors) in [
    ('light', AppTheme.light(), AppColors.light),
    ('dark', AppTheme.dark(), AppColors.dark),
  ]) {
    group(name, () {
      testWidgets('today selected (the default): its number is readable', (
        tester,
      ) async {
        final now = DateTime.now();
        await openPicker(
          tester,
          theme: theme,
          initial: DateTime(now.year, now.month, now.day),
        );

        final number = tester.widget<Text>(find.text('${now.day}'));
        final ink = number.style!.color!;
        expect(ink, isNot(colors.accent), reason: 'same colour as the circle');
        expect(contrast(ink, colors.accent), greaterThanOrEqualTo(4.5));
      });

      testWidgets('another day selected, today only ringed: both readable', (
        tester,
      ) async {
        final now = DateTime.now();
        // Any other day of the month the picker opens on.
        final other = now.day == 15 ? 16 : 15;
        await openPicker(
          tester,
          theme: theme,
          initial: DateTime(now.year, now.month, other),
        );

        final picked = tester.widget<Text>(find.text('$other')).style!.color!;
        expect(contrast(picked, colors.accent), greaterThanOrEqualTo(4.5));
        final today = tester
            .widget<Text>(find.text('${now.day}'))
            .style!
            .color!;
        expect(contrast(today, colors.surface), greaterThanOrEqualTo(4.5));
      });
    });
  }

  testWidgets('date picker buttons: «Cancelar» and «Aceptar», sentence case', (
    tester,
  ) async {
    await openPicker(tester, theme: AppTheme.light(), initial: DateTime.now());
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('ACEPTAR'), findsNothing);
  });

  testWidgets('time picker buttons: «Cancelar» and «Aceptar»', (tester) async {
    await openPicker(
      tester,
      theme: AppTheme.light(),
      initial: DateTime.now(),
      time: true,
    );
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('ACEPTAR'), findsNothing);
  });
}
