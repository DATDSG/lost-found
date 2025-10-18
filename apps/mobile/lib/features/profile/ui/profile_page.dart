import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/routing/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/reports_provider.dart';
import '../../../core/animations/page_transitions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<AuthProvider, ReportsProvider>(
        builder: (context, authProvider, reportsProvider, _) {
          final user = authProvider.user;
          final myReports = reportsProvider.myReports;

          // Calculate stats
          final activeReports = myReports
              .where((r) => r.status == 'approved' && !r.isResolved)
              .length;
          final resolvedReports = myReports.where((r) => r.isResolved).length;
          final pendingReports =
              myReports.where((r) => r.status == 'pending').length;
          final draftReports =
              myReports.where((r) => r.status == 'draft').length;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              DT.s.lg,
              DT.s.lg,
              DT.s.lg,
              DT.s.xxl + 80,
            ),
            children: [
              // Profile Header with UI Design
              AnimatedListItem(
                index: 0,
                child: Container(
                  padding: EdgeInsets.all(DT.s.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [DT.c.brand, DT.c.brandDeep],
                    ),
                    borderRadius: BorderRadius.circular(DT.r.lg),
                    boxShadow: [
                      BoxShadow(
                        color: DT.c.brand.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with UI design
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: DT.c.brand,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: DT.c.brand,
                              ),
                      ),
                      SizedBox(height: DT.s.md),
                      Text(
                        user?.displayName ?? 'Loading...',
                        style: DT.t.h1.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(height: DT.s.xs),
                      Text(
                        user?.email ?? '',
                        style: DT.t.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: DT.s.lg),
                      // Enhanced Stats with UI images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                            '$activeReports',
                            'Active',
                            Icons.pending_actions_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          _StatItem(
                            '$resolvedReports',
                            'Resolved',
                            Icons.check_circle_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          _StatItem(
                            '$pendingReports',
                            'Pending',
                            Icons.pending_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: DT.s.xl),

              // My Items Section with UI Design
              AnimatedListItem(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 24,
                          color: DT.c.brand,
                        ),
                        SizedBox(width: DT.s.sm),
                        Text(
                          'My Items',
                          style: DT.t.title.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.md),
                  ],
                ),
              ),
              AnimatedListItem(
                index: 2,
                child: _MenuItem(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Active Reports',
                  subtitle: '$activeReports items',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.myItems, arguments: 'active');
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 3,
                child: _MenuItem(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Resolved Items',
                  subtitle: '$resolvedReports items',
                  color: DT.c.successFg,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.myItems, arguments: 'resolved');
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 4,
                child: _MenuItem(
                  icon: Icons.edit_note_rounded,
                  title: 'Pending Reports',
                  subtitle: '$pendingReports items',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.myItems, arguments: 'pending');
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 5,
                child: _MenuItem(
                  icon: Icons.edit_note_rounded,
                  title: 'Draft Reports',
                  subtitle: '$draftReports items',
                  color: DT.c.textMuted,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.myItems, arguments: 'drafts');
                  },
                ),
              ),

              SizedBox(height: DT.s.xl),

              // Settings Section with UI Design
              AnimatedListItem(
                index: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          size: 24,
                          color: DT.c.brand,
                        ),
                        SizedBox(width: DT.s.sm),
                        Text(
                          'Settings',
                          style: DT.t.title.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.md),
                  ],
                ),
              ),
              AnimatedListItem(
                index: 7,
                child: _MenuItem(
                  icon: Icons.edit_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.editProfile);
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 8,
                child: _MenuItem(
                  icon: Icons.settings_rounded,
                  title: 'App Settings',
                  subtitle: 'Notifications, privacy, and more',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.settings);
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 9,
                child: _MenuItem(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  color: DT.c.brand,
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeThumbColor: DT.c.brand,
                  ),
                  onTap: () {},
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 10,
                child: _MenuItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.languageSettings);
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 11,
                child: _MenuItem(
                  icon: Icons.security_rounded,
                  title: 'Privacy & Security',
                  subtitle: 'Control your data and privacy',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.privacySettings);
                  },
                ),
              ),

              SizedBox(height: DT.s.xl),

              // Support Section with UI Design
              AnimatedListItem(
                index: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: DT.c.brand,
                          size: 24,
                        ),
                        SizedBox(width: DT.s.sm),
                        Text(
                          'Support',
                          style: DT.t.title.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.md),
                  ],
                ),
              ),
              AnimatedListItem(
                index: 13,
                child: _MenuItem(
                  icon: Icons.help_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  color: DT.c.brand,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.support);
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 14,
                child: _MenuItem(
                  icon: Icons.info_rounded,
                  title: 'About',
                  subtitle: 'App version and information',
                  color: DT.c.textMuted,
                  onTap: () {
                    Navigator.of(context).pushNamed('/about');
                  },
                ),
              ),
              SizedBox(height: DT.s.sm),
              AnimatedListItem(
                index: 15,
                child: _MenuItem(
                  icon: Icons.feedback_rounded,
                  title: 'Send Feedback',
                  subtitle: 'Help us improve the app',
                  color: DT.c.successFg,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.feedback);
                  },
                ),
              ),

              SizedBox(height: DT.s.xl),

              // Logout Button
              AnimatedListItem(
                index: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: DT.c.dangerBg,
                    borderRadius: BorderRadius.circular(DT.r.md),
                    border: Border.all(
                      color: DT.c.dangerFg.withValues(alpha: 0.3),
                    ),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.landing);
                    },
                    borderRadius: BorderRadius.circular(DT.r.md),
                    child: Padding(
                      padding: EdgeInsets.all(DT.s.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: DT.c.dangerFg,
                            size: 20,
                          ),
                          SizedBox(width: DT.s.sm),
                          Text(
                            'Log Out',
                            style: DT.t.body.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DT.c.dangerFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 24, color: DT.c.brand),
        ),
        SizedBox(height: DT.s.xs),
        Text(value, style: DT.t.h1.copyWith(color: Colors.white, fontSize: 20)),
        Text(
          label,
          style: DT.t.body.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.md),
        boxShadow: [
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.r.md),
        child: Padding(
          padding: EdgeInsets.all(DT.s.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DT.s.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DT.t.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DT.c.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: DT.t.body.copyWith(
                          fontSize: 12,
                          color: DT.c.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: DT.c.textMuted,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
