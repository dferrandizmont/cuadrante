import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router.dart';
import '../../calendar/application/paint_controller.dart';
import '../../schedule/domain/schedule_domain.dart';

/// "Aplicar patrón desde este día": after a long press on a puck of paint
/// mode, the next day tapped is where the pattern starts.
class PatternStartPick {
  const PatternStartPick({this.shiftTypeId});

  /// The puck that was long-pressed (`null` = the eraser): the wizard puts
  /// the patterns that begin with this shift first.
  final String? shiftTypeId;
}

class PatternStartPickController extends Notifier<PatternStartPick?> {
  @override
  PatternStartPick? build() {
    // Leaving paint mode cancels the pick.
    // Watched only so the pick starts over whenever paint mode toggles.
    ref.watch(paintControllerProvider.select((p) => p.active));
    return null;
  }

  void begin(String? shiftTypeId) =>
      state = PatternStartPick(shiftTypeId: shiftTypeId);

  void cancel() => state = null;
}

final patternStartPickProvider =
    NotifierProvider<PatternStartPickController, PatternStartPick?>(
      PatternStartPickController.new,
    );

/// Where the wizard lives, with the day and the shift that opened it.
String patternWizardLocation({CivilDate? start, String? shiftTypeId}) {
  final query = <String, String>{
    'inicio': ?start?.toIso(),
    'turno': ?shiftTypeId,
  };
  return Uri(
    path: AppRoutes.pattern,
    queryParameters: query.isEmpty ? null : query,
  ).toString();
}

/// Called by the month grid when a day is tapped in paint mode: when a
/// pattern start is being picked, [date] is it, the wizard opens and the
/// tap does not paint. Returns whether the tap was consumed.
bool consumePatternStartPick(
  BuildContext context,
  WidgetRef ref,
  CivilDate date,
) {
  final pick = ref.read(patternStartPickProvider);
  if (pick == null) return false;
  ref.read(patternStartPickProvider.notifier).cancel();
  context.push(
    patternWizardLocation(start: date, shiftTypeId: pick.shiftTypeId),
  );
  return true;
}
