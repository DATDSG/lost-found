import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../data/providers/privacy_providers.dart';
import '../../domain/models/privacy_models.dart';

/// Screen for managing user privacy settings
///
/// This screen allows users to configure their privacy preferences including
/// profile visibility, communication settings, location sharing, and data management.
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  /// Creates a new privacy settings screen
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late PrivacySettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = const PrivacySettings(
      profileVisibility: true,
      showEmail: false,
      showPhone: true,
      allowMessages: true,
      showLocation: true,
      allowNotifications: true,
    );

    // Load settings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(privacySettingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final privacyState = ref.watch(privacySettingsProvider);

    // Update local settings when provider state changes
    if (privacyState.settings != null) {
      _currentSettings = privacyState.settings!;
    }

    return MainLayout(
      currentIndex: 3, // Profile is index 3
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Settings'),
          backgroundColor: DT.c.surface,
          foregroundColor: DT.c.textPrimary,
          elevation: 0,
        ),
        body: privacyState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(DT.s.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show success message
                    if (privacyState.isSuccess)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(DT.s.md),
                        margin: EdgeInsets.only(bottom: DT.s.md),
                        decoration: BoxDecoration(
                          color: DT.c.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DT.r.md),
                          border: Border.all(color: DT.c.success),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: DT.c.success),
                            SizedBox(width: DT.s.sm),
                            Text(
                              'Privacy settings saved successfully!',
                              style: DT.t.bodyMedium.copyWith(
                                color: DT.c.success,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Show error message
                    if (privacyState.error != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(DT.s.md),
                        margin: EdgeInsets.only(bottom: DT.s.md),
                        decoration: BoxDecoration(
                          color: DT.c.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DT.r.md),
                          border: Border.all(color: DT.c.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: DT.c.error),
                            SizedBox(width: DT.s.sm),
                            Expanded(
                              child: Text(
                                privacyState.error!,
                                style: DT.t.bodyMedium.copyWith(
                                  color: DT.c.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Profile Visibility Section
                    _buildSection(
                      title: 'Profile Visibility',
                      children: [
                        _buildSwitchTile(
                          title: 'Public Profile',
                          subtitle: 'Allow others to see your profile',
                          value: _currentSettings.profileVisibility,
                          onChanged: (value) => _updateSetting(
                            _currentSettings.copyWith(profileVisibility: value),
                          ),
                        ),
                        _buildSwitchTile(
                          title: 'Show Email',
                          subtitle:
                              'Display your email address on your profile',
                          value: _currentSettings.showEmail,
                          onChanged: (value) => _updateSetting(
                            _currentSettings.copyWith(showEmail: value),
                          ),
                        ),
                        _buildSwitchTile(
                          title: 'Show Phone Number',
                          subtitle: 'Display your phone number on your profile',
                          value: _currentSettings.showPhone,
                          onChanged: (value) => _updateSetting(
                            _currentSettings.copyWith(showPhone: value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.lg),

                    // Communication Preferences Section
                    _buildSection(
                      title: 'Communication Preferences',
                      children: [
                        _buildSwitchTile(
                          title: 'Allow Messages',
                          subtitle: 'Receive direct messages from other users',
                          value: _currentSettings.allowMessages,
                          onChanged: (value) => _updateSetting(
                            _currentSettings.copyWith(allowMessages: value),
                          ),
                        ),
                        _buildSwitchTile(
                          title: 'Push Notifications',
                          subtitle:
                              'Receive notifications for matches and updates',
                          value: _currentSettings.allowNotifications,
                          onChanged: (value) => _updateSetting(
                            _currentSettings.copyWith(
                              allowNotifications: value,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.lg),

                    // Location Settings Section
                    _buildSection(
                      title: 'Location Settings',
                      children: [
                        _buildSwitchTile(
                          title: 'Share Location',
                          subtitle:
                              'Allow the app to use your location for better matching',
                          value: _currentSettings.showLocation,
                          onChanged: (value) => _updateSetting(
                            _currentSettings.copyWith(showLocation: value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.lg),

                    // Data Management Section
                    _buildSection(
                      title: 'Data Management',
                      children: [
                        _buildListTile(
                          title: 'Download Your Data',
                          subtitle: 'Request a copy of your personal data',
                          icon: Icons.download,
                          onTap: _downloadData,
                        ),
                        _buildListTile(
                          title: 'Delete Account',
                          subtitle: 'Permanently delete your account and data',
                          icon: Icons.delete_forever,
                          onTap: _deleteAccount,
                          isDestructive: true,
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.lg),

                    // Save Button
                    Center(
                      child: ElevatedButton(
                        onPressed: privacyState.isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DT.c.brand,
                          foregroundColor: DT.c.textOnBrand,
                          padding: EdgeInsets.symmetric(vertical: DT.s.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DT.r.md),
                          ),
                        ),
                        child: privacyState.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Update a single setting
  void _updateSetting(PrivacySettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
  }

  /// Save settings
  Future<void> _saveSettings() async {
    await ref
        .read(privacySettingsProvider.notifier)
        .saveSettings(_currentSettings);
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: DT.t.titleMedium.copyWith(
          color: DT.c.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: DT.s.sm),
      ...children,
    ],
  );

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
    margin: EdgeInsets.only(bottom: DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border),
    ),
    child: SwitchListTile(
      title: Text(
        title,
        style: DT.t.bodyLarge.copyWith(
          color: DT.c.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: DT.c.brand,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DT.s.md,
        vertical: DT.s.sm,
      ),
    ),
  );

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) => Container(
    margin: EdgeInsets.only(bottom: DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border),
    ),
    child: ListTile(
      leading: Icon(icon, color: isDestructive ? DT.c.error : DT.c.textMuted),
      title: Text(
        title,
        style: DT.t.bodyLarge.copyWith(
          color: isDestructive ? DT.c.error : DT.c.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DT.s.md,
        vertical: DT.s.sm,
      ),
    ),
  );

  void _downloadData() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Data'),
        content: const Text(
          'This will prepare a download link for all your data. You will receive an email when it is ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Store context before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                // Show loading indicator
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DT.c.textOnBrand,
                            ),
                          ),
                        ),
                        SizedBox(width: DT.s.sm),
                        const Text('Requesting data download...'),
                      ],
                    ),
                    backgroundColor: DT.c.brand,
                  ),
                );

                // Call the actual API to request data download
                final authService = ref.read(authServiceProvider);
                await authService.requestDataDownload();

                // Show success message
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Data download requested successfully! You will receive an email when ready.',
                      ),
                      backgroundColor: DT.c.success,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error requesting data download: $e'),
                      backgroundColor: DT.c.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => _AccountDeletionDialog(
        onConfirm: (password, reason) {
          Navigator.pop(context);
          _performAccountDeletion(password: password, reason: reason);
        },
      ),
    );
  }

  /// Perform actual account deletion
  Future<void> _performAccountDeletion({
    required String password,
    String? reason,
  }) async {
    try {
      // Show loading dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      // Call the actual API to delete the account
      final authService = ref.read(authServiceProvider);
      await authService.deleteAccount(password: password, reason: reason);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully'),
            backgroundColor: DT.c.success,
          ),
        );

        // Navigate to login screen
        context.go(loginRoute);
      }
    } on Exception catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: DT.c.error,
          ),
        );
      }
    }
  }
}

