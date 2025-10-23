import 'package:flutter/material.dart';

/// Enhanced Design Tokens - Based on Design Science Principles
///
/// This system follows design science principles for consistent, accessible,
/// and maintainable UI components across the application.
class DT {
  DT._();

  /// Design colors instance
  static DesignColors get c => DesignColors();

  /// Design radii instance
  static DesignRadii get r => DesignRadii();

  /// Design spacing instance
  static DesignSpace get s => DesignSpace();

  /// Design text styles instance
  static DesignText get t => DesignText();

  /// Design elevation instance
  static DesignElev get e => DesignElev();

  /// Design animations instance
  static DesignAnimations get a => DesignAnimations();

  /// Design breakpoints instance
  static DesignBreakpoints get bp => DesignBreakpoints();
}

/// Simple color system based on design science principles
class DesignColors {
  // Primary Colors
  /// Primary brand color
  final Color brand = const Color(0xFF2563EB);

  /// Secondary color
  final Color secondary = const Color(0xFF64748B);

  // Legacy support
  /// Legacy primary color
  final Color primaryColor = const Color(0xFF2563EB);

  /// Legacy primary dark color
  final Color primaryDark = const Color(0xFF1D4ED8);

  /// Legacy primary light color
  final Color primaryLight = const Color(0xFF3B82F6);

  // Semantic Colors
  /// Success color
  final Color success = const Color(0xFF059669);

  /// Error color
  final Color error = const Color(0xFFDC2626);

  /// Warning color
  final Color warning = const Color(0xFFD97706);

  /// Info color
  final Color info = const Color(0xFF2563EB);

  // Accent Colors
  /// Accent red color
  final Color accentRed = const Color(0xFFDC2626);

  /// Accent green color
  final Color accentGreen = const Color(0xFF059669);

  /// Accent orange color
  final Color accentOrange = const Color(0xFFD97706);

  /// Accent purple color
  final Color accentPurple = const Color(0xFF7C3AED);

  /// Accent teal color
  final Color accentTeal = const Color(0xFF0891B2);

  // Neutral Colors
  /// Background color
  final Color background = const Color(0xFFF8FAFC);

  /// Surface color
  final Color surface = Colors.white;

  /// Surface variant color
  final Color surfaceVariant = const Color(0xFFF1F5F9);

  /// Surface container color
  final Color surfaceContainer = const Color(0xFFE2E8F0);

  /// Card color
  final Color card = Colors.white;

  /// Border color
  final Color border = const Color(0xFFE2E8F0);

  /// Divider color
  final Color divider = const Color(0xFFF1F5F9);

  // Text Colors
  /// Primary text color
  final Color text = const Color(0xFF0F172A);

  /// Secondary text color
  final Color textMuted = const Color(0xFF64748B);

  /// Primary text color (legacy)
  final Color textPrimary = const Color(0xFF0F172A);

  /// Secondary text color (legacy)
  final Color textSecondary = const Color(0xFF475569);

  /// Text on brand color
  final Color textOnBrand = Colors.white;

  /// Text on secondary color
  final Color textOnSecondary = Colors.white;

  // State Colors
  /// Success background color
  final Color successBg = const Color(0xFFECFDF5);

  /// Success foreground color
  final Color successFg = const Color(0xFF065F46);

  /// Success border color
  final Color successBorder = const Color(0xFFA7F3D0);

  /// Info background color
  final Color infoBg = const Color(0xFFEFF6FF);

  /// Info foreground color
  final Color infoFg = const Color(0xFF1E40AF);

  /// Info border color
  final Color infoBorder = const Color(0xFFBFDBFE);

  // Gradient Colors
  /// Gradient start color
  final Color gradientStart = const Color(0xFF2563EB);

  /// Gradient end color
  final Color gradientEnd = const Color(0xFF3B82F6);

  // Brand variations
  /// Brand deep color
  final Color brandDeep = const Color(0xFF1D4ED8);

