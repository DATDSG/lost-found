import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/shell/ui/app_shell.dart';
import '../features/auth/ui/landing_page.dart';
import '../core/auth/auth_service.dart';
import '../core/profile/profile_service.dart';

/// Thin bootstrapper (system UI polish, auth gate).
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    await AuthService.I.init();
    await ProfileService.I.init(); // <-- ensure profile is ready for Profile screens
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AuthService.I.isLoggedIn ? const AppShell() : const LandingPage();
  }
}
