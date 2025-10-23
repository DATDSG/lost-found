import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

/// Service for handling file uploads to MinIO backend

/// Base URL for MinIO service
String get _minioBaseUrl => AppConstants.baseUrl.replaceAll(':8000', ':9000');

/// Maximum file size in bytes (10MB)
const int _maxFileSize = 10 * 1024 * 1024;

/// Allowed file extensions
const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

/// Upload a single file to MinIO
Future<String?> uploadFileToMinIO(
  File file, {
  String? bucket,
  String? folder,
  String? fileName,
}) async {
  try {
    // Validate file
    if (!_isValidFile(file)) {
      debugPrint('Invalid file type or size');
      return null;
    }

    // Generate upload URL
    final uploadUrl = await _getUploadUrl(
      bucket: bucket ?? 'lost-found',
      folder: folder ?? 'uploads',
      fileName: fileName ?? _generateFileName(file),
    );

    if (uploadUrl.isEmpty) {
      debugPrint('Failed to get upload URL');
      return null;
    }

    // Upload file
    final success = await _uploadToUrl(file, uploadUrl);

    if (success) {
      return uploadUrl;
    }

    return null;
  } on Exception catch (e) {
    debugPrint('Error uploading file: $e');
    return null;
  }
}

/// Upload multiple files to MinIO
Future<List<String>> uploadMultipleFilesToMinIO(
  List<File> files, {
  String? bucket,
  String? folder,
}) async {
  final uploadedUrls = <String>[];

  for (final file in files) {
    final url = await uploadFileToMinIO(file, bucket: bucket, folder: folder);

    if (url != null) {
      uploadedUrls.add(url);
    }
  }

  return uploadedUrls;
}

/// Delete a file from MinIO
Future<bool> deleteFileFromMinIO(String fileUrl) async {
  try {
    final response = await http.delete(
      Uri.parse('$_minioBaseUrl/files/delete'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'file_url': fileUrl}),
    );

    return response.statusCode == 200;
  } on Exception catch (e) {
    debugPrint('Error deleting file: $e');
    return false;
  }
}

/// Get file metadata
Future<Map<String, dynamic>?> getFileMetadataFromMinIO(String fileUrl) async {
  try {
    final response = await http.get(
      Uri.parse('$_minioBaseUrl/files/metadata'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    }

    return null;
  } on Exception catch (e) {
    debugPrint('Error getting file metadata: $e');
    return null;
  }
}

/// Get upload URL from backend
Future<String> _getUploadUrl({
  required String bucket,
  required String folder,
  required String fileName,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$_minioBaseUrl/files/upload-url'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'bucket': bucket,
        'folder': folder,
        'file_name': fileName,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['upload_url'] as String? ?? '';
    }

    return '';
  } on Exception catch (e) {
    debugPrint('Error getting upload URL: $e');
    return '';
  }
}

/// Upload file to the provided URL
Future<bool> _uploadToUrl(File file, String uploadUrl) async {
  try {
    final List<int> fileBytes = await file.readAsBytes();

    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'application/octet-stream'},
      body: fileBytes,
    );

    return response.statusCode == 200;
  } on Exception catch (e) {
    debugPrint('Error uploading to URL: $e');
    return false;
  }
}

/// Validate file before upload
bool _isValidFile(File file) {
  // Check file extension
  final extension = file.path.toLowerCase().split('.').last;
  if (!_allowedExtensions.contains(extension)) {
    return false;
  }

  // Check file size
  final fileSize = file.lengthSync();
  if (fileSize > _maxFileSize) {
    return false;
  }

  return true;
}

/// Generate unique file name
String _generateFileName(File file) {
  final extension = file.path.toLowerCase().split('.').last;
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final random = (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  return '${timestamp}_$random.$extension';
}

/// Get file size in bytes
int getFileSizeFromMinIO(File file) => file.lengthSync();

/// Format file size for display
String formatFileSizeFromMinIO(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Check if file is within size limits
bool isFileSizeValidForMinIO(File file) =>
    getFileSizeFromMinIO(file) <= _maxFileSize;

/// Get allowed file extensions
List<String> getAllowedExtensionsFromMinIO() => List.from(_allowedExtensions);

/// Get maximum file size in bytes
int getMaxFileSizeFromMinIO() => _maxFileSize;
