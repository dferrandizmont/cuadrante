import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/app_icons.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'page_transitions.dart';
import 'spacing.dart';

export 'theme_context.dart';

/// Builds the full Material 3 [ThemeData] from the design tokens.
class AppTheme {
  const AppTheme._();

  /// Minimum touch target (48 dp, see design system).
  static const double minTouch = Sp.touch;

  static ThemeData light() => _build(AppColors.light);
  static ThemeData dark() => _build(AppColors.dark);

  /// Transparent bars, icon brightness following the theme (edge-to-edge).
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: const Color(0x00000000),
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: const Color(0x00000000),
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: const Color(0x00000000),
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _build(AppColors c) {
    final type = AppTypography.from(c);
    final brightness = c.brightness;
    const clear = Color(0x00000000);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accent,
      onPrimaryContainer: c.onAccent,
      secondary: c.accentStrong,
      onSecondary: c.onAccent,
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.onAccent,
      tertiary: c.accentStrong,
      onTertiary: c.onAccent,
      error: c.danger,
      onError: c.dangerContainer,
      errorContainer: c.dangerContainer,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.borderStrong,
      outlineVariant: c.border,
      shadow: c.textPrimary,
      scrim: c.scrim,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      inversePrimary: c.accent,
      surfaceTint: clear,
      surfaceDim: c.background,
      surfaceBright: c.surface,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surfaceMuted,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surfaceMuted,
    );

    final overlay = overlayStyle(brightness);
    final shape14 = RoundedRectangleBorder(borderRadius: Rad.inputRadius);
    const pill = StadiumBorder();
    final disabledFill = c.primaryButton.withValues(alpha: 0.4);

