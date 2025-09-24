import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class CompareMatchPage extends StatelessWidget {
  final String yourImage, yourTitle, yourPlace;
  final String theirImage, theirTitle, theirPlace;
  final VoidCallback onStartChat;

  const CompareMatchPage({
    super.key,
    required this.yourImage,
    required this.yourTitle,
    required this.yourPlace,
    required this.theirImage,
    required this.theirTitle,
    required this.theirPlace,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: Text('Lost Vs. Found', style: DT.t.h1.copyWith(fontSize: 20)),
      ),
      body: ListView(
        physics: DT.scroll,
        padding: EdgeInsets.all(DT.s.lg),
        children: [
          Row(
            children: [
              Expanded(child: _photoCard(yourImage, yourTitle, yourPlace)),
              SizedBox(width: DT.s.lg),
              Expanded(child: _photoCard(theirImage, theirTitle, theirPlace)),
            ],
          ),
          SizedBox(height: DT.s.xl),
          Text('Similarity Breakdown', style: DT.t.h1.copyWith(fontSize: 24)),
          SizedBox(height: DT.s.md),
          _scoreTile('Geo', 'High (95%)', color: Colors.red),
          _scoreTile('Time', 'Medium (60%)', color: Colors.orange),
          _scoreTile('Text', 'High (90%)', color: Colors.red),
          _scoreTile('Image', 'High (80%)', color: Colors.red),
          SizedBox(height: DT.s.xl),
          Text('Verification Tips', style: DT.t.h1.copyWith(fontSize: 22)),
          SizedBox(height: DT.s.sm),
          Text(
            'To verify ownership , ask for a unique mark or item inside the phone case. '
            'This ensure a secure and accurate return.',
            style: DT.t.body.copyWith(fontSize: 16, color: DT.c.text),
          ),
          SizedBox(height: DT.s.xl),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: onStartChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.c.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Start Masked Chat',
                  style: DT.t.title.copyWith(color: Colors.white, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _photoCard(String url, String title, String place) {
    return Container(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      padding: EdgeInsets.all(DT.s.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE6EAF2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, color: Color(0xFF8C96A4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: DT.t.title.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(place, style: DT.t.body.copyWith(color: DT.c.brand)),
        ],
      ),
    );
  }

  Widget _scoreTile(String left, String right, {required Color color}) {
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      child: Row(
        children: [
          Expanded(child: Text(left, style: DT.t.title.copyWith(fontSize: 18))),
          Text(right, style: DT.t.title.copyWith(color: color)),
        ],
      ),
    );
  }
}
