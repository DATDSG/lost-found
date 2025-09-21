import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens sampled from the mocks (≤2dp tolerance).
class DT {
  DT._();
  static _Colors get c => _Colors();
  static _Radii get r => _Radii();
  static _Space get s => _Space();
  static _Text get t => _Text();
  static _Elev get e => _Elev();
}

class _Colors {
  // Brand
  final Color brand = const Color(0xFF4464B4); // active
  final Color brandDeep = const Color(0xFF446CBC); // search fill

  // Neutrals
  final Color surface = const Color(0xFFF4F4F4);
  final Color card = Colors.white;
  final Color border = const Color(0xFFE8ECF2);
  final Color divider = const Color(0xFFEDEFF3);

  // Text
  final Color text = const Color(0xFF121723);
  final Color textMuted = const Color(0xFF5A606B);

  // States
  final Color successBg = const Color(0xFFE7F9E7);
  final Color successFg = const Color(0xFF2E7D32);
  final Color dangerBg = const Color(0xFFFBE7E7);
  final Color dangerFg = const Color(0xFFD32F2F);

  // Accents
  final Color blueTint = const Color(0xFFE8EEF9);
  final Color shadow = const Color(0x1A000000); // 10% black
  final Color badge = const Color(0xFFFF3B30);
}

class _Radii {
  final double xs = 8;
  final double sm = 12;
  final double md = 16;
  final double lg = 20;  // cards
  final double xl = 28;  // search field
  final double xxl = 32; // bottom nav capsule
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
  TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
  TextStyle get title => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );
  TextStyle get body => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );
  TextStyle get bodyMuted => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: DT.c.textMuted,
        height: 1.4,
      );
  TextStyle get label => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
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
