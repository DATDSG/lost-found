import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress Bar
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final isCompleted = index < currentStep;

            return Expanded(
              child: Row(
                children: [
                  // Step Circle
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: isActive ? DT.c.brand : DT.c.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${index + 1}',
                              style: DT.t.body.copyWith(
                                color: isActive ? Colors.white : DT.c.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Connector Line
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? DT.c.brand : DT.c.divider,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),

        SizedBox(height: DT.s.md),

        // Labels
        Row(
          children: labels.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isActive = index <= currentStep;

            return Expanded(
              child: Text(
                label,
                style: DT.t.caption.copyWith(
                  color: isActive ? DT.c.brand : DT.c.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
