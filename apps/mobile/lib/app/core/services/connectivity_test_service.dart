import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/environment_config.dart';
import '../constants/api_config.dart';
import 'debug_service.dart';
import 'network_connectivity_service.dart';

/// Service for testing and validating API connectivity
class ConnectivityTestService {
  /// Factory constructor for singleton instance
  factory ConnectivityTestService() => _instance;

  /// Private constructor for singleton pattern
  ConnectivityTestService._internal();

  static final ConnectivityTestService _instance =
      ConnectivityTestService._internal();

  /// Debug service for logging
  final DebugService _debugService = DebugService();

  /// Network connectivity service
  final NetworkConnectivityService _connectivityService =
      NetworkConnectivityService();

  /// Test basic network connectivity
  Future<Map<String, dynamic>> testBasicConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test DNS resolution
      final dnsResult = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      stopwatch.stop();

      final isConnected =
          dnsResult.isNotEmpty && dnsResult[0].rawAddress.isNotEmpty;

      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': isConnected,
        'responseTime': stopwatch.elapsedMilliseconds,
        'method': 'dns_lookup',
        'host': 'google.com',
        'addresses': dnsResult.map((addr) => addr.address).toList(),
      };

      _debugService.info(
        'Basic connectivity test completed',
        category: 'connectivity',
        data: result,
      );

      return result;
    } on Exception catch (e) {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': false,
        'error': e.toString(),
        'method': 'dns_lookup',
      };

      _debugService.error(
        'Basic connectivity test failed',
        category: 'connectivity',
        data: result,
      );

      return result;
    }
  }

  /// Test API server connectivity
  Future<Map<String, dynamic>> testApiConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();

      final apiUrl = Uri.parse(EnvironmentConfig.baseUrl);

      // Test if we can reach the API host
      final hostConnectivity = await InternetAddress.lookup(
        apiUrl.host,
      ).timeout(const Duration(seconds: 5));

      if (hostConnectivity.isEmpty) {
        throw Exception('Cannot resolve API host: ${apiUrl.host}');
      }

      // Test API health endpoint
      final healthUrl = '${EnvironmentConfig.baseUrl}/health';
      final response = await http
          .get(Uri.parse(healthUrl), headers: ApiConfig.defaultHeaders)
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();

      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': response.statusCode == 200,
        'responseTime': stopwatch.elapsedMilliseconds,
        'method': 'api_health_check',
        'url': healthUrl,
        'statusCode': response.statusCode,
        'responseBody': response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body,
        'apiHost': apiUrl.host,
        'apiPort': apiUrl.port,
        'apiScheme': apiUrl.scheme,
      };

      _debugService.info(
        'API connectivity test completed',
        category: 'connectivity',
        data: result,
      );

      return result;
    } on Exception catch (e) {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': false,
        'error': e.toString(),
        'method': 'api_health_check',
        'url': '${EnvironmentConfig.baseUrl}/health',
      };

      _debugService.error(
        'API connectivity test failed',
        category: 'connectivity',
        data: result,
      );

      return result;
    }
  }

  /// Test authentication endpoint
  Future<Map<String, dynamic>> testAuthConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test auth endpoint without credentials (should return 422 or 400)
      final authUrl =
          '${EnvironmentConfig.baseUrl}${ApiConfig.authEndpoint}/login';
      final response = await http
          .post(
            Uri.parse(authUrl),
            headers: ApiConfig.defaultHeaders,
            body: json.encode({
              'email': 'test@example.com',
              'password': 'test',
            }),
          )
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();

      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': response.statusCode >= 200 && response.statusCode < 500,
        'responseTime': stopwatch.elapsedMilliseconds,
        'method': 'auth_endpoint_test',
        'url': authUrl,
        'statusCode': response.statusCode,
        'responseBody': response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body,
      };

      _debugService.info(
        'Auth connectivity test completed',
        category: 'connectivity',
        data: result,
      );

      return result;
    } on Exception catch (e) {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': false,
        'error': e.toString(),
        'method': 'auth_endpoint_test',
        'url': '${EnvironmentConfig.baseUrl}${ApiConfig.authEndpoint}/login',
      };

      _debugService.error(
        'Auth connectivity test failed',
        category: 'connectivity',
        data: result,
      );

      return result;
    }
  }

  /// Run comprehensive connectivity tests
  Future<Map<String, dynamic>> runComprehensiveTests() async {
    try {
      _debugService.info(
        'Starting comprehensive connectivity tests',
        category: 'connectivity',
      );

      final stopwatch = Stopwatch()..start();

      // Run all tests in parallel
      final results = await Future.wait([
        testBasicConnectivity(),
        testApiConnectivity(),
        testAuthConnectivity(),
      ]);

      stopwatch.stop();

      final basicConnectivity = results[0];
      final apiConnectivity = results[1];
      final authConnectivity = results[2];

      final overallConnected =
          basicConnectivity['isConnected'] == true &&
          apiConnectivity['isConnected'] == true &&
          authConnectivity['isConnected'] == true;

      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'overallConnected': overallConnected,
        'totalTestTime': stopwatch.elapsedMilliseconds,
        'environment': EnvironmentConfig.currentEnvironment.name,
        'baseUrl': EnvironmentConfig.baseUrl,
        'tests': {
          'basicConnectivity': basicConnectivity,
          'apiConnectivity': apiConnectivity,
          'authConnectivity': authConnectivity,
        },
        'summary': {
          'basicConnectivity': basicConnectivity['isConnected'] == true
              ? 'PASS'
              : 'FAIL',
          'apiConnectivity': apiConnectivity['isConnected'] == true
              ? 'PASS'
              : 'FAIL',
          'authConnectivity': authConnectivity['isConnected'] == true
              ? 'PASS'
              : 'FAIL',
        },
      };

      _debugService.info(
        'Comprehensive connectivity tests completed',
        category: 'connectivity',
        data: result,
      );

      return result;
    } on Exception catch (e) {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'overallConnected': false,
        'error': e.toString(),
        'method': 'comprehensive_test',
      };

      _debugService.error(
        'Comprehensive connectivity tests failed',
        category: 'connectivity',
        data: result,
      );

      return result;
    }
  }

  /// Get connectivity status summary
  Future<Map<String, dynamic>> getConnectivityStatus() async {
    try {
      final basicConnectivity = await _connectivityService
          .checkConnectivityDetailed();
      final apiConnectivity = await testApiConnectivity();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'basicConnectivity': basicConnectivity,
        'apiConnectivity': apiConnectivity,
        'overallStatus':
            basicConnectivity['isConnected'] == true &&
                apiConnectivity['isConnected'] == true
            ? 'ONLINE'
            : 'OFFLINE',
        'environment': EnvironmentConfig.currentEnvironment.name,
        'baseUrl': EnvironmentConfig.baseUrl,
      };
    } on Exception catch (e) {
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'overallStatus': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Test specific endpoint
  Future<Map<String, dynamic>> testEndpoint(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final url = '${EnvironmentConfig.baseUrl}$endpoint';
      final requestHeaders = {...ApiConfig.defaultHeaders, ...?headers};

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(Uri.parse(url), headers: requestHeaders)
              .timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http
              .post(
                Uri.parse(url),
                headers: requestHeaders,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      stopwatch.stop();

      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': response.statusCode >= 200 && response.statusCode < 500,
        'responseTime': stopwatch.elapsedMilliseconds,
        'method': method,
        'url': url,
        'statusCode': response.statusCode,
        'responseBody': response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body,
        'headers': response.headers,
      };

      _debugService.info(
        'Endpoint test completed',
        category: 'connectivity',
        data: result,
      );

      return result;
    } on Exception catch (e) {
      final result = {
        'timestamp': DateTime.now().toIso8601String(),
        'isConnected': false,
        'error': e.toString(),
        'method': method,
        'url': '${EnvironmentConfig.baseUrl}$endpoint',
      };

      _debugService.error(
        'Endpoint test failed',
        category: 'connectivity',
        data: result,
      );

      return result;
    }
  }
}
