import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/design_tokens.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});
  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late Locale _locale;
  bool _dark = false;
  bool _dataSaver = false;
  bool _notif = true;

  @override
  void initState() {
    super.initState();
    // DO NOT read context here (caused your error).
    _dark = false;
    _dataSaver = false;
    _notif = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place to read inherited widgets (e.g., EasyLocalization).
    _locale = context.locale;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(DT.s.lg),
        children: [
          _tile(
            title: 'Language',
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: _locale,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('si'), child: Text('සිංහල')),
                  DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
                ],
                onChanged: (loc) async {
                  if (loc == null) return;
                  setState(() => _locale = loc);
                  await context.setLocale(loc);
                },
              ),
            ),
          ),
          _switchTile('Dark Mode', _dark, (v) => setState(() => _dark = v)),
          _switchTile('Data Saver (compress uploads)', _dataSaver, (v) => setState(() => _dataSaver = v)),
          _switchTile('Notification', _notif, (v) => setState(() => _notif = v)),
        ],
      ),
    );
  }

  Widget _tile({required String title, required Widget trailing}) {
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: DT.e.card,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: DT.t.title)),
          trailing,
        ],
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return _tile(
      title: title,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
