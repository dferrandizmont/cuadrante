import 'backup_store.dart';

/// Which automatic copies the phone keeps (docs/copia-de-seguridad.md,
/// "Cuántas copias se guardan"): the [newest] copies, plus the last copy of
/// each calendar day for the past [dailyForDays] days. Everything else is
/// dropped when a new copy is saved.
///
/// Pure: [now] is passed in, and the "day" of a copy is its local calendar
/// day (a night shift worker's evening is one day, not two).
class BackupRetention {
  const BackupRetention({this.newest = 7, this.dailyForDays = 30})
    : assert(newest >= 1),
      assert(dailyForDays >= 0);

  final int newest;
  final int dailyForDays;

  /// The ids of [entries] to keep. Never empty when [entries] is not: the
  /// newest copy is always kept.
  Set<String> idsToKeep(List<BackupEntry> entries, {required DateTime now}) {
    final sorted = [...entries]
      ..sort((a, b) {
        final byTime = b.modifiedAt.compareTo(a.modifiedAt);
        return byTime != 0 ? byTime : _newerIdFirst(a.id, b.id);
      });
    final keep = <String>{for (final e in sorted.take(newest)) e.id};

    final today = _day(now);
    final seenDays = <int>{};
    for (final e in sorted) {
      final day = _day(e.modifiedAt);
      // `sorted` is newest first: the first copy of a day is its last one.
      if (!seenDays.add(day)) continue;
      if (today - day < dailyForDays) keep.add(e.id);
    }
    return keep;
  }

  /// `<prefix>-<stamp>` plus `-<n>` for the n-th copy of the same second.
  static final RegExp _idPattern = RegExp(
    r'^.+-(\d{8}-\d{6})(?:-(\d+))?\.(?:turnly|cuadrante)$',
  );

  /// Orders two ids that have the same modification time, newest first, the
  /// way `listBackupFiles` does: the same stamp with a higher counter is the
  /// newer copy (`-2` after the plain one, `-10` after `-9`). Plain text order
  /// would put `...-2.turnly` before `....turnly` and `-10` before
  /// `-9`.
  static int _newerIdFirst(String a, String b) {
    final ma = _idPattern.firstMatch(a);
    final mb = _idPattern.firstMatch(b);
    if (ma == null || mb == null) return b.compareTo(a);
    final byBase = mb[1]!.compareTo(ma[1]!);
    if (byBase != 0) return byBase;
    final na = int.tryParse(ma[2] ?? '') ?? 1;
    final nb = int.tryParse(mb[2] ?? '') ?? 1;
    final byCounter = nb.compareTo(na);
    return byCounter != 0 ? byCounter : b.compareTo(a);
  }

  /// The entries [idsToKeep] drops.
  List<BackupEntry> toDrop(List<BackupEntry> entries, {required DateTime now}) {
    final keep = idsToKeep(entries, now: now);
    return [
      for (final e in entries)
        if (!keep.contains(e.id)) e,
    ];
  }

  /// Local calendar day as a count of days, comparable by subtraction.
  static int _day(DateTime t) {
    final local = t.toLocal();
    return DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }
}
