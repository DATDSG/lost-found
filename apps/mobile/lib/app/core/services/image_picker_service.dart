import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling image picking and file operations
class ImagePickerService {
  // Private constructor to prevent instantiation
  ImagePickerService._();

  static final ImagePicker _picker = ImagePicker();

  /// Check and request camera permission
  static Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    return false;
  }

  /// Check and request storage permission
  static Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use READ_MEDIA_IMAGES
      if (await Permission.photos.status.isGranted) {
        return true;
      }

      final result = await Permission.photos.request();
      return result.isGranted;
    } else {
      // For iOS, use photos permission
      final status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }

      return false;
    }
  }

  /// Pick a single image from gallery or camera
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      // Check permissions before picking image
      var hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _checkCameraPermission();
      } else {
        hasPermission = await _checkStoragePermission();
      }

      if (!hasPermission) {
        debugPrint('Permission denied for image picker');
        return null;
      }

      final image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Error picking image: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error details: ${e.toString()}');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      // Check storage permission before picking images
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        debugPrint('Permission denied for multiple image picker');
        return [];
      }

      final images = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );

      return images.map((image) => File(image.path)).toList();
    } on Exception catch (e) {
      debugPrint('Error picking multiple images: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error details: ${e.toString()}');
      return [];
    }
  }

  /// Copy file to a new location
  static Future<File?> copyFile(File source, String destinationPath) async {
    try {
      return await source.copy(destinationPath);
    } on Exception catch (e) {
      debugPrint('Error copying file: $e');
      return null;
    }
  }

  /// Delete a file
  static Future<bool> deleteFile(File file) async {
    try {
      await file.delete();
      return true;
    } on Exception catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } on Exception catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
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

  /// Validate image file
  static bool isValidImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Compress image if needed
  static Future<File?> compressImageIfNeeded(
    File imageFile, {
    int maxSizeBytes = 5 * 1024 * 1024, // 5MB
    int quality = 85,
  }) async {
    try {
      final fileSize = await getFileSize(imageFile);

      if (fileSize <= maxSizeBytes) {
        return imageFile;
      }

      // For now, return the original file
      // In a real implementation, you might want to use a compression library
      debugPrint(
        'Image size: ${formatFileSize(fileSize)} - compression not implemented',
      );
      return imageFile;
    } on Exception catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }
}
