import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: DT.c.brand),
      scaffoldBackgroundColor: DT.c.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: DT.c.surface,
        elevation: 0,
        foregroundColor: DT.c.text,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        titleLarge: DT.t.title,
        bodyMedium: DT.t.body,
        labelSmall: DT.t.label,
      ),
    );
  }
  
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: DT.c.brand, brightness: Brightness.dark),
      scaffoldBackgroundColor: DT.c.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: DT.c.surface,
        elevation: 0,
        foregroundColor: DT.c.text,
        centerTitle: true,
      ),
      textTheme: TextTheme(
        titleLarge: DT.t.title,
        bodyMedium: DT.t.body,
        labelSmall: DT.t.label,
      ),
    );
  }
}