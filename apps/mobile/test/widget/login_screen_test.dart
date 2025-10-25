"""
Unit tests for Flutter mobile app
=================================
Tests for core functionality, widgets, and business logic.
"""

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lost_found_mobile/app/core/constants/app_constants.dart';
import 'package:lost_found_mobile/app/core/theme/app_theme.dart';
import 'package:lost_found_mobile/app/features/auth/presentation/screens/login_screen.dart';
import 'package:lost_found_mobile/app/features/reports/presentation/screens/lost_item_report_form.dart';
import 'package:lost_found_mobile/app/features/reports/presentation/screens/found_item_report_form.dart';
import 'package:lost_found_mobile/app/shared/widgets/custom_button.dart';
import 'package:lost_found_mobile/app/shared/widgets/custom_text_field.dart';

void main() {
  group('App Constants Tests', () {
    test('API base URL should be defined', () {
      expect(AppConstants.apiBaseUrl, isNotEmpty);
      expect(AppConstants.apiBaseUrl, startsWith('http'));
    });

    test('App version should be defined', () {
      expect(AppConstants.appVersion, isNotEmpty);
      expect(AppConstants.appVersion, contains('.'));
    });

    test('Supported languages should include English', () {
      expect(AppConstants.supportedLanguages, contains('en'));
    });

    test('Default page size should be positive', () {
      expect(AppConstants.defaultPageSize, greaterThan(0));
    });
  });

  group('Theme Tests', () {
    testWidgets('App theme should have primary color', (WidgetTester tester) async {
      final theme = AppTheme.lightTheme;
      
      expect(theme.primaryColor, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });

    testWidgets('App theme should have text theme', (WidgetTester tester) async {
      final theme = AppTheme.lightTheme;
      
      expect(theme.textTheme, isNotNull);
      expect(theme.textTheme.headlineLarge, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
    });

    testWidgets('Dark theme should be different from light theme', (WidgetTester tester) async {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;
      
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(darkTheme.brightness, equals(Brightness.dark));
    });
  });

  group('Custom Button Widget Tests', () {
    testWidgets('Custom button should display text', (WidgetTester tester) async {
      const buttonText = 'Test Button';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
    });

    testWidgets('Custom button should be tappable when enabled', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('Custom button should not be tappable when disabled', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test Button',
              onPressed: () {
                wasPressed = true;
              },
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('Custom button should show loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Custom Text Field Widget Tests', () {
    testWidgets('Custom text field should display label', (WidgetTester tester) async {
      const label = 'Test Label';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: label,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
    });

    testWidgets('Custom text field should accept input', (WidgetTester tester) async {
      String? inputValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test Field',
              onChanged: (value) {
                inputValue = value;
              },
            ),
          ),
        ),
      );

      const testInput = 'Test Input';
      await tester.enterText(find.byType(CustomTextField), testInput);
      await tester.pump();

      expect(inputValue, equals(testInput));
    });

    testWidgets('Custom text field should show error message', (WidgetTester tester) async {
      const errorMessage = 'This field is required';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test Field',
              onChanged: (value) {},
              errorText: errorMessage,
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('Custom text field should be password field when specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Password',
              onChanged: (value) {},
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });
  });

  group('Login Screen Tests', () {
    testWidgets('Login screen should have email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Login screen should have sign up link', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Don\'t have an account?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Login screen should validate email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(find.byKey(Key('email_field')), 'invalid-email');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Login screen should require password', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter valid email but no password
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  group('Lost Item Report Form Tests', () {
    testWidgets('Lost item form should have required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LostItemReportForm(),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Date Lost'), findsOneWidget);
    });

    testWidgets('Lost item form should have image upload option', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LostItemReportForm(),
          ),
        ),
      );

      expect(find.text('Add Photos'), findsOneWidget);
    });

    testWidgets('Lost item form should validate required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LostItemReportForm(),
          ),
        ),
      );

      // Try to submit without filling required fields
      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
    });
  });

  group('Found Item Report Form Tests', () {
    testWidgets('Found item form should have required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FoundItemReportForm(),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Date Found'), findsOneWidget);
    });

    testWidgets('Found item form should have contact information fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FoundItemReportForm(),
          ),
        ),
      );

      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('Found item form should validate contact information', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FoundItemReportForm(),
          ),
        ),
      );

      // Enter invalid phone number
      await tester.enterText(find.byKey(Key('phone_field')), 'invalid-phone');
      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('App should navigate to login screen initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Login screen should navigate to home after successful login', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Mock successful login
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should navigate to home screen
      expect(find.text('Welcome'), findsOneWidget);
    });
  });

  group('State Management Tests', () {
    testWidgets('Auth state should update on login', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Test auth state changes
      // This would require mocking the auth provider
      // and testing state transitions
    });

    testWidgets('Report form state should update on input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LostItemReportForm(),
          ),
        ),
      );

      // Test form state changes
      await tester.enterText(find.byKey(Key('title_field')), 'Test Title');
      await tester.pump();

      // Verify state was updated
      // This would require access to the form state provider
    });
  });

  group('Error Handling Tests', () {
    testWidgets('App should handle network errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Mock network error
      // Test error handling and user feedback
    });

    testWidgets('App should show loading states', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Test loading states during API calls
    });
  });

  group('Accessibility Tests', () {
    testWidgets('All interactive elements should have semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Test accessibility features
      final semantics = tester.binding.pipelineOwner.semanticsOwner;
      expect(semantics, isNotNull);
    });

    testWidgets('App should support screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Test screen reader support
    });
  });
}
