import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/search_bar_with_filter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: DT.t.h1),
            SizedBox(height: DT.s.md),
            Text('Design-only placeholder per mock.', style: DT.t.bodyMuted),
            SizedBox(height: DT.s.xl),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.c.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.xxl + 80),
        children: [
          // Search + filter is the first element
          SearchBarWithFilter(controller: _search, onFilter: _openFilter),
          SizedBox(height: DT.s.xl),

          _ItemCard(
            title: 'Black Backpack',
            subtitle: 'Colombo  •  0.5 mi  •  2d ago',
            statusText: 'Found',
            statusColor: DT.c.successFg,
            statusBg: DT.c.successBg,
          ),
          SizedBox(height: DT.s.lg),

          _ItemCard(
            title: 'Apple iPhone 13',
            subtitle: 'Fort Station  •  0.5 mi  •  2d ago',
            statusText: 'Lost',
            statusColor: DT.c.dangerFg,
            statusBg: DT.c.dangerBg,
          ),
          SizedBox(height: DT.s.lg),

          _ItemCard(
            title: 'Gucci GG Wallet',
            subtitle: 'Wallawaththa  •  0.5 mi  •  2d ago',
            statusText: 'Found',
            statusColor: DT.c.successFg,
            statusBg: DT.c.successBg,
          ),
          SizedBox(height: DT.s.lg),

          _ItemCard(
            title: 'TUF Laptop',
            subtitle: 'Gampha  •  0.5 mi  •  5d ago',
            statusText: 'Lost',
            statusColor: DT.c.dangerFg,
            statusBg: DT.c.dangerBg,
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final Color statusBg;

  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.lg), // ≈20dp
        boxShadow: DT.e.card,
      ),
      padding: EdgeInsets.all(DT.s.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail 76x76, radius 16
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 76,
              width: 76,
              color: const Color(0xFFE6EAF2),
              child: const Icon(Icons.image, size: 28, color: Color(0xFF8C96A4)),
            ),
          ),
          SizedBox(width: DT.s.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: DT.t.title.copyWith(fontSize: 18)),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(statusText,
                          style: DT.t.label.copyWith(color: statusColor)),
                    ),
                  ],
                ),
                SizedBox(height: DT.s.xs),
                Text(subtitle, style: DT.t.body.copyWith(color: DT.c.brand)),
                SizedBox(height: DT.s.md),
                Row(
                  children: [
                    _MiniButton('Contact'),
                    SizedBox(width: DT.s.md),
                    _MiniButton('View Details'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  const _MiniButton(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: 10),
      decoration: BoxDecoration(
        color: DT.c.blueTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: DT.t.body.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
