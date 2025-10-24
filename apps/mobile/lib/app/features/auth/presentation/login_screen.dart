import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/design_tokens.dart';

/// Modern login screen with enhanced UX design following design science principles
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a new login screen widget
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < DesignBreakpoints.mobile;

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
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(DT.s.md),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: DT.c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? DT.s.md : DT.s.lg,
            vertical: DT.s.lg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section with improved spacing
                    _buildHeaderSection(isSmallScreen),

                    SizedBox(height: DT.s.xl * 1.5),

                    // Form Fields with better accessibility
                    _buildFormFields(isSmallScreen),

                    SizedBox(height: DT.s.lg),

                    // Action Buttons
                    _buildActionButtons(authState),

                    SizedBox(height: DT.s.lg),

                    // Sign Up Link
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DT.c.brand,
          DT.c.brand.withValues(alpha: 0.8),
          DT.c.accentGreen.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.circular(DT.r.xl),
      boxShadow: [
        BoxShadow(
          color: DT.c.brand.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(DT.s.xl),
      child: Column(
        children: [
          // Enhanced Logo with Better Design
          Semantics(
            label: 'Lost and Found App Logo',
            child: Container(
              height: isSmallScreen ? 80 : 100,
              width: isSmallScreen ? 80 : 100,
              decoration: BoxDecoration(
                color: DT.c.textOnBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.xl),
                border: Border.all(
                  color: DT.c.textOnBrand.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DT.r.xl),
                child: Image.asset(
                  'assets/images/App Logo.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Lost and Found App Logo',
                ),
              ),
            ),
          ),

          SizedBox(height: DT.s.lg),

          // Enhanced Title with Better Typography
          Text(
            'Welcome Back!',
            style: DT.t.headlineSmall.copyWith(
              color: DT.c.textOnBrand,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontSize: isSmallScreen ? 24 : 28,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: DT.s.sm),

          // Enhanced Subtitle with Better Visual Hierarchy
          Text(
            'Sign in to continue helping reunite people with their belongings',
            style: DT.t.bodyLarge.copyWith(
              color: DT.c.textOnBrand.withValues(alpha: 0.9),
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildFormFields(bool isSmallScreen) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Email Field with enhanced accessibility
      Semantics(
        label: 'Email address input field',
        textField: true,
        child: TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: DT.c.textMuted,
              semanticLabel: 'Email icon',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.brand, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.error, width: 2),
            ),
            filled: true,
            fillColor: DT.c.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: DT.s.md,
              vertical: DT.s.md,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
      ),

      SizedBox(height: DT.s.lg),

      // Password Field with enhanced accessibility
      Semantics(
        label: 'Password input field',
        textField: true,
        child: TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icon(
              Icons.lock_outlined,
              color: DT.c.textMuted,
              semanticLabel: 'Password icon',
            ),
            suffixIcon: Semantics(
              label: _isPasswordVisible ? 'Hide password' : 'Show password',
              button: true,
              child: IconButton(
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
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.brand, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DT.r.md),
              borderSide: BorderSide(color: DT.c.error, width: 2),
            ),
            filled: true,
            fillColor: DT.c.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: DT.s.md,
              vertical: DT.s.md,
            ),
          ),
          obscureText: !_isPasswordVisible,
          validator: _validatePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _handleLogin(),
        ),
      ),

      SizedBox(height: DT.s.md),

      // Forgot Password Link with improved accessibility
      Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          label: 'Forgot password link',
          button: true,
          child: TextButton(
            onPressed: () => context.push(forgotPasswordRoute),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: DT.s.sm,
                vertical: DT.s.xs,
              ),
            ),
            child: Text(
              'Forgot Password?',
              style: DT.t.bodySmall.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildActionButtons(AuthState authState) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Remember Me Checkbox
      Semantics(
        label: 'Remember me checkbox',
        child: CheckboxListTile(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          title: Text(
            'Remember Me',
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Keep me signed in',
            style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
          ),
          activeColor: DT.c.brand,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
      ),

      SizedBox(height: DT.s.md),

      // Login Button with enhanced accessibility
      Semantics(
        label: 'Sign in button',
        button: true,
        enabled: !authState.isLoading,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: DT.c.brand,
              foregroundColor: DT.c.textOnBrand,
              padding: EdgeInsets.symmetric(vertical: DT.s.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DT.r.md),
              ),
              elevation: 2,
            ),
            child: authState.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DT.c.textOnBrand,
                      ),
                    ),
                  )
                : Text(
                    'Sign In',
                    style: DT.t.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    ],
  );

  Widget _buildSignUpLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Don't have an account? ",
        style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
      ),
      Semantics(
        label: 'Sign up link',
        button: true,
        child: TextButton(
          onPressed: () => context.push(signupRoute),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.sm,
              vertical: DT.s.xs,
            ),
          ),
          child: Text(
            'Sign Up',
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );

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
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authStateProvider.notifier)
          .login(
            _emailController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
    }
  }

  String _formatErrorMessage(String error) {
    // Format common API error messages for better user experience
    if (error.contains('Incorrect email or password')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    } else if (error.contains('User account is disabled')) {
      return 'Your account has been disabled. Please contact support for assistance.';
    } else if (error.contains('Email already registered')) {
      return 'An account with this email already exists. Please try logging in instead.';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('Password must be')) {
      return 'Password does not meet requirements. Please check and try again.';
    } else if (error.contains('Network') ||
        error.contains('Connection') ||
        error.contains('SocketException')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.contains('timeout') ||
        error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('HandshakeException') || error.contains('SSL')) {
      return 'Connection error. Please check your network settings.';
    } else if (error.contains('FormatException') || error.contains('JSON')) {
      return 'Server response error. Please try again.';
    } else if (error.contains('HttpException')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}