/// Dialog for account deletion confirmation with password input
class _AccountDeletionDialog extends StatefulWidget {
  const _AccountDeletionDialog({required this.onConfirm});

  final void Function(String password, String? reason) onConfirm;

  @override
  State<_AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<_AccountDeletionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _confirmDeletion = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      'Delete Account',
      style: DT.t.titleLarge.copyWith(color: DT.c.error),
    ),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action cannot be undone. All your data will be permanently deleted.',
            style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          ),
          SizedBox(height: DT.s.lg),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Current Password',
              hintText: 'Enter your current password',
              prefixIcon: Icon(Icons.lock_outline, color: DT.c.brand),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: DT.c.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DT.r.lg),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.md),

          // Reason field (optional)
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason (Optional)',
              hintText: 'Why are you deleting your account?',
              prefixIcon: Icon(Icons.feedback_outlined, color: DT.c.brand),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DT.r.lg),
              ),
            ),
            maxLines: 3,
          ),

          SizedBox(height: DT.s.md),

          // Confirmation checkbox
          CheckboxListTile(
            value: _confirmDeletion,
            onChanged: (value) {
              setState(() {
                _confirmDeletion = value ?? false;
              });
            },
            title: Text(
              'I understand this action cannot be undone',
              style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        ),
      ),
      ElevatedButton(
        onPressed: _confirmDeletion ? _handleDelete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: DT.c.error,
          foregroundColor: DT.c.textOnBrand,
          disabledBackgroundColor: DT.c.textMuted,
        ),
        child: const Text('Delete Account'),
      ),
    ],
  );

  void _handleDelete() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onConfirm(
        _passwordController.text,
        _reasonController.text.isNotEmpty ? _reasonController.text : null,
      );
    }
  }
}
