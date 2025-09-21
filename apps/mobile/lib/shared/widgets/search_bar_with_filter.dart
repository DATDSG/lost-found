import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class SearchBarWithFilter extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilter;
  const SearchBarWithFilter({
    super.key,
    required this.controller,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field — height 56, radius 28, fill brandDeep
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: DT.c.brandDeep,
              borderRadius: BorderRadius.circular(DT.r.xl),
            ),
            padding: EdgeInsets.symmetric(horizontal: DT.s.lg), // 20dp
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: Colors.black87),
                SizedBox(width: DT.s.md),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: DT.t.body.copyWith(color: Colors.black),
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Enter item name, category, Locat..',
                      hintStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: DT.s.md),
        // Filter button — 48x48, radius 12, outlined
        _FilterButton(onTap: onFilter),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DT.c.brand, width: 2),
          ),
          child: const _FilterGlyph(),
        ),
      ),
    );
  }
}

class _FilterGlyph extends StatelessWidget {
  const _FilterGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FilterGlyphPainter());
  }
}

class _FilterGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DT.c.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Right-aligned filled circle
    final center = Offset(w * 0.72, h * 0.38);
    canvas.drawCircle(center, 5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // Two horizontal lines
    canvas.drawLine(
      Offset(w * 0.24, h * 0.30),
      Offset(w * 0.60, h * 0.30),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.24, h * 0.65),
      Offset(w * 0.76, h * 0.65),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
