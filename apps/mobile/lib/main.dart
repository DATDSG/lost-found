import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/app/app_root.dart';
import 'core/theme/app_theme.dart'; // your ThemeData

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      saveLocale: true, // persists last selection
      child: const LostFinderApp(),
    ),
  );
}

class LostFinderApp extends StatelessWidget {
  const LostFinderApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mobile',
      theme: AppTheme.light, // your existing theme
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      home: const AppRoot(), // your app shell / entry page
    );
  }
}
