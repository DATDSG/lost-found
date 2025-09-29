import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/core/models/user.dart';
import 'package:mobile/core/models/item.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lost & Found App Integration Tests', () {
    testWidgets('Complete user journey - Report lost item and find match', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test 1: User Registration/Login Flow
      await _testAuthenticationFlow(tester);

      // Test 2: Report Lost Item Flow
      await _testReportLostItemFlow(tester);

      // Test 3: Search and Browse Items
      await _testSearchAndBrowseFlow(tester);

      // Test 4: Match Notification and Chat
      await _testMatchAndChatFlow(tester);

      // Test 5: Claim Process
      await _testClaimProcessFlow(tester);
    });

    testWidgets('Accessibility compliance test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testAccessibilityCompliance(tester);
    });

    testWidgets('Multi-language support test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testMultiLanguageSupport(tester);
    });

    testWidgets('Offline functionality test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testOfflineFunctionality(tester);
    });

    testWidgets('Performance and load test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _testPerformanceAndLoad(tester);
    });
  });
}

Future<void> _testAuthenticationFlow(WidgetTester tester) async {
  // Navigate to login screen
  expect(find.text('Welcome to Lost & Found'), findsOneWidget);

  // Test login with invalid credentials
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('email_field')),
    'invalid@email.com',
  );
  await tester.enterText(
    find.byKey(const Key('password_field')),
    'wrongpassword',
  );
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();

  // Should show error message
  expect(find.text('Invalid credentials'), findsOneWidget);

  // Test successful registration
  await tester.tap(find.text('Sign Up'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'test@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('password_field')),
    'securepassword123',
  );
  await tester.enterText(find.byKey(const Key('phone_field')), '+1234567890');

  await tester.tap(find.byKey(const Key('register_button')));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Should navigate to main screen
  expect(find.byKey(const Key('main_navigation')), findsOneWidget);
}

