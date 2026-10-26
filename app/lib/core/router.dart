import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/agenda/presentation/agenda_screen.dart';
import '../features/alarms/presentation/alarms_settings_screen.dart';
import '../features/backup/application/backup_models.dart';
import '../features/backup/presentation/backup_screen.dart';
import '../features/backup/presentation/restore_preview_screen.dart';
import '../features/calendar/presentation/month_screen.dart';
import '../features/calendar_export/presentation/export_screen.dart';
import '../features/calendars/presentation/calendars_screen.dart';
import '../features/calendars/presentation/compare_screen.dart';
import '../features/holidays/presentation/holidays_settings_screen.dart';
import '../features/import/data/import_file_picker.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/onboarding/application/onboarding_providers.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/patterns/presentation/pattern_wizard_screen.dart';
import '../features/patterns/presentation/runs_screen.dart';
import '../features/schedule/domain/civil_date.dart';
import '../features/settings/presentation/faq_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shift_types/presentation/shift_type_form_screen.dart';
import '../features/shift_types/presentation/shift_types_screen.dart';
import '../features/summary/presentation/summary_screen.dart';
import '../features/year/presentation/year_screen.dart';
import 'providers.dart';

/// Route paths of the app.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const settings = '/ajustes';
  static const settingsCalendars = '/ajustes/calendarios';
  static const settingsHolidays = '/ajustes/festivos';
  static const settingsAlarms = '/ajustes/alarmas';
  static const settingsBackup = '/ajustes/copia';

  /// «Comparar calendarios» (`/comparar?a=<id>&b=<id>&mes=2026-10`; without
  /// query it opens on the calendar on screen and the next one, this month).
  static const compare = '/comparar';

  /// «Preguntas frecuentes» (Ajustes › Ayuda).
  static const settingsFaq = '/ajustes/ayuda';

  /// Import of shifts from the phone calendar, an `.ics`, a CSV or an LRHSoft
  /// backup. `extra` may be a `PickedImportFile` (a file handed to the app) or
  /// an `ImportFileKind` (ask for that kind of file right away).
  static const settingsImport = '/ajustes/importar';

  /// One-off export of the shifts to the phone calendar.
  static const settingsExport = '/ajustes/exportar';

  /// Preview of a `.cuadrante` before restoring it; needs a
  /// `BackupImportRequest` as `extra`.
  static const settingsBackupImport = '/ajustes/copia/importar';
  static const shiftTypes = '/ajustes/turnos';
  static const shiftTypeNew = '/ajustes/turnos/nuevo';

  /// Edit form of one shift type (`/ajustes/turnos/editar/<id>`).
  static String shiftTypeEdit(String id) =>
      '$shiftTypes/editar/${Uri.encodeComponent(id)}';
  static const pattern = '/patron';
  static const year = '/ano';

  /// Monthly summary (`/resumen?mes=2026-10`, add `&vista=ano` for the table
  /// of the year).
  static const summary = '/resumen';

  /// The summary of [month] (any day of it), on the year table when [year].
  static String summaryFor(CivilDate month, {bool year = false}) {
    final mm = month.month.toString().padLeft(2, '0');
    return '$summary?mes=${month.year}-$mm${year ? '&vista=ano' : ''}';
  }

  /// Upcoming notes and search (`/agenda`).
  static const agenda = '/agenda';

  /// The rotations running on the calendar: end or remove them at once.
  static const settingsRuns = '/ajustes/rotaciones';

  /// First use (profession, place, rotation).
  static const onboarding = '/bienvenida';
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// An unknown location (bad deep link) falls back to the same path when it is
/// a valid in-app path, otherwise to home.
void unknownLocationFallback(
  BuildContext context,
  GoRouterState state,
  GoRouter router,
) {
  final current = router.routeInformationProvider.value.uri;
  final valid = !current.hasScheme && current.path.startsWith('/');
  router.go(valid ? current.toString() : AppRoutes.home);
}

