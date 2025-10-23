import 'package:flutter_test/flutter_test.dart';
import 'package:lost_found_mobile/app/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have correct base URL', () {
      expect(AppConstants.baseUrl, 'http://10.0.2.2:8000');
    });

    test('should have correct API version', () {
      expect(AppConstants.apiVersion, 'v1');
    });

    test('should have correct timeout duration', () {
      expect(AppConstants.apiTimeout, const Duration(seconds: 30));
    });

    test('should have correct default page size', () {
      expect(AppConstants.defaultPageSize, 20);
    });

    test('should have correct max image size', () {
      expect(AppConstants.maxImageSize, 5 * 1024 * 1024);
    });

    test('should have correct allowed image types', () {
      expect(AppConstants.allowedImageTypes, ['jpg', 'jpeg', 'png', 'webp']);
    });

    test('should have correct default search radius', () {
      expect(AppConstants.defaultSearchRadius, 10.0);
    });

    test('should have correct UI constants', () {
      expect(AppConstants.defaultPadding, 16.0);
      expect(AppConstants.smallPadding, 8.0);
      expect(AppConstants.largePadding, 24.0);
      expect(AppConstants.borderRadius, 12.0);
      expect(AppConstants.buttonHeight, 48.0);
    });

    test('should have correct animation durations', () {
      expect(AppConstants.shortAnimation, const Duration(milliseconds: 200));
      expect(AppConstants.mediumAnimation, const Duration(milliseconds: 300));
      expect(AppConstants.longAnimation, const Duration(milliseconds: 500));
    });
  });
}
