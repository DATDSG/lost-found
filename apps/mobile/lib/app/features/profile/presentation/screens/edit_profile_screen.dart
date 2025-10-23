/// Edit profile screen with modern design following design science principles
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart' as api_models;
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../data/providers/avatar_providers.dart';
import '../../data/providers/profile_providers.dart';

/// Edit profile screen with enhanced UX following design science principles
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Creates a new edit profile screen
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _selectedImage;

  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordSectionExpanded = false;

  // Additional user details
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  late AnimationController _animationController;
  late AnimationController _sectionAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  void _loadUserData() {
    final authState = ref.read(authStateProvider);
    if (authState.user != null) {
      _displayNameController.text = authState.user?.displayName ?? '';
      _phoneNumberController.text = authState.user?.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _sectionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final profileUpdateState = ref.watch(profileUpdateProvider);
    final passwordChangeState = ref.watch(passwordChangeProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return MainLayout(
      currentIndex: 3, // Profile is index 3
      child: Scaffold(
        backgroundColor: DT.c.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Enhanced App Bar with gradient
                _buildSliverAppBar(authState.user!),

                // Main Content
                SliverPadding(
                  padding: EdgeInsets.all(DT.s.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Profile Header Card
                      _buildEnhancedProfileHeader(
                        authState.user!,
                        isSmallScreen,
                      ),

                      SizedBox(height: DT.s.lg),

                      // Form wrapper for validation
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Personal Information Section
                            _buildPersonalInfoSection(isSmallScreen),

                            SizedBox(height: DT.s.lg),

                            // Password Section with Expandable Design
                            _buildPasswordSection(isSmallScreen),

                            SizedBox(height: DT.s.xl),

                            // Action Buttons with Enhanced Design
                            _buildActionButtons(
                              profileUpdateState,
                              passwordChangeState,
                            ),

                            SizedBox(height: DT.s.lg),

                            // Status Messages
                            ..._buildStatusMessages(
                              profileUpdateState,
                              passwordChangeState,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(api_models.User user) => SliverAppBar(
    expandedHeight: 120,
    pinned: true,
    backgroundColor: DT.c.surface,
    elevation: 0,
    leading: Container(
      margin: EdgeInsets.all(DT.s.sm),
      decoration: BoxDecoration(
        color: DT.c.surface,
        borderRadius: BorderRadius.circular(DT.r.full),
        boxShadow: DT.e.sm,
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: DT.c.text),
        onPressed: () => context.pop(),
      ),
    ),
    flexibleSpace: FlexibleSpaceBar(
      title: Text(
        'Edit Profile',
        style: DT.t.titleLarge.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DT.c.brand.withValues(alpha: 0.1),
              DT.c.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: DT.s.lg),
              Text(
                'Customize your profile',
                style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              ),
              SizedBox(height: DT.s.md),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildEnhancedProfileHeader(
    api_models.User user,
    bool isSmallScreen,
  ) => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.lg),
      border: Border.all(color: DT.c.border),
      boxShadow: DT.e.card,
    ),
    child: Column(
      children: [
        // Avatar Section
        _buildAvatarSection(user, isSmallScreen),

        SizedBox(height: DT.s.lg),

        // User Info
        _buildUserInfo(user),

        SizedBox(height: DT.s.md),

        // Quick Stats
        _buildQuickStats(user),
      ],
    ),
  );

  Widget _buildAvatarSection(api_models.User user, bool isSmallScreen) => Row(
    children: [
      // Enhanced Avatar
      _buildEnhancedAvatar(user, isSmallScreen),

      SizedBox(width: DT.s.lg),

      // Avatar Actions
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Picture',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              'Tap to change your profile picture',
              style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
            ),
            SizedBox(height: DT.s.md),
            _buildAvatarActionButtons(),
          ],
        ),
      ),
    ],
  );

  Widget _buildEnhancedAvatar(api_models.User user, bool isSmallScreen) =>
      GestureDetector(
        onTap: _showAvatarPicker,
        child: Container(
          width: isSmallScreen ? 80 : 100,
          height: isSmallScreen ? 80 : 100,
          decoration: BoxDecoration(
            color: DT.c.brand,
            borderRadius: BorderRadius.circular(DT.r.full),
            border: Border.all(color: DT.c.brand, width: 3),
            boxShadow: DT.e.md,
          ),
          child: Stack(
            children: [
              // Avatar Image
              ClipRRect(
                borderRadius: BorderRadius.circular(DT.r.full),
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 80 : 100,
                        fit: BoxFit.cover,
                      )
                    : user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? Image.network(
                        user.avatarUrl!,
                        width: isSmallScreen ? 80 : 100,
                        height: isSmallScreen ? 80 : 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackIcon(isSmallScreen),
                      )
                    : _buildFallbackIcon(isSmallScreen),
              ),

              // Camera Overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: DT.c.brand,
                    borderRadius: BorderRadius.circular(DT.r.full),
                    border: Border.all(color: DT.c.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: DT.c.textOnBrand,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFallbackIcon(bool isSmallScreen) => Container(
    width: isSmallScreen ? 80 : 100,
    height: isSmallScreen ? 80 : 100,
    decoration: BoxDecoration(
      color: DT.c.brand,
      borderRadius: BorderRadius.circular(DT.r.full),
    ),
    child: Icon(
      Icons.person,
      color: DT.c.textOnBrand,
      size: isSmallScreen ? 40 : 50,
    ),
  );

  Widget _buildUserInfo(api_models.User user) => Column(
    children: [
      Text(
        user.displayName ?? 'No name',
        style: DT.t.titleLarge.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: DT.s.xs),
      Text(
        user.email,
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildQuickStats(api_models.User user) => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Reports', '12', Icons.description_outlined),
        _buildStatItem('Matches', '5', Icons.handshake_outlined),
        _buildStatItem('Success', '3', Icons.check_circle_outline),
      ],
    ),
  );

  Widget _buildStatItem(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: DT.c.brand, size: 20),
      SizedBox(height: DT.s.xs),
      Text(
        value,
        style: DT.t.titleMedium.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(label, style: DT.t.bodySmall.copyWith(color: DT.c.textMuted)),
    ],
  );

  Widget _buildAvatarActionButtons() => Row(
    children: [
      Expanded(
        child: _buildActionButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: _pickImageFromCamera,
        ),
      ),
      SizedBox(width: DT.s.sm),
      Expanded(
        child: _buildActionButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: _pickImageFromGallery,
        ),
      ),
    ],
  );

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(DT.r.sm),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: DT.s.sm, vertical: DT.s.xs),
      decoration: BoxDecoration(
        color: DT.c.brandSubtle,
        borderRadius: BorderRadius.circular(DT.r.sm),
        border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: DT.c.brand, size: 16),
          SizedBox(width: DT.s.xs),
          Text(
            label,
            style: DT.t.bodySmall.copyWith(
              color: DT.c.brand,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPersonalInfoSection(bool isSmallScreen) => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.lg),
      border: Border.all(color: DT.c.border),
      boxShadow: DT.e.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Personal Information',
          Icons.person_outline,
          'Update your personal details',
        ),

        SizedBox(height: DT.s.lg),

        _buildEnhancedTextField(
          controller: _displayNameController,
          label: 'Display Name',
          hint: 'Enter your display name',
          prefixIcon: Icons.badge_outlined,
          validator: (value) {
            if (value != null &&
                value.trim().isNotEmpty &&
                value.trim().length < 2) {
              return 'Display name must be at least 2 characters';
            }
            return null;
          },
        ),

        SizedBox(height: DT.s.lg),

        _buildEnhancedTextField(
          controller: _phoneNumberController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),

        SizedBox(height: DT.s.lg),

        _buildEnhancedTextField(
          controller: _bioController,
          label: 'Bio',
          hint: 'Tell us about yourself',
          keyboardType: TextInputType.multiline,
          prefixIcon: Icons.person_outline,
          maxLines: 3,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.trim().length > 500) {
                return 'Bio must be less than 500 characters';
              }
            }
            return null;
          },
        ),

        SizedBox(height: DT.s.lg),

        _buildEnhancedTextField(
          controller: _locationController,
          label: 'Location',
          hint: 'Enter your city or location',
          prefixIcon: Icons.location_on_outlined,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.trim().length < 2) {
                return 'Location must be at least 2 characters';
              }
            }
            return null;
          },
        ),

        SizedBox(height: DT.s.lg),

        // Gender Selection
        _buildGenderDropdown(),

        SizedBox(height: DT.s.lg),

        // Date of Birth
        _buildDateOfBirthField(),
      ],
    ),
  );

  Widget _buildPasswordSection(bool isSmallScreen) => Container(
    padding: EdgeInsets.all(DT.s.lg),
    decoration: BoxDecoration(
      color: DT.c.surface,
      borderRadius: BorderRadius.circular(DT.r.lg),
      border: Border.all(color: DT.c.border),
      boxShadow: DT.e.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableSectionHeader(
          'Change Password',
          Icons.lock_outline,
          'Update your password for security',
          _isPasswordSectionExpanded,
          () {
            setState(() {
              _isPasswordSectionExpanded = !_isPasswordSectionExpanded;
            });
            if (_isPasswordSectionExpanded) {
              _sectionAnimationController.forward();
            } else {
              _sectionAnimationController.reverse();
            }
          },
        ),

        AnimatedBuilder(
          animation: _sectionAnimationController,
          builder: (context, child) => SizeTransition(
            sizeFactor: _sectionAnimationController,
            child: FadeTransition(
              opacity: _sectionAnimationController,
              child: _isPasswordSectionExpanded
                  ? Column(
                      children: [
                        SizedBox(height: DT.s.lg),

                        _buildEnhancedPasswordField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          hint: 'Enter current password',
                          prefixIcon: Icons.lock_outline,
                          isVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Current password is required';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: DT.s.lg),

                        _buildEnhancedPasswordField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          hint: 'Enter new password',
                          prefixIcon: Icons.lock_outline,
                          isVisible: _isNewPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
                            ).hasMatch(value)) {
                              return 'Password must contain uppercase, lowercase, and number';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: DT.s.lg),

                        _buildEnhancedPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Confirm new password',
                          prefixIcon: Icons.lock_outline,
                          isVisible: _isConfirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) =>
      Row(
        children: [
          Container(
            padding: EdgeInsets.all(DT.s.sm),
            decoration: BoxDecoration(
              color: DT.c.brandSubtle,
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: Icon(icon, color: DT.c.brand, size: 20),
          ),
          SizedBox(width: DT.s.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DT.t.titleMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildExpandableSectionHeader(
    String title,
    IconData icon,
    String subtitle,
    bool isExpanded,
    VoidCallback onToggle,
  ) => InkWell(
    onTap: onToggle,
    borderRadius: BorderRadius.circular(DT.r.sm),
    child: Container(
      padding: EdgeInsets.all(DT.s.sm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DT.s.sm),
            decoration: BoxDecoration(
              color: DT.c.brandSubtle,
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: Icon(icon, color: DT.c.brand, size: 20),
          ),
          SizedBox(width: DT.s.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DT.t.titleMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                ),
              ],
            ),
          ),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down, color: DT.c.textMuted),
          ),
        ],
      ),
    ),
  );

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: DT.t.bodyMedium.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: DT.s.sm),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: DT.t.bodyMedium.copyWith(color: DT.c.text),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: DT.c.brand)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.brand, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.error, width: 2),
          ),
          filled: true,
          fillColor: DT.c.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DT.s.lg,
            vertical: DT.s.md,
          ),
        ),
      ),
    ],
  );

  Widget _buildEnhancedPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: DT.t.bodyMedium.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: DT.s.sm),
      TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        style: DT.t.bodyMedium.copyWith(color: DT.c.text),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: DT.c.brand)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.brand, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.error, width: 2),
          ),
          filled: true,
          fillColor: DT.c.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DT.s.lg,
            vertical: DT.s.md,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: DT.c.textMuted,
              semanticLabel: isVisible ? 'Hide password' : 'Show password',
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    ],
  );

  Widget _buildGenderDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Gender',
        style: DT.t.bodyMedium.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: DT.s.sm),
      DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: InputDecoration(
          hintText: 'Select your gender',
          prefixIcon: Icon(Icons.person_outline, color: DT.c.brand),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.lg),
            borderSide: BorderSide(color: DT.c.brand, width: 2),
          ),
          filled: true,
          fillColor: DT.c.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DT.s.lg,
            vertical: DT.s.md,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
          DropdownMenuItem(value: 'other', child: Text('Other')),
          DropdownMenuItem(
            value: 'prefer_not_to_say',
            child: Text('Prefer not to say'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
      ),
    ],
  );

  Widget _buildDateOfBirthField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Date of Birth',
        style: DT.t.bodyMedium.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: DT.s.sm),
      InkWell(
        onTap: _selectDateOfBirth,
        borderRadius: BorderRadius.circular(DT.r.lg),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: DT.s.lg, vertical: DT.s.md),
          decoration: BoxDecoration(
            color: DT.c.surface,
            borderRadius: BorderRadius.circular(DT.r.lg),
            border: Border.all(color: DT.c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: DT.c.brand),
              SizedBox(width: DT.s.md),
              Expanded(
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                      : 'Select your date of birth',
                  style: DT.t.bodyMedium.copyWith(
                    color: _selectedDateOfBirth != null
                        ? DT.c.text
                        : DT.c.textMuted,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: DT.c.textMuted),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: DT.c.brand,
            onPrimary: DT.c.textOnBrand,
            surface: DT.c.surface,
            onSurface: DT.c.text,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Widget _buildActionButtons(
    ProfileUpdateState profileUpdateState,
    PasswordChangeState passwordChangeState,
  ) => Column(
    children: [
      // Primary Action Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _updateProfile,
          icon: profileUpdateState.isUpdating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(DT.c.textOnBrand),
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            profileUpdateState.isUpdating ? 'Updating...' : 'Save Changes',
            style: DT.t.button.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DT.c.brand,
            foregroundColor: DT.c.textOnBrand,
            padding: EdgeInsets.symmetric(vertical: DT.s.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.lg),
            ),
            elevation: 2,
          ),
        ),
      ),

      SizedBox(height: DT.s.md),

      // View Profile Details Button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showProfileDetails,
          icon: const Icon(Icons.visibility_outlined),
          label: Text(
            'View Profile Details',
            style: DT.t.button.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: DT.c.secondary,
            side: BorderSide(color: DT.c.secondary, width: 2),
            padding: EdgeInsets.symmetric(vertical: DT.s.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.lg),
            ),
          ),
        ),
      ),

      SizedBox(height: DT.s.md),

      // Secondary Action Button
      if (_isPasswordSectionExpanded)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _changePassword,
            icon: passwordChangeState.isChanging
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(DT.c.brand),
                    ),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(
              passwordChangeState.isChanging
                  ? 'Changing...'
                  : 'Change Password',
              style: DT.t.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: DT.c.brand,
              side: BorderSide(color: DT.c.brand, width: 2),
              padding: EdgeInsets.symmetric(vertical: DT.s.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.r.lg),
              ),
            ),
          ),
        ),
    ],
  );

  List<Widget> _buildStatusMessages(
    ProfileUpdateState profileUpdateState,
    PasswordChangeState passwordChangeState,
  ) {
    final messages = <Widget>[];

    if (profileUpdateState.isSuccess) {
      messages.add(_buildSuccessMessage('Profile updated successfully!'));
    }

    if (passwordChangeState.isSuccess) {
      messages.add(_buildSuccessMessage('Password changed successfully!'));
    }

    if (profileUpdateState.error != null) {
      messages.add(_buildErrorMessage(profileUpdateState.error!));
    }

    if (passwordChangeState.error != null) {
      messages.add(_buildErrorMessage(passwordChangeState.error!));
    }

    return messages;
  }

  Widget _buildSuccessMessage(String message) => Container(
    margin: EdgeInsets.only(top: DT.s.md),
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.success.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.success),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle, color: DT.c.success),
        SizedBox(width: DT.s.sm),
        Expanded(
          child: Text(
            message,
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildErrorMessage(String message) => Container(
    margin: EdgeInsets.only(top: DT.s.md),
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.error),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: DT.c.error),
        SizedBox(width: DT.s.sm),
        Expanded(
          child: Text(
            message,
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _updateProfile() async {
    if (kDebugMode) {
      print('_updateProfile called');
      print('Form key current state: ${_formKey.currentState}');
    }

    // Check if there are any changes to save
    var hasChanges = false;
    if (_displayNameController.text.trim().isNotEmpty ||
        _phoneNumberController.text.trim().isNotEmpty ||
        _bioController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty ||
        _selectedGender != null ||
        _selectedDateOfBirth != null) {
      hasChanges = true;
    }

    if (!hasChanges) {
      if (kDebugMode) {
        print('No changes to save');
      }
      // Show a message to user that there are no changes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No changes to save'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
          ),
        ),
      );
      return;
    }

    // Only validate text fields if they have content
    var hasTextFieldsToValidate = false;
    if (_displayNameController.text.trim().isNotEmpty ||
        _phoneNumberController.text.trim().isNotEmpty ||
        _bioController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty) {
      hasTextFieldsToValidate = true;
    }

    if (hasTextFieldsToValidate &&
        _formKey.currentState != null &&
        !_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('Form validation failed');
      }
      return;
    }

    if (kDebugMode) {
      print('Form validation passed');
      print('Display name: ${_displayNameController.text.trim()}');
      print('Phone number: ${_phoneNumberController.text.trim()}');
      print('Bio: ${_bioController.text.trim()}');
      print('Location: ${_locationController.text.trim()}');
      print('Gender: $_selectedGender');
      print('Date of birth: $_selectedDateOfBirth');
    }

    final profileUpdateNotifier = ref.read(profileUpdateProvider.notifier);
    final avatarState = ref.read(avatarUploadProvider);

    // If there's a selected image, upload it first
    if (avatarState.selectedImage != null) {
      try {
        await ref.read(avatarUploadProvider.notifier).uploadSelectedImage();

        // Check if upload was successful
        final updatedAvatarState = ref.read(avatarUploadProvider);
        if (updatedAvatarState.error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error uploading avatar: ${updatedAvatarState.error}',
                ),
                backgroundColor: DT.c.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DT.r.sm),
                ),
              ),
            );
          }
          return;
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading avatar: $e'),
              backgroundColor: DT.c.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
            ),
          );
        }
        return;
      }
    }

    if (kDebugMode) {
      print('Calling profileUpdateNotifier.updateProfile...');
    }

    await profileUpdateNotifier.updateProfile(
      displayName: _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : null,
      phoneNumber: _phoneNumberController.text.trim().isNotEmpty
          ? _phoneNumberController.text.trim()
          : null,
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      gender: _selectedGender,
      dateOfBirth: _selectedDateOfBirth,
    );

    if (kDebugMode) {
      print('Profile update completed');
    }

    // Clear success state after 3 seconds
    Future.delayed(
      const Duration(seconds: 3),
      profileUpdateNotifier.clearSuccess,
    );
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final passwordChangeNotifier = ref.read(passwordChangeProvider.notifier);
    final passwordChangeState = ref.read(passwordChangeProvider);

    await passwordChangeNotifier.changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    // Clear success state after 3 seconds
    Future.delayed(
      const Duration(seconds: 3),
      passwordChangeNotifier.clearSuccess,
    );

    // Clear password fields on success
    if (passwordChangeState.isSuccess) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DT.c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DT.r.lg)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DT.c.textMuted,
                borderRadius: BorderRadius.circular(DT.r.full),
              ),
            ),
            SizedBox(height: DT.s.lg),

            Text(
              'Change Profile Picture',
              style: DT.t.titleLarge.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              'Choose how you want to update your profile picture',
              style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DT.s.lg),

            Row(
              children: [
                Expanded(
                  child: _buildAvatarOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                ),
                SizedBox(width: DT.s.md),
                Expanded(
                  child: _buildAvatarOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ),
                SizedBox(width: DT.s.md),
                Expanded(
                  child: _buildAvatarOption(
                    icon: Icons.delete_outline,
                    label: 'Remove',
                    onTap: () {
                      Navigator.pop(context);
                      _removeAvatar();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: DT.s.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(DT.r.md),
    child: Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.surfaceVariant,
        borderRadius: BorderRadius.circular(DT.r.md),
        border: Border.all(color: DT.c.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: DT.c.brand, size: 32),
          SizedBox(height: DT.s.sm),
          Text(
            label,
            style: DT.t.bodySmall.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      await ref.read(avatarUploadProvider.notifier).selectImageFromCamera();

      final avatarState = ref.read(avatarUploadProvider);

      if (avatarState.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(avatarState.error!),
            backgroundColor: DT.c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      } else if (avatarState.selectedImage != null && mounted) {
        setState(() {
          _selectedImage = avatarState.selectedImage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image selected from camera'),
            backgroundColor: DT.c.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: DT.c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      await ref.read(avatarUploadProvider.notifier).selectImageFromGallery();

      final avatarState = ref.read(avatarUploadProvider);

      if (avatarState.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(avatarState.error!),
            backgroundColor: DT.c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      } else if (avatarState.selectedImage != null && mounted) {
        setState(() {
          _selectedImage = avatarState.selectedImage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image selected from gallery'),
            backgroundColor: DT.c.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: DT.c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    }
  }

  /// Remove avatar
  void _removeAvatar() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DT.r.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: DT.c.warning),
            SizedBox(width: DT.s.sm),
            const Text('Remove Avatar'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove your avatar? This action cannot be undone.',
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
            onPressed: () async {
              Navigator.pop(context);
              await _performAvatarRemoval();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DT.c.error,
              foregroundColor: DT.c.textOnBrand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Perform actual avatar removal
  Future<void> _performAvatarRemoval() async {
    try {
      await ref.read(avatarUploadProvider.notifier).removeAvatar();

      final avatarState = ref.read(avatarUploadProvider);

      if (avatarState.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(avatarState.error!),
            backgroundColor: DT.c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      } else if (avatarState.isSuccess && mounted) {
        setState(() {
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avatar removed successfully'),
            backgroundColor: DT.c.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing avatar: $e'),
            backgroundColor: DT.c.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    }
  }

  void _showProfileDetails() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not found'),
          backgroundColor: DT.c.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.r.sm),
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_outline, color: DT.c.brand),
            SizedBox(width: DT.s.sm),
            const Text('Profile Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Display Name', user.displayName ?? 'Not set'),
              _buildDetailRow('Phone Number', user.phoneNumber ?? 'Not set'),
              _buildDetailRow('Bio', user.bio ?? 'Not set'),
              _buildDetailRow('Location', user.location ?? 'Not set'),
              _buildDetailRow('Gender', user.gender ?? 'Not set'),
              _buildDetailRow(
                'Date of Birth',
                user.dateOfBirth != null
                    ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
                    : 'Not set',
              ),
              _buildDetailRow('Role', user.role.toString()),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow(
                'Member Since',
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: DT.c.brand)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: DT.s.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: DT.t.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: DT.c.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: DT.t.bodyMedium.copyWith(color: DT.c.text)),
        ),
      ],
    ),
  );
}
