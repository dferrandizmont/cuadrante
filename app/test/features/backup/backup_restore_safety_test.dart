import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/core/database/app_database.dart';
import 'package:cuadrante/features/alarms/data/alarm_settings_repository.dart';
import 'package:cuadrante/features/alarms/domain/alarm_settings.dart';
import 'package:cuadrante/features/backup/data/backup_settings_repository.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_data.dart';
import 'package:cuadrante/features/backup/domain/restore_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'backup_ui_support.dart';
import 'golden_dataset_v2.dart';

/// A file is data from outside: the preview says who sent it and what
/// protections it would switch off, and guards its confirm button.
BackupData _withSettings(BackupData base, Map<String, String> settings) =>
    BackupData(
      calendars: base.calendars,
      shiftTypes: base.shiftTypes,
      patterns: base.patterns,
      patternRuns: base.patternRuns,
      dayEntries: base.dayEntries,
      holidays: base.holidays,
      absenceBalances: base.absenceBalances,
      settings: settings,
    );

const _alarmsOn = '{"enabled":true,"horizonDays":14,"types":{}}';
const _alarmsOff = '{"enabled":false,"horizonDays":14,"types":{}}';

void main() {
  setUpAll(initializeLocale);

  group('what a file would switch off (domain)', () {
    const none = <String, String>{};

    test('automatic copies: on by default, off only when stored false', () {
      expect(autoBackupIsOn(none), isTrue);
      expect(autoBackupIsOn({autoBackupKey: 'true'}), isTrue);
      expect(autoBackupIsOn({autoBackupKey: 'false'}), isFalse);
      expect(autoBackupIsOn({autoBackupKey: 'garbage'}), isTrue);
    });

    test('alarms: off unless stored on', () {
      expect(alarmsAreOn(none), isFalse);
      expect(alarmsAreOn({alarmSettingsKey: _alarmsOn}), isTrue);
      expect(alarmsAreOn({alarmSettingsKey: _alarmsOff}), isFalse);
      expect(alarmsAreOn({alarmSettingsKey: 'garbage'}), isFalse);
      expect(alarmsAreOn({alarmSettingsKey: '[1]'}), isFalse);
    });

    RestoreSummary summary(Map<String, String> file, Map<String, String> now) =>
        summarizeRestore(
          _withSettings(buildGoldenBackupDataV2(), file),
          BackupCounts.of(buildGoldenBackupDataV2()),
          currentSettings: now,
        );

    test('says so when the file turns off what is on now', () {
      final s = summary(
        {autoBackupKey: 'false'},
        {alarmSettingsKey: _alarmsOn},
      );
      expect(s.turnsOffAutoBackup, isTrue);
      // The file has no alarms at all: restoring removes the current ones.
      expect(s.turnsOffAlarms, isTrue);
    });

    test('is silent when nothing that is on goes off', () {
      expect(summary(none, none).turnsOffAutoBackup, isFalse);
      expect(summary(none, none).turnsOffAlarms, isFalse);
      // Already off now: nothing to warn about.
      final off = summary(
        {autoBackupKey: 'false', alarmSettingsKey: _alarmsOff},
        {autoBackupKey: 'false', alarmSettingsKey: _alarmsOff},
      );
      expect(off.turnsOffAutoBackup, isFalse);
      expect(off.turnsOffAlarms, isFalse);
      // The file keeps them on.
      final keep = summary(
        {alarmSettingsKey: _alarmsOn},
        {alarmSettingsKey: _alarmsOn},
      );
      expect(keep.turnsOffAlarms, isFalse);
    });
  });

  group('the preview', () {
    Finder key(String k) => find.byKey(ValueKey(k));

    Future<BackupUiHarness> openShared(
      WidgetTester tester, {
      required BackupData data,
      String? sender,
      Future<void> Function(AppDatabase db)? prepare,
    }) async {
      final h = BackupUiHarness(tester);
      await AppUnderTest.pump(tester, overrides: h.overrides, prepare: prepare);
      h.channel.incoming = IncomingFile.bytes(
        BackupUiHarness.fileOf(data),
        sender: sender,
      );
      h.channel.listener!();
      await pumpIo(tester, until: key('restore-preview'));
      return h;
    }

    testWidgets('names the app that sent the file, as information', (
      tester,
    ) async {
      await openShared(
        tester,
        data: buildGoldenBackupDataV2(),
        sender: 'WhatsApp (com.whatsapp)',
      );
      expect(
        textOf(tester, key('restore-sender')),
        'Enviado desde WhatsApp (com.whatsapp)',
      );
      expect(key('restore-sender-hint'), findsOneWidget);
      // It is only information: the same confirmation as always.
      expect(key('restore-confirm'), findsOneWidget);
    });

    testWidgets('says nothing about a sender the system did not name', (
      tester,
    ) async {
      await openShared(tester, data: buildGoldenBackupDataV2());
      expect(key('restore-sender'), findsNothing);
      expect(key('restore-sender-hint'), findsNothing);
    });

    testWidgets('says out loud that the file turns off the automatic copies '
        'and the alarms', (tester) async {
      await openShared(
        tester,
        data: _withSettings(buildGoldenBackupDataV2(), {
          autoBackupKey: 'false',
          alarmSettingsKey: _alarmsOff,
        }),
        // Alarms are on on this phone.
        prepare: (db) =>
            AlarmSettingsRepository(db)
                .save(const AlarmSettings(enabled: true)),
      );
      expect(key('restore-turns-off'), findsOneWidget);
      expect(
        find.textContaining('Desactiva las copias automáticas.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Desactiva las alarmas de turno.'),
        findsOneWidget,
      );
    });

    testWidgets('does not cry wolf when nothing that is on goes off', (
      tester,
    ) async {
      await openShared(tester, data: buildGoldenBackupDataV2());
      expect(key('restore-turns-off'), findsNothing);
    });

    testWidgets('only the alarms line shows when only the alarms go off', (
      tester,
    ) async {
      await openShared(
        tester,
        data: _withSettings(buildGoldenBackupDataV2(), {}),
        prepare: (db) =>
            AlarmSettingsRepository(db)
                .save(const AlarmSettings(enabled: true)),
      );
      expect(find.text('Desactiva las alarmas de turno.'), findsOneWidget);
      expect(find.text('Desactiva las copias automáticas.'), findsNothing);
    });

    testWidgets('guards the confirm button against overlays while it is open', (
      tester,
    ) async {
      final h = await openShared(tester, data: buildGoldenBackupDataV2());
      expect(h.channel.protection, [true]);

      await tester.tap(find.byType(BackButton).last);
      await pumpIo(tester);

      expect(h.channel.protection, [true, false]);
    });
  });
}
