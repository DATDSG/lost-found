import 'package:flutter/material.dart';

import '../../../core/api/models/item_dto.dart';
import '../../../core/api/models/match_dto.dart';
import '../../../core/api/services/item_api.dart';
import '../../../core/theme/design_tokens.dart';
import '../../messages/ui/chat_thread_page.dart';
import '../../messages/ui/data/chat_models.dart';
import '../../../core/notify/notification_service.dart';
import 'compare_match_page.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  int _tab = 0; // 0=For Lost, 1=For Found
  bool _loading = false;
  String? _error;
  List<ItemDto> _items = <ItemDto>[];
  final Map<int, List<MatchDto>> _matches = <int, List<MatchDto>>{};

  List<ItemDto> get _lostItems =>
      _items.where((it) => it.status.toLowerCase() == 'lost').toList();
  List<ItemDto> get _foundItems =>
      _items.where((it) => it.status.toLowerCase() == 'found').toList();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ItemApi.I.listItems();
      if (!mounted) return;
      setState(() {
        _items = items;
      });

      for (final item in items) {
        final matches = await ItemApi.I.listMatches(item.id);
        if (!mounted) return;
        setState(() {
          _matches[item.id] = matches;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: DT.scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.md),
              child: Text('Matches', style: DT.t.h1.copyWith(fontSize: 28)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
              child: _PillTabs(
                left: 'For Lost',
                right: 'For Found',
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
          ),
          if (_tab == 0) const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.xl, DT.s.lg, DT.s.md),
              child: Text('My Posts', style: DT.t.title.copyWith(fontSize: 22)),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.md),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DT.c.dangerBg,
                    borderRadius: BorderRadius.circular(DT.r.md),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(DT.s.md),
                    child: Text(
                      'Could not load matches.\n\n$_error',
                      style: DT.t.body.copyWith(color: DT.c.danger),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final items = _tab == 0 ? _lostItems : _foundItems;
                  if (index >= items.length) {
                    return const SizedBox(height: 96);
                  }
                  final item = items[index];
                  final matches = _matches[item.id] ?? const <MatchDto>[];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(DT.s.lg, 0, DT.s.lg, DT.s.xl),
                    child: _MatchCard(
                      baseItem: item,
                      candidates: matches.map((match) {
                        final otherId = match.otherItemIdFor(item.id);
                        final other = _itemById(otherId) ?? ItemDto(
                          id: otherId,
                          title: 'Candidate #$otherId',
                          status: item.status.toLowerCase() == 'lost' ? 'found' : 'lost',
                          createdAt: item.createdAt,
                          description: null,
                          ownerId: null,
                          lat: null,
                          lng: null,
                        );
                        return _MatchCandidate(item: other, match: match);
                      }).toList(),
                      timeAgo: _timeAgo,
                      confidenceLabel: (candidate) => _confidenceLabel(candidate.match.score),
                      scorePercent: (candidate) => _scorePercent(candidate.match.score),
                      onCompare: (candidate) => _openCompareMatch(item, candidate.item, candidate.match),
                      onChat: (candidate) => _startChat(item, candidate.item),
                      onFeedback: (candidate, helpful) => _recordFeedback(item, candidate.item, candidate.match, helpful),
                    ),
                  );
                },
                childCount: (_tab == 0 ? _lostItems : _foundItems).length + 1,
              ),
            ),
        ],
      ),
    );
  }

  ItemDto? _itemById(int id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _openCompareMatch(ItemDto base, ItemDto other, MatchDto match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CompareMatchPage(
          yourImage: _placeholderImageFor(base),
          yourTitle: base.title,
          yourPlace: 'Reported ${_timeAgo(base.createdAt)}',
          theirImage: _placeholderImageFor(other),
          theirTitle: other.title,
          theirPlace: 'Reported ${_timeAgo(other.createdAt)}',
          onStartChat: () {
            Navigator.pop(ctx);
            _startChat(base, other);
          },
        ),
      ),
    );
  }

  void _startChat(ItemDto base, ItemDto other) {
    final thread = ChatThread(
      id: 'match_${base.id}_${other.id}',
      name: other.title,
      online: true,
      messages: [
        ChatMessage(
          id: 'seed',
          sender: other.title,
          avatarUrl: '',
          isMe: false,
          kind: MessageKind.text,
          text: 'Hi! This might match your "${base.title}".',
        ),
      ],
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatThreadPage(thread: thread)),
    );
  }

  void _recordFeedback(ItemDto base, ItemDto other, MatchDto match, bool helpful) {
    final title = helpful ? 'Thanks for the feedback!' : 'Marked as not helpful';
    final body = helpful
        ? 'We will prioritise similar matches for "${base.title}".'
        : 'We will learn from this signal for "${base.title}".';
    NotificationService.I.inAppBanner(context, title, body);
  }

  String _confidenceLabel(double score) {
    final pct = _scorePercent(score);
    if (score >= 0.75) return 'High • $pct';
    if (score >= 0.45) return 'Medium • $pct';
    return 'Low • $pct';
  }

  String _scorePercent(double score) {
    final pct = (score.clamp(0, 1) * 100).round();
    return '$pct%';
  }

  String _placeholderImageFor(ItemDto item) {
    final encoded = Uri.encodeComponent(item.title);
    return 'https://placehold.co/600x600/0F3E5A/FFFFFF?text=$encoded';
  }


  String _timeAgo(DateTime createdAt) {
    final delta = DateTime.now().difference(createdAt.toLocal());
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${(delta.inDays / 7).floor()}w ago';
  }
}

