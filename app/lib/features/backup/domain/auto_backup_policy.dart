/// When an automatic copy is due (docs/copia-de-seguridad.md, "Copias
/// automáticas"). Pure: it only does date arithmetic, so the rules are tested
/// with a fake clock.
///
/// - **Debounce:** a copy is taken [debounce] after the *last* change, so a
///   burst of edits (painting a month) makes one copy.
/// - **Cap:** a user who never pauses for [debounce] still gets a copy
///   [maxDebounce] after the *first* change of the burst.
/// - **Spacing:** never sooner than [minInterval] after the previous attempt
///   (successful or not), so a failing disk is not hammered and a busy
///   evening does not fill the folder.
class AutoBackupPolicy {
  const AutoBackupPolicy({
    this.debounce = const Duration(seconds: 10),
    this.maxDebounce = const Duration(minutes: 2),
    this.minInterval = const Duration(minutes: 15),
  });

  final Duration debounce;
  final Duration maxDebounce;
  final Duration minInterval;

  /// The moment the copy for a burst of changes is due.
  ///
  /// [firstChange] and [lastChange] delimit the burst; [lastAttempt] is the
  /// start of the previous copy attempt (`null` if there was none this
  /// session). An attempt "in the future" (the phone's clock went back) is
  /// ignored rather than delaying the copy for hours.
  DateTime dueAt({
    required DateTime now,
    required DateTime firstChange,
    required DateTime lastChange,
    DateTime? lastAttempt,
  }) {
    final settled = lastChange.add(debounce);
    final capped = firstChange.add(maxDebounce);
    var due = settled.isBefore(capped) ? settled : capped;
    if (lastAttempt != null && !lastAttempt.isAfter(now)) {
      final earliest = lastAttempt.add(minInterval);
      if (earliest.isAfter(due)) due = earliest;
    }
    return due;
  }

  /// [dueAt] as a wait from [now] (never negative).
  Duration delayFor({
    required DateTime now,
    required DateTime firstChange,
    required DateTime lastChange,
    DateTime? lastAttempt,
  }) {
    final wait = dueAt(
      now: now,
      firstChange: firstChange,
      lastChange: lastChange,
      lastAttempt: lastAttempt,
    ).difference(now);
    return wait.isNegative ? Duration.zero : wait;
  }
}
