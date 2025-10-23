import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found_mobile/app/features/splash/presentation/screens/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('should display splash screen', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify the widget is displayed
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('should have proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify basic structure exists
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
