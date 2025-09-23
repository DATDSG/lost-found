import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

enum ReportType { lost, found }

class ReportWizardStub extends StatelessWidget {
  final ReportType type;
  const ReportWizardStub({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final title = type == ReportType.lost ? 'Report Lost Item' : 'Report Found Item';
    return Scaffold(
      appBar: AppBar(title: Text(title, style: DT.t.h1.copyWith(fontSize: 20))),
      body: Center(
        child: Text(
          'This is a stub for the $title flow.\nReplace with your actual form.',
          textAlign: TextAlign.center,
          style: DT.t.body.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}
