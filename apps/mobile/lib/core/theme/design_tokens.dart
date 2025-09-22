import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design Tokens — tuned from the 4 reference images (≤2dp variance).
class DT {
  DT._();
  static _Colors get c => _Colors();
  static _Radii get r => _Radii();
  static _Space get s => _Space();
  static _Text get t => _Text();
  static _Elev get e => _Elev();
  static ScrollPhysics get scroll => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class _Colors {
  // Brand sampled from mocks
  final brand = const Color(0xFF4464B4);
  final brandDeep = const Color(0xFF446CBC); // search bar fill
  // Neutrals
  final surface = const Color(0xFFF4F6F8);
  final card = Colors.white;
  final border = const Color(0xFFE8ECF2);
  final divider = const Color(0xFFEDEFF3);
  // Text
  final text = const Color(0xFF121723);
  final textMuted = const Color(0xFF606771);
  // States
  final successBg = const Color(0xFFE7F9E7);
  final successFg = const Color(0xFF2E7D32);
  final dangerBg = const Color(0xFFFBE7E7);
  final dangerFg = const Color(0xFFD32F2F);
  // Accents
  final blueTint = const Color(0xFFE8EEF9);
  final badge = const Color(0xFFFF3B30);
  final shadow10 = const Color(0x1A000000); // 10% black
  final shadow08 = const Color(0x14000000); // 8% black
}

class _Radii {
  final xs = 8.0;
  final sm = 12.0;
  final md = 16.0;
  final lg = 20.0;   // cards
  final xl = 28.0;   // search field
  final xxl = 32.0;  // bottom nav capsule
  final pill = 999.0;
}

class _Space {
  final xxs = 4.0;
  final xs = 8.0;
  final sm = 12.0;
  final md = 16.0;
  final lg = 20.0;
  final xl = 24.0;
  final xxl = 32.0;
}

class _Text {
  TextStyle get h1 => GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2);
  TextStyle get title => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3);
  TextStyle get body => GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  TextStyle get bodyMuted => GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: DT.c.textMuted, height: 1.4);
  TextStyle get label => GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, height: 1.15);
}

class _Elev {
  final bar = [BoxShadow(color: DT.c.shadow08, blurRadius: 18, offset: const Offset(0, -2))];
  final card = [BoxShadow(color: DT.c.shadow10, blurRadius: 12, offset: const Offset(0, 6))];
}
