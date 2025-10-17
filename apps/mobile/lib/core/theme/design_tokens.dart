import 'package:flutter/material.dart';

/// Unified Design Tokens - Consolidated theme system
class DT {
  DT._();
  static _Colors get c => _Colors();
  static _Radii get r => _Radii();
  static _Space get s => _Space();
  static _Text get t => _Text();
  static _Elev get e => _Elev();
}

class _Colors {
  // Brand / Primary Colors
  final Color brand = const Color(0xFF4464B4); // active
  final Color brandDeep = const Color(0xFF446CBC); // search fill
  final Color primaryColor = const Color(0xFF6366F1); // Indigo (legacy)
  final Color primaryDark = const Color(0xFF4F46E5);
  final Color primaryLight = const Color(0xFF818CF8);

  // Accent Colors
  final Color accentRed = const Color(0xFFEF4444); // For Lost items
  final Color accentGreen = const Color(0xFF10B981); // For Found items
  final Color accentOrange = const Color(0xFFF59E0B); // For warnings/pending

  // Neutrals
  final Color surface = const Color(0xFFF4F4F4);
  final Color card = Colors.white;
  final Color border = const Color(0xFFE8ECF2);
  final Color divider = const Color(0xFFEDEFF3);
  final Color background = const Color(0xFFFAFAFA);

  // Text
  final Color text = const Color(0xFF121723);
  final Color textMuted = const Color(0xFF5A606B);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color textTertiary = const Color(0xFF9CA3AF);

  // States
  final Color successBg = const Color(0xFFE7F9E7);
  final Color successFg = const Color(0xFF2E7D32);
  final Color dangerBg = const Color(0xFFFBE7E7);
  final Color dangerFg = const Color(0xFFD32F2F);
  final Color success = const Color(0xFF10B981);
  final Color error = const Color(0xFFEF4444);
  final Color warning = const Color(0xFFF59E0B);
  final Color info = const Color(0xFF3B82F6);

  // Accents
  final Color blueTint = const Color(0xFFE8EEF9);
  final Color shadow = const Color(0x1A000000); // 10% black
  final Color badge = const Color(0xFFFF3B30);
}

class _Radii {
  final double xs = 8;
  final double sm = 12;
  final double md = 16;
  final double lg = 20; // cards
  final double xl = 28; // search field
  final double xxl = 32; // bottom nav capsule
  final double full = 999.0;
}

class _Space {
  final double xxs = 4;
  final double xs = 8;
  final double sm = 12;
  final double md = 16;
  final double lg = 20;
  final double xl = 24;
  final double xxl = 32;
}

class _Text {
  TextStyle get h1 => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  TextStyle get headline1 => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937),
    height: 1.2,
  );
  TextStyle get headline2 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937),
    height: 1.3,
  );
  TextStyle get headline3 => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F2937),
    height: 1.4,
  );
  TextStyle get title => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  TextStyle get body => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1F2937),
    height: 1.5,
  );
  TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DT.c.textSecondary,
    height: 1.5,
  );
  TextStyle get bodyMuted => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: DT.c.textMuted,
    height: 1.4,
  );
  TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: DT.c.textTertiary,
    height: 1.5,
  );
  TextStyle get label => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  TextStyle get button => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: DT.c.textSecondary,
  );
}

class _Elev {
  final List<BoxShadow> card = [
    BoxShadow(color: DT.c.shadow, blurRadius: 12, offset: const Offset(0, 6)),
  ];
  final List<BoxShadow> bar = [
    BoxShadow(color: DT.c.shadow, blurRadius: 18, offset: const Offset(0, -2)),
  ];
}
