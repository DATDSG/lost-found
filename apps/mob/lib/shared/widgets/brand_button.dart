import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final EdgeInsetsGeometry padding;
  const PrimaryGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DT.g.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DT.c.brand.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20).add(padding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: DT.t.title.copyWith(color: surface, fontSize: 18)),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, color: surface),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OutlineBrandButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leading;
  const OutlineBrandButton(
      {super.key, required this.label, this.onPressed, this.leading});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: leading == null ? const SizedBox() : Icon(leading, color: DT.c.brand),
      label: Text(label, style: DT.t.title.copyWith(color: DT.c.brand)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: DT.c.brand, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: DT.c.brand,
      ),
    );
  }
}
