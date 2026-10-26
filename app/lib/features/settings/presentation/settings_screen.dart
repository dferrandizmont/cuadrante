import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import 'sections/appearance_section.dart';
import 'sections/help_section.dart';
import 'sections/import_export_section.dart';
import 'sections/more_section.dart';
import 'sections/schedule_section.dart';

/// Settings (`/ajustes`): grouped sections of rows (`docs/diseno.md`). Each
/// area is its own section widget in `sections/`; a new setting goes in its
/// section, and a new area is one more entry in [_sections].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Widget> _sections = [
    ScheduleSection(),
    AppearanceSection(),
    MoreSection(),
    ImportExportSection(),
    HelpSection(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(context.l10n.settingsTitle),
      ),
      body: PageBody(
        // A handful of sections: all built at once, so every row can be
        // reached (and found by tests) without waiting for a lazy list.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.s, Sp.page, Sp.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _sections.length; i++) ...[
                if (i > 0) const SizedBox(height: Sp.section),
                _sections[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
