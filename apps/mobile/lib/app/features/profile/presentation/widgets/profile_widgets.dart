library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_models.dart' as api_models;
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/home_models.dart';
import '../../../../shared/providers/api_providers.dart';
import '../../../../shared/widgets/enhanced_statistics_widget.dart';
import '../../../../shared/widgets/report_card.dart';

/// Profile info card widget
class ProfileInfoCard extends StatelessWidget {
  /// Creates a new [ProfileInfoCard] instance
  const ProfileInfoCard({
    required this.user,
    super.key,
    this.showEditButton = false,
    this.onEditPressed,
  });

  /// The user data
  final api_models.User user;

  /// Whether to show edit button
  final bool showEditButton;

  /// Callback when edit button is pressed
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.lg),
      boxShadow: DT.e.card,
      border: Border.all(color: DT.c.border),
    ),
    child: Column(
      children: [
        ProfileAvatar(imageUrl: user.avatarUrl),
        SizedBox(height: DT.s.md),
        Text(
          user.email,
          style: DT.t.titleLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DT.s.sm),
        Text(
          'User ID: ${user.id}',
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        ),
        SizedBox(height: DT.s.sm),
        Text(
          'Role: ${user.role}',
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        ),
        if (showEditButton) ...[
          SizedBox(height: DT.s.lg),
          ElevatedButton(
            onPressed: onEditPressed,
            child: const Text('Edit Profile'),
          ),
        ],
      ],
    ),
  );
}

/// Profile avatar widget with fallback
class ProfileAvatar extends StatelessWidget {
  /// Creates a new [ProfileAvatar] instance
  const ProfileAvatar({required this.imageUrl, super.key, this.size = 80});

  /// The URL of the avatar image.
  final String? imageUrl;

  /// The size of the avatar.
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: DT.c.brand,
    backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
    child: imageUrl == null ? _buildFallbackIcon() : null,
  );

  Widget _buildFallbackIcon() =>
      Icon(Icons.person, color: Colors.white, size: size * 0.5);
}

/// Profile stats widget with enhanced real-time statistics
class ProfileStatsWidget extends ConsumerWidget {
  /// Creates a new [ProfileStatsWidget] instance
  const ProfileStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const EnhancedStatisticsWidget(compactMode: true);
}

/// Profile tab bar widget
class ProfileTabBar extends StatelessWidget {
  /// Creates a new [ProfileTabBar] instance
  const ProfileTabBar({required this.controller, super.key});

  /// Tab controller
  final TabController controller;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.symmetric(horizontal: DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.xl),
      boxShadow: [
        BoxShadow(
          color: DT.c.brand.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: DT.c.border.withValues(alpha: 0.5)),
    ),
    child: TabBar(
      controller: controller,
      indicatorColor: DT.c.brand,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: DT.c.text,
      unselectedLabelColor: DT.c.textMuted,
      labelStyle: DT.t.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: DT.t.bodyMedium.copyWith(
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(icon: Icon(Icons.schedule_outlined, size: 20), text: 'Active'),
        Tab(icon: Icon(Icons.edit_outlined, size: 20), text: 'Drafts'),
        Tab(icon: Icon(Icons.check_circle_outline, size: 20), text: 'Resolved'),
      ],
    ),
  );
}

/// Profile tab content widget
class ProfileTabContent extends StatelessWidget {
  /// Creates a new [ProfileTabContent] instance
  const ProfileTabContent({
    required this.tabIndex,
    required this.user,
    super.key,
  });

  /// The current tab index
  final int tabIndex;

