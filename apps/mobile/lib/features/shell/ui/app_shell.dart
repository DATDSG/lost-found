import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/app_badge_icon.dart';
import '../../home/ui/home_page.dart';
import '../../report/ui/report_page.dart';
import '../../matches/ui/matches_page.dart';
import '../../profile/ui/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  String _lang = 'En';
  final _pages = const [HomePage(), ReportPage(), MatchesPage(), ProfilePage()];

  void _cycleLang() {
    setState(() {
      _lang = _lang == 'En' ? 'Si' : _lang == 'Si' ? 'Ta' : 'En';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top App Bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(DT.s.md, DT.s.sm, DT.s.md, DT.s.sm),
            child: Row(
              children: [
                _LogoMark(),
                const Spacer(),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: DT.c.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                ),
                SizedBox(width: DT.s.md),
                AppBadgeIcon(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: 1,
                  onTap: () {},
                ),
                SizedBox(width: DT.s.md),
                InkWell(
                  onTap: _cycleLang,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DT.c.brand, width: 1.5),
                    ),
                    child: Text(
                      _lang,
                      style: DT.t.body.copyWith(
                        color: DT.c.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: IndexedStack(index: _index, children: _pages),

      bottomNavigationBar:
          _BottomNav(index: _index, onChanged: (i) => setState(() => _index = i)),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder mark (replace with real asset if available)
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: DT.c.brand,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.search, color: Colors.white, size: 18),
        ),
        SizedBox(width: DT.s.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('LOST',
                style:
                    DT.t.title.copyWith(color: const Color(0xFF0F3E5A), letterSpacing: 0.5)),
            Text('FINDER',
                style:
                    DT.t.title.copyWith(color: const Color(0xFF0F3E5A), letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _BottomNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BNI(Icons.home_outlined, 'Home'),
      _BNI(Icons.receipt_long_outlined, 'Report'),
      _BNI(Icons.verified_user_outlined, 'Matches'),
      _BNI(Icons.person_outline, 'Profile'),
    ];

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: DT.s.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: DT.c.card,
            borderRadius: BorderRadius.circular(DT.r.xxl),
            boxShadow: DT.e.bar,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final isActive = i == index;
              final color = isActive ? DT.c.brand : DT.c.textMuted;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(DT.r.xxl),
                  child: Padding(
                    padding: EdgeInsets.only(top: DT.s.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(it.icon, size: 28, color: color),
                        SizedBox(height: DT.s.xs),
                        Text(it.label,
                            style:
                                DT.t.body.copyWith(color: color, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BNI {
  final IconData icon;
  final String label;
  const _BNI(this.icon, this.label);
}
