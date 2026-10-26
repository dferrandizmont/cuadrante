import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../schedule/domain/schedule_domain.dart';
import 'schedule_controller.dart';

/// State of paint mode.
class PaintState {
  const PaintState({
    this.active = false,
    this.shiftTypeId,
    this.doubling = false,
  });

  /// Paint mode on: drags paint instead of swiping months.
  final bool active;

  /// Selected shift type; `null` = the eraser.
  final String? shiftTypeId;

  /// "Doblar": add the shift to the day's shifts instead of replacing them.
  final bool doubling;

  bool get erasing => shiftTypeId == null;

  /// The brush the current selection paints with.
  PaintTool get tool => erasing
      ? const PaintTool.erase()
      : doubling
      ? PaintTool.add(shiftTypeId!)
      : PaintTool.replace(shiftTypeId!);

  PaintState copyWith({
    bool? active,
    String? shiftTypeId,
    bool clearShiftTypeId = false,
    bool? doubling,
  }) => PaintState(
    active: active ?? this.active,
    shiftTypeId: clearShiftTypeId ? null : shiftTypeId ?? this.shiftTypeId,
    doubling: doubling ?? this.doubling,
  );
}

class PaintController extends Notifier<PaintState> {
  @override
  PaintState build() {
    // Read, not watched: the default brush must not reset on every stroke.
    final types = ref.read(scheduleControllerProvider).palette;
    // A shift type archived in the editor leaves the palette: the brush
    // must not keep painting with it.
    ref.listen(scheduleControllerProvider.select((s) => s.palette), (_, next) {
      final id = state.shiftTypeId;
      if (id != null && !next.any((t) => t.id == id)) {
        final fallback = _firstWork(next);
        state = fallback == null
            ? state.copyWith(clearShiftTypeId: true)
            : state.copyWith(shiftTypeId: fallback);
      }
    });
    return PaintState(shiftTypeId: _firstWork(types));
  }

  static String? _firstWork(List<ShiftType> types) =>
      types.where((t) => t.category == ShiftCategory.work).firstOrNull?.id;

  void toggle() => state.active ? exit() : enter();

  void enter() => state = state.copyWith(active: true);

  /// Leaves paint mode, closing any stroke still open.
  void exit() {
    ref.read(scheduleControllerProvider.notifier).endStroke();
    state = state.copyWith(active: false);
  }

  void selectShift(String shiftTypeId) =>
      state = state.copyWith(shiftTypeId: shiftTypeId);

  void selectEraser() => state = state.copyWith(clearShiftTypeId: true);

  void toggleDoubling() => state = state.copyWith(doubling: !state.doubling);
}

final paintControllerProvider = NotifierProvider<PaintController, PaintState>(
  PaintController.new,
);
