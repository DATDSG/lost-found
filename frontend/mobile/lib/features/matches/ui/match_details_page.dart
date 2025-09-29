import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/models/item.dart';
import '../../../core/models/match.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../claims/ui/create_claim_page.dart';
import '../../messages/ui/chat_thread_page.dart';
import '../../messages/ui/data/chat_models.dart';

class MatchDetailsPage extends StatefulWidget {
  final Item sourceItem;
  final ItemMatch match;

  const MatchDetailsPage({
    super.key,
    required this.sourceItem,
    required this.match,
  });

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showFullExplanation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: Text('Match Details', style: DT.t.h2),
        backgroundColor: DT.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.compare), text: 'Compare'),
            Tab(icon: Icon(Icons.analytics), text: 'Score'),
            Tab(icon: Icon(Icons.map), text: 'Location'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompareTab(),
          _buildScoreTab(),
          _buildLocationTab(),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildCompareTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchHeader(),
          SizedBox(height: DT.s.xl),
          _buildItemComparison(),
          SizedBox(height: DT.s.xl),
          _buildAttributeComparison(),
        ],
      ),
    );
  }

  Widget _buildScoreTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallScore(),
          SizedBox(height: DT.s.xl),
          _buildScoreBreakdown(),
          SizedBox(height: DT.s.xl),
          _buildExplanation(),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                widget.sourceItem.location.latitude,
                widget.sourceItem.location.longitude,
              ),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lostfound',
              ),
              MarkerLayer(
                markers: [
                  // Source item marker
                  Marker(
                    point: LatLng(
                      widget.sourceItem.location.latitude,
                      widget.sourceItem.location.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.sourceItem.type == ItemType.lost 
                            ? DT.c.danger 
                            : DT.c.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        widget.sourceItem.type == ItemType.lost 
                            ? Icons.search 
                            : Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // Matched item marker
                  Marker(
                    point: LatLng(
                      widget.match.matchedItem.location.latitude,
                      widget.match.matchedItem.location.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.match.matchedItem.type == ItemType.lost 
                            ? DT.c.danger 
                            : DT.c.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        widget.match.matchedItem.type == ItemType.lost 
                            ? Icons.search 
                            : Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(DT.s.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance Analysis', style: DT.t.h3),
              SizedBox(height: DT.s.md),
              Row(
                children: [
                  Icon(Icons.straighten, color: DT.c.brand),
                  SizedBox(width: DT.s.sm),
                  Text(
                    '${widget.match.explanation.distanceKm.toStringAsFixed(1)} km apart',
                    style: DT.t.title,
                  ),
                ],
              ),
              SizedBox(height: DT.s.sm),
              Text(
                'Items are within reasonable distance for a match',
                style: DT.t.body.copyWith(color: DT.c.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchHeader() {
    final confidence = _getConfidenceLevel(widget.match.score.total);
    return Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            confidence.color.withValues(alpha: 0.1),
            confidence.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: confidence.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
                decoration: BoxDecoration(
                  color: confidence.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  confidence.label,
                  style: DT.t.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(widget.match.score.total * 100).round()}%',
                style: DT.t.h1.copyWith(
                  color: confidence.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: DT.s.md),
          Text(
            widget.match.explanation.summary,
            style: DT.t.body.copyWith(color: DT.c.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Comparison', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildItemCard(widget.sourceItem, 'Your Item')),
            SizedBox(width: DT.s.md),
            Expanded(child: _buildItemCard(widget.match.matchedItem, 'Potential Match')),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(Item item, String label) {
    return Container(
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DT.c.blueTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DT.t.caption.copyWith(
              color: DT.c.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: DT.s.sm),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: DT.c.blueTint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.images.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, color: DT.c.textMuted);
                      },
                    ),
                  )
                : Icon(Icons.image, color: DT.c.textMuted),
          ),
          SizedBox(height: DT.s.sm),
          Text(
            item.title,
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DT.s.xs),
          Container(
            padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: 2),
            decoration: BoxDecoration(
              color: item.type == ItemType.lost 
                  ? DT.c.danger.withValues(alpha: 0.1)
                  : DT.c.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.type == ItemType.lost ? 'LOST' : 'FOUND',
              style: DT.t.caption.copyWith(
                color: item.type == ItemType.lost ? DT.c.danger : DT.c.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attribute Comparison', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        _buildAttributeRow('Category', widget.sourceItem.category, widget.match.matchedItem.category),
        _buildAttributeRow('Brand', widget.sourceItem.brand ?? 'Not specified', widget.match.matchedItem.brand ?? 'Not specified'),
        _buildAttributeRow('Color', widget.sourceItem.color ?? 'Not specified', widget.match.matchedItem.color ?? 'Not specified'),
        _buildAttributeRow('Model', widget.sourceItem.model ?? 'Not specified', widget.match.matchedItem.model ?? 'Not specified'),
      ],
    );
  }

  Widget _buildAttributeRow(String attribute, String value1, String value2) {
    final isMatch = value1.toLowerCase() == value2.toLowerCase();
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.sm),
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: isMatch ? DT.c.success.withValues(alpha: 0.1) : DT.c.blueTint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMatch ? DT.c.success.withValues(alpha: 0.3) : DT.c.blueTint.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              attribute,
              style: DT.t.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: DT.c.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(value1, style: DT.t.body),
          ),
          Icon(
            isMatch ? Icons.check_circle : Icons.compare_arrows,
            color: isMatch ? DT.c.success : DT.c.textMuted,
            size: 20,
          ),
          Expanded(
            child: Text(
              value2,
              style: DT.t.body,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScore() {
    final confidence = _getConfidenceLevel(widget.match.score.total);
    return Container(
      padding: EdgeInsets.all(DT.s.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [confidence.color, confidence.color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Overall Match Score',
            style: DT.t.title.copyWith(color: Colors.white),
          ),
          SizedBox(height: DT.s.md),
          Text(
            '${(widget.match.score.total * 100).round()}%',
            style: DT.t.h1.copyWith(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DT.s.sm),
          Text(
            confidence.label,
            style: DT.t.title.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score Breakdown', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Text(
          'This score is calculated using multiple factors to ensure accurate matching:',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
        SizedBox(height: DT.s.lg),
        _buildScoreComponent('Category Match', widget.match.score.category, Icons.category),
        _buildScoreComponent('Distance', widget.match.score.distance, Icons.location_on),
        _buildScoreComponent('Time Proximity', widget.match.score.time, Icons.schedule),
        _buildScoreComponent('Attributes', widget.match.score.attributes, Icons.info),
        if (widget.match.score.text != null)
          _buildScoreComponent('Text Similarity', widget.match.score.text!, Icons.text_fields),
        if (widget.match.score.image != null)
          _buildScoreComponent('Image Similarity', widget.match.score.image!, Icons.image),
      ],
    );
  }

  Widget _buildScoreComponent(String label, double score, IconData icon) {
    final percentage = (score * 100).round();
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DT.c.blueTint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DT.c.brand, size: 20),
              SizedBox(width: DT.s.sm),
              Text(label, style: DT.t.title),
              const Spacer(),
              Text(
                '$percentage%',
                style: DT.t.title.copyWith(
                  color: DT.c.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: DT.s.sm),
          LinearProgressIndicator(
            value: score,
            backgroundColor: DT.c.blueTint.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(DT.c.brand),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Match Explanation', style: DT.t.h3),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showFullExplanation = !_showFullExplanation;
                });
              },
              child: Text(_showFullExplanation ? 'Show Less' : 'Show More'),
            ),
          ],
        ),
        SizedBox(height: DT.s.md),
        Container(
          padding: EdgeInsets.all(DT.s.lg),
          decoration: BoxDecoration(
            color: DT.c.blueTint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.match.explanation.summary,
                style: DT.t.body,
              ),
              if (_showFullExplanation) ...[
                SizedBox(height: DT.s.lg),
                _buildExplanationDetail('Distance', '${widget.match.explanation.distanceKm.toStringAsFixed(1)} km apart'),
                _buildExplanationDetail('Time Difference', '${widget.match.explanation.timeDiffHours.toStringAsFixed(1)} hours'),
                _buildExplanationDetail('Category Match', widget.match.explanation.categoryMatch ? 'Exact match' : 'Different categories'),
                if (widget.match.explanation.attributeMatches.isNotEmpty)
                  _buildExplanationDetail('Matching Attributes', widget.match.explanation.attributeMatches.join(', ')),
                _buildExplanationDetail('Confidence Level', widget.match.explanation.confidenceLevel),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: DT.t.body),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Start Chat',
              onPressed: _startChat,
              isOutlined: true,
              icon: Icons.chat_bubble_outline,
            ),
          ),
          SizedBox(width: DT.s.md),
          Expanded(
            child: CustomButton(
              text: widget.sourceItem.type == ItemType.lost ? 'Claim Item' : 'Contact Owner',
              onPressed: _claimOrContact,
              icon: widget.sourceItem.type == ItemType.lost ? Icons.flag : Icons.contact_phone,
            ),
          ),
        ],
      ),
    );
  }

  void _startChat() {
    final thread = ChatThread(
      id: 'match-${widget.match.id}',
      name: widget.match.matchedItem.userName ?? 'Item Owner',
      online: true,
      messages: [
        ChatMessage(
          id: 'initial',
          sender: widget.match.matchedItem.userName ?? 'Item Owner',
          avatarUrl: '',
          isMe: false,
          kind: MessageKind.text,
          text: 'Hi! I saw your interest in the ${widget.match.matchedItem.title}. Let\'s discuss!',
        ),
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThreadPage(thread: thread),
      ),
    );
  }

  void _claimOrContact() {
    if (widget.sourceItem.type == ItemType.lost) {
      // Navigate to claim page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateClaimPage(item: widget.match.matchedItem),
        ),
      );
    } else {
      // Start chat for found items
      _startChat();
    }
  }

  ConfidenceLevel _getConfidenceLevel(double score) {
    if (score >= 0.75) {
      return ConfidenceLevel('High Confidence', DT.c.success);
    } else if (score >= 0.45) {
      return ConfidenceLevel('Medium Confidence', Colors.orange);
    } else {
      return ConfidenceLevel('Low Confidence', DT.c.danger);
    }
  }
}

class ConfidenceLevel {
  final String label;
  final Color color;

  ConfidenceLevel(this.label, this.color);
}
