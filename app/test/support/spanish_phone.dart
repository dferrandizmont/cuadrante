import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone in Spanish (Spain). The test engine reports `en_US`, and the app
/// follows the phone's language by default (Ajustes › Idioma › Sistema), so
/// the tests that read the Spanish texts set it first. Undone after the test.
void useSpanishPhone(WidgetTester tester) {
  tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
  tester.platformDispatcher.localeTestValue = const Locale('es', 'ES');
  addTearDown(() {
    tester.platformDispatcher.clearLocalesTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
  });
}
