import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/ui/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LostFinderApp());
}

class LostFinderApp extends StatelessWidget {
  const LostFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lost Finder',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
