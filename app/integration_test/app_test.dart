import 'package:integration_test/integration_test.dart';

import 'scenarios/registry.dart';
import 'support/qa_core.dart';

/// Entry point of the QA battery (docs/qa.md). Run it with
/// `tool/qa/run_android.sh`, which starts the emulator, grants the
/// notification permission and collects the report and the screenshots.
/// `--dart-define=QA_ONLY=Q02,Q03` limits the run, `QA_SKIP=Q13` leaves some out.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerQaScenarios(binding, qaScenarios);
}
