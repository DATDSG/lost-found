import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/home_models.dart';
import '../../../../shared/providers/api_providers.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../../shared/widgets/optimized_report_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../widgets/profile_widgets.dart';

/// Enhanced profile screen with modern design following design science principles
class ProfileScreen extends ConsumerStatefulWidget {
  /// Creates a new profile screen widget
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with 3 tabs: Active, Drafts, Resolved
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Invalidate and refresh all user data providers
    ref
      ..invalidate(userReportsProvider)
      ..invalidate(userActiveReportsProvider)
      ..invalidate(userDraftReportsProvider)
      ..invalidate(userResolvedReportsProvider);

    // Wait a bit for the refresh to complete
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < DesignBreakpoints.mobile;

    return MainLayout(
      currentIndex: 3, // Profile is index 3
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: DT.c.brand,
        backgroundColor: DT.c.surface,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header with improved spacing
              _buildProfileHeader(isSmallScreen),

              // Stats Section with better accessibility
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? DT.s.sm : DT.s.md,
                ),
                child: const ProfileStatsWidget(),
              ),

              SizedBox(height: DT.s.lg),

              // Tab Bar with enhanced accessibility
              _buildTabBar(isSmallScreen),

              // Tab Content with improved layout
              SizedBox(
                height:
                    screenSize.height *
                    0.5, // Increased height for better content display
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(isSmallScreen),
                    _buildDraftsTab(isSmallScreen),
                    _buildResolvedTab(isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isSmallScreen) => Consumer(
    builder: (context, ref, child) {
      final authState = ref.watch(authStateProvider);

      if (authState.user == null) {
        return Container(
          margin: EdgeInsets.all(isSmallScreen ? DT.s.sm : DT.s.md),
          child: SkeletonCard(
            width: double.infinity,
            padding: EdgeInsets.all(DT.s.lg),
          ),
        );
      }

      return Container(
        margin: EdgeInsets.all(isSmallScreen ? DT.s.sm : DT.s.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DT.c.brand,
              DT.c.brand.withValues(alpha: 0.9),
              DT.c.accentGreen.withValues(alpha: 0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(DT.r.xl),
          boxShadow: [
            BoxShadow(
              color: DT.c.brand.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(DT.s.lg),
          child: Column(
            children: [
              // Enhanced Profile Info Section
              Row(
                children: [
                  // Enhanced Avatar with Better Design
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DT.c.textOnBrand.withValues(alpha: 0.4),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: DT.c.textOnBrand.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: DT.c.textOnBrand.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: DT.c.textOnBrand,
                        size: 45,
                      ),
                    ),
                  ),

                  SizedBox(width: DT.s.lg),

                  // Enhanced User Info with Better Typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: DT.t.bodyMedium.copyWith(
                            color: DT.c.textOnBrand.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: DT.s.xs),
                        Text(
                          authState.user!.displayName ?? 'User',
                          style: DT.t.headlineSmall.copyWith(
                            color: DT.c.textOnBrand,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: DT.s.xs),
                        Text(
                          authState.user!.email,
                          style: DT.t.bodyMedium.copyWith(
                            color: DT.c.textOnBrand.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Action Buttons
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: DT.c.textOnBrand.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DT.r.md),
                          border: Border.all(
                            color: DT.c.textOnBrand.withValues(alpha: 0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: DT.c.textOnBrand,
                            size: 20,
                          ),
                          onPressed: _navigateToEditProfile,
                        ),
                      ),
                      SizedBox(width: DT.s.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: DT.c.accentRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DT.r.md),
                          border: Border.all(
                            color: DT.c.accentRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.logout_rounded,
                            color: DT.c.accentRed,
                            size: 20,
                          ),
                          onPressed: _handleLogout,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: DT.s.lg),

              // Enhanced Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: _buildProfileActionButton(
                      title: 'Edit Profile',
                      icon: Icons.person_outline_rounded,
                      onTap: _navigateToEditProfile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildProfileActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.textOnBrand.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DT.r.lg),
        border: Border.all(
          color: DT.c.textOnBrand.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: DT.c.textOnBrand, size: 18),
          SizedBox(width: DT.s.sm),
          Text(
            title,
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.textOnBrand,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTabBar(bool isSmallScreen) =>
      ProfileTabBar(controller: _tabController);

  Widget _buildActiveTab(bool isSmallScreen) => SingleChildScrollView(
    padding: EdgeInsets.all(isSmallScreen ? DT.s.sm : DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Reports',
          style: DT.t.title.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.md),
        Consumer(
          builder: (context, ref, child) {
            final userReportsAsync = ref.watch(userActiveReportsProvider);

            return userReportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No active reports',
                    subtitle: 'Your active reports will appear here',
                  );
                }

                return Column(
                  children: reports
                      .map(
                        (report) => Padding(
                          padding: EdgeInsets.only(bottom: DT.s.md),
                          child: OptimizedReportCard(
                            key: ValueKey(report.id),
                            report: report,
                            onContact: () => _showContactDialog(report),
                            onViewDetails: () => _showDetailsDialog(report),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: _buildLoadingState,
              error: (error, stackTrace) => _buildErrorState(
                title: 'Error loading reports',
                subtitle: 'Pull down to refresh',
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _buildDraftsTab(bool isSmallScreen) => SingleChildScrollView(
    padding: EdgeInsets.all(isSmallScreen ? DT.s.sm : DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Draft Reports',
          style: DT.t.title.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.md),
        Consumer(
          builder: (context, ref, child) {
            final userDraftsAsync = ref.watch(userDraftReportsProvider);

            return userDraftsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.edit_outlined,
                    title: 'No draft reports',
                    subtitle: 'Your draft reports will appear here',
                  );
                }

                return Column(
                  children: reports
                      .map(
                        (report) => Padding(
                          padding: EdgeInsets.only(bottom: DT.s.md),
                          child: OptimizedReportCard(
                            key: ValueKey(report.id),
                            report: report,
                            onContact: () => _showContactDialog(report),
                            onViewDetails: () => _showDetailsDialog(report),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: _buildLoadingState,
              error: (error, stackTrace) => _buildErrorState(
                title: 'Error loading reports',
                subtitle: 'Pull down to refresh',
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _buildResolvedTab(bool isSmallScreen) => SingleChildScrollView(
    padding: EdgeInsets.all(isSmallScreen ? DT.s.sm : DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolved Reports',
          style: DT.t.title.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.md),
        Consumer(
          builder: (context, ref, child) {
            final userResolvedAsync = ref.watch(userResolvedReportsProvider);

            return userResolvedAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No resolved reports',
                    subtitle: 'Your resolved reports will appear here',
                  );
                }

                return Column(
                  children: reports
                      .map(
                        (report) => Padding(
                          padding: EdgeInsets.only(bottom: DT.s.md),
                          child: OptimizedReportCard(
                            key: ValueKey(report.id),
                            report: report,
                            onContact: () => _showContactDialog(report),
                            onViewDetails: () => _showDetailsDialog(report),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: _buildLoadingState,
              error: (error, stackTrace) => _buildErrorState(
                title: 'Error loading reports',
                subtitle: 'Pull down to refresh',
              ),
            );
          },
        ),
      ],
    ),
  );

  void _showContactDialog(ReportItem report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Information'),
        content: Text('Contact: ${report.contactInfo}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(ReportItem report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${report.category}'),
            Text('Location: ${report.location}'),
            Text('Type: ${report.itemType.name}'),
            if (report.description.isNotEmpty)
              Text('Description: ${report.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Navigate to edit profile screen
  void _navigateToEditProfile() {
    context.push(editProfileRoute);
  }

  /// Handle logout with confirmation dialog
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: DT.t.titleMedium.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Logout',
              style: DT.t.bodyMedium.copyWith(
                color: DT.c.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if ((shouldLogout ?? false) && mounted) {
      try {
        // Perform logout
        await ref.read(authStateProvider.notifier).logout();

        // Navigate to login screen
        if (mounted) {
          context.go(loginRoute);
        }
      } on Exception {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to logout. Please try again.',
                style: DT.t.bodyMedium.copyWith(color: DT.c.textOnBrand),
              ),
              backgroundColor: DT.c.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Build empty state widget with consistent styling
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Container(
    padding: EdgeInsets.all(DT.s.xl),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          color: DT.c.textMuted,
          size: 48,
          semanticLabel: 'Empty state icon',
        ),
        SizedBox(height: DT.s.md),
        Text(
          title,
          style: DT.t.titleMedium.copyWith(
            color: DT.c.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.sm),
        Text(
          subtitle,
          style: DT.t.bodySmall.copyWith(color: DT.c.textMuted, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  /// Build loading state widget with skeleton loading
  Widget _buildLoadingState() => Column(
    children: [
      SkeletonCard(
        width: double.infinity,
        height: 100,
        padding: EdgeInsets.all(DT.s.md),
      ),
      SizedBox(height: DT.s.md),
      SkeletonCard(
        width: double.infinity,
        height: 100,
        padding: EdgeInsets.all(DT.s.md),
      ),
      SizedBox(height: DT.s.md),
      SkeletonCard(
        width: double.infinity,
        height: 100,
        padding: EdgeInsets.all(DT.s.md),
      ),
    ],
  );

  /// Build error state widget with consistent styling
  Widget _buildErrorState({required String title, required String subtitle}) =>
      Container(
        padding: EdgeInsets.all(DT.s.xl),
        decoration: BoxDecoration(
          color: DT.c.surfaceVariant,
          borderRadius: BorderRadius.circular(DT.r.md),
          border: Border.all(color: DT.c.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: DT.c.accentRed,
              size: 48,
              semanticLabel: 'Error icon',
            ),
            SizedBox(height: DT.s.md),
            Text(
              title,
              style: DT.t.titleMedium.copyWith(
                color: DT.c.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              subtitle,
              style: DT.t.bodySmall.copyWith(
                color: DT.c.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
