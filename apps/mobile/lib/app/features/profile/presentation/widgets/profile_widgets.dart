/// Reusable profile widgets and components
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_models.dart' as api_models;
import '../../../../core/theme/design_tokens.dart';
import '../../data/providers/profile_providers.dart';
import '../../domain/models/profile_models.dart';

/// Profile avatar widget with fallback
class ProfileAvatar extends StatelessWidget {
  /// Creates a new [ProfileAvatar] instance
  const ProfileAvatar({
    required this.user,
    super.key,
    this.size = 80,
    this.showBorder = true,
  });

  /// User data
  final api_models.User user;

  /// Avatar size
  final double size;

  /// Whether to show border
  final bool showBorder;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: DT.c.brand,
      borderRadius: BorderRadius.circular(DT.r.full),
      border: showBorder ? Border.all(color: DT.c.border, width: 2) : null,
      boxShadow: showBorder ? DT.e.sm : null,
    ),
    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(DT.r.full),
            child: Image.network(
              user.avatarUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackIcon(),
            ),
          )
        : _buildFallbackIcon(),
  );

  Widget _buildFallbackIcon() =>
      Icon(Icons.person, color: Colors.white, size: size * 0.5);
}

/// Profile stats widget
class ProfileStatsWidget extends ConsumerWidget {
  /// Creates a new [ProfileStatsWidget] instance
  const ProfileStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);

    return statsAsync.when(
      data: _buildStatsGrid,
      loading: _buildLoadingStats,
      error: (error, stackTrace) => _buildErrorStats(),
    );
  }

  Widget _buildStatsGrid(ProfileStats stats) => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.lg),
      boxShadow: DT.e.card,
      border: Border.all(color: DT.c.border),
    ),
    child: Column(
      children: [
        // First row with primary stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              title: '${stats.totalReports}',
              subtitle: 'Total Reports',
              color: DT.c.brand,
              icon: Icons.description_outlined,
            ),
            _buildStatItem(
              title: '${stats.activeReports}',
              subtitle: 'Active',
              color: DT.c.accentOrange,
              icon: Icons.schedule_outlined,
            ),
            _buildStatItem(
              title: '${stats.resolvedReports}',
              subtitle: 'Resolved',
              color: DT.c.accentGreen,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        SizedBox(height: DT.s.lg),
        // Second row with secondary stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              title: '${stats.matchesFound}',
              subtitle: 'Matches Found',
              color: DT.c.accentPurple,
              icon: Icons.search_outlined,
            ),
            _buildStatItem(
              title: '${stats.successfulMatches}',
              subtitle: 'Successful',
              color: DT.c.accentTeal,
              icon: Icons.handshake_outlined,
            ),
            _buildStatItem(
              title: '${stats.draftReports}',
              subtitle: 'Drafts',
              color: DT.c.textMuted,
              icon: Icons.edit_outlined,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildStatItem({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) => Semantics(
    label: '$title $subtitle',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(DT.s.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DT.r.md),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
            semanticLabel: '$subtitle icon',
          ),
        ),
        SizedBox(height: DT.s.sm),
        Text(
          title,
          style: DT.t.headline3.copyWith(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: DT.s.xs),
        Text(
          subtitle,
          style: DT.t.bodySmall.copyWith(
            color: DT.c.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _buildLoadingStats() => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(DT.r.md),
      boxShadow: DT.e.card,
    ),
    child: Center(child: CircularProgressIndicator(color: DT.c.brand)),
  );

  Widget _buildErrorStats() => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(DT.r.md),
      boxShadow: DT.e.card,
      border: Border.all(color: DT.c.border),
    ),
    child: Column(
      children: [
        Icon(Icons.error_outline, color: DT.c.accentRed, size: 32),
        SizedBox(height: DT.s.sm),
        Text(
          'Unable to load statistics',
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        ),
      ],
    ),
  );
}

/// Profile action button widget
class ProfileActionButton extends StatelessWidget {
  /// Creates a new [ProfileActionButton] instance
  const ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.isDestructive = false,
    this.isLoading = false,
  });

  /// Button icon
  final IconData icon;

  /// Button label
  final String label;

  /// Button onPressed callback
  final VoidCallback onPressed;

  /// Whether this is a destructive action
  final bool isDestructive;

  /// Whether button is in loading state
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? DT.c.accentRed : DT.c.brand;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: EdgeInsets.symmetric(vertical: DT.s.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.r.sm),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  SizedBox(width: DT.s.sm),
                  Text(label, style: DT.t.button.copyWith(color: color)),
                ],
              ),
      ),
    );
  }
}

/// Profile info card widget
class ProfileInfoCard extends StatelessWidget {
  /// Creates a new [ProfileInfoCard] instance
  const ProfileInfoCard({
    required this.user,
    super.key,
    this.showEditButton = false,
    this.onEditPressed,
  });

  /// User data
  final api_models.User user;

  /// Whether to show edit button
  final bool showEditButton;

  /// Edit button callback
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(DT.s.xl),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.xl),
      boxShadow: DT.e.card,
      border: Border.all(color: DT.c.border),
    ),
    child: Column(
      children: [
        // Profile Avatar with enhanced styling
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: DT.e.lg,
            border: Border.all(color: DT.c.brand, width: 3),
          ),
          child: ProfileAvatar(user: user, size: 100),
        ),

        SizedBox(height: DT.s.lg),

        // User Info with better typography
        Text(
          user.displayName ?? 'User',
          style: DT.t.titleLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: DT.s.sm),

        Text(
          user.email,
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted, fontSize: 16),
          textAlign: TextAlign.center,
        ),

        if (user.phoneNumber != null) ...[
          SizedBox(height: DT.s.xs),
          Text(
            user.phoneNumber!,
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.textMuted,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        SizedBox(height: DT.s.lg),

        // Member since with enhanced styling
        Container(
          padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.md),
          decoration: BoxDecoration(
            color: DT.c.brandSubtle,
            borderRadius: BorderRadius.circular(DT.r.lg),
            border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                color: DT.c.brand,
                size: 16,
                semanticLabel: 'Member since icon',
              ),
              SizedBox(width: DT.s.sm),
              Text(
                'Member since ${_formatDate(user.createdAt)}',
                style: DT.t.bodySmall.copyWith(
                  color: DT.c.brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        if (showEditButton && onEditPressed != null) ...[
          SizedBox(height: DT.s.lg),
          ProfileActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onPressed: onEditPressed!,
          ),
        ],
      ],
    ),
  );

  String _formatDate(DateTime date) {
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
      boxShadow: DT.e.card,
      border: Border.all(color: DT.c.border),
    ),
    child: TabBar(
      controller: controller,
      indicator: BoxDecoration(
        color: DT.c.brand,
        borderRadius: BorderRadius.circular(DT.r.xl),
        boxShadow: DT.e.sm,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: DT.c.textOnBrand,
      unselectedLabelColor: DT.c.textMuted,
      labelStyle: DT.t.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: DT.t.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(icon: Icon(Icons.schedule_outlined, size: 18), text: 'Active'),
        Tab(icon: Icon(Icons.edit_outlined, size: 18), text: 'Drafts'),
        Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Settings'),
        Tab(icon: Icon(Icons.check_circle_outline, size: 18), text: 'Resolved'),
      ],
    ),
  );
}
