import 'dart:io';
import 'package:dio/dio.dart' show Dio, BaseOptions, InterceptorsWrapper, MultipartFile, FormData, DioException, DioExceptionType;
import 'package:http_parser/http_parser.dart';
import '../auth/auth_service.dart';
import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: ApiConfig.baseUrl),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthService.I.apiToken;
        if (token.isNotEmpty && token != 'demo') {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, sign out user
          AuthService.I.signOut();
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient I = ApiClient._();
  late final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<T>(path, queryParameters: queryParameters);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.post<T>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.put<T>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> patch<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch<T>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> delete<T>(String path) async {
    try {
      final response = await _dio.delete<T>(path);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadFile(String path, File file, {String fieldName = 'file'}) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: MediaType('application', 'octet-stream'),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(path, data: formData);
      return response.data?['url'] ?? '';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    String message = 'Network error occurred';
    int statusCode = 0;

    if (error.response != null) {
      statusCode = error.response!.statusCode ?? 0;
      final data = error.response!.data;
      
      if (data is Map<String, dynamic>) {
        message = data['detail'] ?? data['message'] ?? 'Request failed';
      } else if (data is String) {
        message = data;
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Receive timeout';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return ApiException(statusCode, message);
  }
}
