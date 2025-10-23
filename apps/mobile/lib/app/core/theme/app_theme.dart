import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Unified App Theme - Consolidated from multiple theme files

/// Light theme configuration
ThemeData get appThemeLight => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: DT.c.brand,
    secondary: DT.c.primaryLight,
    error: DT.c.error,
    surface: DT.c.card,
  ),
  scaffoldBackgroundColor: DT.c.background,
  appBarTheme: AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: DT.c.text,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DT.r.md)),
    color: DT.c.card,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DT.r.sm),
      borderSide: BorderSide(color: DT.c.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DT.r.sm),
      borderSide: BorderSide(color: DT.c.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DT.r.sm),
      borderSide: BorderSide(color: DT.c.brand, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DT.r.sm),
      borderSide: BorderSide(color: DT.c.error),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: DT.s.md,
      vertical: DT.s.md,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DT.c.brand,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: DT.s.xl, vertical: DT.s.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DT.r.sm),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DT.c.brand,
      side: BorderSide(color: DT.c.brand),
      padding: EdgeInsets.symmetric(horizontal: DT.s.xl, vertical: DT.s.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DT.r.sm),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: DT.c.brand,
      padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[100],
    labelStyle: TextStyle(color: DT.c.text, fontSize: 14),
    padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: DT.c.brand,
    unselectedItemColor: DT.c.textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
  ),
);

// Legacy color aliases for backward compatibility
/// Primary brand color
Color get appThemePrimaryColor => DT.c.brand;

/// Primary dark color
Color get appThemePrimaryDark => DT.c.primaryDark;

/// Primary light color
Color get appThemePrimaryLight => DT.c.primaryLight;

/// Accent red color
Color get appThemeAccentRed => DT.c.accentRed;

/// Accent green color
Color get appThemeAccentGreen => DT.c.accentGreen;

/// Accent orange color
Color get appThemeAccentOrange => DT.c.accentOrange;

/// Primary text color
Color get appThemeTextPrimary => DT.c.text;

/// Secondary text color
Color get appThemeTextSecondary => DT.c.textMuted;

/// Tertiary text color
Color get appThemeTextTertiary => DT.c.textMuted;

/// Background color
Color get appThemeBackground => DT.c.surface;

/// Card background color
Color get appThemeCardBackground => DT.c.card;

/// Divider color
Color get appThemeDivider => DT.c.divider;

/// Success color
Color get appThemeSuccess => DT.c.success;

/// Error color
Color get appThemeError => DT.c.error;

/// Warning color
Color get appThemeWarning => DT.c.warning;

/// Info color
Color get appThemeInfo => DT.c.info;

/// Legacy text styles for backward compatibility
/// Headline 1 text style
TextStyle get appTextStylesHeadline1 => DT.t.headline1;

/// Headline 2 text style
TextStyle get appTextStylesHeadline2 => DT.t.headline2;

/// Headline 3 text style
TextStyle get appTextStylesHeadline3 => DT.t.headline3;

/// Body large text style
TextStyle get appTextStylesBodyLarge => DT.t.bodyLarge;

/// Body medium text style
TextStyle get appTextStylesBodyMedium => DT.t.bodyMedium;

/// Body small text style
TextStyle get appTextStylesBodySmall => DT.t.bodySmall;

/// Button text style
TextStyle get appTextStylesButton => DT.t.button;

/// Caption text style
TextStyle get appTextStylesCaption => DT.t.caption;

/// Legacy spacing constants for backward compatibility
/// Extra small spacing
double get appSpacingXs => DT.s.xxs;

/// Small spacing
double get appSpacingSm => DT.s.xs;

/// Medium spacing
double get appSpacingMd => DT.s.md;

/// Large spacing
double get appSpacingLg => DT.s.xl;

/// Extra large spacing
double get appSpacingXl => DT.s.xxl;

/// Extra extra large spacing
double get appSpacingXxl => DT.s.xxl;

/// Legacy radius constants for backward compatibility
/// Small radius
double get appRadiusSm => DT.r.xs;

/// Medium radius
double get appRadiusMd => DT.r.sm;

/// Large radius
double get appRadiusLg => DT.r.md;

/// Extra large radius
double get appRadiusXl => DT.r.lg;

/// Full radius
double get appRadiusFull => DT.r.full;
