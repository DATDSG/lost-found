import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

enum ItemStatus { found, lost }
enum ItemCardSize { medium, large }

class ItemCard extends StatelessWidget {
  final ImageProvider<Object>? image;          // pass an AssetImage or keep null for placeholder
  final String title;
  final String location;
  final String distance;                       // e.g. "0.5 mi"
  final String timeAgo;                        // e.g. "2d ago"
  final ItemStatus status;
  final VoidCallback onContact;
  final VoidCallback onViewDetails;
  final ItemCardSize size;

  const ItemCard({
    super.key,
    this.image,
    required this.title,
    required this.location,
    required this.distance,
    required this.timeAgo,
    required this.status,
    required this.onContact,
    required this.onViewDetails,
    this.size = ItemCardSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final isFound = status == ItemStatus.found;
    final isLarge = size == ItemCardSize.large;

    // Medium sizing
    final double thumb = isLarge ? 140 : 112;
    final double corner = isLarge ? 28 : 20;
    final double titleSize = isLarge ? 24 : 20;
    final double pillRadius = isLarge ? 28 : 22;
    final EdgeInsets cardPad = isLarge
        ? EdgeInsets.all(DT.s.lg)
        : EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.md);

    return Container(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(corner),
        boxShadow: DT.e.card,
      ),
      padding: cardPad,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(image: image, size: thumb, radius: corner - 4),
              SizedBox(width: DT.s.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DT.t.h1.copyWith(fontSize: titleSize),
                    ),
                    SizedBox(height: DT.s.sm),
                    // Meta
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(location,
                            style: DT.t.title.copyWith(
                                color: DT.c.brand, fontWeight: FontWeight.w600)),
                        _sep(),
                        Text(distance,
                            style: DT.t.title.copyWith(
                                color: DT.c.brand, fontWeight: FontWeight.w600)),
                        _sep(),
                        Text(timeAgo,
                            style: DT.t.title.copyWith(
                                color: DT.c.brand, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: DT.s.md),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _PillButton(
                            label: 'Contact',
                            onTap: onContact,
                            compact: !isLarge,
                          ),
                        ),
                        SizedBox(width: DT.s.md),
                        Expanded(
                          child: _PillButton(
                            label: 'View Details',
                            onTap: onViewDetails,
                            compact: !isLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Status pill
          Positioned(
            right: 0,
            top: 0,
            child: _StatusPill(
              text: isFound ? 'Found' : 'Lost',
              bg: isFound ? DT.c.successBg : DT.c.dangerBg,
              fg: isFound ? DT.c.success : DT.c.danger,
              radius: pillRadius,
              compact: !isLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep() => Text(' | ', style: DT.t.title.copyWith(color: DT.c.brand));
}

class _Thumb extends StatelessWidget {
  final ImageProvider<Object>? image;
  final double size;
  final double radius;
  const _Thumb({required this.image, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFE6EAF2),
        child: image == null
            ? const Icon(Icons.image, size: 40, color: Color(0xFF8C96A4))
            : Image(image: image!, fit: BoxFit.cover),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double radius;
  final bool compact;
  const _StatusPill({
    required this.text,
    required this.bg,
    required this.fg,
    required this.radius,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DT.s.md : DT.s.lg,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        style: DT.t.title.copyWith(
          color: fg,
          fontSize: compact ? 14 : 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _PillButton({required this.label, required this.onTap, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: DT.c.blueTint.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DT.s.xl,
            vertical: compact ? 10 : 14,
          ),
          child: Center(
            child: Text(
              label,
              style: DT.t.title.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
