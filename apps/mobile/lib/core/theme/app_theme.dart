import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Unified App Theme - Consolidated from multiple theme files
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: DT.c.brand,
        secondary: DT.c.primaryLight,
        error: DT.c.error,
        surface: DT.c.card,
      ),
      scaffoldBackgroundColor: DT.c.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: DT.c.text,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DT.r.md),
        ),
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
  }

  // Legacy color aliases for backward compatibility
  static Color get primaryColor => DT.c.brand;
  static Color get primaryDark => DT.c.primaryDark;
  static Color get primaryLight => DT.c.primaryLight;
  static Color get accentRed => DT.c.accentRed;
  static Color get accentGreen => DT.c.accentGreen;
  static Color get accentOrange => DT.c.accentOrange;
  static Color get textPrimary => DT.c.text;
  static Color get textSecondary => DT.c.textMuted;
  static Color get textTertiary => DT.c.textMuted;
  static Color get background => DT.c.surface;
  static Color get cardBackground => DT.c.card;
  static Color get divider => DT.c.divider;
  static Color get success => DT.c.success;
  static Color get error => DT.c.error;
  static Color get warning => DT.c.warning;
  static Color get info => DT.c.info;
}

/// Legacy text styles for backward compatibility
class AppTextStyles {
  static TextStyle get headline1 => DT.t.headline1;
  static TextStyle get headline2 => DT.t.headline2;
  static TextStyle get headline3 => DT.t.headline3;
  static TextStyle get bodyLarge => DT.t.bodyLarge;
  static TextStyle get bodyMedium => DT.t.bodyMedium;
  static TextStyle get bodySmall => DT.t.bodySmall;
  static TextStyle get button => DT.t.button;
  static TextStyle get caption => DT.t.caption;
}

/// Legacy spacing constants for backward compatibility
class AppSpacing {
  static double get xs => DT.s.xxs;
  static double get sm => DT.s.xs;
  static double get md => DT.s.md;
  static double get lg => DT.s.xl;
  static double get xl => DT.s.xxl;
  static double get xxl => DT.s.xxl;
}

/// Legacy radius constants for backward compatibility
class AppRadius {
  static double get sm => DT.r.xs;
  static double get md => DT.r.sm;
  static double get lg => DT.r.md;
  static double get xl => DT.r.lg;
  static double get full => DT.r.full;
}
