import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/design_tokens.dart';

/// Modern signup screen with enhanced UX design
class SignupScreen extends ConsumerStatefulWidget {
  /// Creates a new signup screen widget
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen to auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go(homeRoute);
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatErrorMessage(next.error!)),
            backgroundColor: DT.c.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: DT.c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: DT.c.text),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(DT.s.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: DT.s.md),

                // Header Section
                Column(
                  children: [
                    // Logo
                    Container(
                      height: 80,
                      margin: EdgeInsets.only(bottom: DT.s.lg),
                      child: Image.asset(
                        'assets/images/App Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Title
                    Text(
                      'Create Account',
                      style: DT.t.titleLarge.copyWith(
                        color: DT.c.text,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: DT.s.sm),

                    Text(
                      'Join our community and help reunite people with their belongings',
                      style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                SizedBox(height: DT.s.xl),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(
                      Icons.person_outlined,
                      color: DT.c.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.brand, width: 2),
                    ),
                    filled: true,
                    fillColor: DT.c.surface,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: DT.s.md),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: DT.c.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.brand, width: 2),
                    ),
                    filled: true,
                    fillColor: DT.c.surface,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: DT.s.md),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a strong password',
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: DT.c.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: DT.c.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.brand, width: 2),
                    ),
                    filled: true,
                    fillColor: DT.c.surface,
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: DT.s.md),

                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: DT.c.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: DT.c.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DT.r.sm),
                      borderSide: BorderSide(color: DT.c.brand, width: 2),
                    ),
                    filled: true,
                    fillColor: DT.c.surface,
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                ),
                SizedBox(height: DT.s.lg),

                // Terms and Conditions
                _buildTermsCheckbox(),
                SizedBox(height: DT.s.xl),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DT.c.brand,
                      foregroundColor: DT.c.textOnBrand,
                      padding: EdgeInsets.symmetric(vertical: DT.s.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DT.r.sm),
                      ),
                    ),
                    child: authState.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                DT.c.textOnBrand,
                              ),
                            ),
                          )
                        : Text('Create Account', style: DT.t.button),
                  ),
                ),
                SizedBox(height: DT.s.md),

                // Sign In Link
                _buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      ref
          .read(authStateProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms and conditions'),
          backgroundColor: DT.c.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.r.sm),
          ),
        ),
      );
    }
  }

  Widget _buildTermsCheckbox() => Row(
    children: [
      Checkbox(
        value: _acceptTerms,
        onChanged: (newValue) {
          setState(() {
            _acceptTerms = newValue!;
          });
        },
        activeColor: DT.c.brand,
        checkColor: DT.c.textOnBrand,
        side: BorderSide(color: DT.c.border),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _acceptTerms = !_acceptTerms;
            });
          },
          child: RichText(
            text: TextSpan(
              style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: DT.t.bodySmall.copyWith(
                    color: DT.c.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: DT.t.bodySmall.copyWith(
                    color: DT.c.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildSignInLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Already have an account? ',
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
      ),
      TextButton(
        onPressed: () => context.pop(),
        child: Text(
          'Sign In',
          style: DT.t.bodyMedium.copyWith(
            color: DT.c.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String _formatErrorMessage(String error) {
    // Format common API error messages for better user experience
    if (error.contains('Email already registered')) {
      return 'An account with this email already exists. Please try logging in instead.';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('Password must be')) {
      return 'Password does not meet requirements. Please check and try again.';
    } else if (error.contains('Display name')) {
      return 'Please enter a valid display name.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
