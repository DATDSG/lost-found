import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/widgets/app_top_app_bar.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../home/ui/home_page.dart';
import '../../report/ui/report_page.dart';
import '../../matches/ui/matches_page.dart';
import '../../profile/ui/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  String get _langLabel {
    switch (context.locale.languageCode) {
      case 'si':
        return 'SI';
      case 'ta':
        return 'TA';
      default:
        return 'EN';
    }
  }

  Future<void> _cycleLang() async {
    const order = [Locale('en'), Locale('si'), Locale('ta')];
    final i = order.indexWhere((l) => l.languageCode == context.locale.languageCode);
    final next = order[(i + 1) % order.length];
    await context.setLocale(next);
    if (mounted) setState(() {}); // refresh AppBar label
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [HomePage(), ReportPage(), MatchesPage(), ProfilePage()];

    return Scaffold(
      appBar: AppTopAppBar(
        logoAsset: 'assets/images/App Logo.png', // ensure listed in pubspec
        onChat: () => debugPrint('Chat tapped'),
        onNotifications: () => debugPrint('Notifications tapped'),
        onCycleLanguage: _cycleLang,
        languageLabel: _langLabel,
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
