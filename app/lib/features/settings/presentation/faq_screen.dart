import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/content_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import 'sections/help_section.dart';

/// One question of the help screen and its answer. Paragraphs of the answer
/// are separated by a blank line.
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
  });

  /// Stable key part (`faq-<id>`).
  final String id;
  final String question;
  final String answer;

  /// The answer split into paragraphs.
  List<String> get paragraphs => answer.split('\n\n');
}

/// The questions of the help screen, in order (texts in the ARB).
List<FaqEntry> faqEntries(AppLocalizations l10n, {TargetPlatform? platform}) {
  final target = platform ?? defaultTargetPlatform;
  final apple = target == TargetPlatform.iOS || target == TargetPlatform.macOS;
  return [
    FaqEntry(id: 'paint', question: l10n.faqPaintQ, answer: l10n.faqPaintA),
    FaqEntry(
      id: 'pattern',
      question: l10n.faqPatternQ,
      answer: l10n.faqPatternA,
    ),
    FaqEntry(id: 'double', question: l10n.faqDoubleQ, answer: l10n.faqDoubleA),
    FaqEntry(
      id: 'post-night',
      question: l10n.faqPostNightQ,
      answer: l10n.faqPostNightA,
    ),
    FaqEntry(id: 'notes', question: l10n.faqNotesQ, answer: l10n.faqNotesA),
    FaqEntry(
      id: 'alarms',
      question: apple ? l10n.faqAlarmsQIos : l10n.faqAlarmsQ,
      answer: apple ? l10n.faqAlarmsAIos : l10n.faqAlarmsA,
    ),
    FaqEntry(
      id: 'holidays',
      question: l10n.faqHolidaysQ,
      answer: l10n.faqHolidaysA,
    ),
    FaqEntry(
      id: 'widget',
      question: l10n.faqWidgetQ,
      answer: apple ? l10n.faqWidgetAIos : l10n.faqWidgetA,
    ),
    FaqEntry(id: 'backup', question: l10n.faqBackupQ, answer: l10n.faqBackupA),
    FaqEntry(id: 'import', question: l10n.faqImportQ, answer: l10n.faqImportA),
    FaqEntry(
      id: 'calendars',
      question: l10n.faqCalendarsQ,
      answer: l10n.faqCalendarsA,
    ),
    FaqEntry(
      id: 'summary',
      question: l10n.faqSummaryQ,
      answer: l10n.faqSummaryA,
    ),
  ];
}

/// «Preguntas frecuentes» (`/ajustes/ayuda`, `docs/paridad.md` A13): the
/// questions people ask about painting, rotations, alarms, the widget, copies
/// and the rest, as expandable items, and a way to the contact sheet. Texts
/// are in the ARB; nothing here needs the network.
class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final entries = faqEntries(l10n, platform: Theme.of(context).platform);
    return Scaffold(
      appBar: ContentAppBar.adaptive(
        context,
        title: Text(l10n.settingsFaqTitle),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Sp.page,
            Sp.xs,
            Sp.page,
            Sp.section,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xs, 0, Sp.xs, Sp.l),
              child: Text(
                l10n.faqIntro,
                style: type.meta.copyWith(color: colors.textMuted),
              ),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: colors.border),
                    _FaqTile(entry: entries[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Sp.section),
            Semantics(
              header: true,
              child: Text(l10n.faqNotFound, style: type.bodyStrong),
            ),
            const SizedBox(height: Sp.s),
            SecondaryButton(
              key: const ValueKey('faq-contact'),
              label: l10n.faqContact,
              onPressed: () => HelpSection.showContactSheet(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// A question that opens to its answer. Answers are built only while open.
class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.entry});

  final FaqEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Theme(
      // The tile draws its own dividers by default; the card has them.
      data: Theme.of(context).copyWith(dividerColor: const Color(0x00000000)),
      child: ExpansionTile(
        key: ValueKey('faq-${entry.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: Sp.l),
        childrenPadding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: colors.textSecondary,
        collapsedIconColor: colors.textMuted,
        title: Semantics(
          header: true,
          child: Text(entry.question, style: type.bodyStrong),
        ),
        children: [
          for (final (index, paragraph) in entry.paragraphs.indexed) ...[
            if (index > 0) const SizedBox(height: Sp.m),
            Text(
              paragraph,
              key: ValueKey('faq-${entry.id}-answer-$index'),
              style: type.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
