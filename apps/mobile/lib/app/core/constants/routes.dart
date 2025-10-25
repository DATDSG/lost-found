// Core routes
/// Route for the splash screen
const String splashRoute = '/splash';

/// Route for the onboarding flow
const String onboardingRoute = '/onboarding';

// Auth routes
/// Route for the login screen
const String loginRoute = '/login';

/// Route for the signup screen
const String signupRoute = '/signup';

/// Route for the forgot password screen
const String forgotPasswordRoute = '/forgot-password';

/// Route for the reset password screen
const String resetPasswordRoute = '/reset-password';

// Main app routes
/// Route for the home screen
const String homeRoute = '/home';

/// Route for the report screen
const String reportRoute = '/report';

/// Route for the item details screen
const String itemDetailsRoute = '/item-details';

/// Route for the matches screen
const String matchesRoute = '/matches';

/// Route for the profile screen
const String profileRoute = '/profile';

/// Route for the edit profile screen
const String editProfileRoute = '/profile/edit';

/// Route for the settings screen
const String settingsRoute = '/settings';

// Support routes
/// Route for the support screen
const String supportRoute = '/support';

/// Route for the FAQ screen
const String faqRoute = '/faq';

/// Route for the terms of service screen
const String termsOfServiceRoute = '/terms-of-service';

/// Route for the user guide screen
const String userGuideRoute = '/user-guide';

/// Route for the tutorials screen
const String tutorialsRoute = '/tutorials';

/// Route for the bug report screen
const String bugReportRoute = '/bug-report';

/// Route for the feature request screen
const String featureRequestRoute = '/feature-request';

// Helper functions for route generation
/// Generates item details route with the given item ID
String itemDetailsWithId(String id) => '$itemDetailsRoute/$id';

/// Generates reset password route with the given token
String resetPasswordWithToken(String token) => '$resetPasswordRoute/$token';