    WidgetStateProperty<Color?> overlayColor(Color base) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return base.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return base.withValues(alpha: 0.08);
          }
          return null;
        });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.family,
      textTheme: type.toTextTheme(),
      primaryTextTheme: type.toTextTheme(),
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      cardColor: c.surface,
      dividerColor: c.border,
      shadowColor: clear,
      splashColor: c.accent.withValues(alpha: 0.18),
      highlightColor: clear,
      hoverColor: c.accent.withValues(alpha: 0.12),
      focusColor: c.accentStrong.withValues(alpha: 0.12),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [c, type],
      iconTheme: IconThemeData(color: c.textSecondary, size: IconSize.base),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          // Keep the native edge-swipe back gesture on Apple platforms.
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => Icon(AppIcons.back),
        closeButtonIconBuilder: (_) => Icon(AppIcons.close),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: clear,
        shadowColor: clear,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 4,
        titleTextStyle: type.title,
        iconTheme: IconThemeData(color: c.textPrimary, size: IconSize.base),
        actionsIconTheme: IconThemeData(
          color: c.textPrimary,
          size: IconSize.base,
        ),
        systemOverlayStyle: overlay,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: clear,
        shadowColor: clear,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Rad.rowRadius,
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        tileColor: clear,
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: type.bodyStrong,
        subtitleTextStyle: type.meta,
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l),
        shape: RoundedRectangleBorder(borderRadius: Rad.rowRadius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.m),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(clear),
          surfaceTintColor: const WidgetStatePropertyAll(clear),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(type.button),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledFill
                : c.primaryButton,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.onPrimaryButton.withValues(alpha: 0.6)
                : c.onPrimaryButton,
          ),
          iconColor: WidgetStatePropertyAll(c.onPrimaryButton),
          overlayColor: overlayColor(c.onPrimaryButton),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.m),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(clear),
          surfaceTintColor: const WidgetStatePropertyAll(clear),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(type.button),
          backgroundColor: WidgetStatePropertyAll(c.surface),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.secondaryLabel.withValues(alpha: 0.5)
                : c.secondaryLabel,
          ),
          iconColor: WidgetStatePropertyAll(c.secondaryLabel),
          side: WidgetStatePropertyAll(
            BorderSide(color: c.borderStrong, width: 1),
          ),
          overlayColor: overlayColor(c.secondaryLabel),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.s),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(type.button),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.disabled) ? c.textMuted : c.accentText,
          ),
          iconColor: WidgetStatePropertyAll(c.accentText),
          overlayColor: overlayColor(c.accentText),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.fab,
        foregroundColor: c.onFab,
        extendedTextStyle: type.button.copyWith(color: c.onFab),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
        extendedPadding: const EdgeInsetsDirectional.only(
          start: Sp.xl,
          end: Sp.xxl,
        ),
        extendedIconLabelSpacing: Sp.m,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.fab),
          side: BorderSide(color: c.fabBorder),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.disabledContent
                : c.textPrimary,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.disabledContent
                : c.textPrimary,
          ),
          overlayColor: overlayColor(c.textPrimary),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.checkbox),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? BorderSide.none
              : BorderSide(color: c.checkboxBorder, width: 1.5),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : clear,
        ),
        checkColor: WidgetStatePropertyAll(c.onAccent),
        overlayColor: overlayColor(c.accentStrong),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.accentStrong
              : c.controlBorder,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          // Dark: accentStrong equals the track, so the thumb takes onAccent.
          (s) => s.contains(WidgetState.selected)
              ? (c.accentStrong == c.accent ? c.onAccent : c.accentStrong)
              : c.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.controlBorder,
        ),
        overlayColor: overlayColor(c.accentStrong),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sp.l,
          vertical: 14,
        ),
        hintStyle: type.body.copyWith(color: c.textSecondary),
        labelStyle: type.meta,
        floatingLabelStyle: type.meta,
        helperStyle: type.meta,
        errorStyle: type.meta.copyWith(color: c.danger),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        counterStyle: type.meta,
        border: OutlineInputBorder(
          borderRadius: Rad.inputRadius,
          borderSide: BorderSide(color: c.controlBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Rad.inputRadius,
          borderSide: BorderSide(color: c.controlBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Rad.inputRadius,
          borderSide: BorderSide(color: c.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Rad.inputRadius,
          borderSide: BorderSide(color: c.accentStrong, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Rad.inputRadius,
          borderSide: BorderSide(color: c.danger.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Rad.inputRadius,
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accentStrong,
        selectionColor: c.accent.withValues(alpha: 0.5),
        selectionHandleColor: c.accentStrong,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.accent,
        disabledColor: c.surfaceMuted,
        surfaceTintColor: clear,
        shadowColor: clear,
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: type.button,
        secondaryLabelStyle: type.button.copyWith(color: c.onAccent),
        labelPadding: const EdgeInsets.symmetric(horizontal: Sp.xs),
        padding: const EdgeInsets.symmetric(horizontal: Sp.s, vertical: Sp.s),
        iconTheme: IconThemeData(color: c.textSecondary, size: IconSize.inline),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: c.background,
        surfaceTintColor: clear,
        shadowColor: clear,
        elevation: 0,
        indicatorColor: c.accentSoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 26,
            color: s.contains(WidgetState.selected)
                ? c.accentStrong
                : c.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => type.caption.copyWith(
            overflow: TextOverflow.ellipsis,
            color: s.contains(WidgetState.selected)
                ? c.accentText
                : c.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.background,
        elevation: 0,
        indicatorColor: c.accentSoft,
        indicatorShape: const StadiumBorder(),
        labelType: NavigationRailLabelType.all,
        minWidth: 80,
        useIndicator: true,
        selectedIconTheme: IconThemeData(color: c.accentStrong, size: 26),
        unselectedIconTheme: IconThemeData(color: c.textSecondary, size: 26),
        selectedLabelTextStyle: type.caption.copyWith(color: c.accentText),
        unselectedLabelTextStyle: type.caption,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.accent,
        textColor: c.onAccent,
        textStyle: type.caption.copyWith(color: c.onAccent),
        smallSize: 8,
        largeSize: 16,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: clear,
        shadowColor: c.softShadow,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: c.border,
        dragHandleSize: const Size(36, 4),
        clipBehavior: Clip.antiAlias,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: clear,
        shadowColor: clear,
        elevation: 0,
        barrierColor: c.scrim,
        titleTextStyle: type.headline,
        contentTextStyle: type.body,
        actionsPadding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.sheet),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // Night mode keeps the snack bar dark; day mode inverts it.
        backgroundColor: c.isDark ? c.surfaceMuted : c.textPrimary,
        contentTextStyle: type.body.copyWith(
          color: c.isDark ? c.textPrimary : c.background,
        ),
        actionTextColor: AppColors.dark.accentText,
        elevation: 0,
        insetPadding: const EdgeInsets.all(Sp.l),
        shape: shape14,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accentStrong,
        circularTrackColor: clear,
        linearTrackColor: c.accentSoft,
        linearMinHeight: 4,
        strokeWidth: 3,
        strokeCap: StrokeCap.round,
        refreshBackgroundColor: c.surface,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.borderStrong),
        radius: const Radius.circular(Rad.chipSmall),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: clear,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Rad.rowRadius,
          side: BorderSide(color: c.border),
        ),
        textStyle: type.body,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: clear,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.sheet),
        ),
        headerBackgroundColor: c.surface,
        headerForegroundColor: c.textPrimary,
        dayStyle: type.body,
        todayBorder: BorderSide(color: c.accentStrong),
        // Today keeps its own text colour, but not when it is also the
        // selected day: that circle is filled with the accent, and `accentText`
        // on it is the same colour (H-T01-1, the number vanished).
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.accentText,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : null,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textPrimary,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: c.accentText,
          textStyle: type.button,
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: c.accentText,
          textStyle: type.button,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.sheet),
        ),
        dialBackgroundColor: c.surfaceMuted,
        dialHandColor: c.accentStrong,
        hourMinuteColor: c.surfaceMuted,
        hourMinuteTextColor: c.textPrimary,
        dayPeriodColor: c.surfaceMuted,
        entryModeIconColor: c.textSecondary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(Rad.input),
        ),
        textStyle: type.meta.copyWith(color: c.background),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
