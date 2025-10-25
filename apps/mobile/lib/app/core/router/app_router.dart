import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/matches/presentation/screens/matches_screen.dart';
import '../../features/matches/presentation/screens/matching_details_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/found_item_report_form.dart';
import '../../features/reports/presentation/screens/lost_item_report_form.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/test/presentation/screens/connectivity_test_screen.dart';
import '../constants/routes.dart';

/// Application router configuration
///
/// This provider configures the GoRouter with all app routes
final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: splashRoute,
    routes: [
      GoRoute(
        path: splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signupRoute,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: forgotPasswordRoute,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: homeRoute,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: matchesRoute,
        name: 'matches',
        builder: (context, state) => const MatchesScreen(),
      ),
      GoRoute(
        path: '/report-detail/:reportId',
        name: 'report-detail',
        builder: (context, state) {
          final reportId = state.pathParameters['reportId']!;
          return ReportDetailScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/matching-details/:reportId',
        name: 'matching-details',
        builder: (context, state) {
          final reportId = state.pathParameters['reportId']!;
          return MatchingDetailsScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: reportRoute,
        name: 'report',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/lost-report',
        name: 'lost-report',
        builder: (context, state) => const LostItemReportForm(),
      ),
      GoRoute(
        path: '/found-report',
        name: 'found-report',
        builder: (context, state) => const FoundItemReportForm(),
      ),
      GoRoute(
        path: profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: editProfileRoute,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/test-connectivity',
        name: 'test-connectivity',
        builder: (context, state) => const ConnectivityTestScreen(),
      ),
      // Add more routes as you develop features
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "The page you're looking for doesn't exist.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(homeRoute),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  ),
);
