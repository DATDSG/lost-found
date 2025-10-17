import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/animations/page_transitions.dart';
import '../../../providers/auth_provider.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DT.s.lg,
              DT.s.lg,
              DT.s.lg,
              DT.s.xxl + 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Item', style: DT.t.h1),
                SizedBox(height: DT.s.sm),
                Text(
                  'Help reunite people with their belongings',
                  style: DT.t.bodyMuted.copyWith(fontSize: 15),
                ),
                SizedBox(height: DT.s.xl),

                // Show authentication message if not logged in
                if (!authProvider.isAuthenticated) ...[
                  Container(
                    padding: EdgeInsets.all(DT.s.lg),
                    decoration: BoxDecoration(
                      color: DT.c.blueTint,
                      borderRadius: BorderRadius.circular(DT.r.lg),
                      border: Border.all(
                        color: DT.c.brand.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: DT.c.brand, size: 32),
                        SizedBox(height: DT.s.md),
                        Text(
                          'Please log in to report items',
                          style: DT.t.title.copyWith(color: DT.c.brand),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: DT.s.sm),
                        Text(
                          'You need to be logged in to create reports and help others find their belongings.',
                          style: DT.t.body.copyWith(color: DT.c.text),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: DT.s.lg),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.login);
                          },
                          child: const Text('Log In'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: DT.s.xl),
                ],

                // Report Type Cards
                AnimatedListItem(
                  index: 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ReportTypeCard(
                          icon: Icons.search_off_rounded,
                          title: 'Lost',
                          subtitle: 'I lost something',
                          color: DT.c.dangerFg,
                          bgColor: DT.c.dangerBg,
                          onTap: () {
                            if (authProvider.isAuthenticated) {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.reportLost);
                            } else {
                              Navigator.of(context).pushNamed(AppRoutes.login);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: DT.s.md),
                      Expanded(
                        child: _ReportTypeCard(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Found',
                          subtitle: 'I found something',
                          color: DT.c.successFg,
                          bgColor: DT.c.successBg,
                          onTap: () {
                            if (authProvider.isAuthenticated) {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.reportFound);
                            } else {
                              Navigator.of(context).pushNamed(AppRoutes.login);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: DT.s.xl),

                // Quick Tips
                AnimatedListItem(
                  index: 1,
                  child: Container(
                    padding: EdgeInsets.all(DT.s.lg),
                    decoration: BoxDecoration(
                      color: DT.c.blueTint,
                      borderRadius: BorderRadius.circular(DT.r.lg),
                      border: Border.all(
                        color: DT.c.brand.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: DT.c.brand,
                              size: 24,
                            ),
                            SizedBox(width: DT.s.sm),
                            Text(
                              'Quick Tips',
                              style: DT.t.title.copyWith(color: DT.c.brand),
                            ),
                          ],
                        ),
                        SizedBox(height: DT.s.md),
                        _TipItem('Add clear photos for better matches'),
                        _TipItem('Provide accurate location details'),
                        _TipItem('Include distinctive features'),
                        _TipItem('Check back regularly for updates'),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: DT.s.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DT.r.lg),
        child: Container(
          padding: EdgeInsets.all(DT.s.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DT.r.lg),
            boxShadow: [
              BoxShadow(
                color: DT.c.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(DT.s.md),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(height: DT.s.md),
              Text(
                title,
                style: DT.t.title.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              SizedBox(height: DT.s.xs),
              Text(
                subtitle,
                style: DT.t.body.copyWith(fontSize: 12, color: DT.c.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: DT.c.successFg, size: 18),
          SizedBox(width: DT.s.sm),
          Expanded(
            child: Text(
              text,
              style: DT.t.body.copyWith(fontSize: 14, color: DT.c.text),
            ),
          ),
        ],
      ),
    );
  }
}
