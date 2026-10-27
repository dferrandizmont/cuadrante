@Tags(['store'])
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cuadrante/app.dart';
import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/database_provider.dart';
import 'package:cuadrante/core/providers.dart';
import 'package:cuadrante/core/router.dart';
import 'package:cuadrante/core/theme/app_colors.dart';
import 'package:cuadrante/core/theme/app_typography.dart';
import 'package:cuadrante/features/calendar/application/paint_controller.dart';
import 'package:cuadrante/features/calendars/data/calendars_repository.dart';
import 'package:cuadrante/features/calendars/domain/calendar.dart';
import 'package:cuadrante/features/holidays/application/holidays_provider.dart';
import 'package:cuadrante/features/holidays/data/holiday_repository.dart';
import 'package:cuadrante/features/holidays/presentation/holidays_settings_providers.dart';
import 'package:cuadrante/features/patterns/application/pattern_wizard.dart';
import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/schedule/application/schedule_providers.dart';
import 'package:cuadrante/features/settings/application/preferences_controller.dart';
import 'package:cuadrante/features/settings/domain/preferences.dart';
import 'package:cuadrante/features/summary/domain/month_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_storage.dart';
import 'readme_render_support.dart';

final _now = DateTime(2026, 12, 24, 18);
const _month = CivilDate(2026, 12, 1);
const _logical = Size(412, 940);
const _targetName = String.fromEnvironment(
  'STORE_TARGET',
  defaultValue: 'readme',
);
const _targets = {
  'readme': Size(540, 1080),
  'play': Size(1080, 1920),
  'ios69': Size(1320, 2868),
  'ios65': Size(1242, 2688),
};
const _shots = [
  '01-mes',
  '02-lista',
  '03-pintar',
  '04-rotaciones',
  '05-horas',
  '06-festivos',
];
// One caption per shot, in the order of [_shots]. Vocabulary from
// docs/glosario-idiomas.md; ca, gl and eu are pending native review.
const _captions = {
  'es': [
    'Tus turnos, de un vistazo',
    'Cada horario, al detalle',
    'Pinta tus turnos',
    'Tu rotación, a tu manera',
    'Noches y festivos, por separado',
    'Tus festivos, sin conexión',
  ],
  'ca': [
    "Els teus torns, d'un cop d'ull",
    'Cada horari, al detall',
    'Pinta els teus torns',
    'La teva rotació, a la teva manera',
    'Nits i festius, per separat',
    'Els teus festius, sense connexió',
  ],
  'gl': [
    'As túas quendas, dunha ollada',
    'Cada horario, ao detalle',
    'Pinta as túas quendas',
    'A túa rotación, ao teu xeito',
    'Noites e festivos, por separado',
    'Os teus festivos, sen conexión',
  ],
  'eu': [
    'Zure txandak, begi-kolpe batean',
    'Ordutegi bakoitza, xehetasunez',
    'Margotu zure txandak',
    'Zure txandaketa, zure erara',
    'Gauak eta jaiegunak, bereiz',
    'Zure jaiegunak, konexiorik gabe',
  ],
  'en': [
    'Your shifts at a glance',
    'Every shift in detail',
    'Paint your shifts',
    'Your rotation, your way',
    'Night and public holiday hours',
    'Your public holidays, offline',
  ],
};
const _industry = {
  'es': 'Industria',
  'ca': 'Indústria',
  'gl': 'Industria',
  'eu': 'Industria',
  'en': 'Industry',
};

