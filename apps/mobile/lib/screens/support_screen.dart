import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/routing/app_routes.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
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
            // Help & FAQ Section
            _buildSectionHeader('Help & FAQ'),
            _buildSupportCard([
              _buildSupportItem(
                icon: Icons.help_outline_rounded,
                title: 'Frequently Asked Questions',
                subtitle: 'Find answers to common questions',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.faq);
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.book_rounded,
                title: 'User Guide',
                subtitle: 'Learn how to use the app',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.userGuide);
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.video_library_rounded,
                title: 'Video Tutorials',
                subtitle: 'Watch step-by-step guides',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.tutorials);
                },
              ),
            ]),

            SizedBox(height: DT.s.lg),

            // Contact Support Section
            _buildSectionHeader('Contact Support'),
            _buildSupportCard([
              _buildSupportItem(
                icon: Icons.email_rounded,
                title: 'Email Support',
                subtitle: 'support@lostfinder.com',
                color: DT.c.successFg,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email functionality coming soon'),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.phone_rounded,
                title: 'Phone Support',
                subtitle: '+1 (555) 123-4567',
                color: DT.c.successFg,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone functionality coming soon'),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.chat_rounded,
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                color: DT.c.successFg,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.liveChat);
                },
              ),
            ]),

            SizedBox(height: DT.s.lg),

            // Report Issue Section
            _buildSectionHeader('Report an Issue'),
            Container(
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
              child: Padding(
                padding: EdgeInsets.all(DT.s.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send us a message',
                      style: DT.t.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: DT.s.md),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Your Email',
                        hintText: 'Enter your email address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DT.r.md),
                        ),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    SizedBox(height: DT.s.md),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe your issue or question',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DT.r.md),
                        ),
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    SizedBox(height: DT.s.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendMessage,
                        child: const Text('Send Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: DT.s.lg),

            // About Section
            _buildSectionHeader('About'),
            _buildSupportCard([
              _buildSupportItem(
                icon: Icons.info_outline_rounded,
                title: 'About Lost Finder',
                subtitle: 'Version 1.0.0',
                color: DT.c.textMuted,
                onTap: () {
                  Navigator.of(context).pushNamed('/about');
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                subtitle: 'How we protect your data',
                color: DT.c.textMuted,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.description_rounded,
                title: 'Terms of Service',
                subtitle: 'Terms and conditions',
                color: DT.c.textMuted,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.terms);
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.code_rounded,
                title: 'Open Source',
                subtitle: 'View source code and contribute',
                color: DT.c.textMuted,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL functionality coming soon'),
                    ),
                  );
                },
              ),
            ]),

            SizedBox(height: DT.s.lg),

            // Community Section
            _buildSectionHeader('Community'),
            _buildSupportCard([
              _buildSupportItem(
                icon: Icons.forum_rounded,
                title: 'Community Forum',
                subtitle: 'Connect with other users',
                color: DT.c.brand,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Community functionality coming soon'),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.bug_report_rounded,
                title: 'Report Bug',
                subtitle: 'Help us improve the app',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.bugReport);
                },
              ),
              _buildDivider(),
              _buildSupportItem(
                icon: Icons.lightbulb_rounded,
                title: 'Feature Request',
                subtitle: 'Suggest new features',
                color: DT.c.successFg,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.featureRequest);
                },
              ),
            ]),

            SizedBox(height: DT.s.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.md),
      child: Text(
        title,
        style: DT.t.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSupportCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(DT.s.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(DT.s.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DT.t.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DT.c.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DT.t.body.copyWith(
                      fontSize: 12,
                      color: DT.c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: DT.c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DT.s.md),
      height: 1,
      color: DT.c.divider,
    );
  }

  void _sendMessage() {
    if (_emailController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // TODO: Implement send message functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message sent successfully!')));

    _emailController.clear();
    _messageController.clear();
  }
}
