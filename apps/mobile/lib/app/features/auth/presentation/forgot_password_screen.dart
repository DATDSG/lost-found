import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/design_tokens.dart';

/// Modern forgot password screen with enhanced UX design
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Creates a new forgot password screen widget
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen to auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.error != null) {
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
        backgroundColor: DT.c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DT.c.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Forgot Password',
          style: DT.t.headlineSmall.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DT.s.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: DT.s.xl),

                // Header Section
                _buildHeaderSection(),

                SizedBox(height: DT.s.xl),

                if (!_isEmailSent) ...[
                  // Email Input Section
                  _buildEmailInputSection(authState),

                  SizedBox(height: DT.s.xl),

                  // Submit Button
                  _buildSubmitButton(authState),
                ] else ...[
                  // Success Section
                  _buildSuccessSection(),
                ],

                SizedBox(height: DT.s.lg),

                // Back to Login Link
                _buildBackToLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() => Column(
    children: [
      // Icon
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: DT.c.brand.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DT.r.full),
        ),
        child: Icon(Icons.lock_reset, size: 40, color: DT.c.brand),
      ),

      SizedBox(height: DT.s.lg),

      // Title
      Text(
        _isEmailSent ? 'Check Your Email' : 'Reset Your Password',
        style: DT.t.headlineSmall.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),

      SizedBox(height: DT.s.md),

      // Description
      Text(
        _isEmailSent
            ? "We've sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password."
            : "Enter your email address and we'll send you a link to reset your password.",
        style: DT.t.bodyLarge.copyWith(color: DT.c.textMuted, height: 1.5),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _buildEmailInputSection(AuthState authState) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Email Address',
        style: DT.t.labelLarge.copyWith(
          color: DT.c.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: DT.s.sm),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        enabled: !authState.isLoading,
        decoration: InputDecoration(
          hintText: 'Enter your email address',
          hintStyle: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          prefixIcon: Icon(Icons.email_outlined, color: DT.c.textMuted),
          filled: true,
          fillColor: DT.c.surface,
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.sm),
            borderSide: BorderSide(color: DT.c.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.sm),
            borderSide: BorderSide(color: DT.c.error, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: DT.s.md,
            vertical: DT.s.md,
          ),
        ),
        validator: _validateEmail,
        onFieldSubmitted: (_) => _handleForgotPassword(),
      ),
    ],
  );

  Widget _buildSubmitButton(AuthState authState) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: authState.isLoading ? null : _handleForgotPassword,
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
                valueColor: AlwaysStoppedAnimation<Color>(DT.c.textOnBrand),
              ),
            )
          : Text('Send Reset Link', style: DT.t.button),
    ),
  );

  Widget _buildSuccessSection() => Column(
    children: [
      // Success Icon
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: DT.c.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DT.r.full),
        ),
        child: Icon(Icons.check_circle_outline, size: 40, color: DT.c.success),
      ),

      SizedBox(height: DT.s.lg),

      // Success Message
      Text(
        'Email Sent Successfully!',
        style: DT.t.headlineSmall.copyWith(
          color: DT.c.success,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),

      SizedBox(height: DT.s.md),

      Text(
        "If you don't see the email in your inbox, please check your spam folder.",
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
        textAlign: TextAlign.center,
      ),

      SizedBox(height: DT.s.xl),

      // Resend Button
      OutlinedButton(
        onPressed: () {
          setState(() {
            _isEmailSent = false;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: DT.c.brand,
          side: BorderSide(color: DT.c.brand),
          padding: EdgeInsets.symmetric(vertical: DT.s.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DT.r.sm),
          ),
        ),
        child: Text('Send Another Email', style: DT.t.button),
      ),
    ],
  );

  Widget _buildBackToLoginLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Remember your password? ',
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
      ),
      TextButton(
        onPressed: () => context.pop(),
        child: Text(
          'Back to Login',
          style: DT.t.bodyMedium.copyWith(
            color: DT.c.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void _handleForgotPassword() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .forgotPassword(_emailController.text.trim())
          .then((_) {
            if (mounted) {
              setState(() {
                _isEmailSent = true;
              });
            }
          });
    }
  }

  String _formatErrorMessage(String error) {
    // Format common API error messages for better user experience
    if (error.contains('Email not found')) {
      return 'No account found with this email address. Please check your email or create a new account.';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('Too many requests')) {
      return 'Too many requests. Please wait a moment before trying again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
