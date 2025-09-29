import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Medium height + gentle rounded top corners
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            index: 0,
            isSelected: currentIndex == 0,
            label: 'Home',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            onTap: onTap,
          ),
          _NavItem(
            index: 1,
            isSelected: currentIndex == 1,
            label: 'Report',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            onTap: onTap,
          ),
          _NavItem(
            index: 2,
            isSelected: currentIndex == 2,
            label: 'Matches',
            icon: Icons.verified_outlined,
            selectedIcon: Icons.verified_rounded,
            onTap: onTap,
          ),
          _NavItem(
            index: 3,
            isSelected: currentIndex == 3,
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.isSelected,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? DT.c.brand : DT.c.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onTap(index),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? selectedIcon : icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: DT.t.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
