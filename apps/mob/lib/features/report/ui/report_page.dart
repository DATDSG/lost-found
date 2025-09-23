import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'report_wizard_stub.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  void _openWizard(BuildContext context, ReportType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportWizardStub(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: DT.scroll,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.xl, DT.s.lg, DT.s.lg),
            child: Text(
              'What would you like to report?',
              style: DT.t.h1.copyWith(fontSize: 24),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
          sliver: SliverList.list(children: [
            _ReportCard(
              title: 'Lost',
              subtitle: "Report an item you've lost",
              image: const AssetImage('assets/images/Lost.png'),
              onSelect: () => _openWizard(context, ReportType.lost),
            ),
            SizedBox(height: DT.s.xl),
            _ReportCard(
              title: 'Found',
              subtitle: "Report an item you've found",
              image: const AssetImage('assets/images/Found.png'),
              onSelect: () => _openWizard(context, ReportType.found),
            ),
            const SizedBox(height: 96),
          ]),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final ImageProvider image;
  final VoidCallback onSelect;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DT.c.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onSelect,
        child: Padding(
          padding: EdgeInsets.all(DT.s.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustration from asset
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image(
                    image: image,
                    fit: BoxFit.cover,
                    // Fallback if asset missing (prevents red screen)
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEFF3F7),
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: DT.c.textMuted, size: 42),
                    ),
                  ),
                ),
              ),
              SizedBox(height: DT.s.lg),
              Text(title, style: DT.t.h1.copyWith(fontSize: 22)),
              SizedBox(height: DT.s.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: DT.t.body.copyWith(
                        color: DT.c.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DT.c.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: DT.s.xl, vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
