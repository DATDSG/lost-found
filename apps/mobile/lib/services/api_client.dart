import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Enhanced API Client for Lost & Found Mobile App
/// Provides better error handling, retry logic, and offline support
class ApiClient {
  /// Factory constructor for singleton instance
  factory ApiClient() => _instance;

  /// Private constructor for singleton pattern
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();

  late Dio _dio;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();

  // Configuration

  /// Base URL for API requests
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  /// API version to use
  String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';

  /// Request timeout in milliseconds
  int get timeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;

  /// Initialize the API client
  Future<void> initialize() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/$apiVersion',
        connectTimeout: Duration(milliseconds: timeout),
        receiveTimeout: Duration(milliseconds: timeout),
        sendTimeout: Duration(milliseconds: timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'LostFound-Mobile/1.0.0',
        },
      ),
    );

    // Add interceptors
    _addInterceptors();
  }

  /// Add request/response interceptors
  void _addInterceptors() {
    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token if available
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add request ID for tracking
          options.headers['X-Request-ID'] = _generateRequestId();

          // Log request
          _logger.d('🚀 API Request: ${options.method} ${options.path}');

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          _logger.d(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle errors
          await _handleError(error);
          handler.next(error);
        },
      ),
    );

    // Retry interceptor
    _dio.interceptors.add(RetryInterceptor(dio: _dio, logPrint: _logger.d));
  }

  /// Handle API errors
  Future<void> _handleError(DioException error) async {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        _logger.e('⏰ Request timeout');
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 401:
            _logger.e('🔐 Authentication failed');
            await _clearAuthToken();
            break;
          case 403:
            _logger.e('🚫 Access forbidden');
            break;
          case 404:
            _logger.e('❌ Resource not found');
            break;
          case 429:
            _logger.e('🚦 Rate limited');
            break;
          case 500:
            _logger.e('💥 Server error');
            break;
          default:
            _logger.e('❌ HTTP Error: $statusCode');
        }
        break;
      case DioExceptionType.cancel:
        _logger.w('🚫 Request cancelled');
        break;
      case DioExceptionType.connectionError:
        _logger.e('🌐 Network error');
        break;
      case DioExceptionType.badCertificate:
        _logger.e('🔒 Certificate error');
        break;
      case DioExceptionType.unknown:
        _logger.e('❓ Unknown error: ${error.message}');
        break;
    }
  }

  /// Check network connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Make GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );
    }

    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make POST request
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );
    }

    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make PUT request
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );
    }

    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );
    }

    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Upload file with progress tracking
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, Object>? data,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );
    }

    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?data,
    });

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: options,
    );
  }

  /// Download file
  Future<Response<void>> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: urlPath),
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );
    }

    return _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Health check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await get<Map<String, dynamic>>('/health');
    return response.data!;
  }

  /// Get authentication token
  Future<String?> _getAuthToken() async =>
      // This would typically come from secure storage
      // For now, return null
      null;

  /// Clear authentication token
  Future<void> _clearAuthToken() async {
    // Clear token from secure storage
  }

  /// Generate unique request ID
  String _generateRequestId() =>
      'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
}

/// Retry interceptor for handling failed requests
class RetryInterceptor extends Interceptor {
  /// Constructor for RetryInterceptor
  RetryInterceptor({
    required this.dio,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
    this.logPrint,
  });

  /// Dio instance for retrying requests
  final Dio dio;

  /// Number of retry attempts
  final int retries = 3;

  /// Delays between retry attempts
  final List<Duration> retryDelays;

  /// Optional logging function
  final void Function(String message)? logPrint;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      if (err.requestOptions.extra['retryCount'] == null) {
        err.requestOptions.extra['retryCount'] = 0;
      }

      final retryCount = err.requestOptions.extra['retryCount'] as int;
      if (retryCount < retries) {
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        final delay = retryDelays[retryCount % retryDelays.length];
        logPrint?.call('Retrying request in ${delay.inSeconds} seconds...');

        await Future<void>.delayed(delay);

        try {
          final response = await dio.fetch<void>(err.requestOptions);
          handler.resolve(response);
          return;
        } on Exception {
          // Continue to next retry or fail
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) =>
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.sendTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.connectionError ||
      (err.response?.statusCode != null && err.response!.statusCode! >= 500);
}
