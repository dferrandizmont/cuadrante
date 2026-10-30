import 'dart:io';

import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/l10n/app_localizations_es.dart';
import 'package:cuadrante/features/backup/application/auto_backup_runner.dart';
import 'package:cuadrante/features/backup/application/backup_models.dart';
import 'package:cuadrante/features/backup/data/platform_backup_channel.dart';
import 'package:cuadrante/features/backup/domain/backup_errors.dart';
import 'package:cuadrante/features/backup/presentation/backup_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(initializeLocale);

  final l10n = AppLocalizationsEs();

  group('error messages (the matrix: R6 and R7)', () {
    test('a newer file asks to update the app', () {
      expect(
        backupErrorMessage(
          l10n,
          const NewerFormatVersion(found: 3, supported: 2),
        ),
        'Este archivo es de una versión más nueva de Turnly: actualiza la '
        'app.',
      );
    });

    test('a file that is not ours', () {
      expect(
        backupErrorMessage(l10n, const NotACuadranteFile('x')),
        'Este archivo no es una copia de Turnly.',
      );
    });

    test('a damaged file', () {
      expect(
        backupErrorMessage(l10n, const CorruptBackup('x')),
        'El archivo está dañado o incompleto y no se puede usar.',
      );
    });

    test('a file that is too big, and one that cannot be read', () {
      expect(
        backupErrorMessage(l10n, IncomingFileProblem.tooLarge),
        'Este archivo es demasiado grande para ser una copia de Turnly.',
      );
      expect(
        backupErrorMessage(l10n, IncomingFileProblem.unreadable),
        'No se ha podido leer el archivo.',
      );
      expect(
        backupErrorMessage(l10n, const FileSystemException('x')),
        'No se ha podido leer el archivo.',
      );
    });
  });

  group('why a copy failed', () {
    test('a full disk is told apart', () {
      expect(
        backupFailureReason(
          l10n,
          const FileSystemException(
            'write failed',
            '/x',
            OSError('No space left on device', 28),
          ),
        ),
        'El dispositivo no tiene espacio libre.',
      );
    });

    test('anything else is the generic reason', () {
      expect(
        backupFailureReason(l10n, StateError('x')),
        'No se pudo escribir el archivo de la copia.',
      );
      expect(
        backupFailureReason(l10n, null),
        'No se pudo escribir el archivo de la copia.',
      );
    });
  });

  group('when', () {
    final now = DateTime(2026, 10, 19, 12);

    test('today, yesterday, this year and other years', () {
      expect(
        backupWhen(l10n, DateTime(2026, 10, 19, 9, 5), now),
        'hoy a las 09:05',
      );
      expect(
        backupWhen(l10n, DateTime(2026, 10, 18, 23, 59), now),
        'ayer a las 23:59',
      );
      expect(
        backupWhen(l10n, DateTime(2026, 9, 3, 18, 20), now),
        'el jue 3 sep a las 18:20',
      );
      expect(
        backupWhen(l10n, DateTime(2025, 12, 31, 8), now),
        'el mié 31 dic 2025 a las 08:00',
      );
    });

    test('a night copy still counts as yesterday', () {
      expect(
        backupWhen(l10n, DateTime(2026, 10, 18, 0, 10), now),
        'ayer a las 00:10',
      );
    });

    test('a sentence can start with it', () {
      expect(sentenceCase('hoy a las 09:05'), 'Hoy a las 09:05');
      expect(sentenceCase(''), '');
    });
  });

  group('sizes', () {
    test('KB for small files, never zero', () {
      expect(backupSize(1, 'es'), '1 KB');
      expect(backupSize(1024, 'es'), '1 KB');
      expect(backupSize(1025, 'es'), '2 KB');
      expect(backupSize(900 * 1024, 'es'), '900 KB');
    });

    test('MB with a decimal comma', () {
      expect(backupSize(1536 * 1024, 'es'), '1,5 MB');
    });
  });

  group('the name of an exported file', () {
    test('lower case, with the local date and time', () {
      expect(
        exportFileName(DateTime(2026, 11, 10, 23, 59, 7)),
        'turnly-2026-11-10-235907.turnly',
      );
      expect(
        exportFileName(DateTime(2026, 1, 5)),
        'turnly-2026-01-05-000000.turnly',
      );
    });

    test('two exports of the same day are two different files', () {
      expect(
        exportFileName(DateTime(2026, 11, 10, 9, 0, 0)),
        isNot(exportFileName(DateTime(2026, 11, 10, 9, 0, 1))),
      );
    });
  });

  group('the line while changes wait for their copy (H-T13-1)', () {
    final now = DateTime(2026, 10, 22, 11, 0);

    test('a copy due within a minute: «unos segundos»', () {
      final status = AutoBackupStatus(
        pending: true,
        dueAt: now.add(const Duration(seconds: 10)),
      );
      expect(
        pendingCopyMessage(l10n, status, now),
        'Hay cambios nuevos: la copia se hará en unos segundos.',
      );
    });

    test('a copy held back by the 15 min spacing says the time', () {
      final status = AutoBackupStatus(
        pending: true,
        dueAt: DateTime(2026, 10, 22, 11, 3),
      );
      final text = pendingCopyMessage(l10n, status, now);
      expect(text, contains('hacia las 11:03'));
      expect(text, isNot(contains('unos segundos')));
      expect(text, contains('Hacer copia ahora'));
    });

    test('without a scheduled time it still promises nothing quick', () {
      final text = pendingCopyMessage(
        l10n,
        const AutoBackupStatus(pending: true),
        now,
      );
      expect(text, contains('en unos minutos'));
      expect(text, isNot(contains('unos segundos')));
    });
  });
}
