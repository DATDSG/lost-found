import 'package:flutter/material.dart';

/// DesignTokens: one place for colors, spacing, radii, type, elevation, gradients.
class DT {
  DT._();

  // Palettes / scales
  static DTColors get c => DTColors();
  static DTSpacing get s => DTSpacing();
  static DTRadii get r => DTRadii();
  static DTType get t => DTType();
  static DTElevation get e => DTElevation();
  static DTGradients get g => DTGradients();

  // Common physics
  static ScrollPhysics get scroll =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class DTColors {
  // Brand / base
  final Color brand = const Color(0xFF0F3E5A);
  final Color brandDeep = const Color(0xFFE9F3FF);
  final Color surface = const Color(0xFFF8FAFD);
  final Color card = Colors.white;

  final Color text = const Color(0xFF1F2430);
  final Color textMuted = const Color(0xFF7C8797);

  final Color badge = const Color(0xFFE53935);
  final Color blueTint = const Color(0xFFDCEBFF);

  // States
  final Color success = const Color(0xFF2E7D32);
  final Color successBg = const Color(0xFFE7F9E7);

  final Color danger = const Color(0xFFD32F2F);
  final Color dangerBg = const Color(0xFFFBE7E7);

  final Color warning = const Color(0xFFF59E0B);
  final Color warningBg = const Color(0xFFFFF4CC);

  final Color info = const Color(0xFF2563EB);
  final Color infoBg = const Color(0xFFE8F0FF);

  // Helpers
  Color muted([double a = .55]) => textMuted.withValues(alpha: a);
  Color overlay([double a = .04]) => Colors.black.withValues(alpha: a);
}

class DTSpacing {
  final double xs = 6, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
}

class DTRadii {
  final double sm = 8, md = 12, lg = 16, xl = 20, xxl = 28;
}

class DTType {
  final TextStyle h1 = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
  final TextStyle h2 = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  final TextStyle h3 = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  final TextStyle title = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  final TextStyle body = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  final TextStyle caption = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  final TextStyle label = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: .2,
  );

  TextStyle get display =>
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w800);
}

class DTElevation {
  final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 6),
    ),
  ];
}

class DTGradients {
  /// Primary brand gradient (left ➜ right) used by primary buttons.
  final Gradient primary = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5F7BE6), Color(0xFF0D2C6A)],
  );

  /// Light chip background fade.
  final Gradient chip = const LinearGradient(
    colors: [Color(0xFFE9F3FF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
