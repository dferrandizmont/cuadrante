import 'dart:convert';
import 'dart:io';

import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/config.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/core/database/database_opener.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendar/application/schedule_controller.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/schedule/data/schedule_repository.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'qa_core.dart';

export 'month_navigation.dart';

/// Monday 19 October 2026, 18:20 (Europe/Madrid): the fixed "now" of the
/// battery. The demo rotation puts a Noche on this day, so the "Hoy" card
/// reads "Esta noche, empieza en 3 h 40 min".
final DateTime qaNow = DateTime(2026, 10, 19, 18, 20);
const CivilDate qaToday = CivilDate(2026, 10, 19);

/// What `prepare` of [QaApp.open] gets: the stored data, before the app
/// loads it.
class QaStorage {
  QaStorage(this.database, this.repository);
  final AppDatabase database;
  final ScheduleRepository repository;
}

/// The app running inside the integration test, on a real database FILE in a
/// scratch directory (the same code path as the phone: `openAppDatabase`,
/// `bootstrapApp`, the `ProviderScope` of `main.dart`), plus handles to look
/// at what is stored. Nothing here touches `lib/`.
class QaApp {
  QaApp._(
    this.qa,
    this.dir, {
    required this.clock,
    required this.demo,
    required this.overrides,
  });

  final QaContext qa;
  final Directory dir;
  final DateTime Function() clock;
  final bool demo;
  final List<Override> overrides;

  late AppDatabase database;
  bool _mounted = false;

  WidgetTester get tester => qa.tester;

  /// Creates a scratch directory and database, seeds it (demo data around
  /// [now] unless [demo] is false), runs [prepare] on the stored data and
  /// mounts the app. [beforeOpen] runs first with the (empty) directory, to
  /// leave a database file from an older version there.
  static Future<QaApp> open(
    QaContext qa, {
    DateTime? now,
    DateTime Function()? clock,
    bool demo = true,
    Future<void> Function(QaStorage storage)? prepare,
    Future<void> Function(Directory dir)? beforeOpen,
    bool mount = true,
    List<Override> overrides = const [],
  }) async {
    final tester = qa.tester;
    final fixed = now ?? qaNow;
    final dir = (await tester.runAsync(() async {
      final base = await getTemporaryDirectory();
      return Directory(
        p.join(
          base.path,
          'qa-${qa.id}-${DateTime.now().microsecondsSinceEpoch}',
        ),
      ).create(recursive: true);
    }))!;
    // The QA phone may be in English: the checks read the Spanish texts and
    // the Spanish names of the seeded palette.
    debugPhoneLocales = const [Locale('es', 'ES')];
    final app = QaApp._(
      qa,
      dir,
      clock: clock ?? () => fixed,
      demo: demo,
      overrides: overrides,
    );
    addTearDown(app._dispose);
    await tester.runAsync(() async {
      // Leave a file behind BEFORE the app opens the database (U01: a v1 file).
      if (beforeOpen != null) await beforeOpen(dir);
      app.database = await openAppDatabase(directory: dir);
      if (prepare != null) {
        // Seed first (a no-op the second time), then let the test change what
        // is stored before the app loads it.
        await bootstrapApp(
          config: AppConfig(useDemoData: demo),
          database: app.database,
          now: app.clock,
        );
        await prepare(
          QaStorage(
            app.database,
            ScheduleRepository(app.database, now: app.clock),
          ),
        );
      }
    });
    // `mount: false` leaves the app unmounted so a test can look at the
    // database before `bootstrapApp` touches it; call `app.mount()` later.
    if (mount) await app.mount();
    return app;
  }

