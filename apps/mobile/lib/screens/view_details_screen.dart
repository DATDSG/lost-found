import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

class ViewDetailsScreen extends StatelessWidget {
  final String reportId;
  final String reportType; // 'lost' or 'found'
  final Map<String, dynamic>? reportData;

  const ViewDetailsScreen({
    super.key,
    required this.reportId,
    required this.reportType,
    this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from API
    final reportData = this.reportData ?? _getMockReportData();
    final isLost = reportType == 'lost';

    return Scaffold(
      backgroundColor: DT.c.background,
      appBar: AppBar(
        backgroundColor: DT.c.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isLost ? 'Lost Item Details' : 'Found Item Details',
          style: DT.t.title.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Container(
              width: double.infinity,
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
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DT.s.sm,
                          vertical: DT.s.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isLost ? DT.c.dangerFg : DT.c.successFg,
                          borderRadius: BorderRadius.circular(DT.r.sm),
                        ),
                        child: Text(
                          isLost ? 'LOST' : 'FOUND',
                          style: DT.t.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        reportData['date'] ?? 'Unknown date',
                        style: DT.t.body.copyWith(
                          color: DT.c.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DT.s.md),
                  Text(
                    reportData['title'] ?? 'Unknown Item',
                    style: DT.t.h1.copyWith(fontSize: 24),
                  ),
                  SizedBox(height: DT.s.sm),
                  Text(
                    reportData['description'] ?? 'No description provided',
                    style: DT.t.body.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),

            SizedBox(height: DT.s.lg),

            // Item Details
            _buildSection('Item Details', [
              _buildDetailRow('Category', reportData['category'] ?? 'Unknown'),
              _buildDetailRow('Brand', reportData['brand'] ?? 'Unknown'),
              _buildDetailRow('Color', reportData['color'] ?? 'Unknown'),
              _buildDetailRow(
                'Condition',
                reportData['condition'] ?? 'Unknown',
              ),
              _buildDetailRow('Value', reportData['value'] ?? 'Unknown'),
            ]),

            SizedBox(height: DT.s.lg),

            // Location Details
            _buildSection('Location', [
              _buildDetailRow(
                'Address',
                reportData['address'] ?? 'Not specified',
              ),
              _buildDetailRow('City', reportData['city'] ?? 'Unknown'),
              _buildDetailRow('State', reportData['state'] ?? 'Unknown'),
              _buildDetailRow('Landmark', reportData['landmark'] ?? 'None'),
            ]),

            SizedBox(height: DT.s.lg),

            // Contact Information
            _buildSection('Contact Information', [
              _buildDetailRow(
                'Name',
                reportData['reporterName'] ?? 'Anonymous',
              ),
              _buildDetailRow('Phone', reportData['phone'] ?? 'Not provided'),
              _buildDetailRow('Email', reportData['email'] ?? 'Not provided'),
              _buildDetailRow(
                'Preferred Contact',
                reportData['preferredContact'] ?? 'Any',
              ),
            ]),

            SizedBox(height: DT.s.xxl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(DT.s.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: DT.c.shadow.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _contactReporter(context),
                icon: const Icon(Icons.message_rounded),
                label: const Text('Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DT.c.brand,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: DT.s.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.r.lg),
                  ),
                ),
              ),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _saveReport(context),
                icon: const Icon(Icons.bookmark_outline_rounded),
                label: const Text('Save'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DT.c.brand,
                  side: BorderSide(color: DT.c.brand),
                  padding: EdgeInsets.symmetric(vertical: DT.s.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DT.r.lg),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          Text(title, style: DT.t.title.copyWith(fontSize: 18)),
          SizedBox(height: DT.s.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: DT.t.body.copyWith(
                color: DT.c.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: DT.t.body)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMockReportData() {
    return {
      'title': 'Black Backpack',
      'description':
          'A black backpack with multiple compartments. Contains laptop charger, notebook, and some personal items. Lost near the university campus.',
      'category': 'Bag',
      'brand': 'Unknown',
      'color': 'Black',
      'condition': 'Good',
      'value': '\$50-100',
      'reporterName': 'John Doe',
      'phone': '+1 (555) 123-4567',
      'email': 'john.doe@email.com',
      'preferredContact': 'Phone',
      'address': '123 University Ave',
      'city': 'Boston',
      'state': 'MA',
      'zipCode': '02115',
      'landmark': 'Near Starbucks',
      'status': 'Active',
      'lastUpdated': '2 hours ago',
      'views': 45,
      'date': '2 hours ago',
      'images': [],
    };
  }

  void _contactReporter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact feature coming soon!'),
        backgroundColor: DT.c.brand,
      ),
    );
  }

  void _saveReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report saved successfully!'),
        backgroundColor: DT.c.successFg,
      ),
    );
  }

  void _shareReport() {
    // Share functionality
  }
}
