import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/design_tokens.dart';
import 'bottom_nav_bar.dart';
import 'custom_app_bar.dart';

/// Main layout wrapper that includes app bar and bottom navigation
/// This should only be used for the main 4 pages: Home, Report, Matches, Profile
class MainLayout extends ConsumerStatefulWidget {
  /// Creates a new [MainLayout] instance
  const MainLayout({
    required this.child,
    required this.currentIndex,
    super.key,
  });

  /// The child widget to display in the main content area
  final Widget child;

  /// The current selected index for bottom navigation
  final int currentIndex;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DT.c.surface,
    body: SafeArea(
      child: Column(
        children: [
          // Custom App Bar
          const CustomAppBar(),

          // Main Content
          Expanded(child: widget.child),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavBar(
      currentIndex: widget.currentIndex,
      onTap: (int index) {
        // Handle navigation based on index
        switch (index) {
          case 0:
            context.go(homeRoute);
            break;
          case 1:
            context.go(reportRoute);
            break;
          case 2:
            context.go(matchesRoute);
            break;
          case 3:
            context.go(profileRoute);
            break;
        }
      },
    ),
  );
}
