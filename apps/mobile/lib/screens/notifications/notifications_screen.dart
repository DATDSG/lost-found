import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationsState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationsState.isLoading &&
              notificationsState.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notificationsState.error != null
              ? _buildErrorView(notificationsState.error!)
              : _buildNotificationsList(notificationsState.notifications),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).loadNotifications();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationsProvider.notifier).loadNotifications();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return _NotificationTile(notification: notifications[index]);
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.verified;
      case 'message':
        return Icons.chat_bubble;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'match':
        return Colors.green;
      case 'message':
        return Colors.blue;
      case 'update':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _getColorForType(notification.type);

    return ListTile(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationsProvider.notifier).markAsRead(notification.id);
        }
        _navigateToRelatedContent(context, notification);
      },
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getIconForType(notification.type),
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: !notification.isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  void _navigateToRelatedContent(
      BuildContext context, AppNotification notification) {
    switch (notification.type) {
      case 'match':
        // Navigate to match details or item details
        if (notification.itemId != null) {
          Navigator.pushNamed(
            context,
            '/item-details',
            arguments: notification.itemId,
          );
        } else {
          Navigator.pushNamed(context, '/matches');
        }
        break;
      case 'message':
        // Navigate to chat conversation
        if (notification.conversationId != null) {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: notification.conversationId,
          );
        } else {
          Navigator.pushNamed(context, '/chat');
        }
        break;
      case 'update':
        // Navigate to item details or user's items
        if (notification.itemId != null) {
          Navigator.pushNamed(
            context,
            '/item-details',
            arguments: notification.itemId,
          );
        } else {
          Navigator.pushNamed(context, '/my-items');
        }
        break;
      default:
        // Navigate to home or show a generic message
        Navigator.pushNamed(context, '/home');
        break;
    }
  }
}
