import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/design_tokens.dart';

/// Modern splash screen with design science principles and accessibility
class SplashScreen extends ConsumerStatefulWidget {
  /// Creates a new [SplashScreen] instance
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _progressOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _particleOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Background animation
    _backgroundOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Progress animations
    _progressOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleOpacity = Tween<double>(begin: 0, end: 0.6).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startAnimations() async {
    // Start background animation immediately
    unawaited(_backgroundController.forward());

    // Start particle animation
    unawaited(_particleController.forward());

    // Start logo animation after a short delay
    await Future<void>.delayed(const Duration(milliseconds: 400));
    unawaited(_logoController.forward());

    // Start text animation after logo starts
    await Future<void>.delayed(const Duration(milliseconds: 800));
    unawaited(_textController.forward());

    // Start progress animation
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    unawaited(_progressController.forward());

    // Navigate to appropriate screen after animations complete
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      unawaited(HapticFeedback.lightImpact());

      // Check authentication status and attempt auto-login
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated && authState.user != null) {
        ref.read(appRouterProvider).go(homeRoute);
      } else {
        // Attempt auto-login if remember me is enabled
        final authNotifier = ref.read(authStateProvider.notifier);
        final autoLoginSuccess = await authNotifier.autoLogin();

        if (autoLoginSuccess && mounted) {
          ref.read(appRouterProvider).go(homeRoute);
        } else {
          ref.read(appRouterProvider).go(loginRoute);
        }
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedBuilder(
      animation: _backgroundOpacity,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DT.c.gradientStart, DT.c.gradientEnd, DT.c.brandDeep],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Semantics(
            label: 'Lost & Found app loading screen',
            child: Stack(
              children: [
                // Animated background particles
                _buildParticles(),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // App logo with enhanced animation
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) => Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: DT.c.textOnBrand.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(DT.r.xl),
                                  border: Border.all(
                                    color: DT.c.textOnBrand.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DT.c.textOnBrand.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(DT.s.lg),
                                  child: Image.asset(
                                    'assets/images/App Logo.png',
                                    fit: BoxFit.contain,
                                    semanticLabel: 'Lost Finder app logo',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: DT.s.xl),

                      // App name with slide animation
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) => SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textOpacity,
                            child: Column(
                              children: [
                                Text(
                                  'Lost & Found',
                                  style: DT.t.displayMedium.copyWith(
                                    color: DT.c.textOnBrand,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: DT.c.textOnBrand.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: DT.s.sm),
                                Text(
                                  "Find what you're looking for",
                                  style: DT.t.bodyLarge.copyWith(
                                    color: DT.c.textOnBrand.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Progress indicator
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) => FadeTransition(
                          opacity: _progressOpacity,
                          child: Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: DT.c.textOnBrand.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(DT.r.full),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressValue,
                              builder: (context, child) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressValue.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: DT.c.textOnBrand,
                                    borderRadius: BorderRadius.circular(
                                      DT.r.full,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DT.c.textOnBrand.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: DT.s.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildParticles() => AnimatedBuilder(
    animation: _particleOpacity,
    builder: (context, child) => Opacity(
      opacity: _particleOpacity.value,
      child: CustomPaint(painter: ParticlePainter(), size: Size.infinite),
    ),
  );
}

/// Custom painter for animated background particles
class ParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DT.c.textOnBrand.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (var i = 0; i < 20; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 23.0) % size.height;
      final radius = (i % 3 + 1) * 2.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
