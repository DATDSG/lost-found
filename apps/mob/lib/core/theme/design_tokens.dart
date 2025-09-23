import 'package:flutter/material.dart';

/// DesignTokens: one place for your colors, spacing, radii, type, elevation.
class DT {
  DT._();

  // Colors
  static _C get c => _C();
  // Spacing (dp)
  static _S get s => _S();
  // Radii (dp)
  static _R get r => _R();
  // Type
  static _T get t => _T();
  // Elevations
  static _E get e => _E();

  // Common physics
  static ScrollPhysics get scroll => const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
}

class _C {
  final Color brand = const Color(0xFF0F3E5A);
  final Color brandDeep = const Color(0xFFE9F3FF);
  final Color surface = const Color(0xFFF8FAFD);
  final Color card = Colors.white;
  final Color text = const Color(0xFF1F2430);
  final Color textMuted = const Color(0xFF7C8797);
  final Color badge = const Color(0xFFE53935);
  final Color blueTint = const Color(0xFFDCEBFF);

  // ✅ new – for Found/Lost pills
  final Color success = const Color(0xFF2E7D32);
  final Color successBg = const Color(0xFFE7F9E7);
  final Color danger = const Color(0xFFD32F2F);
  final Color dangerBg = const Color(0xFFFBE7E7);
}

class _S {
  final double xs = 6;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 24;
  final double xxl = 32;
}

class _R {
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 20;
}

class _T {
  final TextStyle h1 = const TextStyle(fontSize: 20, fontWeight: FontWeight.w800);
  final TextStyle title = const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  final TextStyle body = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  final TextStyle label = const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .2);
}

class _E {
  final List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 8),
    )
  ];
}