  /// The user data
  final api_models.User user;

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return _buildActiveReports();
      case 1:
        return _buildDraftReports();
      case 2:
        return _buildResolvedReports();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildActiveReports() => Consumer(
    builder: (context, ref, child) {
      final reportsAsync = ref.watch(userActiveReportsProvider);

      return reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return _buildEmptyState(
              'No Active Reports',
              "You don't have any active reports yet",
              Icons.assignment_outlined,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(DT.s.md),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                report: report,
                onContact: () => _showContactDialog(context, report),
                onViewDetails: () => _navigateToReportDetails(context, report),
              );
            },
          );
        },
        loading: () => _buildLoadingState('Loading active reports...'),
        error: (error, stackTrace) =>
            _buildErrorState('Error loading active reports', error.toString()),
      );
    },
  );

  Widget _buildDraftReports() => Consumer(
    builder: (context, ref, child) {
      final reportsAsync = ref.watch(userDraftReportsProvider);

      return reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return _buildEmptyState(
              'No Draft Reports',
              "You don't have any draft reports",
              Icons.edit_outlined,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(DT.s.md),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                report: report,
                onContact: () => _showContactDialog(context, report),
                onViewDetails: () => _navigateToReportDetails(context, report),
              );
            },
          );
        },
        loading: () => _buildLoadingState('Loading draft reports...'),
        error: (error, stackTrace) =>
            _buildErrorState('Error loading draft reports', error.toString()),
      );
    },
  );

  Widget _buildResolvedReports() => Consumer(
    builder: (context, ref, child) {
      final reportsAsync = ref.watch(userResolvedReportsProvider);

      return reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return _buildEmptyState(
              'No Resolved Reports',
              "You don't have any resolved reports yet",
              Icons.check_circle_outline,
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(DT.s.md),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                report: report,
                onContact: () => _showContactDialog(context, report),
                onViewDetails: () => _navigateToReportDetails(context, report),
              );
            },
          );
        },
        loading: () => _buildLoadingState('Loading resolved reports...'),
        error: (error, stackTrace) => _buildErrorState(
          'Error loading resolved reports',
          error.toString(),
        ),
      );
    },
  );

  Widget _buildEmptyState(String title, String subtitle, IconData icon) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: DT.c.textMuted),
            SizedBox(height: DT.s.md),
            Text(
              title,
              style: DT.t.titleMedium.copyWith(color: DT.c.textMuted),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              subtitle,
              style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLoadingState(String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: DT.c.brand),
        SizedBox(height: DT.s.md),
        Text(message, style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted)),
      ],
    ),
  );

  Widget _buildErrorState(String title, String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: DT.c.accentRed),
        SizedBox(height: DT.s.md),
        Text(title, style: DT.t.titleMedium.copyWith(color: DT.c.accentRed)),
        SizedBox(height: DT.s.sm),
        Text(
          message,
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  void _showContactDialog(BuildContext context, ReportItem report) {
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

  void _navigateToReportDetails(BuildContext context, ReportItem report) {
    // Navigate to report details screen
    Navigator.of(context).pushNamed('/report-detail/${report.id}');
  }
}

/// Profile edit form widget
class ProfileEditForm extends StatefulWidget {
  /// Creates a new [ProfileEditForm] instance
  const ProfileEditForm({required this.user, required this.onSave, super.key});

  /// The user data
  final api_models.User user;

  /// Callback when form is saved
  final void Function(api_models.User) onSave;

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.email);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(DT.s.lg),
    child: Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
            ),
          ),
        ),
        SizedBox(height: DT.s.md),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
            ),
          ),
        ),
        SizedBox(height: DT.s.md),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
            ),
          ),
        ),
        SizedBox(height: DT.s.lg),
        ElevatedButton(
          onPressed: _saveProfile,
          child: const Text('Save Profile'),
        ),
      ],
    ),
  );

  void _saveProfile() {
    final updatedUser = api_models.User(
      id: widget.user.id,
      email: _emailController.text,
      isActive: widget.user.isActive,
      role: widget.user.role,
      createdAt: widget.user.createdAt,
    );
    widget.onSave(updatedUser);
  }
}

/// Profile date formatter utility
class ProfileDateFormatter {
  /// Private constructor to prevent instantiation
  ProfileDateFormatter._();

  /// Format date for display
  static String formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }
}
