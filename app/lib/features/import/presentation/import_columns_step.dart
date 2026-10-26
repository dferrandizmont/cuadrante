import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_callout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/value_row.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/import_wizard.dart';
import '../domain/csv_parser.dart';
import 'import_format.dart';
import 'import_step_layout.dart';

/// Widest a cell of the preview gets (four of the biggest gaps).
const double _previewCellMaxWidth = Sp.x4 * 4;

/// Step 2 of a CSV: which column is the date, which is the shift, and the
/// optional start and end times, over the first rows of the file.
class ImportColumnsStep extends ConsumerWidget {
  const ImportColumnsStep({super.key});

  /// Rows shown in the preview.
  static const int previewRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final wizard = ref.watch(importWizardProvider);
    final notifier = ref.read(importWizardProvider.notifier);
    final table = wizard.csv;
    final columns = wizard.columns;
    if (table == null || columns == null) return const SizedBox.shrink();

    String name(int column) => table.hasHeader && column < table.header.length
        ? l10n.importColumnNamed(column + 1, table.header[column])
        : l10n.importColumnNumber(column + 1);

    return ImportStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.importColumnsTitle,
              key: const ValueKey('import-title'),
              style: type.headline,
            ),
          ),
          const SizedBox(height: Sp.s),
          Text(
            l10n.importColumnsHelp,
            style: type.body.copyWith(color: colors.textSecondary),
          ),
          if (importFileLine(l10n, wizard) case final fileLine?) ...[
            const SizedBox(height: Sp.m),
            Text(
              fileLine,
              style: type.meta.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: Sp.l),
          Semantics(
            header: true,
            child: Text(
              l10n.importColumnsPreview.toUpperCase(),
              style: type.label.copyWith(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: Sp.s),
          _PreviewTable(table: table, columns: columns),
          const SizedBox(height: Sp.s),
          SettingsSwitchRow(
            key: const ValueKey('import-csv-header'),
            switchKey: const ValueKey('import-csv-header-switch'),
            icon: AppIcons.schedule,
            title: l10n.importColumnsHeader,
            value: table.hasHeader,
            onChanged: notifier.setHeader,
          ),
          const SizedBox(height: Sp.l),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ColumnRow(
                  key: const ValueKey('import-column-date'),
                  label: l10n.importColumnDate,
                  value: name(columns.date),
                  onTap: () async {
                    final picked = await _choose(
                      context,
                      l10n.importColumnDate,
                      table,
                      name,
                      columns.date,
                      optional: false,
                    );
                    if (picked != null && picked >= 0) {
                      notifier.setColumns(columns.assign(CsvRole.date, picked));
                    }
                  },
                ),
                _divider(colors),
                _ColumnRow(
                  key: const ValueKey('import-column-title'),
                  label: l10n.importColumnTitle,
                  value: name(columns.title),
                  onTap: () async {
                    final picked = await _choose(
                      context,
                      l10n.importColumnTitle,
                      table,
                      name,
                      columns.title,
                      optional: false,
                    );
                    if (picked != null && picked >= 0) {
                      notifier.setColumns(
                        columns.assign(CsvRole.title, picked),
                      );
                    }
                  },
                ),
                _divider(colors),
                _ColumnRow(
                  key: const ValueKey('import-column-start'),
                  label: l10n.importColumnStart,
                  value: columns.start == null
                      ? l10n.importColumnNone
                      : name(columns.start!),
                  onTap: () async {
                    final picked = await _choose(
                      context,
                      l10n.importColumnStart,
                      table,
                      name,
                      columns.start ?? -1,
                      optional: true,
                    );
                    if (picked == null) return;
                    notifier.setColumns(
                      columns.assign(CsvRole.start, picked < 0 ? null : picked),
                    );
                  },
                ),
                _divider(colors),
                _ColumnRow(
                  key: const ValueKey('import-column-end'),
                  label: l10n.importColumnEnd,
                  value: columns.end == null
                      ? l10n.importColumnNone
                      : name(columns.end!),
                  onTap: () async {
                    final picked = await _choose(
                      context,
                      l10n.importColumnEnd,
                      table,
                      name,
                      columns.end ?? -1,
                      optional: true,
                    );
                    if (picked == null) return;
                    notifier.setColumns(
                      columns.assign(CsvRole.end, picked < 0 ? null : picked),
                    );
                  },
                ),
              ],
            ),
          ),
          if (wizard.problem != null) ...[
            const SizedBox(height: Sp.l),
            AppCallout(
              titleKey: const ValueKey('import-problem'),
              icon: AppIcons.error,
              title: importProblemText(l10n, wizard.problem!),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _divider(AppColors colors) =>
      Divider(height: 1, thickness: 1, color: colors.border);

  /// The sheet with the columns; `-1` is «Ninguna» (only when [optional]).
  static Future<int?> _choose(
    BuildContext context,
    String title,
    CsvTable table,
    String Function(int) name,
    int selected, {
    required bool optional,
  }) => showChoiceSheet<int>(
    context: context,
    title: title,
    selected: selected,
    options: [
      if (optional) ChoiceOption(-1, context.l10n.importColumnNone),
      for (var c = 0; c < table.columnCount; c++) ChoiceOption(c, name(c)),
    ],
  );
}

class _ColumnRow extends StatelessWidget {
  const _ColumnRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sp.touch + Sp.s),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.l,
              vertical: Sp.m,
            ),
            child: ValueRow(
              valueGap: 0,
              title: Text(label, style: type.body),
              value: Text(
                value,
                style: type.bodyStrong.copyWith(color: colors.textPrimary),
              ),
              trailing: Icon(
                AppIcons.chevronRight,
                size: IconSize.inline,
                color: colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The first rows of the file, the columns in use marked in the header.
///
/// The table is as wide as its columns, so on a narrow phone the last ones
/// were cut off with no sign that there was more (H-T14-5: «Hora de fin»
/// was 3 px wide). It scrolls sideways; a scrollbar that is always visible
/// and a line under it («Desliza hacia los lados…») say so while there is
/// more to the right.
class _PreviewTable extends StatefulWidget {
  const _PreviewTable({required this.table, required this.columns});

  final CsvTable table;
  final CsvColumns columns;

  @override
  State<_PreviewTable> createState() => _PreviewTableState();
}

class _PreviewTableState extends State<_PreviewTable> {
  final ScrollController _scroll = ScrollController();
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_check)
      ..dispose();
    super.dispose();
  }

  /// Whether there is more table to the right of what is on screen.
  void _check() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;
    final more = position.maxScrollExtent - position.pixels > 1;
    if (more != _more) setState(() => _more = more);
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final columns = widget.columns;
    final l10n = context.l10n;
    final colors = context.colors;
    final type = context.type;
    final count = table.columnCount;
    final rows = table.dataRows.take(ImportColumnsStep.previewRows).toList();

    String? role(int column) {
      if (column == columns.date) return l10n.importColumnDate;
      if (column == columns.title) return l10n.importColumnTitle;
      if (column == columns.start) return l10n.importColumnStart;
      if (column == columns.end) return l10n.importColumnEnd;
      return null;
    }

    // One line per cell, cut with an ellipsis past a fixed width: a cell of
    // 120 characters must not make the table as wide as the text.
    Widget cell(String text, TextStyle style) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s, vertical: Sp.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _previewCellMaxWidth),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );

    TextStyle cellStyle({bool strong = false}) => type.meta.copyWith(
      color: strong ? colors.textPrimary : colors.textSecondary,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
    );

    return AppCard.tinted(
      key: const ValueKey('import-csv-preview'),
      padding: const EdgeInsets.all(Sp.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NotificationListener<ScrollMetricsNotification>(
            // The widths change when a column is given another role.
            onNotification: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _check());
              return false;
            },
            child: Scrollbar(
              key: const ValueKey('import-csv-scrollbar'),
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                // Room for the scrollbar under the last row.
                padding: const EdgeInsets.only(bottom: Sp.s),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    TableRow(
                      children: [
                        for (var c = 0; c < count; c++)
                          cell(
                            role(c) ??
                                (table.hasHeader && c < table.header.length
                                    ? table.header[c]
                                    : l10n.importColumnNumber(c + 1)),
                            cellStyle(strong: true).copyWith(
                              color: role(c) != null ? colors.accentText : null,
                            ),
                          ),
                      ],
                    ),
                    for (final row in rows)
                      TableRow(
                        children: [
                          for (var c = 0; c < count; c++)
                            cell(c < row.length ? row[c] : '', cellStyle()),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_more)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xs, Sp.xs, Sp.xs, 0),
              child: Row(
                key: const ValueKey('import-csv-more'),
                children: [
                  Expanded(
                    child: Text(
                      l10n.importColumnsScrollHint,
                      style: type.meta.copyWith(color: colors.textMuted),
                    ),
                  ),
                  const SizedBox(width: Sp.xs),
                  ExcludeSemantics(
                    child: Icon(
                      AppIcons.chevronRight,
                      size: IconSize.inline,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
