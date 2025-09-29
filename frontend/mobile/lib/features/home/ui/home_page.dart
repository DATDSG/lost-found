import 'package:flutter/material.dart';

import '../../../core/api/models/item_dto.dart';
import '../../../core/api/services/item_api.dart';
import '../../../core/models/item.dart' as models;
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/filter_sheet.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/search_bar_with_filter.dart';
import '../../item_details/ui/item_details_page.dart';
import '../../messages/ui/chat_thread_page.dart';
import '../../messages/ui/data/chat_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<ItemDto> _items = <ItemDto>[];
  FilterState _activeFilters = FilterState();
  String _query = '';
  bool _loading = false;
  String? _error;

  List<ItemDto> get _filteredItems {
    return _items.where((item) {
      final status = item.status.toLowerCase();
      if (!_activeFilters.lost && status == 'lost') return false;
      if (!_activeFilters.found && status == 'found') return false;

      if (_query.isNotEmpty) {
        final haystack = '${item.title} ${item.description ?? ''}'
            .toLowerCase();
        if (!haystack.contains(_query.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ItemApi.I.listItems();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _loadItems();

  void _onSubmit(String q, FilterState filters) {
    setState(() {
      _query = q;
      _activeFilters = filters.copy();
    });
  }

  void _openChatFor(String name) {
    final thread = ChatThread(
      id: 't_${name.hashCode}',
      name: name,
      online: true,
      messages: const [
        ChatMessage(
          id: 'm1',
          sender: 'Liam Carter',
          avatarUrl: '',
          isMe: false,
          kind: MessageKind.text,
          text: 'Hi, is this yours?',
        ),
        ChatMessage(
          id: 'm2',
          sender: 'You',
          avatarUrl: '',
          isMe: true,
          kind: MessageKind.text,
          text: 'Looks like it!',
        ),
      ],
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatThreadPage(thread: thread)),
    );
  }

  void _openDetails(ItemDto item) {
    // Convert ItemDto to Item model
    final itemModel = models.Item(
      id: item.id.toString(),
      type: item.status == 'found'
          ? models.ItemType.found
          : models.ItemType.lost,
      status: item.status == 'active'
          ? models.ItemStatus.active
          : models.ItemStatus.claimed,
      title: item.title,
      description: item.description ?? '',
      category: 'general',
      location: models.Location(
        latitude: item.lat ?? 0.0,
        longitude: item.lng ?? 0.0,
      ),
      dateLostFound: item.createdAt,
      createdAt: item.createdAt,
      updatedAt: item.createdAt,
      userId: item.ownerId?.toString() ?? '0',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailsPage(item: itemModel)),
    );
  }

  String _timeAgo(DateTime createdAt) {
    final delta = DateTime.now().difference(createdAt.toLocal());
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${(delta.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return SafeArea(
      child: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: DT.scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DT.s.lg,
                  DT.s.lg,
                  DT.s.lg,
                  DT.s.xl,
                ),
                child: SearchBarWithFilter(onSubmit: _onSubmit),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_error != null && !_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DT.s.lg,
                    vertical: DT.s.md,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DT.c.dangerBg,
                      borderRadius: BorderRadius.circular(DT.r.md),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(DT.s.md),
                      child: Text(
                        'Could not load items. Tap to retry.\n\n$_error',
                        style: DT.t.body.copyWith(color: DT.c.danger),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_loading && _error == null)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
                sliver: items.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: DT.s.xl),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.black26,
                              ),
                              SizedBox(height: DT.s.md),
                              Text(
                                'No reports yet',
                                style: DT.t.h1.copyWith(fontSize: 22),
                              ),
                              SizedBox(height: DT.s.sm),
                              Text(
                                'Pull to refresh after adding a report.',
                                style: DT.t.body.copyWith(
                                  color: DT.c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final status = item.status.toLowerCase() == 'found'
                              ? ItemStatus.found
                              : ItemStatus.lost;
                          return Padding(
                            padding: EdgeInsets.only(bottom: DT.s.lg),
                            child: ItemCard(
                              size: ItemCardSize.medium,
                              image: null,
                              title: item.title,
                              location: 'Owner only',
                              distance: '—',
                              timeAgo: _timeAgo(item.createdAt),
                              status: status,
                              onContact: () => _openChatFor('Finder'),
                              onViewDetails: () => _openDetails(item),
                            ),
                          );
                        },
                      ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 72)),
          ],
        ),
      ),
    );
  }
}
