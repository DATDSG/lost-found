import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/notifications_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/notification.dart';
import '../../../core/routing/app_routes.dart';

/// Notifications page for system and chat notifications
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();

    // Initialize notifications provider to load notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final notificationsProvider = Provider.of<NotificationsProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only load data if user is authenticated
    if (authProvider.isAuthenticated) {
      await Future.wait([
        notificationsProvider.loadNotifications(),
        notificationsProvider.loadStats(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.background,
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: DT.c.surface,
        foregroundColor: DT.c.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, notificationsProvider, _) {
          if (notificationsProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: DT.c.brand));
          }

          if (notificationsProvider.error != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(DT.s.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: DT.c.dangerFg,
                    ),
                    SizedBox(height: DT.s.md),
                    Text(
                      'Failed to load notifications',
                      style: DT.t.title.copyWith(color: DT.c.dangerFg),
                    ),
                    SizedBox(height: DT.s.sm),
                    Text(
                      notificationsProvider.error!,
                      style: DT.t.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DT.s.lg),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (notificationsProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => notificationsProvider.refresh(),
            color: DT.c.brand,
            child: ListView.builder(
              padding: EdgeInsets.all(DT.s.lg),
              itemCount: notificationsProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationsProvider.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(
                    notification,
                    notificationsProvider,
                  ),
                  onMarkAsRead: () =>
                      notificationsProvider.markAsRead(notification.id),
                  onDelete: () =>
                      notificationsProvider.deleteNotification(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(DT.s.lg),
        padding: EdgeInsets.all(DT.s.xl),
        decoration: BoxDecoration(
          color: DT.c.surface,
          borderRadius: BorderRadius.circular(DT.r.lg),
          boxShadow: DT.e.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: DT.c.textTertiary,
            ),
            SizedBox(height: DT.s.md),
            Text(
              'No notifications',
              style: DT.t.title.copyWith(color: DT.c.textSecondary),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              'You\'ll see notifications for new messages, matches, and system updates here',
              style: DT.t.body.copyWith(color: DT.c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead() {
    final notificationsProvider = context.read<NotificationsProvider>();
    notificationsProvider.markAllAsRead();
  }

  void _handleNotificationTap(
    AppNotification notification,
    NotificationsProvider notificationsProvider,
  ) {
    // Mark as read if not already read
    if (!notification.isRead) {
      notificationsProvider.markAsRead(notification.id);
    }

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat conversation
        if (notification.referenceId != null &&
            notification.referenceId!.isNotEmpty) {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.chat, arguments: notification.referenceId);
        }
        break;
      case NotificationType.match:
        // Navigate to matches page
        Navigator.of(context).pushNamed(AppRoutes.matches);
        break;
      case NotificationType.report:
        // Navigate to report details
        if (notification.referenceId != null &&
            notification.referenceId!.isNotEmpty) {
          Navigator.of(context).pushNamed(
            AppRoutes.viewDetails,
            arguments: {
              'reportId': notification.referenceId,
              'reportType': 'unknown',
              'reportData': null,
            },
          );
        }
        break;
      case NotificationType.system:
        // Show system notification details
        _showSystemNotificationDialog(notification);
        break;
    }
  }

  void _showSystemNotificationDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Enhanced notification card widget
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      decoration: BoxDecoration(
        color: notification.isRead
            ? DT.c.card
            : DT.c.brand.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DT.r.lg),
        border: Border.all(
          color: notification.isRead
              ? DT.c.border.withValues(alpha: 0.3)
              : DT.c.brand.withValues(alpha: 0.3),
        ),
        boxShadow: DT.e.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DT.r.lg),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(DT.s.md),
            child: Row(
              children: [
                // Notification icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DT.r.lg),
                  ),
                  child: Icon(
                    notification.typeIcon,
                    color: notification.typeColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: DT.s.md),

                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: DT.t.title.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: DT.c.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: DT.c.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: DT.s.xs),
                      Text(
                        notification.content,
                        style: DT.t.body.copyWith(color: DT.c.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: DT.s.xs),
                      Row(
                        children: [
                          Text(
                            notification.timeAgo,
                            style: DT.t.caption.copyWith(
                              color: DT.c.textTertiary,
                            ),
                          ),
                          SizedBox(width: DT.s.sm),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DT.s.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notification.typeColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(DT.r.sm),
                            ),
                            child: Text(
                              notification.typeLabel,
                              style: DT.t.caption.copyWith(
                                color: notification.typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (notification.priority ==
                                  NotificationPriority.high ||
                              notification.priority ==
                                  NotificationPriority.urgent)
                            Container(
                              margin: EdgeInsets.only(left: DT.s.xs),
                              padding: EdgeInsets.symmetric(
                                horizontal: DT.s.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: notification.priorityColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(DT.r.sm),
                              ),
                              child: Text(
                                notification.priorityLabel,
                                style: DT.t.caption.copyWith(
                                  color: notification.priorityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                if (!notification.isRead)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onMarkAsRead,
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          color: DT.c.textTertiary,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: DT.c.dangerFg,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
