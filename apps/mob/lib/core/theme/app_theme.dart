import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: DT.c.brand);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DT.c.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: DT.c.surface,
        elevation: 0,
        foregroundColor: DT.c.text,
        centerTitle: true,
        titleTextStyle: DT.t.h1.copyWith(color: DT.c.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: DT.t.body.copyWith(color: DT.c.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DT.r.md),
          borderSide: BorderSide(color: DT.c.blueTint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DT.r.md),
          borderSide: BorderSide(color: DT.c.blueTint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DT.r.md),
          borderSide: BorderSide(color: DT.c.brand, width: 1.5),
        ),
      ),
    );
  }
}
