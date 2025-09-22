import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/shell/ui/app_shell.dart';

/// Thin bootstrap root:
/// - sets system UI (status/nav bars)
/// - shows a tiny splash if you add async startup later
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
    // System UI polish
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    // TODO: add any other lightweight startup here (preload, log, etc.)
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return const AppShell(); // uses EasyLocalization via main.dart's MaterialApp
  }
}