  /// Bootstraps from the open database (what `main` does) and pumps the app.
  Future<void> mount({bool settle = true}) async {
    // The QA phone may be in English: the checks read the Spanish texts
    // (the app follows the phone's language by default).
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
    final boot = await tester.runAsync(
      () => bootstrapApp(
        config: AppConfig(useDemoData: demo),
        database: database,
        now: clock,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          initialScheduleProvider.overrideWithValue(boot!.schedule),
          initialHolidaysProvider.overrideWithValue(boot.holidays),
          clockProvider.overrideWithValue(clock),
          ...overrides,
        ],
        child: const CuadranteApp(),
      ),
    );
    _mounted = true;
    if (settle) await tester.settle();
  }

  /// Waits for the writes of the editor, then removes the whole widget tree
  /// (every provider is disposed).
  Future<void> unmount() async {
    if (_mounted) {
      await flushWrites();
      await tester.pumpWidget(const SizedBox.shrink());
      _mounted = false;
    }
  }

  /// Closes the database connection (the file stays).
  Future<void> closeDatabase() => tester.runAsync(database.close).then((_) {});

  /// Opens the same file again.
  Future<void> reopenDatabase() async {
    database = (await tester.runAsync(() => openAppDatabase(directory: dir)))!;
  }

  /// Tear down the tree and the connection, reopen the same file and mount
  /// again: what closing the app and opening it does.
  Future<void> restart() async {
    await unmount();
    await closeDatabase();
    await reopenDatabase();
    await mount();
  }

  Future<void> _dispose() async {
    try {
      await unmount();
    } catch (_) {
      // The tree may already be gone.
    }
    try {
      await tester.runAsync(() async {
        await database.close();
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
    } catch (_) {
      // Already closed or already gone.
    }
  }

  // ---- providers --------------------------------------------------------

  /// The container of the running app, found from the app widget itself: it
  /// works whichever route is on top (the month screen is offstage under the
  /// day sheet, the shift editor, the pattern wizard or the year view).
  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(CuadranteApp)));

  ScheduleController get scheduleController =>
      container.read(scheduleControllerProvider.notifier);

  ScheduleState get scheduleState => container.read(scheduleControllerProvider);

  Schedule get schedule => scheduleState.schedule;

  PaintState get paint => container.read(paintControllerProvider);

  HolidayController get holidayController =>
      container.read(holidayControllerProvider.notifier);

  /// Completes when every write queued by the editor reached the database.
  Future<void> flushWrites() async {
    await tester.runAsync(() => scheduleController.pendingWrites);
  }

  // ---- stored data ------------------------------------------------------

  /// The `day_entries` row of [date] (`null` = no row).
  Future<StoredDay?> storedDay(CivilDate date) async {
    final rows = (await tester.runAsync(
      () => database
          .customSelect(
            'SELECT date, shift_type_ids, note FROM day_entries WHERE date = ?',
            variables: [Variable.withString(date.toIso())],
          )
          .get(),
    ))!;
    if (rows.isEmpty) return null;
    return StoredDay.fromRow(rows.single.data);
  }

  Future<int> storedDayCount() async {
    final rows = (await tester.runAsync(
      () =>
          database.customSelect('SELECT COUNT(*) AS n FROM day_entries').get(),
    ))!;
    return rows.single.read<int>('n');
  }

  /// Raw rows of any query (for assertions that need a table).
  Future<List<Map<String, Object?>>> query(String sql) async {
    final rows = (await tester.runAsync(
      () => database.customSelect(sql).get(),
    ))!;
    return [for (final r in rows) r.data];
  }

  /// The tables the editor writes, without `updated_at`, in a stable order:
  /// two equal dumps mean the stored schedule is identical.
  Future<String> dumpSchedule() async {
    final tables = <String, List<Map<String, Object?>>>{
      'day_entries': await query(
        'SELECT date, shift_type_ids, note FROM day_entries ORDER BY date',
      ),
      'pattern_runs': await query(
        'SELECT id, pattern_id, start_date, end_date, step_offset, seq '
        'FROM pattern_runs ORDER BY seq',
      ),
      'shift_types': await query(
        'SELECT id, code, name, color_value, category, start_minute, '
        'end_minute, sort_order, archived FROM shift_types ORDER BY sort_order',
      ),
    };
    return jsonEncode(tables);
  }

  /// The days the engine resolves from the in-memory schedule, as plain
  /// strings (`2026-10-19|night|note`).
  List<String> resolved(CivilDate from, int days) => [
    for (final d in schedule.resolveRange(from, from.addDays(days - 1)))
      '${d.date.toIso()}|${d.shiftIds.join('+')}|${d.note ?? ''}',
  ];
}

/// A `day_entries` row.
class StoredDay {
  StoredDay({
    required this.date,
    required this.shiftTypeIds,
    required this.note,
  });

  factory StoredDay.fromRow(Map<String, Object?> row) {
    final raw = row['shift_type_ids'] as String?;
    return StoredDay(
      date: row['date']! as String,
      shiftTypeIds: raw == null
          ? null
          : (jsonDecode(raw) as List<dynamic>).cast<String>(),
      note: row['note'] as String?,
    );
  }

  final String date;

