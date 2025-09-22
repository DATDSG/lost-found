import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/messages/ui/messages_list_page.dart';
import '../../core/theme/design_tokens.dart';

class AppTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onChat;
  final VoidCallback onNotifications;
  final VoidCallback onCycleLanguage;
  final String languageLabel;
  final String logoAsset;

  const AppTopAppBar({
    super.key,
    required this.onChat,
    required this.onNotifications,
    required this.onCycleLanguage,
    required this.languageLabel,
    required this.logoAsset,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      leadingWidth: 156,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            logoAsset,
            height: 28,
            fit: BoxFit.contain,
            // Safe fallback if the asset is missing
            errorBuilder: (_, __, ___) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: DT.c.brand,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  'LOST  FINDER',
                  style: DT.t.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F3E5A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Chat
        IconButton(
          icon: const Icon(Icons.chat_bubble_rounded),
          color: DT.c.brand,
          tooltip: 'Chat',
          onPressed: () {
            HapticFeedback.selectionClick();
            onChat(); // allow external side-effects/logging
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesListPage()),
            );
          },
        ),

        // Notifications (with badge)
        Badge.count(
          count: 1,
          backgroundColor: DT.c.badge,
          alignment: AlignmentDirectional.topEnd,
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: DT.c.brand,
            tooltip: 'Notifications',
            onPressed: () {
              HapticFeedback.selectionClick();
              onNotifications();
            },
          ),
        ),

        // Language switcher
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onCycleLanguage();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              side: BorderSide(color: DT.c.brand, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: DT.c.brand,
              textStyle: DT.t.body.copyWith(fontWeight: FontWeight.w700),
            ),
            child: Text(languageLabel),
          ),
        ),
      ],
    );
  }
}
