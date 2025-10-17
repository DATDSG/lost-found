import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class MatchesDetailPage extends StatefulWidget {
  final String reportId;

  const MatchesDetailPage({super.key, required this.reportId});

  @override
  State<MatchesDetailPage> createState() => _MatchesDetailPageState();
}

class _MatchesDetailPageState extends State<MatchesDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        backgroundColor: DT.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DT.c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(DT.s.lg),
              decoration: BoxDecoration(
                color: DT.c.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.lg),
                border: Border.all(color: DT.c.brand.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics_rounded, size: 48, color: DT.c.brand),
                  SizedBox(width: DT.s.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matching Analysis',
                          style: DT.t.title.copyWith(
                            color: DT.c.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: DT.s.xs),
                        Text(
                          'AI-powered matching for your report',
                          style: DT.t.body.copyWith(
                            color: DT.c.brand.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: DT.s.lg),

            // Match Score Section
            _buildMatchScoreSection(),

            SizedBox(height: DT.s.lg),

            // Potential Matches Section
            _buildPotentialMatchesSection(),

            SizedBox(height: DT.s.lg),

            // Matching Criteria Section
            _buildMatchingCriteriaSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchScoreSection() {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Match Score',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: DT.s.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '85%',
                      style: DT.t.title.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: DT.c.successFg,
                      ),
                    ),
                    SizedBox(height: DT.s.xs),
                    Text(
                      'High Confidence',
                      style: DT.t.body.copyWith(
                        color: DT.c.successFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      value: 0.85,
                      backgroundColor: DT.c.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(DT.c.successFg),
                      strokeWidth: 8,
                    ),
                    SizedBox(height: DT.s.sm),
                    Text(
                      'Based on 12 factors',
                      style: DT.t.body.copyWith(
                        color: DT.c.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPotentialMatchesSection() {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, color: DT.c.brand),
              SizedBox(width: DT.s.sm),
              Text(
                'Potential Matches',
                style: DT.t.title.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: DT.s.md),
          Text(
            '8 potential matches found',
            style: DT.t.body.copyWith(color: DT.c.textMuted),
          ),
          SizedBox(height: DT.s.md),
          _buildMatchItem('Black iPhone 13', 'Found 2 days ago', 0.92),
          _buildMatchItem(
            'Lost iPhone near Central Park',
            'Lost 1 week ago',
            0.78,
          ),
          _buildMatchItem(
            'iPhone with cracked screen',
            'Found 3 days ago',
            0.65,
          ),
          SizedBox(height: DT.s.sm),
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to full matches list
              },
              child: Text(
                'View All Matches',
                style: DT.t.body.copyWith(
                  color: DT.c.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(String title, String subtitle, double score) {
    final scoreColor = score >= 0.8
        ? DT.c.successFg
        : score >= 0.6
        ? DT.c.brand
        : DT.c.dangerFg;

    return Container(
      margin: EdgeInsets.only(bottom: DT.s.sm),
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DT.r.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: DT.s.xs),
                Text(
                  subtitle,
                  style: DT.t.body.copyWith(
                    color: DT.c.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(score * 100).toInt()}%',
              style: DT.t.label.copyWith(
                color: scoreColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingCriteriaSection() {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: DT.c.brand),
              SizedBox(width: DT.s.sm),
              Text(
                'Matching Criteria',
                style: DT.t.title.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: DT.s.md),
          _buildCriteriaItem('Description Similarity', 0.88, DT.c.successFg),
          _buildCriteriaItem('Location Proximity', 0.75, DT.c.brand),
          _buildCriteriaItem('Time Relevance', 0.65, DT.c.brand),
          _buildCriteriaItem('Category Match', 0.92, DT.c.successFg),
          _buildCriteriaItem('Visual Similarity', 0.45, DT.c.dangerFg),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String label, double score, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: DT.t.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(width: DT.s.md),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: DT.c.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          SizedBox(width: DT.s.sm),
          Text(
            '${(score * 100).toInt()}%',
            style: DT.t.label.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
