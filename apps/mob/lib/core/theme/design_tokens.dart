import 'package:flutter/material.dart';

/// DesignTokens: one place for colors, spacing, radii, type, elevation.
class DT {
  DT._();

  static DTColors get c => DTColors();
  static DTSpacing get s => DTSpacing();
  static DTRadii get r => DTRadii();
  static DTType get t => DTType();
  static DTElevation get e => DTElevation();

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

  // ✅ Added to fix "getter isn't defined" errors
  final Color success = const Color(0xFF2E7D32);
  final Color successBg = const Color(0xFFE7F9E7);
  final Color danger = const Color(0xFFD32F2F);
  final Color dangerBg = const Color(0xFFFBE7E7);
}

class DTSpacing {
  final double xs = 6, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32;
}

class DTRadii {
  final double sm = 8, md = 12, lg = 16, xl = 20;
}

class DTType {
  final TextStyle h1 =
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w800);
  final TextStyle title =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  final TextStyle body =
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  final TextStyle label = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: .2,
  );
}

class DTElevation {
  final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05), // no deprecated withOpacity
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
