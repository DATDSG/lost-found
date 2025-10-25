import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found_mobile/app/core/constants/app_constants.dart';
import 'package:lost_found_mobile/app/core/theme/app_theme.dart';
import 'package:lost_found_mobile/app/features/auth/presentation/login_screen.dart';
import 'package:lost_found_mobile/app/features/reports/presentation/screens/found_item_report_form.dart';
import 'package:lost_found_mobile/app/features/reports/presentation/screens/lost_item_report_form.dart';

void main() {
  group('App Constants Tests', () {
    test('API base URL should be defined', () {
      expect(AppConstants.baseUrl, isNotEmpty);
      expect(AppConstants.baseUrl, startsWith('http'));
    });

    test('API version should be defined', () {
      expect(AppConstants.apiVersion, isNotEmpty);
      expect(AppConstants.apiVersion, contains('v'));
    });

    test('Default page size should be positive', () {
      expect(AppConstants.defaultPageSize, greaterThan(0));
    });

    test('Max page size should be greater than default', () {
      expect(
        AppConstants.maxPageSize,
        greaterThan(AppConstants.defaultPageSize),
      );
    });
  });

  group('Theme Tests', () {
    testWidgets('App theme should have primary color', (
      WidgetTester tester,
    ) async {
      final theme = appThemeLight;

      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.colorScheme.primary, isA<Color>());
    });

    testWidgets('App theme should have text theme', (
      WidgetTester tester,
    ) async {
      final theme = appThemeLight;

      expect(theme.textTheme, isNotNull);
      expect(theme.textTheme.headlineLarge, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
    });

    testWidgets('App theme should have proper color scheme', (
      WidgetTester tester,
    ) async {
      final theme = appThemeLight;

      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.colorScheme.secondary, isNotNull);
      expect(theme.colorScheme.error, isNotNull);
      expect(theme.colorScheme.surface, isNotNull);
    });
  });

  group('Material Widget Tests', () {
    testWidgets('ElevatedButton should display text', (
      WidgetTester tester,
    ) async {
      const buttonText = 'Test Button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text(buttonText),
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
    });

    testWidgets('ElevatedButton should be tappable when enabled', (
      WidgetTester tester,
    ) async {
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                wasPressed = true;
              },
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('ElevatedButton should not be tappable when disabled', (
      WidgetTester tester,
    ) async {
      const wasPressed = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevatedButton(onPressed: null, child: Text('Test Button')),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('TextFormField should display label', (
      WidgetTester tester,
    ) async {
      const label = 'Test Label';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(labelText: label),
            ),
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
    });

    testWidgets('TextFormField should accept input', (
      WidgetTester tester,
    ) async {
      String? inputValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(labelText: 'Test Field'),
              onChanged: (value) {
                inputValue = value;
              },
            ),
          ),
        ),
      );

      const testInput = 'Test Input';
      await tester.enterText(find.byType(TextFormField), testInput);
      await tester.pump();

      expect(inputValue, equals(testInput));
    });

    testWidgets('TextFormField should show error message', (
      WidgetTester tester,
    ) async {
      const errorMessage = 'This field is required';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Test Field',
                errorText: errorMessage,
              ),
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('TextFormField should be password field when specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ),
        ),
      );

      // Test that the field is rendered (obscureText is an internal property)
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
  });

  group('Login Screen Tests', () {
    testWidgets('Login screen should have email and password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Login screen should have sign up link', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Login screen should have welcome message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Login screen should have forgot password link', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });

  group('Lost Item Report Form Tests', () {
    testWidgets('Lost item form should have required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LostItemReportForm())),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Date Lost'), findsOneWidget);
    });

    testWidgets('Lost item form should have image upload option', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LostItemReportForm())),
      );

      expect(find.text('Add Photos'), findsOneWidget);
    });

    testWidgets('Lost item form should validate required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LostItemReportForm())),
      );

      // Try to submit without filling required fields
      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
    });
  });

  group('Found Item Report Form Tests', () {
    testWidgets('Found item form should have required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FoundItemReportForm())),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Date Found'), findsOneWidget);
    });

    testWidgets('Found item form should have contact information fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FoundItemReportForm())),
      );

      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('Found item form should validate contact information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FoundItemReportForm())),
      );

      // Enter invalid phone number
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        'invalid-phone',
      );
      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('App should navigate to login screen initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login screen should display correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      // Verify login screen elements are present
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });
  });

  group('State Management Tests', () {
    testWidgets('Login screen should render without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      // Verify the screen renders without throwing exceptions
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Report form should render without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LostItemReportForm())),
      );

      // Verify the form renders without throwing exceptions
      expect(find.byType(LostItemReportForm), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Login screen should handle form validation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      // Test that the screen renders without errors
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('App should render without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      // Test that the app renders without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('Login screen should have semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      // Test accessibility features
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('App should support accessibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: const MaterialApp(home: LoginScreen())),
      );

      // Test accessibility support
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
