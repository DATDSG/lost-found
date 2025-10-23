import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';
import '../utils/error_utils.dart';

/// Repository for handling reports data
class ReportsRepository {
  /// Creates a new [ReportsRepository] instance
  ReportsRepository(this._apiService);
  final ApiService _apiService;

  /// Get reports with filters
  Future<List<ReportSummary>> getReports({
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

      return response.map(ReportSummary.fromJson).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get specific report by ID
  Future<ReportDetail> getReport(String reportId) async {
    try {
      final response = await _apiService.getReport(reportId);
      return ReportDetail.fromJson(response);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Create new report
  Future<ReportDetail> createReport(ReportCreate reportData) async {
    try {
      final response = await _apiService.createReport(reportData.toJson());
      return ReportDetail.fromJson(response);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get user's own reports
  Future<List<ReportSummary>> getUserReports() async {
    try {
      final response = await _apiService.getUserReports();
      return response.map(ReportSummary.fromJson).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get report statistics
  Future<Map<String, dynamic>> getReportStatistics() async {
    try {
      return await _apiService.getReportStatistics();
    } catch (e) {
      throw handleError(e);
    }
  }
}

/// Repository for handling categories and colors
class TaxonomyRepository {
  /// Creates a new [TaxonomyRepository] instance
  TaxonomyRepository(this._apiService);
  final ApiService _apiService;

  /// Get categories list
  Future<List<Category>> getCategories({bool activeOnly = true}) async {
    try {
      final response = await _apiService.getCategories(activeOnly: activeOnly);
      return response.map(Category.fromJson).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get colors list
  Future<List<Color>> getColors({bool activeOnly = true}) async {
    try {
      final response = await _apiService.getColors(activeOnly: activeOnly);
      return response.map(Color.fromJson).toList();
    } catch (e) {
      throw handleError(e);
    }
  }
}

/// Repository for handling matches data
class MatchesRepository {
  /// Creates a new [MatchesRepository] instance
  MatchesRepository(this._apiService);
  final ApiService _apiService;

  /// Get matches for current user
  Future<List<MatchSummary>> getMatches({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.getMatches(
        page: page,
        pageSize: pageSize,
      );

      return response.map(MatchSummary.fromJson).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Accept a match
  Future<Map<String, dynamic>> acceptMatch(String matchId) async {
    try {
      return await _apiService.acceptMatch(matchId);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Reject a match
  Future<Map<String, dynamic>> rejectMatch(String matchId) async {
    try {
      return await _apiService.rejectMatch(matchId);
    } catch (e) {
      throw handleError(e);
    }
  }
}

/// Repository for handling media uploads
class MediaRepository {
  /// Creates a new [MediaRepository] instance
  MediaRepository(this._apiService);
  final ApiService _apiService;

  /// Upload media file
  Future<Media> uploadMedia(File file) async {
    try {
      final response = await _apiService.uploadMedia(file);
      return Media.fromJson(response);
    } catch (e) {
      throw handleError(e);
    }
  }
}

/// Repository for handling authentication
class AuthRepository {
  /// Creates a new [AuthRepository] instance
  AuthRepository(this._apiService);
  final ApiService _apiService;

  /// Login user
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      return AuthResponse.fromJson(response);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      return AuthResponse.fromJson(response);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.forgotPassword(email);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _apiService.resetPassword(token: token, password: newPassword);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get current user profile
  Future<User> getCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      return user;
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? location,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      final response = await _apiService.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      return User.fromJson(response);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get user profile statistics
  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      return await _apiService.getProfileStats();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Get user privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      return await _apiService.getPrivacySettings();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Update user privacy settings
  Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      return await _apiService.updatePrivacySettings(settings);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount({required String password, String? reason}) async {
    try {
      await _apiService.deleteAccount(password: password, reason: reason);
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Request user data download
  Future<Map<String, dynamic>> requestDataDownload() async {
    try {
      return await _apiService.requestDataDownload();
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Logout user
  void logout() {
    _apiService.logout();
  }
}

/// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Provider for reports repository
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReportsRepository(apiService);
});

/// Provider for taxonomy repository
final taxonomyRepositoryProvider = Provider<TaxonomyRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TaxonomyRepository(apiService);
});

/// Provider for matches repository
final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MatchesRepository(apiService);
});

/// Provider for media repository
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MediaRepository(apiService);
});

/// Provider for auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});
