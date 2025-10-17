import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

class FormFieldWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const FormFieldWrapper({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.md),
        border: Border.all(color: DT.c.divider),
        boxShadow: [
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
