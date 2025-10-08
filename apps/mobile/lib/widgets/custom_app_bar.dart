import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/chat_provider.dart';
import '../config/routes.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localeState = ref.watch(localeProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final chatState = ref.watch(chatProvider);

    final unreadNotifications = notificationsState.unreadCount;
    final unreadMessages = chatState.unreadCount;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  'LOST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'FINDER',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        // Chat icon with badge
        _buildIconWithBadge(
          context: context,
          icon: Icons.chat_bubble_outline,
          badgeCount: unreadMessages,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.chat);
          },
          theme: theme,
        ),

        // Notification icon with badge
        _buildIconWithBadge(
          context: context,
          icon: Icons.notifications_outlined,
          badgeCount: unreadNotifications,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          theme: theme,
        ),

        // Language changer
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => _showLanguageDialog(context, ref),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localeState.language.shortName,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildIconWithBadge({
    required BuildContext context,
    required IconData icon,
    required int badgeCount,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          onPressed: onPressed,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(localeProvider).language;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SupportedLanguage.values.map((language) {
            final isSelected = language == currentLanguage;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(language.name),
              onTap: () {
                ref.read(localeProvider.notifier).changeLanguage(language);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
