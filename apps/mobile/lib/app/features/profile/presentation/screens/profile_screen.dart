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
    _tabController = TabController(length: 4, vsync: this);
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
                    0.45, // Reduced height to prevent overflow
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(isSmallScreen),
                    _buildDraftsTab(isSmallScreen),
                    _buildResolvedTab(isSmallScreen),
                    _buildEditTab(isSmallScreen),
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
        child: ProfileInfoCard(
          user: authState.user!,
          showEditButton: true,
          onEditPressed: _navigateToEditProfile,
        ),
      );
    },
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

  Widget _buildEditTab(bool isSmallScreen) => SingleChildScrollView(
    padding: EdgeInsets.all(isSmallScreen ? DT.s.sm : DT.s.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Settings',
          style: DT.t.title.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.lg),

        // Settings Options with improved accessibility
        Container(
          padding: EdgeInsets.all(DT.s.lg),
          decoration: BoxDecoration(
            color: DT.c.surface,
            borderRadius: BorderRadius.circular(DT.r.md),
            boxShadow: DT.e.card,
          ),
          child: Column(
            children: [
              // Edit Profile Option
              _buildSettingsOption(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: _navigateToEditProfile,
              ),

              Divider(color: DT.c.divider),

              // Change Password Option
              _buildSettingsOption(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: _navigateToEditProfile,
              ),

              Divider(color: DT.c.divider),

              // Privacy Settings Option
              _buildSettingsOption(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Settings',
                subtitle: 'Manage your privacy preferences',
                onTap: () {
                  context.push(privacySettingsRoute);
                },
              ),

              Divider(color: DT.c.divider),

              // Logout Option
              _buildSettingsOption(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                isDestructive: true,
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? DT.c.accentRed : DT.c.text;

    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.r.sm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: DT.s.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DT.s.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DT.r.sm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                  semanticLabel: '$title icon',
                ),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DT.t.body.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: DT.s.xs),
                    Text(
                      subtitle,
                      style: DT.t.bodySmall.copyWith(
                        color: DT.c.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: DT.c.textMuted,
                size: 16,
                semanticLabel: 'Navigate to $title',
              ),
            ],
          ),
        ),
      ),
    );
  }

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
