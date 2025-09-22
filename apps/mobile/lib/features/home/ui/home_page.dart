import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/search_bar_with_filter.dart';
import '../../../shared/widgets/filter_sheet.dart'; // for FilterState type

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keep one FilterState to preserve the filter button's active state across rebuilds.
  final FilterState _filters = FilterState();

  Future<void> _refresh() async =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  void _onSubmit(String query, FilterState filters) {
    debugPrint('Search: "$query", filters: $filters');
    // TODO: apply query + filters to your list here
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
                child: SearchBarWithFilter(
                  onSubmit: _onSubmit,
                  initialFilters: _filters, // keeps icon state in sync
                  // hint: 'Enter item name, category, Locat..', // optional
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final data = _demo[i % _demo.length];
                    return Padding(
                      padding: EdgeInsets.only(bottom: DT.s.lg),
                      child: _ItemCard(
                        title: data.title,
                        subtitle: data.subtitle,
                        statusText: data.statusText,
                        statusColor: data.statusColor,
                        statusBg: data.statusBg,
                      ),
                    );
                  },
                  childCount: _demo.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

class _CardData {
  final String title, subtitle, statusText;
  final Color statusColor, statusBg;
  const _CardData(
      this.title, this.subtitle, this.statusText, this.statusColor, this.statusBg);
}

const _demo = [
  _CardData('Black Backpack', 'Colombo  •  0.5 mi  •  2d ago',
      'Found', Color(0xFF2E7D32), Color(0xFFE7F9E7)),
  _CardData('Apple iPhone 13', 'Fort Station  •  0.5 mi  •  2d ago',
      'Lost', Color(0xFFD32F2F), Color(0xFFFBE7E7)),
  _CardData('Gucci GG Wallet', 'Wallawaththa  •  0.5 mi  •  2d ago',
      'Found', Color(0xFF2E7D32), Color(0xFFE7F9E7)),
  _CardData('TUF Laptop', 'Gampha  •  0.5 mi  •  5d ago',
      'Lost', Color(0xFFD32F2F), Color(0xFFFBE7E7)),
];

class _ItemCard extends StatelessWidget {
  final String title, subtitle, statusText;
  final Color statusColor, statusBg;
  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      padding: EdgeInsets.all(DT.s.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Row(children: [
                  Expanded(
                    child: Text(title, style: DT.t.title.copyWith(fontSize: 18)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: DT.s.sm, vertical: DT.s.xs),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: DT.t.label.copyWith(color: statusColor),
                    ),
                  ),
                ]),
                SizedBox(height: DT.s.xs),
                Text(subtitle, style: DT.t.body.copyWith(color: DT.c.brand)),
                SizedBox(height: DT.s.md),
                Row(
                  children: const [
                    _MiniButton('Contact'),
                    SizedBox(width: 16),
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
    return Ink(
      decoration: BoxDecoration(
        color: DT.c.blueTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: 10),
          child: Text(
            label,
            style: DT.t.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
