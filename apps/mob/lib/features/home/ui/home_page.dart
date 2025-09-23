import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/search_bar_with_filter.dart';
import '../../../shared/widgets/filter_sheet.dart';
import '../../../shared/widgets/item_card.dart';
import '../../item_details/ui/item_details_page.dart';
import '../../messages/ui/data/chat_models.dart';
import '../../messages/ui/chat_thread_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _refresh() async =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  void _onSubmit(String q, FilterState filters) {
    debugPrint(
      'Search: "$q"  | filters: '
      'lost=${filters.lost}, found=${filters.found}, '
      'cat=${filters.category}, near=${filters.nearbyOnly}',
    );
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

  void _openDetails(_CardDemo d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailsPage(
          itemId: 'Lost Item #1234567890',
          title: d.title,
          rewardLkr: d.reward,
          brandModel: d.brandModel,
          foundDate: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          lastSeen: d.location,
          description: d.description,
          images: d.images, // nulls show placeholder; safe to pass
          contactName: d.contactName,
          contactPhone: d.phone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: DT.scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.xl),
                child: SearchBarWithFilter(onSubmit: _onSubmit),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
              sliver: SliverList.builder(
                itemCount: _demo.length,
                itemBuilder: (context, i) {
                  final d = _demo[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: DT.s.lg),
                    child: ItemCard(
                      size: ItemCardSize.medium,
                      image: d.images.isNotEmpty ? d.images.first : null,
                      title: d.title,
                      location: d.location,
                      distance: d.distance,
                      timeAgo: d.timeAgo,
                      status: d.status,
                      onContact: () => _openChatFor(d.contactName),
                      onViewDetails: () => _openDetails(d),
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

/// Demo data (images can be null -> placeholder; no asset/network required)
class _CardDemo {
  final List<ImageProvider?> images;
  final String title, brandModel, location, distance, timeAgo, description;
  final ItemStatus status;
  final int? reward;
  final String contactName;
  final String phone;

  const _CardDemo({
    this.images = const [],
    required this.title,
    required this.brandModel,
    required this.location,
    required this.distance,
    required this.timeAgo,
    required this.description,
    required this.status,
    this.reward,
    required this.contactName,
    required this.phone,
  });
}

const _demo = <_CardDemo>[
  _CardDemo(
    images: [null, null, null, null], // keep null -> placeholder squares
    title: 'Apple iPhone 13 - Red',
    brandModel: 'Apple iPhone 13',
    location: 'Fort Railway Station',
    distance: '0.5 mi',
    timeAgo: '2d ago',
    description:
        'Red iPhone 13 in a clear protective case. Lost at Fort Railway Station while boarding the evening train.',
    status: ItemStatus.found,
    reward: 5000,
    contactName: 'Liam Carter',
    phone: '+94 11 222 3344',
  ),
  _CardDemo(
    images: [null, null, null],
    title: 'Black Backpack',
    brandModel: 'Generic Backpack',
    location: 'Colombo',
    distance: '0.7 mi',
    timeAgo: '1d ago',
    description: 'Black backpack with laptop sleeve.',
    status: ItemStatus.lost,
    contactName: 'Sophia Bennett',
    phone: '+94 11 999 8877',
  ),
];
