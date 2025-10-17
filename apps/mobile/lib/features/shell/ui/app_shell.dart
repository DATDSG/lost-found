import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../home/ui/home_page.dart';
import '../../report/ui/report_page.dart';
import '../../matches/ui/matches_page.dart';
import '../../profile/ui/profile_page.dart';
import '../../chat/ui/chat_page.dart';
import '../../notifications/ui/notifications_page.dart';
import '../../../widgets/app_shell_app_bar.dart';
import '../../../widgets/app_shell_bottom_nav.dart';
import '../../../widgets/language_selector.dart';
import '../../../widgets/localized_text.dart';

/// Enhanced app shell with improved UI components
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _currentLanguage = 'en';
  bool _isPageTransitioning = false;

  late AnimationController _pageAnimationController;
  late Animation<double> _pageAnimation;

  final List<Widget> _pages = [
    const HomePage(),
    const ReportPage(),
    const MatchesPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    // Page transition animation
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index != _currentIndex && !_isPageTransitioning) {
      setState(() {
        _currentIndex = index;
        _isPageTransitioning = true;
      });

      // Haptic feedback for tab change
      HapticFeedback.lightImpact();

      // Page transition animation
      _pageAnimationController.reset();
      _pageAnimationController.forward().then((_) {
        if (mounted) {
          setState(() {
            _isPageTransitioning = false;
          });
        }
      });
    }
  }

  void updateLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });

    // Haptic feedback for language change
    HapticFeedback.lightImpact();
  }

  void cycleLanguage() {
    final currentIndex = AppLanguage.getLanguageIndex(_currentLanguage);
    final nextIndex =
        (currentIndex + 1) % AppLanguage.supportedLanguages.length;
    final nextLanguage = AppLanguage.supportedLanguages[nextIndex];

    setState(() {
      _currentLanguage = nextLanguage.code;
    });

    // Haptic feedback for language cycle
    HapticFeedback.lightImpact();
  }

  void _onChatTap() {
    // Haptic feedback for chat tap
    HapticFeedback.lightImpact();
    // Show chat page in modal
    _showChatModal();
  }

  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: DT.c.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(DT.r.xl)),
            boxShadow: [
              BoxShadow(
                color: DT.c.shadow.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: DT.s.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DT.c.divider,
                  borderRadius: BorderRadius.circular(DT.r.sm),
                ),
              ),

              // Chat page content
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DT.r.xl),
                  ),
                  child: const ChatPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNotificationTap() {
    // Haptic feedback for notification tap
    HapticFeedback.lightImpact();
    // Navigate to notifications or show notification sheet
    _showNotificationSheet();
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(DT.r.lg)),
            boxShadow: [
              BoxShadow(
                color: DT.c.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced handle bar
              Container(
                margin: EdgeInsets.only(top: DT.s.sm),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: DT.c.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Notifications page content
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(DT.r.lg),
                  ),
                  child: const NotificationsPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedNotificationItem(int index) {
    final notifications = [
      AppLocalizations.getText('new_match_found', _currentLanguage),
      AppLocalizations.getText('someone_found_keys', _currentLanguage),
      AppLocalizations.getText('message_from_john', _currentLanguage),
    ];

    final icons = [
      Icons.search_rounded,
      Icons.vpn_key_rounded,
      Icons.message_rounded,
    ];

    final colors = [
      DT.c.successBg,
      DT.c.brand.withValues(alpha: 0.1),
      DT.c.brand.withValues(alpha: 0.1),
    ];

    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Handle notification tap
          },
          borderRadius: BorderRadius.circular(DT.r.md),
          child: Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(
                color: DT.c.brand.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: DT.c.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: DT.c.brand,
                    borderRadius: BorderRadius.circular(DT.r.sm),
                    boxShadow: [
                      BoxShadow(
                        color: DT.c.brand.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icons[index], color: Colors.white, size: 24),
                ),

                SizedBox(width: DT.s.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notifications[index],
                        style: DT.t.body.copyWith(
                          color: DT.c.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: DT.s.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: DT.c.textMuted,
                          ),
                          SizedBox(width: DT.s.xs),
                          LocalizedText(
                            'minutes_ago',
                            language: _currentLanguage,
                            style: DT.t.label.copyWith(color: DT.c.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                Container(
                  padding: EdgeInsets.all(DT.s.xs),
                  decoration: BoxDecoration(
                    color: DT.c.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DT.r.sm),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: DT.c.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,

      // Enhanced App Bar
      appBar: AppShellAppBar(
        onChatTap: _onChatTap,
        onNotificationTap: _onNotificationTap,
        onLanguageTap: cycleLanguage,
        onLanguageChanged: updateLanguage,
        currentLanguage: _currentLanguage,
      ),

      // Page Content with Enhanced Animation
      body: AnimatedBuilder(
        animation: _pageAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(_pageAnimation),
            child: FadeTransition(
              opacity: _pageAnimation,
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          );
        },
      ),

      // Enhanced Bottom Navigation
      bottomNavigationBar: AppShellBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