/// Builds the router. Pages use the theme's page transitions
/// (`AppPageTransitionsBuilder` on Android, Cupertino on iOS).
///
/// [today] gives today's date (`clockProvider` in the app): a `?mes=` link
/// more than [maxLinkYearsFromToday] years away is ignored.
GoRouter buildRouter({
  String initialLocation = AppRoutes.home,
  CivilDate Function()? today,
}) {
  CivilDate now() => (today ?? () => CivilDate.fromDateTime(DateTime.now()))();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    onException: unknownLocationFallback,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (c, s) => const MonthScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (c, s) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsCalendars,
        builder: (c, s) => const CalendarsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsHolidays,
        builder: (c, s) => const HolidaysSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsAlarms,
        builder: (c, s) => const AlarmsSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsBackup,
        builder: (c, s) => const BackupScreen(),
      ),
      GoRoute(
        path: AppRoutes.compare,
        builder: (c, s) => CompareScreen(
          // A new link to the same screen starts over.
          key: ValueKey(s.uri.toString()),
          firstId: s.uri.queryParameters['a'],
          secondId: s.uri.queryParameters['b'],
          month: _parseMonth(s.uri.queryParameters['mes'], now()),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsFaq,
        builder: (c, s) => const FaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsBackupImport,
        builder: (c, s) => switch (s.extra) {
          final BackupImportRequest request => RestorePreviewScreen(
            request: request,
          ),
          // Opened without a file (a bad link, a restored route): back to the
          // copies.
          _ => const BackupScreen(),
        },
      ),
      GoRoute(
        path: AppRoutes.settingsImport,
        builder: (c, s) => ImportScreen(
          initialFile: s.extra is PickedImportFile
              ? s.extra! as PickedImportFile
              : null,
          initialPick: s.extra is ImportFileKind
              ? s.extra! as ImportFileKind
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsExport,
        builder: (c, s) => const ExportScreen(),
      ),
      GoRoute(
        path: AppRoutes.shiftTypes,
        builder: (c, s) => const ShiftTypesScreen(),
      ),
      GoRoute(
        path: AppRoutes.shiftTypeNew,
        builder: (c, s) => const ShiftTypeFormScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.shiftTypes}/editar/:id',
        builder: (c, s) =>
            ShiftTypeFormScreen(shiftTypeId: s.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.pattern,
        builder: (c, s) => PatternWizardScreen(
          // /patron?inicio=2026-10-24&turno=night
          start: _parseDate(s.uri.queryParameters['inicio']),
          shiftId: s.uri.queryParameters['turno'],
        ),
      ),
      GoRoute(path: AppRoutes.year, builder: (c, s) => const YearScreen()),
      GoRoute(path: AppRoutes.agenda, builder: (c, s) => const AgendaScreen()),
      GoRoute(
        path: AppRoutes.settingsRuns,
        builder: (c, s) => const RunsScreen(),
      ),
      GoRoute(
        path: AppRoutes.summary,
        builder: (c, s) => SummaryScreen(
          // A new link to the same screen starts over.
          key: ValueKey(s.uri.toString()),
          // /resumen?mes=2026-10&vista=ano
          month: _parseMonth(s.uri.queryParameters['mes'], now()),
          yearView: s.uri.queryParameters['vista'] == 'ano',
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (c, s) => const OnboardingScreen(),
      ),
    ],
  );
}

CivilDate? _parseDate(String? iso) {
  if (iso == null) return null;
  try {
    return CivilDate.parse(iso);
  } catch (_) {
    return null;
  }
}

/// `2026-10` -> first day of that month; null for anything else, a year more
/// than [maxLinkYearsFromToday] from [today] included (the screen then opens
/// on today's month).
@visibleForTesting
CivilDate? parseMonthParam(String? value, CivilDate today) =>
    _parseMonth(value, today);

CivilDate? _parseMonth(String? value, CivilDate today) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value ?? '');
  if (match == null) return null;
  final month = int.parse(match[2]!);
  if (month < 1 || month > 12) return null;
  final year = int.parse(match[1]!);
  if (!isLinkYearInRange(year, today)) return null;
  return CivilDate(year, month, 1);
}

final routerProvider = Provider<GoRouter>((ref) {
  // The first launch opens the first-use flow instead of the month.
  final onboarding = ref.read(initialOnboardingProvider)?.needed ?? false;
  final clock = ref.read(clockProvider);
  final router = buildRouter(
    initialLocation: onboarding ? AppRoutes.onboarding : AppRoutes.home,
    today: () => CivilDate.fromDateTime(clock()),
  );
  ref.onDispose(router.dispose);
  return router;
});
