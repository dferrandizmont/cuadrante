import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_callout.dart';
import '../domain/device_calendar_api.dart';

/// What the calendar permission card says: the import reads calendars, the
/// export writes to one.
enum CalendarPermissionPurpose { read, write }

/// The card shown instead of the calendars while the permission is missing,
/// for the import and for the export. It never asks on its own: the button
/// does, and only after saying why (docs/alarmas.md follows the same rule for
/// notifications).
///
/// - never asked: why, and «Permitir acceso».
/// - refused once on Android, which allows asking again (the plugin reports it
///   as «never asked» when read afterwards): the same question with
///   «Permitir acceso», and a line that says it was refused.
/// - refused for good (the system no longer shows the question; iOS never asks
///   twice): how to turn it on in the system settings, plus «Abrir ajustes» and
///   «Comprobar de nuevo».
/// - restricted by the system: says so, no buttons.
/// - add-only (iOS 17+): says full access is needed and asks again.
class CalendarPermissionCard extends StatelessWidget {
  const CalendarPermissionCard({
    super.key,
    required this.access,
    required this.purpose,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onRecheck,
    this.busy = false,
    this.declined = false,
  });

  /// The permission now (`null` while it is being read).
  final CalendarAccess? access;
  final CalendarPermissionPurpose purpose;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final VoidCallback onRecheck;
  final bool busy;

  /// The user refused the question just now (and it can be asked again).
  final bool declined;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final body = purpose == CalendarPermissionPurpose.read
        ? l10n.calExportPermissionReadBody
        : l10n.calExportPermissionWriteBody;
    return switch (access) {
      CalendarAccess.denied => AppCallout(
        titleKey: const ValueKey('calendar-permission-denied'),
        icon: AppIcons.error,
        title: l10n.calExportPermissionDeniedTitle,
        message: apple
            ? l10n.calExportPermissionDeniedBodyIos
            : l10n.calExportPermissionDeniedBody,
        primaryKey: const ValueKey('calendar-permission-settings'),
        primaryLabel: l10n.calExportPermissionSettings,
        onPrimary: busy ? null : onOpenSettings,
        secondaryKey: const ValueKey('calendar-permission-recheck'),
        secondaryLabel: l10n.calExportPermissionRecheck,
        onSecondary: busy ? null : onRecheck,
      ),
      CalendarAccess.restricted => AppCallout(
        titleKey: const ValueKey('calendar-permission-restricted'),
        icon: AppIcons.error,
        title: l10n.calExportPermissionRestrictedTitle,
        message: l10n.calExportPermissionRestrictedBody,
      ),
      CalendarAccess.writeOnly => AppCallout(
        titleKey: const ValueKey('calendar-permission-write-only'),
        icon: AppIcons.error,
        title: l10n.calExportPermissionTitle,
        message: l10n.calExportPermissionWriteOnlyBody,
        primaryKey: const ValueKey('calendar-permission-allow'),
        primaryLabel: l10n.calExportPermissionAllow,
        onPrimary: busy ? null : onRequest,
        primaryLoading: busy,
        secondaryKey: const ValueKey('calendar-permission-settings'),
        secondaryLabel: l10n.calExportPermissionSettings,
        onSecondary: busy ? null : onOpenSettings,
      ),
      _ => AppCallout(
        titleKey: const ValueKey('calendar-permission-needed'),
        icon: AppIcons.calendar,
        title: l10n.calExportPermissionTitle,
        // After a «No permitir» that Android lets ask again: it says so, and
        // «Permitir acceso» is still there. Once the system stops showing the
        // question, the card above («Abrir ajustes») takes over.
        message: declined ? l10n.calExportPermissionAgainBody : body,
        primaryKey: const ValueKey('calendar-permission-allow'),
        primaryLabel: l10n.calExportPermissionAllow,
        onPrimary: busy ? null : onRequest,
        primaryLoading: busy,
      ),
    };
  }
}