  /// Brand light color
  final Color brandLight = const Color(0xFF3B82F6);

  /// Brand subtle color
  final Color brandSubtle = const Color(0xFFEFF6FF);
}

/// Design radii class containing all border radius tokens
class DesignRadii {
  /// Extra small radius
  final double xs = 8;

  /// Small radius
  final double sm = 12;

  /// Medium radius
  final double md = 16;

  /// Large radius for cards
  final double lg = 20; // cards
  /// Extra large radius for search field
  final double xl = 28; // search field
  /// Extra extra large radius for bottom nav capsule
  final double xxl = 32; // bottom nav capsule
  /// Full radius
  final double full = 999;
}

/// Simple spacing system based on 8dp grid
class DesignSpace {
  /// Extra extra small spacing (4dp)
  final double xxs = 4;

  /// Extra small spacing (8dp)
  final double xs = 8;

  /// Small spacing (12dp)
  final double sm = 12;

  /// Medium spacing (16dp)
  final double md = 16;

  /// Large spacing (20dp)
  final double lg = 20;

  /// Extra large spacing (24dp)
  final double xl = 24;

  /// Extra extra large spacing (32dp)
  final double xxl = 32;
}

/// Simple typography system
class DesignText {
  /// Headline styles
  /// Large headline text style
  TextStyle get headline1 =>
      const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2);

  /// Medium headline text style
  TextStyle get headline2 =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3);

  /// Small headline text style
  TextStyle get headline3 =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);

  /// Extra small headline text style
  TextStyle get headlineSmall =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  /// Medium display text style
  TextStyle get displayMedium =>
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.3);

  /// Title styles
  /// Default title text style
  TextStyle get title =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3);

  /// Large title text style
  TextStyle get titleLarge =>
      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2);

  /// Medium title text style
  TextStyle get titleMedium =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  /// Small title text style
  TextStyle get titleSmall =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  /// Body styles
  /// Default body text style
  TextStyle get body =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);

  /// Large body text style
  TextStyle get bodyLarge =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5);

  /// Medium body text style
  TextStyle get bodyMedium =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.5);

  /// Small body text style
  TextStyle get bodySmall =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.5);

  /// Muted body text style
  TextStyle get bodyMuted =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);

  /// Label styles
  /// Default label text style
  TextStyle get label =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);

  /// Large label text style
  TextStyle get labelLarge =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  /// Medium label text style
  TextStyle get labelMedium =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4);

  /// Small label text style
  TextStyle get labelSmall =>
      const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.4);

  /// Button text style
  /// Default button text style
  TextStyle get button =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  /// Caption text style
  TextStyle get caption =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5);
}

/// Simple elevation system
class DesignElev {
  /// No elevation
  final List<BoxShadow> none = [];

  /// Extra small elevation
  final List<BoxShadow> xs = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Small elevation
  final List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium elevation
  final List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Large elevation
  final List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Card shadow
  List<BoxShadow> get card => md;
}

/// Design animations system for consistent motion
class DesignAnimations {
  /// Fast animation duration
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal animation duration
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow animation duration
  static const Duration slow = Duration(milliseconds: 500);

  /// Very slow animation duration
  static const Duration verySlow = Duration(milliseconds: 800);

  /// Standard easing curve
  static const Curve standard = Curves.easeInOut;

  /// Bounce easing curve
  static const Curve bounce = Curves.bounceOut;

  /// Elastic easing curve
  static const Curve elastic = Curves.elasticOut;

  /// Fast out slow in curve
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}

/// Design breakpoints for responsive design
class DesignBreakpoints {
  /// Mobile breakpoint
  static const double mobile = 480;

  /// Tablet breakpoint
  static const double tablet = 768;

  /// Desktop breakpoint
  static const double desktop = 1024;

  /// Large desktop breakpoint
  static const double largeDesktop = 1440;
}
