import 'package:flutter_test/flutter_test.dart';

import '../lib/services/api_input_validator.dart';
import '../lib/services/api_response_handler.dart';
import '../lib/services/data_transformation_service.dart';

void main() {
  group('API Integration Tests', () {
    late ApiInputValidator inputValidator;
    late ApiResponseHandler responseHandler;
    late DataTransformationService dataTransformer;

    setUp(() {
      inputValidator = ApiInputValidator();
      responseHandler = ApiResponseHandler();
      dataTransformer = DataTransformationService();
    });

    group('Input Validation Tests', () {
      test('should validate email correctly', () {
        // Valid email
        final validResult = inputValidator.validateEmail('test@example.com');
        expect(validResult.isValid, true);
        expect(validResult.errors, isEmpty);

        // Invalid email
        final invalidResult = inputValidator.validateEmail('invalid-email');
        expect(invalidResult.isValid, false);
        expect(invalidResult.errors, isNotEmpty);
      });

      test('should validate password correctly', () {
        // Valid password
        final validResult = inputValidator.validatePassword('Password123');
        expect(validResult.isValid, true);
        expect(validResult.errors, isEmpty);

        // Invalid password (too short)
        final invalidResult = inputValidator.validatePassword('123');
        expect(invalidResult.isValid, false);
        expect(invalidResult.errors, contains('Password must be at least 8 characters long'));
      });

      test('should validate report data correctly', () {
        final validReportData = {
          'title': 'Lost iPhone',
          'description': 'Lost my iPhone at the park yesterday',
          'type': 'lost',
          'category': 'electronics',
          'city': 'New York',
          'occurred_at': DateTime.now().toIso8601String(),
        };

        final result = inputValidator.validateReportData(validReportData);
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should validate display name correctly', () {
        // Valid display name
        final validResult = inputValidator.validateDisplayName('John Doe');
        expect(validResult.isValid, true);
        expect(validResult.errors, isEmpty);

        // Invalid display name (too short)
        final invalidResult = inputValidator.validateDisplayName('J');
        expect(invalidResult.isValid, false);
        expect(invalidResult.errors, contains('Display name must be at least 2 characters long'));
      });

      test('should validate phone number correctly', () {
        // Valid phone number
        final validResult = inputValidator.validatePhoneNumber('+1234567890');
        expect(validResult.isValid, true);
        expect(validResult.errors, isEmpty);

        // Invalid phone number
        final invalidResult = inputValidator.validatePhoneNumber('123');
        expect(invalidResult.isValid, false);
        expect(invalidResult.errors, isNotEmpty);
      });
    });

    group('Data Transformation Tests', () {
      test('should transform auth token correctly', () {
        final tokenData = {
          'access_token': 'test_access_token',
          'refresh_token': 'test_refresh_token',
          'token_type': 'Bearer',
        };

        final token = dataTransformer.transformAuthToken(tokenData);
        expect(token, isNotNull);
        expect(token!.accessToken, 'test_access_token');
        expect(token.refreshToken, 'test_refresh_token');
        expect(token.tokenType, 'Bearer');
      });

      test('should transform user data correctly', () {
        final userData = {
          'id': 'user_123',
          'email': 'test@example.com',
          'display_name': 'Test User',
          'role': 'user',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        final user = dataTransformer.transformUser(userData);
        expect(user, isNotNull);
        expect(user!.id, 'user_123');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
      });

      test('should transform report data correctly', () {
        final reportData = {
          'id': 'report_123',
          'type': 'lost',
          'title': 'Lost iPhone',
          'description': 'Lost my iPhone at the park',
          'category': 'electronics',
          'city': 'New York',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'occurred_at': DateTime.now().toIso8601String(),
        };

        final report = dataTransformer.transformReport(reportData);
        expect(report, isNotNull);
        expect(report!.id, 'report_123');
        expect(report.type, 'lost');
        expect(report.title, 'Lost iPhone');
        expect(report.description, 'Lost my iPhone at the park');
      });

      test('should transform list of reports correctly', () {
        final reportsData = [
          {
            'id': 'report_1',
            'type': 'lost',
            'title': 'Lost iPhone',
            'description': 'Lost my iPhone',
            'category': 'electronics',
            'city': 'New York',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'occurred_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'report_2',
            'type': 'found',
            'title': 'Found Wallet',
            'description': 'Found a wallet',
            'category': 'personal',
            'city': 'Boston',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'occurred_at': DateTime.now().toIso8601String(),
          },
        ];

        final reports = dataTransformer.transformReports(reportsData);
        expect(reports, isNotNull);
        expect(reports.length, 2);
        expect(reports[0].id, 'report_1');
        expect(reports[1].id, 'report_2');
      });
    });

    group('API Response Handler Tests', () {
      test('should handle auth response correctly', () {
        final authData = {
          'access_token': 'test_access_token',
          'refresh_token': 'test_refresh_token',
          'token_type': 'Bearer',
        };

        final token = responseHandler.handleAuthResponse(authData);
        expect(token, isNotNull);
        expect(token!.accessToken, 'test_access_token');
        expect(token.refreshToken, 'test_refresh_token');
      });

      test('should handle user response correctly', () {
        final userData = {
          'id': 'user_123',
          'email': 'test@example.com',
          'display_name': 'Test User',
          'role': 'user',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        final user = responseHandler.handleUserResponse(userData);
        expect(user, isNotNull);
        expect(user!.id, 'user_123');
        expect(user.email, 'test@example.com');
      });

      test('should handle reports response correctly', () {
        final reportsData = [
          {
            'id': 'report_1',
            'type': 'lost',
            'title': 'Lost iPhone',
            'description': 'Lost my iPhone',
            'category': 'electronics',
            'city': 'New York',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'occurred_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'report_2',
            'type': 'found',
            'title': 'Found Wallet',
            'description': 'Found a wallet',
            'category': 'personal',
            'city': 'Boston',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'occurred_at': DateTime.now().toIso8601String(),
          },
        ];

        final reports = responseHandler.handleReportsResponse(reportsData);
        expect(reports, isNotNull);
        expect(reports.length, 2);
        expect(reports[0].id, 'report_1');
        expect(reports[1].id, 'report_2');
      });
    });

    group('Error Handling Tests', () {
      test('should handle null data gracefully', () {
        final token = dataTransformer.transformAuthToken(null);
        expect(token, isNull);

        final user = dataTransformer.transformUser(null);
        expect(user, isNull);

        final report = dataTransformer.transformReport(null);
        expect(report, isNull);
      });

      test('should handle missing required fields', () {
        final incompleteData = {
          'email': 'test@example.com',
          // Missing required fields
        };

        final result = inputValidator.validateReportData(incompleteData);
        expect(result.isValid, false);
        expect(result.errors, isNotEmpty);
      });

      test('should handle empty lists gracefully', () {
        final emptyReports = dataTransformer.transformReports([]);
        expect(emptyReports, isEmpty);

        final emptyUsers = dataTransformer.transformUsers([]);
        expect(emptyUsers, isEmpty);
      });
    });

    group('Integration Tests', () {
      test('should validate input, transform data, and handle response in sequence', () {
        // Step 1: Validate input
        final reportData = {
          'title': 'Lost iPhone',
          'description': 'Lost my iPhone at the park yesterday',
          'type': 'lost',
          'category': 'electronics',
          'city': 'New York',
          'occurred_at': DateTime.now().toIso8601String(),
        };

        final validationResult = inputValidator.validateReportData(reportData);
        expect(validationResult.isValid, true);

        // Step 2: Transform data
        final transformedData = validationResult.sanitizedData!;
        final report = dataTransformer.transformReport(transformedData);
        expect(report, isNotNull);

        // Step 3: Handle response
        final responseData = report!.toJson();
        final processedReport = responseHandler.handleReportResponse(responseData);
        expect(processedReport, isNotNull);
        expect(processedReport!.id, report.id);
        expect(processedReport.title, report.title);
      });

      test('should handle complete authentication flow', () {
        // Step 1: Validate login input
        final loginData = {
          'email': 'test@example.com',
          'password': 'Password123',
        };

        final emailValidation = inputValidator.validateEmail(loginData['email']!);
        expect(emailValidation.isValid, true);

        // Step 2: Transform auth response
        final authResponse = {
          'access_token': 'test_access_token',
          'refresh_token': 'test_refresh_token',
          'token_type': 'Bearer',
        };

        final token = dataTransformer.transformAuthToken(authResponse);
        expect(token, isNotNull);

        // Step 3: Handle auth response
        final processedToken = responseHandler.handleAuthResponse(authResponse);
        expect(processedToken, isNotNull);
        expect(processedToken!.accessToken, 'test_access_token');
      });
    });

    group('Edge Cases Tests', () {
      test('should handle very long strings', () {
        final longTitle = 'A' * 300; // Very long title
        final reportData = {
          'title': longTitle,
          'description': 'Test description',
          'type': 'lost',
          'category': 'electronics',
          'city': 'New York',
          'occurred_at': DateTime.now().toIso8601String(),
        };

        final result = inputValidator.validateReportData(reportData);
        expect(result.isValid, false);
        expect(result.errors, contains('Title is too long (max 200 characters)'));
      });

      test('should handle special characters in input', () {
        final specialChars = r'Test@#$%^&*()_+-=[]{}|;:,.<>?';
        final result = inputValidator.validateDisplayName(specialChars);
        expect(result.isValid, false);
        expect(result.errors, contains('Display name contains invalid characters'));
      });

      test('should handle unicode characters', () {
        final unicodeString = '测试用户';
        final result = inputValidator.validateDisplayName(unicodeString);
        expect(result.isValid, false); // Should fail due to regex validation
      });
    });
  });
}