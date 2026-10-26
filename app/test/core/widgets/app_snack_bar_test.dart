import 'dart:io';

import 'package:cuadrante/core/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// H-T04-1: a SnackBar with an action stayed up for ever. They are all built
/// by `appSnackBar` now.
void main() {
  for (final accessible in [false, true]) {
    for (final hasAction in [false, true]) {
      testWidgets(
        'timeout with accessibleNavigation=$accessible, action=$hasAction',
        (tester) async {
          final messenger = GlobalKey<ScaffoldMessengerState>();
          await tester.pumpWidget(
            MaterialApp(
              scaffoldMessengerKey: messenger,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(accessibleNavigation: accessible),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      appSnackBar(
                        context: context,
                        content: const Text('Hecho'),
                        action: hasAction
                            ? SnackBarAction(
                                label: 'Deshacer',
                                onPressed: () {},
                              )
                            : null,
                      ),
                    ),
                    child: const Text('Mostrar'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Mostrar'));
          await tester.pumpAndSettle();
          final bar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(bar.persist, accessible && hasAction);
          expect(bar.duration, kSnackBarDuration);
          await tester.pump(kSnackBarDuration + const Duration(seconds: 1));
          await tester.pumpAndSettle();
          if (accessible && hasAction) {
            expect(find.text('Hecho'), findsOneWidget);
            await tester.tap(find.byTooltip('Close'));
            await tester.pumpAndSettle();
          }
          expect(find.text('Hecho'), findsNothing);
        },
      );
    }
  }

  test('no screen builds a raw SnackBar: they all go through appSnackBar', () {
    final offenders = <String>[];
    final raw = RegExp(r'(?<![\w.])SnackBar\(');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.replaceAll('\\', '/').endsWith('app_snack_bar.dart')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(line)) offenders.add('${entity.path}:${i + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'build SnackBars with appSnackBar (a raw one with an action never '
          'goes away): $offenders',
    );
  });
}
