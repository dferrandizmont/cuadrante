import 'dart:async';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/schedule/domain/presets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file. The app follows the phone's language, and
/// the test engine (and the machine running it) may be in any: a new
/// database is seeded as on a Spanish phone, and every test starts with the
/// Spanish catalogue texts (a test that switched the language does not leak
/// it into the next one). Widget tests that read the Spanish texts also set
/// a Spanish phone (`test/support/spanish_phone.dart`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugPhoneLocales = const [Locale('es', 'ES')];
  setUp(() => catalogTexts = CatalogTexts.spanish);
  await testMain();
}
