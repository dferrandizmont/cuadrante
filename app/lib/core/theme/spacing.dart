import 'package:flutter/widgets.dart';

/// Spacing scale (dp): 4, 8, 12, 16, 20, 24, 32, 40.
class Sp {
  const Sp._();

  /// Hairline nudge (2 dp): optical alignment of an icon with a text line.
  static const double hair = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3 = 32;
  static const double x4 = 40;

  /// Screen horizontal padding.
  static const double page = 20;

  /// Gap between cards.
  static const double card = 8;

  /// Gap between sections.
  static const double section = 24;

  /// Content never grows wider than this (tablets, landscape).
  static const double maxContentWidth = 640;

  /// Notices keep their action close to the message on wide windows.
  static const double snackBarMaxWidth = 560;

  /// Extended paint button and the space separating it from content.
  static const double fabHeight = 56;
  static const double fabClearance = fabHeight + l;

  /// Width from which the shell switches to a navigation rail.
  static const double railBreakpoint = 840;

  /// Stroke of the inner ring of today's cell and of a cell in the stroke.
  static const double ring = 2;

  /// Stroke of the ring around the selected shift puck, and its gap.
  static const double selectionRing = 2.5;
  static const double selectionGap = 3;

  /// Stroke of the border of a chosen day cell: thicker than the ring of the
  /// open day ([selectionRing]) and than the ring of today ([ring]), so the
  /// selection is told apart by its shape.
  static const double selectedBorder = 3.5;

  /// Bottom bar of a day cell (design: 6 px) and of the "today" card (5 px).
  static const double bar = 6;
  static const double cardBar = 5;

  /// Gap between two day cells.
  static const double cellGap = 4;

  /// Dot beside a compact start time when a shift has two segments.
  static const double cellSegmentDot = 6;

  /// Minimum touch target.
  static const double touch = 48;

  static const EdgeInsets pageInsets = EdgeInsets.symmetric(horizontal: page);
}

/// Corner radii (dp).
class Rad {
  const Rad._();

  static const double chip = 999;

  /// Tiny legend swatches (10-14 dp squares).
  static const double swatch = 4;
  static const double checkbox = 7;

  /// Small chips, badges and inline tags.
  static const double chipSmall = 10;

  /// The countdown chip of the "today" card.
  static const double countdown = 12;

  /// Inner blocks inside a card (slots, swatches, nested panels) and the
  /// day cells of the month grid.
  static const double inner = 12;
  static const double cell = 12;
  static const double input = 14;
  static const double button = 14;

  /// The card and row radius: every `AppCard` uses it by default.
  static const double row = 16;

  /// Shift badge of the "today" card (56 dp).
  static const double badge = 18;

  /// Hero cards (the "today" card).
  static const double card = 24;

  /// Bottom sheets (paint tools, day sheet) and dialogs.
  static const double sheet = 26;

  /// The extended "Pintar" button (56 dp tall, fully rounded ends).
  static const double fab = 28;

  /// The home-screen widget preview (Android's launcher widget radius).
  static const double preview = 24;

  static BorderRadius get rowRadius => BorderRadius.circular(row);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get cellRadius => BorderRadius.circular(cell);
  static BorderRadius get badgeRadius => BorderRadius.circular(badge);
  static BorderRadius get countdownRadius => BorderRadius.circular(countdown);
  static BorderRadius get inputRadius => BorderRadius.circular(input);
  static BorderRadius get innerRadius => BorderRadius.circular(inner);
  static BorderRadius get chipSmallRadius => BorderRadius.circular(chipSmall);
  static BorderRadius get swatchRadius => BorderRadius.circular(swatch);
  static BorderRadius get previewRadius => BorderRadius.circular(preview);
  static BorderRadius get pill => BorderRadius.circular(chip);
}

/// Round icon-disc diameters (dp).
class Disc {
  const Disc._();

  /// Inline discs inside dense rows and chips.
  static const double s = 28;

  /// Default: item rows, kind discs, list leading icons.
  static const double m = 36;

  /// Card headers, setup rows.
  static const double l = 44;

  /// Empty states and hero illustrations.
  static const double xl = 72;

  /// Shift badge of the "today" card.
  static const double badge = 56;

  /// Shift puck of the paint tools.
  static const double puck = 54;

  /// Round undo / redo buttons of the paint tools.
  static const double round = 48;
}

/// Icon sizes (dp).
class IconSize {
  const IconSize._();

  /// Inline with text (meta lines, chips).
  static const double inline = 18;

  /// Inside buttons.
  static const double button = 20;

  /// Default (app bar, list leading, nav).
  static const double base = 24;

  /// The glyph inside a [Disc.xl] hero disc (empty states, sheet heroes).
  static const double hero = 34;
}

/// Motion durations.
class Motion {
  const Motion._();

  static const Duration state = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 280);
  static const Duration checkbox = Duration(milliseconds: 160);
  static const Curve curve = Curves.easeOutCubic;

  /// Zero when the user asked to reduce motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}