  /// `null` = the row does not replace the rotation (note only).
  final List<String>? shiftTypeIds;
  final String? note;

  @override
  String toString() => 'StoredDay($date, $shiftTypeIds, $note)';
}

// ---- finders and gestures ------------------------------------------------

Finder cell(CivilDate date) => find.byKey(ValueKey('day-${date.toIso()}'));

/// [matching] inside the cell of [date].
Finder inCell(CivilDate date, Finder matching) =>
    find.descendant(of: cell(date), matching: matching);

Finder tool(String shiftTypeId) => find.byKey(ValueKey('tool-$shiftTypeId'));

/// The 42 cells of the month grid.
Finder get allCells => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('day-'),
);

extension QaTester on WidgetTester {
  /// Lets animations and queued frames finish (never hangs the run: after
  /// [limit] it just pumps a few more frames and goes on).
  Future<void> settle({Duration limit = const Duration(seconds: 8)}) async {
    try {
      await pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        limit,
      );
    } catch (_) {
      for (var i = 0; i < 5; i++) {
        await pump(const Duration(milliseconds: 100));
      }
    }
  }

  /// Scrolls [finder] into view and taps its first match, then settles.
  ///
  /// On a real device the focused text field keeps scrolling its caret into
  /// view whenever the system keyboard talks to the app, which can undo an
  /// `ensureVisible` made a moment earlier and leave the target off screen (a
  /// tap that silently hits nothing: a form «Guardar» that never saved).
  /// So the target is revealed and checked to be hit-testable in the same
  /// breath as the tap, retried a few times (dismissing the keyboard as the
  /// last resort), and a target that cannot be reached FAILS instead of being
  /// tapped blindly.
  Future<void> tapAndSettle(Finder finder, {String? reason}) async {
    if (finder.evaluate().isEmpty) {
      throw TestFailure('Nada que pulsar: ${reason ?? finder}');
    }
    final target = finder.first;
    var reached = false;
    for (var attempt = 0; attempt < 6 && !reached; attempt++) {
      if (target.evaluate().isEmpty) break;
      if (attempt >= 3) {
        FocusManager.instance.primaryFocus?.unfocus();
        await pump(const Duration(milliseconds: 100));
      }
      await ensureVisible(target); // includes a pump
      reached = target.hitTestable().evaluate().isNotEmpty;
      if (!reached) await pump(const Duration(milliseconds: 100));
    }
    if (!reached) {
      throw TestFailure(
        'No se puede pulsar ${reason ?? finder}: fuera de pantalla o tapado '
        '(el teclado o una capa encima).',
      );
    }
    await tap(target, warnIfMissed: false);
    await settle();
  }

  /// Waits (real time) until [finder] matches.
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 15),
    String? reason,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure(
      'Tiempo agotado esperando ${reason ?? finder}. En pantalla: '
      '${visibleTexts().take(40).join(' | ')}',
    );
  }

  /// Drags with ONE finger through the centre of each cell, in small steps
  /// (the grid maps the pointer to the cells it crosses).
  Future<void> dragAcross(List<Finder> cells) async {
    final points = [for (final c in cells) getCenter(c.first)];
    final gesture = await startGesture(points.first);
    await pump();
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      const steps = 6;
      for (var s = 1; s <= steps; s++) {
        await gesture.moveTo(Offset.lerp(from, to, s / steps)!);
        await pump(const Duration(milliseconds: 16));
      }
    }
    await gesture.up();
    await settle();
  }

  /// Every non-blank string drawn by a [Text] (for messages).
  List<String> visibleTexts() {
    final out = <String>[];
    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget as Text;
      final text = widget.data ?? widget.textSpan?.toPlainText();
      if (text != null && text.trim().isNotEmpty) out.add(text.trim());
    }
    return out;
  }
}

/// Paint mode on/off through the visible controls.
Future<void> enterPaintMode(WidgetTester tester) async {
  await tester.tapAndSettle(find.text('Pintar'), reason: 'botón Pintar');
  expect(
    find.byKey(const ValueKey('paint-done')),
    findsOneWidget,
    reason: 'el modo pintar debe mostrar «Listo»',
  );
}

Future<void> exitPaintMode(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const ValueKey('paint-done')));
  expect(find.text('Pintar'), findsOneWidget);
}

/// Shift ids as `a+b` (`''` when empty), like the widget tests print them.
String idsOn(Schedule schedule, CivilDate date) =>
    schedule.resolve(date).shiftIds.join('+');
