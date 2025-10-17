import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/chat_provider.dart';
import '../../../models/chat_models.dart';

/// Chat page with conversations list and individual chat views
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showConversationList = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.background,
      appBar: AppBar(
        title: Text(_showConversationList ? 'Messages' : 'Chat'),
        backgroundColor: DT.c.surface,
        foregroundColor: DT.c.textPrimary,
        elevation: 0,
        leading: !_showConversationList
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _showConversationList = true;
                  });
                  context.read<ChatProvider>().clearCurrentConversation();
                },
                icon: Icon(Icons.arrow_back_rounded),
              )
            : null,
        actions: _showConversationList
            ? [
                IconButton(
                  onPressed: _showNewConversationDialog,
                  icon: Icon(Icons.add_rounded),
                ),
              ]
            : [
                IconButton(
                  onPressed: _showConversationOptions,
                  icon: Icon(Icons.more_vert_rounded),
                ),
              ],
      ),
      body: _showConversationList
          ? _buildConversationsList()
          : _buildChatView(),
    );
  }

  Widget _buildConversationsList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.isAnyLoading) {
          return Center(child: CircularProgressIndicator(color: DT.c.brand));
        }

        if (chatProvider.error != null) {
          return _buildErrorState(chatProvider.error!);
        }

        if (chatProvider.conversations.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Tab bar for conversations and notifications
            Container(
              margin: EdgeInsets.all(DT.s.lg),
              decoration: BoxDecoration(
                color: DT.c.surface,
                borderRadius: BorderRadius.circular(DT.r.lg),
                border: Border.all(color: DT.c.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: DT.c.brand,
                  borderRadius: BorderRadius.circular(DT.r.md),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: DT.c.textSecondary,
                labelStyle: DT.t.label.copyWith(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_rounded, size: 18),
                        SizedBox(width: DT.s.xs),
                        Text('Conversations'),
                        if (chatProvider.hasUnreadMessages) ...[
                          SizedBox(width: DT.s.xs),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DT.s.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DT.c.dangerFg,
                              borderRadius: BorderRadius.circular(DT.r.sm),
                            ),
                            child: Text(
                              '${chatProvider.totalUnreadCount}',
                              style: DT.t.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_rounded, size: 18),
                        SizedBox(width: DT.s.xs),
                        Text('Notifications'),
                        if (chatProvider.hasNotifications) ...[
                          SizedBox(width: DT.s.xs),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DT.s.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DT.c.dangerFg,
                              borderRadius: BorderRadius.circular(DT.r.sm),
                            ),
                            child: Text(
                              '${chatProvider.notificationCount}',
                              style: DT.t.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationsTab(chatProvider),
                  _buildNotificationsTab(chatProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConversationsTab(ChatProvider chatProvider) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
      itemCount: chatProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = chatProvider.conversations[index];
        return _ConversationCard(
          conversation: conversation,
          onTap: () {
            setState(() {
              _showConversationList = false;
            });
            chatProvider.loadMessages(conversation.id);
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab(ChatProvider chatProvider) {
    if (chatProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'You\'ll see notifications for new messages and matches here',
              style: DT.t.body.copyWith(color: DT.c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
      itemCount: chatProvider.notifications.length,
      itemBuilder: (context, index) {
        final notification = chatProvider.notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            chatProvider.markNotificationAsRead(notification.id);
            if (notification.conversationId.isNotEmpty) {
              setState(() {
                _showConversationList = false;
              });
              chatProvider.loadMessages(notification.conversationId);
            }
          },
        );
      },
    );
  }

  Widget _buildChatView() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.isAnyLoading) {
          return Center(child: CircularProgressIndicator(color: DT.c.brand));
        }

        return Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(DT.s.lg),
                itemCount:
                    chatProvider.messages.length +
                    (chatProvider.typingUsers.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatProvider.messages.length) {
                    final message = chatProvider.messages[index];
                    return _MessageBubble(message: message);
                  } else {
                    // Typing indicator
                    return _TypingIndicator(
                      typingUsers: chatProvider.typingUsers,
                    );
                  }
                },
              ),
            ),

            // Message input
            _MessageInput(
              onSendMessage: (content) {
                chatProvider.sendMessage(content);
              },
              onTypingStart: () {
                chatProvider.startTyping();
              },
              onTypingStop: () {
                chatProvider.stopTyping();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(DT.s.lg),
        padding: EdgeInsets.all(DT.s.xl),
        decoration: BoxDecoration(
          color: DT.c.dangerBg,
          borderRadius: BorderRadius.circular(DT.r.lg),
          border: Border.all(color: DT.c.dangerFg.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DT.c.dangerFg, size: 48),
            SizedBox(height: DT.s.md),
            Text(
              'Error loading messages',
              style: DT.t.title.copyWith(color: DT.c.dangerFg),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              error,
              style: DT.t.body.copyWith(color: DT.c.dangerFg),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DT.s.md),
            ElevatedButton(
              onPressed: () {
                context.read<ChatProvider>().initialize();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.c.brand,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
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
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: DT.c.textTertiary,
            ),
            SizedBox(height: DT.s.md),
            Text(
              'No conversations yet',
              style: DT.t.title.copyWith(color: DT.c.textSecondary),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              'Start a conversation with someone who found your lost item or report a found item',
              style: DT.t.body.copyWith(color: DT.c.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DT.s.lg),
            ElevatedButton.icon(
              onPressed: _showNewConversationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.c.brand,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: DT.s.lg,
                  vertical: DT.s.md,
                ),
              ),
              icon: Icon(Icons.add_rounded),
              label: const Text('Start Conversation'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start New Conversation'),
        content: Text(
          'This feature will be available soon. You can start conversations from matches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.archive_rounded),
              title: Text('Archive Conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.block_rounded),
              title: Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded),
              title: Text('Delete Conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Conversation card widget
class _ConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        border: Border.all(
          color: conversation.isUnread
              ? DT.c.brand.withValues(alpha: 0.3)
              : DT.c.border.withValues(alpha: 0.3),
        ),
        boxShadow: DT.e.card,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(DT.s.md),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: DT.c.brand.withValues(alpha: 0.1),
          backgroundImage: conversation.participantAvatar != null
              ? NetworkImage(conversation.participantAvatar!)
              : null,
          child: conversation.participantAvatar == null
              ? Icon(Icons.person_rounded, color: DT.c.brand)
              : null,
        ),
        title: Text(
          conversation.title,
          style: DT.t.title.copyWith(
            fontWeight: conversation.isUnread
                ? FontWeight.w600
                : FontWeight.w500,
            color: conversation.isUnread
                ? DT.c.textPrimary
                : DT.c.textSecondary,
          ),
        ),
        subtitle: conversation.lastMessage != null
            ? Text(
                conversation.lastMessage!.content,
                style: DT.t.body.copyWith(
                  color: conversation.isUnread
                      ? DT.c.textPrimary
                      : DT.c.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageAt != null)
              Text(
                _formatTime(conversation.lastMessageAt!),
                style: DT.t.caption.copyWith(color: DT.c.textTertiary),
              ),
            if (conversation.isUnread && conversation.unreadCount > 0)
              Container(
                margin: EdgeInsets.only(top: DT.s.xs),
                padding: EdgeInsets.symmetric(horizontal: DT.s.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: DT.c.brand,
                  borderRadius: BorderRadius.circular(DT.r.sm),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: DT.t.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Notification card widget
class _NotificationCard extends StatelessWidget {
  final ChatNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

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
      child: ListTile(
        contentPadding: EdgeInsets.all(DT.s.md),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: DT.c.brand.withValues(alpha: 0.1),
          child: Icon(
            _getNotificationIcon(notification.notificationType),
            color: DT.c.brand,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: DT.t.title.copyWith(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
            color: DT.c.textPrimary,
          ),
        ),
        subtitle: Text(
          notification.body,
          style: DT.t.body.copyWith(color: DT.c.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(notification.createdAt),
              style: DT.t.caption.copyWith(color: DT.c.textTertiary),
            ),
            if (!notification.isRead)
              Container(
                margin: EdgeInsets.only(top: DT.s.xs),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: DT.c.brand,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_rounded;
      case NotificationType.match:
        return Icons.verified_user_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      case NotificationType.report:
        return Icons.receipt_long_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe =
        message.senderId ==
        'current_user'; // This should come from auth provider

    return Container(
      margin: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: DT.c.brand.withValues(alpha: 0.1),
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Icon(Icons.person_rounded, color: DT.c.brand, size: 16)
                  : null,
            ),
            SizedBox(width: DT.s.sm),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: DT.s.md,
                vertical: DT.s.sm,
              ),
              decoration: BoxDecoration(
                color: isMe ? DT.c.brand : DT.c.surface,
                borderRadius: BorderRadius.circular(DT.r.lg).copyWith(
                  bottomLeft: isMe
                      ? Radius.circular(DT.r.lg)
                      : Radius.circular(DT.r.xs),
                  bottomRight: isMe
                      ? Radius.circular(DT.r.xs)
                      : Radius.circular(DT.r.lg),
                ),
                border: Border.all(
                  color: isMe
                      ? DT.c.brand.withValues(alpha: 0.3)
                      : DT.c.border.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: DT.t.caption.copyWith(
                        color: DT.c.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    message.content,
                    style: DT.t.body.copyWith(
                      color: isMe ? Colors.white : DT.c.textPrimary,
                    ),
                  ),
                  SizedBox(height: DT.s.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: DT.t.caption.copyWith(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : DT.c.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: DT.s.xs),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: DT.s.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: DT.c.brand.withValues(alpha: 0.1),
              child: Icon(Icons.person_rounded, color: DT.c.brand, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule_rounded;
      case MessageStatus.sent:
        return Icons.check_rounded;
      case MessageStatus.delivered:
        return Icons.done_all_rounded;
      case MessageStatus.read:
        return Icons.done_all_rounded;
      case MessageStatus.failed:
        return Icons.error_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Typing indicator widget
class _TypingIndicator extends StatelessWidget {
  final List<TypingIndicator> typingUsers;

  const _TypingIndicator({required this.typingUsers});

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DT.c.brand.withValues(alpha: 0.1),
            child: Icon(Icons.person_rounded, color: DT.c.brand, size: 16),
          ),
          SizedBox(width: DT.s.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.md,
              vertical: DT.s.sm,
            ),
            decoration: BoxDecoration(
              color: DT.c.surface,
              borderRadius: BorderRadius.circular(
                DT.r.lg,
              ).copyWith(bottomLeft: Radius.circular(DT.r.xs)),
              border: Border.all(color: DT.c.border.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${typingUsers.map((u) => u.userName).join(', ')} typing',
                  style: DT.t.caption.copyWith(
                    color: DT.c.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(width: DT.s.xs),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DT.c.brand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Message input widget
class _MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback onTypingStart;
  final VoidCallback onTypingStop;

  const _MessageInput({
    required this.onSendMessage,
    required this.onTypingStart,
    required this.onTypingStop,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTypingStart();
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      widget.onTypingStop();
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingStop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.card,
        border: Border(
          top: BorderSide(color: DT.c.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DT.c.surface,
                borderRadius: BorderRadius.circular(DT.r.xl),
                border: Border.all(color: DT.c.border.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: DT.t.body.copyWith(color: DT.c.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DT.s.md,
                    vertical: DT.s.sm,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: DT.s.sm),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DT.c.brand,
                borderRadius: BorderRadius.circular(DT.r.xl),
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
