import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Base API service with common error handling patterns
abstract class BaseApiService {
  Dio dio;

  BaseApiService() : dio = Dio();

  /// Execute API request with common error handling
  Future<T?> executeRequest<T>(
    Future<Response> Function() request, {
    String? operation,
    T Function(dynamic data)? transform,
  }) async {
    try {
      final response = await request();
      final data = transform != null ? transform(response.data) : response.data;
      return data as T?;
    } catch (e) {
      if (kDebugMode) {
        print('Error ${operation ?? 'in API request'}: $e');
      }
      rethrow;
    }
  }

  /// Execute API request that returns a list
  Future<List<T>> executeListRequest<T>(
    Future<Response> Function() request, {
    String? operation,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      final data = response.data as List;
      return data.map((json) => fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error ${operation ?? 'loading list'}: $e');
      }
      return [];
    }
  }

  /// Execute API request that returns a single item
  Future<T?> executeItemRequest<T>(
    Future<Response> Function() request, {
    String? operation,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await request();
      return fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error ${operation ?? 'loading item'}: $e');
      }
      return null;
    }
  }

  /// Execute API request with no return value
  Future<void> executeVoidRequest(
    Future<Response> Function() request, {
    String? operation,
  }) async {
    try {
      await request();
    } catch (e) {
      if (kDebugMode) {
        print('Error ${operation ?? 'in API request'}: $e');
      }
      rethrow;
    }
  }

  /// GET request
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  /// POST request
  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  /// PUT request
  Future<Response> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.put(path, data: data, queryParameters: queryParameters);
  }

  /// DELETE request
  Future<Response> delete(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await dio.delete(path, queryParameters: queryParameters);
  }

  /// Upload file with multipart
  Future<Response> uploadFile(
      String path, String filePath, String fieldName) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return await dio.post(path, data: formData);
  }
}
