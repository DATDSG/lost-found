import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import 'package:flutter/services.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: DT.s.xs),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: DT.c.card,
            borderRadius: BorderRadius.circular(DT.r.xxl),
            boxShadow: DT.e.bar,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DT.r.xxl),
            child: BottomNavigationBar(
              backgroundColor: DT.c.card,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              elevation: 0,
              selectedItemColor: DT.c.brand,
              unselectedItemColor: DT.c.textMuted,
              selectedLabelStyle: DT.t.body.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: DT.t.body,
              onTap: (i) { HapticFeedback.lightImpact(); onTap(i); },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long_rounded), label: 'Report'),
                BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), activeIcon: Icon(Icons.verified_user_rounded), label: 'Matches'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
