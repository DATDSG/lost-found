import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/profile/profile_service.dart';
import 'profile_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // Safe even if AppRoot already initialized (idempotent).
    // Keeps ProfilePage resilient if it’s pushed directly in tests.
    ProfileService.I.init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile>(
      stream: ProfileService.I.stream,
      // IMPORTANT: no initialData here; it would touch the late field early.
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snap.data!; // <-- use snapshot only

        return Scaffold(
          backgroundColor: DT.c.surface,
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            backgroundColor: DT.c.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _Header(profile: profile),
              TabBar(
                controller: _tabs,
                indicatorColor: DT.c.brand,
                labelColor: DT.c.brand,
                unselectedLabelColor: DT.c.textMuted,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Resolved'),
                  Tab(text: 'Drafts'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: const [
                    _ListPlaceholder(label: 'No active posts'),
                    _ListPlaceholder(label: 'No resolved posts'),
                    _ListPlaceholder(label: 'No drafts'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final UserProfile profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DT.c.blueTint.withValues(alpha: .45),
      padding: EdgeInsets.all(DT.s.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage:
                profile.avatarPath != null ? Image.asset(profile.avatarPath!).image : null,
            child: profile.avatarPath == null ? const Icon(Icons.person) : null,
          ),
          SizedBox(width: DT.s.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: DT.t.h1.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text(profile.handle, style: DT.t.body.copyWith(color: DT.c.textMuted)),
                const SizedBox(height: 8),
                Text(
                  'Member since ${profile.memberSince.year} • ${profile.itemsPosted} items posted',
                  style: DT.t.label.copyWith(color: DT.c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListPlaceholder extends StatelessWidget {
  final String label;
  const _ListPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: DT.t.body.copyWith(color: DT.c.textMuted)),
    );
  }
}
