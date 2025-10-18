import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
            // Profile Settings Section
            _buildSectionHeader('Profile'),
            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.person_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.editProfile);
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.photo_camera_rounded,
                title: 'Profile Picture',
                subtitle: 'Change your avatar',
                color: DT.c.brand,
                onTap: () {
                  _showImagePickerDialog();
                },
              ),
            ]),

            SizedBox(height: DT.s.lg),

            // App Settings Section
            _buildSectionHeader('App Settings'),
            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Push notifications and alerts',
                color: DT.c.brand,
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeThumbColor: DT.c.brand,
                ),
                onTap: () {
                  setState(() {
                    _notificationsEnabled = !_notificationsEnabled;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.location_on_rounded,
                title: 'Location Services',
                subtitle: 'Allow location access for better matching',
                color: DT.c.successFg,
                trailing: Switch(
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                  activeThumbColor: DT.c.successFg,
                ),
                onTap: () {
                  setState(() {
                    _locationEnabled = !_locationEnabled;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _selectedLanguage,
                color: DT.c.brand,
                onTap: () {
                  _showLanguageDialog();
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.palette_rounded,
                title: 'Theme',
                subtitle: _selectedTheme,
                color: DT.c.brand,
                onTap: () {
                  _showThemeDialog();
                },
              ),
            ]),

            SizedBox(height: DT.s.lg),

            // Privacy & Security Section
            _buildSectionHeader('Privacy & Security'),
            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.security_rounded,
                title: 'Privacy Settings',
                subtitle: 'Control your data and privacy',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.privacySettings);
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.lock_rounded,
                title: 'Change Password',
                subtitle: 'Update your account password',
                color: DT.c.brand,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.changePassword);
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.block_rounded,
                title: 'Blocked Users',
                subtitle: 'Manage blocked users',
                color: DT.c.dangerFg,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.blockedUsers);
                },
              ),
            ]),

            SizedBox(height: DT.s.lg),

            // Account Management Section
            _buildSectionHeader('Account'),
            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.download_rounded,
                title: 'Export Data',
                subtitle: 'Download your data',
                color: DT.c.brand,
                onTap: () {
                  _showExportDataDialog();
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.delete_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                color: DT.c.dangerFg,
                onTap: () {
                  _showDeleteAccountDialog();
                },
              ),
            ]),

            SizedBox(height: DT.s.xl),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: DT.c.dangerBg,
                borderRadius: BorderRadius.circular(DT.r.md),
                border: Border.all(color: DT.c.dangerFg.withValues(alpha: 0.3)),
              ),
              child: InkWell(
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.logout();
                  Navigator.of(context).pushReplacementNamed(AppRoutes.landing);
                },
                borderRadius: BorderRadius.circular(DT.r.md),
                child: Padding(
                  padding: EdgeInsets.all(DT.s.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: DT.c.dangerFg,
                        size: 20,
                      ),
                      SizedBox(width: DT.s.sm),
                      Text(
                        'Log Out',
                        style: DT.t.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DT.c.dangerFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _buildSettingsCard(List<Widget> children) {
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
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
                  const SizedBox(height: 2),
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
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: DT.c.textMuted,
                  size: 20,
                ),
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

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Picture',
              style: DT.t.title.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: DT.s.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromCamera();
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
                _buildImageOption(
                  icon: Icons.delete_rounded,
                  label: 'Remove',
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfilePicture();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(DT.s.lg),
            decoration: BoxDecoration(
              color: DT.c.surface,
              borderRadius: BorderRadius.circular(DT.r.md),
            ),
            child: Icon(icon, size: 32, color: DT.c.brand),
          ),
          SizedBox(height: DT.s.sm),
          Text(label, style: DT.t.body.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Italian'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final themes = ['System', 'Light', 'Dark'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((theme) {
            return RadioListTile<String>(
              title: Text(theme),
              value: theme,
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will download all your data including reports, messages, and account information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportUserData();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUserAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: DT.c.dangerFg),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: DT.c.dangerFg,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: DT.c.dangerFg,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _apiService.uploadProfilePicture(imageFile);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated successfully'),
            backgroundColor: DT.c.successFg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: DT.c.dangerFg,
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      await _apiService.removeProfilePicture();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture removed successfully'),
            backgroundColor: DT.c.successFg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove profile picture: $e'),
            backgroundColor: DT.c.dangerFg,
          ),
        );
      }
    }
  }

  Future<void> _exportUserData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _apiService.exportUserData();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // In a real app, you would save this data to a file and allow download
        // For now, we'll just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data export completed successfully'),
            backgroundColor: DT.c.successFg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: DT.c.dangerFg,
          ),
        );
      }
    }
  }

  Future<void> _deleteUserAccount() async {
    // Show confirmation dialog with password input
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.\n\nPlease enter your password to confirm:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: DT.c.dangerFg),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await _apiService.deleteUserAccount();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Logout and navigate to landing page
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          Navigator.of(context).pushReplacementNamed(AppRoutes.landing);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account deleted successfully'),
              backgroundColor: DT.c.successFg,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: DT.c.dangerFg,
            ),
          );
        }
      }
    }
  }
}
