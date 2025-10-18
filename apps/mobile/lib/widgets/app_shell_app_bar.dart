import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/chat_provider.dart';
import 'app_logo.dart';
import 'language_selector.dart';

/// Custom app bar for the main app shell
class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onChatTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLanguageTap;
  final Function(String)? onLanguageChanged;
  final String currentLanguage;

  const AppShellAppBar({
    super.key,
    this.onChatTap,
    this.onNotificationTap,
    this.onLanguageTap,
    this.onLanguageChanged,
    this.currentLanguage = 'en',
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: DT.c.divider.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.md, DT.s.lg, DT.s.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white.withValues(alpha: 0.98)],
            ),
          ),
          child: Row(
            children: [
              // Logo Section with enhanced visibility
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DT.s.sm,
                    vertical: DT.s.xs,
                  ),
                  decoration: BoxDecoration(
                    color: DT.c.brand.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DT.r.sm),
                    border: Border.all(
                      color: DT.c.brand.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: AppLogoPresets.appBarLogo(),
                ),
              ),

              SizedBox(width: DT.s.md),

              // Action Buttons Section with enhanced visibility
              Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return Row(
                    children: [
                      // Chat Button
                      _EnhancedActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: onChatTap,
                        backgroundColor: DT.c.brand,
                        iconColor: Colors.white,
                        tooltip: 'Chat',
                        isPrimary: true,
                        badgeCount: chatProvider.totalUnreadCount > 0
                            ? chatProvider.totalUnreadCount
                            : null,
                      ),

                      SizedBox(width: DT.s.sm),

                      // Notifications Button
                      _EnhancedNotificationButton(
                        icon: Icons.notifications_outlined,
                        badgeCount: chatProvider.notificationCount > 0
                            ? chatProvider.notificationCount
                            : null,
                        onTap: onNotificationTap,
                      ),

                      SizedBox(width: DT.s.sm),

                      // Language Switcher
                      _EnhancedLanguageButton(
                        currentLanguage: currentLanguage,
                        onTap: onLanguageTap,
                        onLanguageChanged: onLanguageChanged,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced action button with better visibility
class _EnhancedActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final String? tooltip;
  final bool isPrimary;
  final int? badgeCount;

  const _EnhancedActionButton({
    required this.icon,
    this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.tooltip,
    this.isPrimary = false,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DT.r.md),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(
                color: backgroundColor.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: isPrimary ? 22 : 20,
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: DT.c.dangerFg,
                        borderRadius: BorderRadius.circular(DT.r.sm),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        style: DT.t.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced notification button with better visibility
class _EnhancedNotificationButton extends StatelessWidget {
  final IconData icon;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _EnhancedNotificationButton({
    required this.icon,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DT.r.md),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(
                color: DT.c.divider.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DT.c.shadow.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, color: DT.c.textMuted, size: 20)),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color: DT.c.badge,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced language button with better visibility
class _EnhancedLanguageButton extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback? onTap;
  final Function(String)? onLanguageChanged;

  const _EnhancedLanguageButton({
    required this.currentLanguage,
    this.onTap,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languageOption = AppLanguage.getLanguageByCode(currentLanguage);

    return Tooltip(
      message: 'Language: ${languageOption.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DT.r.md),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(
                color: DT.c.brand.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DT.c.brand.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    languageOption.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    languageOption.shortName,
                    style: DT.t.label.copyWith(
                      color: DT.c.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