void main() {
  setUpAll(() async {
    if (generateStore) await loadStoreFonts();
  });
  tearDownAll(() => AppTypography.debugFamily = null);

  for (final language in _captions.keys) {
    for (final (index, shot) in _shots.indexed) {
      testWidgets(
        '$language/$shot ($_targetName)',
        (tester) async {
          final target = _targets[_targetName];
          expect(
            target,
            isNotNull,
            reason: 'STORE_TARGET: ${_targets.keys.join(', ')}',
          );
          debugDefaultTargetPlatformOverride = _targetName.startsWith('ios')
              ? TargetPlatform.iOS
              : TargetPlatform.android;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          tester.view.physicalSize = _logical;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.localesTestValue = [Locale(language)];
          tester.platformDispatcher.localeTestValue = Locale(language);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          debugPhoneLocales = [Locale(language)];
          addTearDown(() => debugPhoneLocales = const [Locale('es', 'ES')]);
          final storage = await openTestStorage(tester, now: _now, demo: false);
          await tester.runAsync(() async {
            final repository = storage.repository;
            final calendars = CalendarsRepository(
              storage.database,
              now: () => _now,
            );
            await calendars.rename(mainCalendarId, 'Demo');
            if (index == 3) {
              await CalendarsRepository(
                storage.database,
                now: () => _now,
                newId: () => 'store-industry',
              ).create(name: _industry[language]!, colorValue: 0xFF4B4FD1);
            }
            // Keep a useful, compact palette; archived types remain in history.
            for (final t in shiftTemplates) {
              if (![
                'morning',
                'afternoon',
                'night',
                'rest',
                'postNight',
              ].contains(t.key)) {
                await repository.archiveShiftType(t.key);
              }
            }
            final changes = <CivilDate, EntryChange>{};
            for (var day = 1; day <= 31; day++) {
              final id = switch (day) {
                >= 1 && <= 4 => 'morning',
                10 || 11 => 'afternoon',
                23 || 24 || 25 => 'night',
                26 => 'postNight',
                _ => 'rest',
              };
              final date = CivilDate(2026, 12, day);
              changes[date] = EntryChange(
                null,
                DayEntry(date: date, shiftTypeIds: [id]),
              );
            }
            await repository.apply(
              mainCalendarId,
              ScheduleChange(patch: EntriesPatch(changes)),
            );
            await HolidayRepository(storage.database)
                .savePlace(regionCode: 'ES-MD', municipalityCode: '28079');
          });
          final snapshot = (await tester.runAsync(
            storage.withReloadedSnapshot,
          ))!;
          final holidays = (await tester.runAsync(
            () => HolidayRepository(storage.database).loadSnapshot(),
          ))!;
          final summary = summarizeMonth(
            snapshot.snapshot.schedule,
            _month,
            holidays: holidays.byDay.keys.toSet(),
          );
          expect(summary.shiftsWorked, 9);
          expect(summary.workedMinutes, 72 * 60);
          expect(summary.nightMinutes, 24 * 60);
          expect(summary.holidayMinutes, 8 * 60);
          final initial = index == 3
              ? (await tester.runAsync(
                  () => storage.repository.load('store-industry'),
                ))!
              : snapshot.snapshot;
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: ProviderScope(
                overrides: [
                  appDatabaseProvider.overrideWithValue(storage.database),
                  initialScheduleProvider.overrideWithValue(initial),
                  clockProvider.overrideWithValue(() => _now),
                  initialHolidaysProvider.overrideWithValue(holidays),
                  initialPreferencesProvider.overrideWithValue(
                    Preferences(
                      themeMode: index == 0 || index == 2
                          ? ThemeMode.dark
                          : ThemeMode.light,
                      language: AppLanguage.values.byName(language),
                    ),
                  ),
                ],
                child: const CuadranteApp(),
              ),
            ),
          );
          try {
            await tester.pumpAndSettle();
            final container = ProviderScope.containerOf(
              tester.element(find.byType(CuadranteApp)),
            );
            final router = container.read(routerProvider);
            switch (index) {
              case 1:
                await tester.tap(
                  find.byKey(const ValueKey('month-presentation-list')),
                );
                await tester.pumpAndSettle();
                // The app initially reveals today; use the beginning of the
                // list for a complete header and whole, unclipped rows.
                tester
                    .state<ScrollableState>(find.byType(Scrollable).first)
                    .position
                    .jumpTo(0);
              case 2:
                final paint = container.read(paintControllerProvider.notifier);
                paint.enter();
                paint.selectShift('night');
              case 3:
                router.push('${AppRoutes.pattern}?inicio=2026-12-01');
                await tester.pumpAndSettle();
                final wizard = container.read(
                  patternWizardProvider((start: _month, shiftId: null))
                      .notifier,
                );
                wizard.selectPreset('continental');
                wizard.next();
                wizard.next();
                await tester.pumpAndSettle();
                await tester.ensureVisible(
                  find.byKey(const ValueKey('pattern-preview')),
                );
              case 4:
                router.push(AppRoutes.summaryFor(_month));
              case 5:
                router.push(AppRoutes.settingsHolidays);
                await tester.pumpAndSettle();
                await tester.runAsync(
                  () => container.read(municipalityIndexProvider.future),
                );
                await tester.runAsync(
                  () => container.read(regionalNationalEntriesProvider.future),
                );
            }
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final screen = await boundary.toImage(pixelRatio: 3);
              try {
                final image = await _compose(
                  screen,
                  target!,
                  _captions[language]![index],
                  index,
                );
                try {
                  final path = _targetName == 'readme'
                      ? '../docs/readme/$language/$shot.png'
                      : 'build/store/$_targetName/$language/$shot.png';
                  await writeStorePng(image, path);
                } finally {
                  image.dispose();
                }
              } finally {
                screen.dispose();
              }
            });
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            debugDefaultTargetPlatformOverride = null;
          }
        },
        skip: !generateStore,
        timeout: const Timeout(Duration(minutes: 3)),
      );
    }
  }
}

Future<ui.Image> _compose(
  ui.Image screen,
  Size target,
  String caption,
  int index,
) async {
  final colors = index == 0 || index == 2 ? AppColors.dark : AppColors.light;
  final type = AppTypography.from(colors);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & target, Paint()..color = colors.background);
  final margin = target.width * .06;
  final titleHeight = target.height * .12;
  paintCaption(
    canvas,
    caption,
    Rect.fromLTWH(margin, margin, target.width - margin * 2, titleHeight),
    type.headline.copyWith(fontSize: target.width * .057),
  );
  final scale = math.min(
    (target.width - margin * 2) / _logical.width,
    (target.height - titleHeight - margin * 2) / _logical.height,
  );
  final rect = Rect.fromLTWH(
    (target.width - _logical.width * scale) / 2,
    titleHeight + margin,
    _logical.width * scale,
    _logical.height * scale,
  );
  final frame = RRect.fromRectAndRadius(
    rect.inflate(2),
    Radius.circular(target.width * .025),
  );
  canvas.drawRRect(frame, Paint()..color = colors.borderStrong);
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(target.width * .025)),
  );
  canvas.drawImageRect(
    screen,
    Rect.fromLTWH(0, 0, screen.width.toDouble(), screen.height.toDouble()),
    rect,
    Paint()..filterQuality = FilterQuality.high,
  );
  canvas.restore();
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(target.width.toInt(), target.height.toInt());
  } finally {
    picture.dispose();
  }
}
