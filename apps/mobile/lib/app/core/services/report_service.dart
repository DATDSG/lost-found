import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/api_models.dart' as models;
import 'api_service.dart';

/// Service for handling report operations
class ReportService {
  /// Factory constructor for singleton instance
  factory ReportService() => _instance;

  /// Private constructor for singleton pattern
  ReportService._internal();
  static final ReportService _instance = ReportService._internal();

  final ApiService _apiService = ApiService();

  /// Create a lost item report
  Future<models.ReportDetail> createLostItemReport({
    required String title,
    required String description,
    required String category,
    required List<String> colors,
    required DateTime occurredAt,
    String? occurredTime,
    double? latitude,
    double? longitude,
    String? locationCity,
    String? locationAddress,
    String? contactInfo,
    String? condition,
    bool? isUrgent,
    bool? rewardOffered,
    String? rewardAmount,
    String? brand,
    String? model,
    String? serialNumber,
    String? size,
    String? material,
    String? estimatedValue,
    String? lastSeenLocation,
    String? circumstancesOfLoss,
    String? additionalDetails,
    bool? hasSerialNumber,
    bool? isInsured,
    bool? hasReceipt,
    List<File>? images,
  }) async {
    try {
      // Upload images first if any
      final mediaIds = <String>[];
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final mediaResponse = await _apiService.uploadMedia(image);
          if (mediaResponse['id'] != null) {
            mediaIds.add(mediaResponse['id'] as String);
          }
        }
      }

      // Create report data
      final reportData = models.ReportCreate(
        type: models.ReportType.lost,
        title: title,
        description: description,
        category: category,
        colors: colors,
        occurredAt: occurredAt,
        occurredTime: occurredTime,
        latitude: latitude,
        longitude: longitude,
        locationCity: locationCity,
        locationAddress: locationAddress,
        contactInfo: contactInfo,
        condition: condition,
        isUrgent: isUrgent,
        rewardOffered: rewardOffered,
        rewardAmount: rewardAmount,
        brand: brand,
        model: model,
        serialNumber: serialNumber,
        size: size,
        material: material,
        estimatedValue: estimatedValue,
        lastSeenLocation: lastSeenLocation,
        circumstancesOfLoss: circumstancesOfLoss,
        additionalInfo: additionalDetails,
        hasSerialNumber: hasSerialNumber,
        isInsured: isInsured,
        hasReceipt: hasReceipt,
        mediaIds: mediaIds,
      );

      // Submit to API
      final response = await _apiService.createReport(reportData.toJson());

      return models.ReportDetail.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating lost item report: $e');
      }
      rethrow;
    }
  }

  /// Create a found item report
  Future<models.ReportDetail> createFoundItemReport({
    required String title,
    required String description,
    required String category,
    required List<String> colors,
    required DateTime occurredAt,
    String? occurredTime,
    double? latitude,
    double? longitude,
    String? locationCity,
    String? locationAddress,
    String? contactInfo,
    String? additionalInfo,
    String? condition,
    String? safetyStatus,
    bool? isSafe,
    String? brand,
    String? model,
    String? serialNumber,
    String? size,
    String? material,
    String? estimatedValue,
    String? foundCircumstances,
    String? storageLocation,
    String? handlingInstructions,
    bool? hasSerialNumber,
    bool? isValuable,
    bool? needsSpecialHandling,
    bool? turnedIntoPolice,
    List<File>? images,
  }) async {
    try {
      // Upload images first if any
      final mediaIds = <String>[];
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final mediaResponse = await _apiService.uploadMedia(image);
          if (mediaResponse['id'] != null) {
            mediaIds.add(mediaResponse['id'] as String);
          }
        }
      }

      // Create report data
      final reportData = models.ReportCreate(
        type: models.ReportType.found,
        title: title,
        description: description,
        category: category,
        colors: colors,
        occurredAt: occurredAt,
        occurredTime: occurredTime,
        latitude: latitude,
        longitude: longitude,
        locationCity: locationCity,
        locationAddress: locationAddress,
        contactInfo: contactInfo,
        additionalInfo: additionalInfo,
        condition: condition,
        safetyStatus: safetyStatus,
        isSafe: isSafe,
        brand: brand,
        model: model,
        serialNumber: serialNumber,
        size: size,
        material: material,
        estimatedValue: estimatedValue,
        foundCircumstances: foundCircumstances,
        storageLocation: storageLocation,
        handlingInstructions: handlingInstructions,
        hasSerialNumber: hasSerialNumber,
        isValuable: isValuable,
        needsSpecialHandling: needsSpecialHandling,
        turnedIntoPolice: turnedIntoPolice,
        mediaIds: mediaIds,
      );

      // Submit to API
      final response = await _apiService.createReport(reportData.toJson());

      return models.ReportDetail.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating found item report: $e');
      }
      rethrow;
    }
  }

  /// Get reports list
  Future<List<models.ReportSummary>> getReports({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? type,
    String? category,
    String? status,
  }) async {
    try {
      final response = await _apiService.getReports(
        page: page,
        pageSize: pageSize,
        search: search,
        type: type,
        category: category,
        status: status,
      );

      return response.map(models.ReportSummary.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting reports: $e');
      }
      rethrow;
    }
  }

  /// Get specific report by ID
  Future<models.ReportDetail> getReport(String reportId) async {
    try {
      final response = await _apiService.getReport(reportId);
      return models.ReportDetail.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting report: $e');
      }
      rethrow;
    }
  }

  /// Get user's own reports
  Future<List<models.ReportSummary>> getUserReports() async {
    try {
      final response = await _apiService.getUserReports();
      return response.map(models.ReportSummary.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user reports: $e');
      }
      rethrow;
    }
  }

  /// Get categories
  Future<List<models.Category>> getCategories({bool activeOnly = true}) async {
    try {
      final response = await _apiService.getCategories(activeOnly: activeOnly);
      return response.map(models.Category.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting categories: $e');
      }
      rethrow;
    }
  }

  /// Get colors
  Future<List<models.Color>> getColors({bool activeOnly = true}) async {
    try {
      final response = await _apiService.getColors(activeOnly: activeOnly);
      return response.map(models.Color.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting colors: $e');
      }
      rethrow;
    }
  }

  /// Upload media file
  Future<models.Media> uploadMedia(File file) async {
    try {
      final response = await _apiService.uploadMedia(file);
      return models.Media.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading media: $e');
      }
      rethrow;
    }
  }
}
