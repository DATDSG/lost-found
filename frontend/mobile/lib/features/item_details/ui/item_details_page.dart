import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/models/item.dart';
import '../../../core/models/match.dart';
import '../../messages/ui/chat_thread_page.dart';
import '../../messages/ui/data/chat_models.dart';

class ItemDetailsPage extends StatefulWidget {
  final Item item;
  final List<ItemMatch>? matches;

  const ItemDetailsPage({super.key, required this.item, this.matches});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final PageController _pager = PageController();
  int _index = 0;

  List<ItemImage> get images => widget.item.images;

  @override
  void initState() {
    super.initState();
    _pager.addListener(() {
      final p = _pager.page?.round() ?? 0;
      if (p != _index) setState(() => _index = p);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  // ---- Actions --------------------------------------------------------------

  Future<void> _openChat() async {
    final thread = ChatThread(
      id: 'item-${widget.item.id}',
      name: widget.item.userName ?? 'Anonymous',
      online: true,
      messages: [
        ChatMessage(
          id: 'seed1',
          sender: widget.item.userName ?? 'Anonymous',
          avatarUrl: '',
          isMe: false,
          kind: MessageKind.text,
          text:
              "Hey, I think I found your ${widget.item.title.split('-').first.trim()}.",
        ),
      ],
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatThreadPage(thread: thread)),
    );
  }

  Future<void> _call() async {
    final phoneNumber =
        widget.item.contactInfo?['phone'] as String? ?? '+94 11 000 0000';
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _share() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share tapped')));
  }

  Future<void> _alertOwner() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Alert owner tapped')));
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dateStr = _fmtDateTime(widget.item.dateLostFound);

    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Details', style: DT.t.h1.copyWith(fontSize: 20)),
            Text(
              'Item #${widget.item.id}',
              style: DT.t.label.copyWith(color: DT.c.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Alert',
            icon: const Icon(Icons.notification_important_outlined),
            onPressed: _alertOwner,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.sm, DT.s.lg, DT.s.xxl),
        physics: DT.scroll,
        children: [
          // Top media
          _HeroMedia(
            pager: _pager,
            index: _index,
            rewardLkr: widget.item.rewardOffered?.toInt(),
            images: images
                .map((img) => NetworkImage(img.url) as ImageProvider<Object>?)
                .toList(),
          ),
          SizedBox(height: DT.s.md),

          // Thumbs (scrollable to avoid overflow)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => SizedBox(width: DT.s.md),
              itemBuilder: (_, i) {
                final img = images[i];
                final selected = _index == i;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _pager.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                  child: Ink(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFFE6EAF2),
                      border: Border.all(
                        color: selected ? DT.c.brand : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(img.url),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: null,
                  ),
                );
              },
            ),
          ),

          SizedBox(height: DT.s.xl),

          // Title
          Text(
            widget.item.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: DT.s.lg),

          // Info tiles
          _InfoTile(
            icon: Icons.credit_card_rounded,
            label: 'Brand & Model',
            value:
                '${widget.item.brand ?? ''} ${widget.item.model ?? ''}'
                    .trim()
                    .isEmpty
                ? '—'
                : '${widget.item.brand ?? ''} ${widget.item.model ?? ''}'
                      .trim(),
          ),
          SizedBox(height: DT.s.md),
          _InfoTile(
            icon: Icons.event_rounded,
            label: 'Found Date',
            value: dateStr,
          ),
          SizedBox(height: DT.s.md),
          _InfoTile(
            icon: Icons.place_rounded,
            label: 'Last Seen',
            value: widget.item.location.address ?? '—',
          ),

          SizedBox(height: DT.s.xl),

          // Description
          Text('Item Description', style: DT.t.title.copyWith(fontSize: 20)),
          SizedBox(height: DT.s.sm),
          Text(
            widget.item.description.isNotEmpty
                ? widget.item.description
                : 'No additional description has been provided.',
            style: DT.t.body.copyWith(height: 1.6),
          ),

          SizedBox(height: DT.s.xl),

          // If Found This
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DT.r.lg),
              boxShadow: DT.e.card,
            ),
            padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('If Found This', style: DT.t.title.copyWith(fontSize: 18)),
                SizedBox(height: DT.s.lg),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.send_rounded,
                        label: 'Message',
                        onTap: _openChat,
                      ),
                    ),
                    SizedBox(width: DT.s.lg),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        filled: true,
                        onTap: _call,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: DT.s.xl),

          // Quick links (optional)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _QuickLink(icon: Icons.search_rounded, label: 'Matches'),
              _QuickLink(icon: Icons.place_outlined, label: 'Nearby'),
            ],
          ),
        ],
      ),
    );
  }
}

// === Pieces ==================================================================

class _HeroMedia extends StatelessWidget {
  const _HeroMedia({
    required this.pager,
    required this.index,
    required this.images,
    required this.rewardLkr,
  });

  final PageController pager;
  final int index;
  final List<ImageProvider?> images;
  final int? rewardLkr;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DT.r.lg),
          child: SizedBox(
            height: 280,
            child: PageView.builder(
              controller: pager,
              itemCount: images.length,
              itemBuilder: (_, i) {
                final img = images[i];
                return Container(
                  color: const Color(0xFFE6EAF2),
                  alignment: Alignment.center,
                  child: img == null
                      ? const Icon(
                          Icons.image,
                          size: 48,
                          color: Color(0xFF8C96A4),
                        )
                      : Image(
                          image: img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                );
              },
            ),
          ),
        ),
        if (rewardLkr != null)
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Reward Rs ${rewardLkr!}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 12,
          child: _PageCountBadge(current: index + 1, total: images.length),
        ),
      ],
    );
  }
}

class _PageCountBadge extends StatelessWidget {
  const _PageCountBadge({required this.current, required this.total});
  final int current, total;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: DT.c.blueTint,
        borderRadius: BorderRadius.circular(DT.r.lg),
      ),
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
      child: Row(
        children: [
          Icon(icon, color: DT.c.text),
          SizedBox(width: DT.s.lg),
          Expanded(
            child: Text(
              label,
              style: DT.t.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: DT.t.body.copyWith(color: DT.c.textMuted),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? DT.c.brand : DT.c.blueTint;
    final fg = filled ? Colors.white : DT.c.text;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 10),
              Text(
                label,
                style: DT.t.title.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: DT.c.blueTint,
          child: Icon(icon, color: DT.c.text),
        ),
        const SizedBox(height: 8),
        Text(label, style: DT.t.body.copyWith(color: DT.c.textMuted)),
      ],
    );
  }
}

// --- helpers -----------------------------------------------------------------

String _fmtDateTime(DateTime dt) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hh = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final mm = dt.minute.toString().padLeft(2, '0');
  final am = dt.hour < 12 ? 'AM' : 'PM';
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hh:$mm $am';
}
