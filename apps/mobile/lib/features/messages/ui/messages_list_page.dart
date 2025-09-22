import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'chat_thread_page.dart';
import '../data/chat_models.dart';

class MessagesListPage extends StatefulWidget {
  const MessagesListPage({super.key});
  @override
  State<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends State<MessagesListPage> {
  final List<ChatThread> _threads = List<ChatThread>.from(_demoThreads);
  final Set<String> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  void _toggleSelect(String id) {
    setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _threads.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_threads.map((t) => t.id));
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      _threads.removeWhere((t) => _selected.contains(t.id));
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(_selectionMode ? Icons.close_rounded : Icons.arrow_back_rounded),
          onPressed: () => _selectionMode ? setState(_selected.clear) : Navigator.pop(context),
        ),
        title: Text(
          _selectionMode ? '${_selected.length} selected' : 'Messages',
          style: DT.t.h1.copyWith(fontSize: 22),
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  tooltip: 'Select all',
                  icon: const Icon(Icons.select_all_rounded),
                  onPressed: _selectAll,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _deleteSelected,
                ),
              ]
            : [],
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.md, DT.s.lg, DT.s.xxl),
        itemBuilder: (context, i) {
          final m = _threads[i];
          final selected = _selected.contains(m.id);
          final cardColor = i == 0 ? DT.c.blueTint.withOpacity(0.35) : Colors.white;

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onLongPress: () => _toggleSelect(m.id),
            onTap: () {
              if (_selectionMode) {
                _toggleSelect(m.id);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatThreadPage(thread: m)),
              );
            },
            child: Container(
              padding: EdgeInsets.all(DT.s.lg),
              decoration: BoxDecoration(
                color: selected ? DT.c.blueTint.withOpacity(0.6) : cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: i == 0 ? null : DT.e.card,
                border: selected
                    ? Border.all(color: DT.c.brand, width: 1.2)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFE6EAF2),
                        // In offline testing, show a placeholder color
                        child: Text(m.name.characters.first,
                            style: DT.t.title.copyWith(color: DT.c.brand)),
                      ),
                      // presence dot
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: m.online ? const Color(0xFF2E7D32) : const Color(0xFF9AA4B2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: DT.s.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + date + unread
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                m.name,
                                style: DT.t.title.copyWith(color: DT.c.brand, fontSize: 18),
                              ),
                            ),
                            if (m.unread > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DT.c.brand,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${m.unread}',
                                    style: DT.t.label.copyWith(color: Colors.white)),
                              ),
                            const SizedBox(width: 8),
                            Text(_formatDate(m.date), style: DT.t.bodyMuted),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(m.preview1, style: DT.t.body),
                        Text(m.preview2, style: DT.t.body),
                        if (!m.online && m.lastSeen != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Last seen ${_ago(m.lastSeen!)}',
                                style: DT.t.label.copyWith(color: DT.c.textMuted)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: DT.s.lg),
        itemCount: _threads.length,
      ),
    );
  }
}

String _formatDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '$mm/$dd/$yy';
}

String _ago(DateTime t) {
  final s = DateTime.now().difference(t).inSeconds;
  if (s < 60) return '${max(1, s)}s ago';
  final m = s ~/ 60;
  if (m < 60) return '${m}m ago';
  final h = m ~/ 60;
  if (h < 24) return '${h}h ago';
  final d = h ~/ 24;
  return '${d}d ago';
}

// ---- Demo data (image URLs removed to avoid network) ----
final _demoThreads = <ChatThread>[
  ChatThread(
    id: '1',
    name: 'Liam Carter',
    avatarUrl: '',
    date: DateTime(2025, 10, 26),
    preview1: 'Hey, I think I found your Iphone!',
    preview2: 'Found: Red Iphone 13',
    online: true,
    unread: 1,
    messages: const [],
  ),
  ChatThread(
    id: '2',
    name: 'Sophia Bennett',
    avatarUrl: '',
    date: DateTime(2025, 10, 25),
    preview1: 'Did you see a blue backpack?',
    preview2: 'Lost: Blue Backpack',
    lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
    messages: const [],
  ),
  ChatThread(
    id: '3',
    name: 'Liam Carter',
    avatarUrl: '',
    date: DateTime(2025, 10, 26),
    preview1: 'Hey, I think I found your wallet!',
    preview2: 'Found: Black Wallet',
    messages: const [],
  ),
  ChatThread(
    id: '4',
    name: 'Olivia Reed',
    avatarUrl: '',
    date: DateTime(2025, 10, 23),
    preview1: 'Have you seen a red scarf?',
    preview2: 'Lost: Red Scarf',
    messages: const [],
  ),
];
