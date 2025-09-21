import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Profile', style: DT.t.h1));
  }
}
