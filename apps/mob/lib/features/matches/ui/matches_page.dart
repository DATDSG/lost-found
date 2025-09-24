import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../messages/ui/data/chat_models.dart';
import '../../messages/ui/chat_thread_page.dart';
import 'compare_match_page.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});
  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  int _tab = 0; // 0=For Lost, 1=For Found

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
          if (_tab == 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
                child: Column(
                  children: [
                    _MyPostTile(
                      title: 'Casio G-shock - Black Gold',
                      subtitle: 'Fort Station  |  0.5 mi  |  2d ago',
                      imageUrl:
                          'https://images.unsplash.com/photo-1524805444758-089113d48a6d?q=80&w=600&auto=format&fit=crop',
                      onTap: () {},
                    ),
                    SizedBox(height: DT.s.xl),
                    Divider(thickness: 1, color: Colors.black12),
                    SizedBox(height: DT.s.xl * 2),
                    const _EmptyMatches(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate.fixed([
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
                  child: Column(
                    children: [
                      _MyPostTile(
                        title: 'Apple iPhone 13 - Red',
                        subtitle: 'Fort Station  |  0.5 mi  |  2d ago',
                        imageUrl:
                            'https://images.unsplash.com/photo-1627061089866-6fbe62a5f4b1?q=80&w=600&auto=format&fit=crop',
                        trailing: _StackedFaces(),
                        onTap: () {},
                        bottomLine: '3 Candidates',
                      ),
                      Divider(thickness: 1, color: Colors.black12, height: 40),
                      _CandidateTile(
                        photo:
                            'https://images.unsplash.com/photo-1620891549027-88a8240b6f84?q=80&w=600&auto=format&fit=crop',
                        handle: '@arunp',
                        title: 'Apple iPhone 13 - Red',
                        subtitle: 'Colombo 10  |  0.5 mi  |  1d ago',
                        onTap: () => _openCompare(
                          yourTitle: 'Lost Item : Iphone 13',
                          yourPlace: 'Lost near Fort Railway',
                          yourImage:
                              'https://images.unsplash.com/photo-1627061089866-6fbe62a5f4b1?q=80&w=600&auto=format&fit=crop',
                          theirTitle: 'Found Item : Iphone 13',
                          theirPlace: 'Found near Fort Bus Station',
                          theirImage:
                              'https://images.unsplash.com/photo-1620891549027-88a8240b6f84?q=80&w=600&auto=format&fit=crop',
                        ),
                      ),
                      SizedBox(height: DT.s.md),
                      _CandidateTile(
                        photo:
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop',
                        handle: '@kumara',
                        title: 'Apple iPhone 13 - Red',
                        subtitle: 'Fort Station  |  0.5 mi  |  1d ago',
                        onTap: () => _openCompare(),
                      ),
                      SizedBox(height: DT.s.md),
                      _CandidateTile(
                        photo:
                            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=600&auto=format&fit=crop',
                        handle: '@Perera',
                        title: 'Apple iPhone 13 - Red',
                        subtitle: 'Borella  |  0.5 mi  |  24h ago',
                        onTap: () => _openCompare(),
                      ),
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _openCompare({
    String yourTitle = 'Lost Item : Iphone 13',
    String yourPlace = 'Lost near Fort Railway',
    String yourImage =
        'https://images.unsplash.com/photo-1627061089866-6fbe62a5f4b1?q=80&w=600&auto=format&fit=crop',
    String theirTitle = 'Found Item : Iphone 13',
    String theirPlace = 'Found near Fort Bus Station',
    String theirImage =
        'https://images.unsplash.com/photo-1595433707802-6b2626ef1c86?q=80&w=600&auto=format&fit=crop',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareMatchPage(
          yourImage: yourImage,
          yourTitle: yourTitle,
          yourPlace: yourPlace,
          theirImage: theirImage,
          theirTitle: theirTitle,
          theirPlace: theirPlace,
          onStartChat: () {
            final thread = ChatThread(
              id: 'cmp_${DateTime.now().millisecondsSinceEpoch}',
              name: 'Arun',
              online: true,
              messages: [
                ChatMessage(
                  id: 'm1',
                  sender: 'Arun',
                  avatarUrl: '',
                  isMe: false,
                  kind: MessageKind.text,
                  text:
                      'Hi! I found a red iPhone near Fort bus stand. Can you confirm a unique mark?',
                ),
              ],
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatThreadPage(thread: thread)),
            );
          },
        ),
      ),
    );
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
    final bg = DT.c.blueTint.withOpacity(.6);
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
                  color: selected ? Colors.white : DT.c.text.withOpacity(.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyPostTile extends StatelessWidget {
  final String title, subtitle;
  final String imageUrl;
  final String? bottomLine;
  final Widget? trailing;
  final VoidCallback onTap;
  const _MyPostTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.bottomLine,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.r.lg),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(DT.s.md),
          child: Row(
            children: [
              _Thumb(url: imageUrl, size: 84),
              SizedBox(width: DT.s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DT.t.title.copyWith(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: DT.t.body.copyWith(color: DT.c.brand)),
                    if (bottomLine != null) ...[
                      const SizedBox(height: 10),
                      Text(bottomLine!, style: DT.t.body),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final String photo, handle, title, subtitle;
  final VoidCallback onTap;
  const _CandidateTile({
    required this.photo,
    required this.handle,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DT.r.lg),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(DT.s.md),
          child: Row(
            children: [
              _Thumb(url: photo, size: 84),
              SizedBox(width: DT.s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1557053910-d9eadeed1c58?q=80&w=120&auto=format&fit=crop',
                          ),
                          onBackgroundImageError: (_, __) {},
                          backgroundColor: const Color(0xFFE6EAF2),
                        ),
                        const SizedBox(width: 8),
                        Text(handle, style: DT.t.title.copyWith(color: DT.c.brand)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: DT.t.title.copyWith(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: DT.t.body.copyWith(color: DT.c.brand)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: DT.c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;
  final double size;
  const _Thumb({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFFE6EAF2),
          alignment: Alignment.center,
          child: const Icon(Icons.image, color: Color(0xFF8C96A4)),
        ),
      ),
    );
  }
}

class _StackedFaces extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final urls = [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=120&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1519345182560-3f2917c472ef?q=80&w=120&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=120&auto=format&fit=crop',
    ];
    return SizedBox(
      width: 96,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(urls.length, (i) {
          return Positioned(
            right: i * 28.0,
            top: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(urls[i]),
              backgroundColor: const Color(0xFFE6EAF2),
              onBackgroundImageError: (_, __) {},
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DT.s.xl * 2),
      child: Column(
        children: [
          const Icon(Icons.extension_outlined, size: 96, color: Colors.black38),
          const SizedBox(height: 20),
          Text('No matches yet', style: DT.t.h1.copyWith(fontSize: 26)),
        ],
      ),
    );
  }
}
