import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: DT.c.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DT.c.brand,
        brightness: Brightness.light,
      ),
      textTheme: TextTheme(
        bodyLarge: DT.t.body,
        bodyMedium: DT.t.body,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DT.c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