// UI Bits

class _PillTabs extends StatelessWidget {
  final String left, right;
  final int index;
  final ValueChanged<int> onChanged;
  const _PillTabs({
    required this.left,
    required this.right,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = DT.c.blueTint.withValues(alpha: .6);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _pillBtn(label: left, selected: index == 0, onTap: () => onChanged(0)),
          const SizedBox(width: 6),
          _pillBtn(label: right, selected: index == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }

  Widget _pillBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? DT.c.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: DT.t.title.copyWith(
                  color: selected ? Colors.white : DT.c.text.withValues(alpha: .5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCandidate {
  const _MatchCandidate({required this.item, required this.match});
  final ItemDto item;
  final MatchDto match;
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.baseItem,
    required this.candidates,
    required this.timeAgo,
    required this.confidenceLabel,
    required this.scorePercent,
    required this.onCompare,
    required this.onChat,
    required this.onFeedback,
  });

  final ItemDto baseItem;
  final List<_MatchCandidate> candidates;
  final String Function(DateTime) timeAgo;
  final String Function(_MatchCandidate) confidenceLabel;
  final String Function(_MatchCandidate) scorePercent;
  final void Function(_MatchCandidate) onCompare;
  final void Function(_MatchCandidate) onChat;
  final void Function(_MatchCandidate, bool) onFeedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baseItem.title, style: DT.t.title.copyWith(fontSize: 20)),
          SizedBox(height: DT.s.xs),
          Text(
            'Created ${timeAgo(baseItem.createdAt)} • ${baseItem.status.toUpperCase()}',
            style: DT.t.body.copyWith(color: DT.c.textMuted),
          ),
          SizedBox(height: DT.s.md),
          if (candidates.isEmpty)
            const _EmptyMatches()
          else
            Column(
              children: [
                for (int i = 0; i < candidates.length; i++) ...[
                  _CandidateRow(
                    candidate: candidates[i],
                    confidenceLabel: confidenceLabel(candidates[i]),
                    scorePercent: scorePercent(candidates[i]),
                    timeAgo: timeAgo(candidates[i].item.createdAt),
                    onCompare: () => onCompare(candidates[i]),
                    onChat: () => onChat(candidates[i]),
                    onFeedback: (helpful) => onFeedback(candidates[i], helpful),
                  ),
                  if (i != candidates.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: DT.s.sm),
                      child: Divider(color: DT.c.text.withValues(alpha: 0.08)),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.confidenceLabel,
    required this.scorePercent,
    required this.timeAgo,
    required this.onCompare,
    required this.onChat,
    required this.onFeedback,
  });

  final _MatchCandidate candidate;
  final String confidenceLabel;
  final String scorePercent;
  final String timeAgo;
  final VoidCallback onCompare;
  final VoidCallback onChat;
  final ValueChanged<bool> onFeedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.item.title, style: DT.t.title),
                  SizedBox(height: DT.s.xs),
                  Text(
                    'Match score $scorePercent • $confidenceLabel',
                    style: DT.t.body.copyWith(color: DT.c.brand),
                  ),
                  SizedBox(height: DT.s.xs),
                  Text('Reported $timeAgo', style: DT.t.body.copyWith(color: DT.c.textMuted)),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onCompare,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: DT.s.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Compare'),
            ),
          ],
        ),
        SizedBox(height: DT.s.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Start Chat'),
              ),
            ),
            SizedBox(width: DT.s.sm),
            IconButton(
              tooltip: 'Helpful match',
              onPressed: () => onFeedback(true),
              icon: const Icon(Icons.thumb_up_alt_outlined),
            ),
            IconButton(
              tooltip: 'Not helpful',
              onPressed: () => onFeedback(false),
              icon: const Icon(Icons.thumb_down_alt_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.extension_outlined, size: 72, color: Colors.black26),
        SizedBox(height: DT.s.sm),
        Text('No candidates yet', style: DT.t.title),
        SizedBox(height: DT.s.xs),
        Text(
          'We will notify you when a new match arrives.',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
      ],
    );
  }
}
