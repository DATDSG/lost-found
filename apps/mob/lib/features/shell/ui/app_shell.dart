import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/notify/notification_service.dart';
import '../../../shared/widgets/app_top_app_bar.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../home/ui/home_page.dart';
import '../../report/ui/report_page.dart';
import '../../matches/ui/matches_page.dart';
import '../../profile/ui/profile_page.dart';
import '../../messages/ui/messages_list_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  String get _langLabel {
    switch (context.locale.languageCode) {
      case 'si': return 'SI';
      case 'ta': return 'TA';
      default: return 'EN';
    }
  }

  Future<void> _cycleLang() async {
    const order = [Locale('en'), Locale('si'), Locale('ta')];
    final i = order.indexWhere((l) => l.languageCode == context.locale.languageCode);
    final next = order[(i + 1) % order.length];
    await context.setLocale(next);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [HomePage(), ReportPage(), MatchesPage(), ProfilePage()];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: StreamBuilder<int>(
          stream: NotificationService.I.badgeStream,
          initialData: NotificationService.I.badgeCount,
          builder: (context, snap) {
            return AppTopAppBar(
              logoAsset: 'assets/images/App Logo.png', // ensure asset is in pubspec
              onChat: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesListPage()));
              },
              onNotifications: () async {
                // demo: fire an instant notification + in-app banner
                await NotificationService.I.instant('Lost & Finder', 'You have a new match!');
                // Also show in-app snack for immediate feedback
                NotificationService.I.inAppBanner(context, 'Notification sent', 'Check your tray.');
              },
              onCycleLanguage: _cycleLang,
              languageLabel: _langLabel,
              notificationsCount: snap.data ?? 0,
            );
          },
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}
