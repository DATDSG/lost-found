import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class AppTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onChat;
  final VoidCallback onNotifications;
  final VoidCallback onCycleLanguage;
  final String languageLabel;
  final String logoAsset;

  /// Optional: provide unread count for badge
  final int? notificationsCount;

  const AppTopAppBar({
    super.key,
    required this.onChat,
    required this.onNotifications,
    required this.onCycleLanguage,
    required this.languageLabel,
    required this.logoAsset,
    this.notificationsCount,
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
            errorBuilder: (_, __, ___) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 28, width: 28,
                  decoration: BoxDecoration(color: DT.c.brand, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.search, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 6),
                Text('LOST  FINDER', style: DT.t.body.copyWith(fontWeight: FontWeight.w800, color: DT.c.text)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_rounded),
          color: DT.c.brand,
          tooltip: 'Chat',
          onPressed: onChat,
        ),
        if ((notificationsCount ?? 0) > 0)
          Badge.count(
            count: notificationsCount!,
            backgroundColor: DT.c.badge,
            alignment: AlignmentDirectional.topEnd,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              color: DT.c.brand,
              tooltip: 'Notifications',
              onPressed: onNotifications,
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: DT.c.brand,
            tooltip: 'Notifications',
            onPressed: onNotifications,
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: OutlinedButton(
            onPressed: onCycleLanguage,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(color: DT.c.brand, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
