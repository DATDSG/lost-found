import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'data/chat_models.dart';
import 'chat_thread_page.dart';

class MessagesListPage extends StatefulWidget {
  const MessagesListPage({super.key});

  @override
  State<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends State<MessagesListPage> {
  late List<ChatThread> _threads;
  ChatThread? _lastRemoved;
  int? _lastRemovedIndex;

  @override
  void initState() {
    super.initState();
    _threads = List<ChatThread>.from(_seedThreads);
  }

  void _undoDelete() {
    if (_lastRemoved != null && _lastRemovedIndex != null) {
      setState(() => _threads.insert(_lastRemovedIndex!, _lastRemoved!));
      _lastRemoved = null;
      _lastRemovedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages', style: DT.t.h1.copyWith(fontSize: 20))),
      body: ListView.separated(
        physics: DT.scroll,
        itemCount: _threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = _threads[i];
          final last = t.messages.isNotEmpty ? t.messages.last : null;

          return Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (_) {
              _lastRemoved = t;
              _lastRemovedIndex = i;
              setState(() => _threads.removeAt(i));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${t.name}"'),
                  action: SnackBarAction(label: 'UNDO', onPressed: _undoDelete),
                ),
              );
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: DT.c.blueTint,
                child: Text(t.name.characters.first),
              ),
              title: Text(t.name, style: DT.t.title),
              subtitle: Text(
                last?.text ?? (last?.kind.name ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: DT.c.textMuted),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadPage(thread: t))),
            ),
          );
        },
      ),
    );
  }
}

final _seedThreads = <ChatThread>[
  ChatThread(
    id: 't1',
    name: 'Liam',
    online: true,
    messages: [
      ChatMessage(id: 'm1', sender: 'Liam', avatarUrl: '', isMe: false, kind: MessageKind.text, text: 'Is this your backpack?'),
      ChatMessage(id: 'm2', sender: 'You', avatarUrl: '', isMe: true, kind: MessageKind.text, text: 'Looks similar!'),
    ],
  ),
  ChatThread(
    id: 't2',
    name: 'Sophia',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 12)),
    messages: [
      ChatMessage(id: 'm3', sender: 'Sophia', avatarUrl: '', isMe: false, kind: MessageKind.text, text: 'I found a wallet near Fort'),
    ],
  ),
];
