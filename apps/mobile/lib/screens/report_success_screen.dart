import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../core/routing/app_routes.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final type = args?['type'] ?? 'lost';
    final title = args?['title'] ?? 'Item';

    final isLost = type == 'lost';
    final icon = isLost
        ? Icons.search_off_rounded
        : Icons.check_circle_outline_rounded;
    final color = isLost ? DT.c.dangerFg : DT.c.successFg;
    final bgColor = isLost ? DT.c.dangerBg : DT.c.successBg;
    final mainText = isLost ? 'Lost Item Reported' : 'Found Item Reported';
    final subText = isLost
        ? 'We\'ll help you find your $title'
        : 'We\'ll help reunite this $title with its owner';

    return Scaffold(
      backgroundColor: DT.c.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DT.s.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Animation
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, size: 100, color: color),
              ),

              SizedBox(height: DT.s.xl),

              // Success Text
              Text(
                mainText,
                style: DT.t.h1.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: DT.s.md),

              Text(
                subText,
                style: DT.t.bodyLarge.copyWith(color: DT.c.textMuted),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: DT.s.xl),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (route) => false,
                        );
                      },
                      child: const Text('Go to Home'),
                    ),
                  ),

                  SizedBox(height: DT.s.md),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          isLost ? AppRoutes.reportLost : AppRoutes.reportFound,
                        );
                      },
                      child: Text(
                        'Report Another ${isLost ? 'Lost' : 'Found'} Item',
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: DT.s.xl),

              // Tips Section
              Container(
                padding: EdgeInsets.all(DT.s.lg),
                decoration: BoxDecoration(
                  color: DT.c.blueTint,
                  borderRadius: BorderRadius.circular(DT.r.lg),
                  border: Border.all(color: DT.c.brand.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: DT.c.brand),
                        SizedBox(width: DT.s.sm),
                        Text(
                          'What\'s Next?',
                          style: DT.t.title.copyWith(color: DT.c.brand),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.md),
                    _buildTipItem(
                      'Check your matches regularly',
                      Icons.search_rounded,
                    ),
                    _buildTipItem(
                      'Respond to messages quickly',
                      Icons.message_rounded,
                    ),
                    _buildTipItem(
                      'Update your report if needed',
                      Icons.edit_rounded,
                    ),
                    if (isLost)
                      _buildTipItem(
                        'Consider offering a reward',
                        Icons.card_giftcard_rounded,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        children: [
          Icon(icon, color: DT.c.brand, size: 18),
          SizedBox(width: DT.s.sm),
          Expanded(
            child: Text(text, style: DT.t.body.copyWith(color: DT.c.text)),
          ),
        ],
      ),
    );
  }
}