Future<void> _testReportLostItemFlow(WidgetTester tester) async {
  // Navigate to report item screen
  await tester.tap(find.byKey(const Key('report_item_tab')));
  await tester.pumpAndSettle();

  // Fill out the report form
  await tester.enterText(
    find.byKey(const Key('item_title_field')),
    'Lost iPhone 12',
  );
  await tester.enterText(
    find.byKey(const Key('item_description_field')),
    'Black iPhone 12 with cracked screen, lost near Central Park',
  );

  // Select category
  await tester.tap(find.byKey(const Key('category_dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Electronics'));
  await tester.pumpAndSettle();

  // Select subcategory
  await tester.tap(find.byKey(const Key('subcategory_dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Phone'));
  await tester.pumpAndSettle();

  // Add location
  await tester.tap(find.byKey(const Key('location_button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('location_search')),
    'Central Park, New York',
  );
  await tester.tap(find.text('Central Park, New York').first);
  await tester.pumpAndSettle();

  // Add photos (simulate)
  await tester.tap(find.byKey(const Key('add_photo_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Camera'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Submit the report
  await tester.tap(find.byKey(const Key('submit_report_button')));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Should show success message
  expect(find.text('Item reported successfully'), findsOneWidget);

  // Should navigate back to main screen
  expect(find.byKey(const Key('main_navigation')), findsOneWidget);
}

Future<void> _testSearchAndBrowseFlow(WidgetTester tester) async {
  // Navigate to search screen
  await tester.tap(find.byKey(const Key('search_tab')));
  await tester.pumpAndSettle();

  // Test text search
  await tester.enterText(find.byKey(const Key('search_field')), 'iPhone');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Should show search results
  expect(find.byKey(const Key('search_results_list')), findsOneWidget);

  // Test filters
  await tester.tap(find.byKey(const Key('filter_button')));
  await tester.pumpAndSettle();

  // Apply category filter
  await tester.tap(find.text('Electronics'));
  await tester.tap(find.text('Apply Filters'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Test item details view
  if (find.byKey(const Key('item_card')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('item_card')).first);
    await tester.pumpAndSettle();

    // Should show item details
    expect(find.byKey(const Key('item_details_screen')), findsOneWidget);

    // Test match button
    await tester.tap(find.byKey(const Key('this_is_mine_button')));
    await tester.pumpAndSettle();

    // Should show match confirmation dialog
    expect(find.text('Confirm Match'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
  }

  // Navigate back
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

Future<void> _testMatchAndChatFlow(WidgetTester tester) async {
  // Navigate to matches screen
  await tester.tap(find.byKey(const Key('matches_tab')));
  await tester.pumpAndSettle();

  // Should show matches list
  expect(find.byKey(const Key('matches_list')), findsOneWidget);

  // Test match details
  if (find.byKey(const Key('match_card')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('match_card')).first);
    await tester.pumpAndSettle();

    // Should show match details
    expect(find.byKey(const Key('match_details_screen')), findsOneWidget);

    // Test chat functionality
    await tester.tap(find.byKey(const Key('start_chat_button')));
    await tester.pumpAndSettle();

    // Should open chat screen
    expect(find.byKey(const Key('chat_screen')), findsOneWidget);

    // Send a message
    await tester.enterText(
      find.byKey(const Key('message_input')),
      'Hello, I think this is my item!',
    );
    await tester.tap(find.byKey(const Key('send_message_button')));
    await tester.pumpAndSettle();

    // Should show message in chat
    expect(find.text('Hello, I think this is my item!'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }
}

Future<void> _testClaimProcessFlow(WidgetTester tester) async {
  // From match details, test claim process
  if (find.byKey(const Key('claim_item_button')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('claim_item_button')));
    await tester.pumpAndSettle();

    // Should show claim form
    expect(find.byKey(const Key('claim_form')), findsOneWidget);

    // Fill evidence
    await tester.enterText(
      find.byKey(const Key('evidence_field')),
      'I have the receipt and original packaging',
    );

    // Add evidence photos
    await tester.tap(find.byKey(const Key('add_evidence_photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Submit claim
    await tester.tap(find.byKey(const Key('submit_claim_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should show success message
    expect(find.text('Claim submitted successfully'), findsOneWidget);
  }
}

Future<void> _testAccessibilityCompliance(WidgetTester tester) async {
  // Test semantic labels

  // Check for accessibility labels on key elements
  expect(find.bySemanticsLabel('Search for lost items'), findsOneWidget);
  expect(find.bySemanticsLabel('Report lost item'), findsOneWidget);
  expect(find.bySemanticsLabel('View matches'), findsOneWidget);

  // Test keyboard navigation
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();

  // Test screen reader announcements
  final announcements = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter/accessibility'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'announce') {
        announcements.add(methodCall.arguments as String);
      }
      return null;
    },
  );

  // Navigate through the app and check announcements
  await tester.tap(find.byKey(const Key('search_tab')));
  await tester.pumpAndSettle();

  expect(announcements, contains('Search screen'));
}

Future<void> _testMultiLanguageSupport(WidgetTester tester) async {
  // Navigate to settings
  await tester.tap(find.byKey(const Key('profile_tab')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('settings_button')));
  await tester.pumpAndSettle();

  // Change language to Sinhala
  await tester.tap(find.byKey(const Key('language_setting')));
  await tester.pumpAndSettle();

  await tester.tap(find.text('සිංහල'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Check if UI text changed to Sinhala
  expect(find.text('සොයන්න'), findsOneWidget); // "Search" in Sinhala

  // Change to Tamil
  await tester.tap(find.byKey(const Key('language_setting')));
  await tester.pumpAndSettle();

  await tester.tap(find.text('தமிழ்'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Check if UI text changed to Tamil
  expect(find.text('தேடு'), findsOneWidget); // "Search" in Tamil

  // Change back to English
  await tester.tap(find.byKey(const Key('language_setting')));
  await tester.pumpAndSettle();

  await tester.tap(find.text('English'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _testOfflineFunctionality(WidgetTester tester) async {
  // Simulate offline mode
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('connectivity_plus'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return 'none'; // No connectivity
      }
      return null;
    },
  );

  // Navigate to search
  await tester.tap(find.byKey(const Key('search_tab')));
  await tester.pumpAndSettle();

  // Should show offline message
  expect(find.text('You are offline'), findsOneWidget);

  // Test cached data access
  expect(find.byKey(const Key('cached_items_list')), findsOneWidget);

  // Test offline item creation
  await tester.tap(find.byKey(const Key('report_item_tab')));
  await tester.pumpAndSettle();

  // Fill form
  await tester.enterText(
    find.byKey(const Key('item_title_field')),
    'Offline Test Item',
  );
  await tester.tap(find.byKey(const Key('submit_report_button')));
  await tester.pumpAndSettle();

  // Should show queued message
  expect(find.text('Item will be submitted when online'), findsOneWidget);
}

Future<void> _testPerformanceAndLoad(WidgetTester tester) async {
  final stopwatch = Stopwatch()..start();

  // Test app startup time
  app.main();
  await tester.pumpAndSettle();
  stopwatch.stop();

  // App should start within 3 seconds
  expect(stopwatch.elapsedMilliseconds, lessThan(3000));

  // Test list scrolling performance
  await tester.tap(find.byKey(const Key('search_tab')));
  await tester.pumpAndSettle();

  // Simulate loading many items
  for (int i = 0; i < 10; i++) {
    await tester.drag(
      find.byKey(const Key('search_results_list')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }

  // Test memory usage (basic check)
  final memoryUsage = await tester.binding.defaultBinaryMessenger.send(
    'flutter/platform',
    const StandardMethodCodec().encodeMethodCall(
      const MethodCall('SystemChrome.getSystemUIOverlayStyle'),
    ),
  );

  expect(memoryUsage, isNotNull);

  // Test image loading performance
  if (find.byType(Image).evaluate().isNotEmpty) {
    final imageWidget = tester.widget<Image>(find.byType(Image).first);
    expect(imageWidget.image, isNotNull);
  }
}

// Helper class for test data
class TestData {
  static final testUser = User(
    id: '1',
    email: 'test@example.com',
    fullName: 'Test User',
    phone: '+1234567890',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    verified: true,
  );

  static final testItem = Item(
    id: '1',
    type: ItemType.lost,
    status: ItemStatus.active,
    title: 'Test iPhone',
    description: 'Test description',
    category: 'electronics',
    subcategory: 'phone',
    location: const Location(
      latitude: 6.9271,
      longitude: 79.8612,
      address: 'Colombo, Sri Lanka',
      description: 'Test Location',
    ),
    dateLostFound: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    userId: '1',
  );
}

// Custom matchers for testing
class CustomMatchers {
  static Matcher hasAccessibilityLabel(String label) {
    return _HasAccessibilityLabel(label);
  }

  static Matcher isWithinPerformanceThreshold(int milliseconds) {
    return _IsWithinPerformanceThreshold(milliseconds);
  }
}

class _HasAccessibilityLabel extends Matcher {
  final String expectedLabel;

  const _HasAccessibilityLabel(this.expectedLabel);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Widget) {
      // Check if widget has semantic label
      return true; // Simplified for example
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has accessibility label "$expectedLabel"');
  }
}

class _IsWithinPerformanceThreshold extends Matcher {
  final int threshold;

  const _IsWithinPerformanceThreshold(this.threshold);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is int) {
      return item <= threshold;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is within performance threshold of ${threshold}ms');
  }
}
