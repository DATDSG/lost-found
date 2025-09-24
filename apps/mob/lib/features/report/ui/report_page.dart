import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'report_wizard_page.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.xl),
        children: [
          Text('What would you like to report?', style: DT.t.h1.copyWith(fontSize: 22)),
          SizedBox(height: DT.s.xl),

          _BigChoiceCard(
            imageAsset: 'assets/images/Lost.jpg', // real photo (add to assets)
            title: 'Lost',
            subtitle: "Report an item you've lost",
            button: 'Select',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportWizardPage(type: ReportType.lost)),
            ),
          ),

          SizedBox(height: DT.s.xl),

          _BigChoiceCard(
            imageAsset: 'assets/images/Found.jpg', // real photo (add to assets)
            title: 'Found',
            subtitle: "Report an item you've found",
            button: 'Select',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportWizardPage(type: ReportType.found)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigChoiceCard extends StatelessWidget {
  final String imageAsset, title, subtitle, button;
  final VoidCallback onTap;
  const _BigChoiceCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: DT.e.card,
      ),
      child: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFEAEFF6),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_rounded, size: 48, color: Color(0xFF8C96A4)),
                  ),
                ),
              ),
            ),
            SizedBox(height: DT.s.lg),
            Text(title, style: DT.t.h1.copyWith(fontSize: 22)),
            SizedBox(height: DT.s.xs),
            Text(subtitle, style: DT.t.body.copyWith(color: DT.c.brand)),
            SizedBox(height: DT.s.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  backgroundColor: DT.c.blueTint,
                  foregroundColor: DT.c.brand,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(button, style: DT.t.body.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
