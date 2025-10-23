import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../exceptions/api_exceptions.dart';
import 'api_service.dart';

/// Service for handling avatar uploads
class AvatarService {
  /// Factory constructor for singleton instance
  factory AvatarService() => _instance;

  /// Private constructor for singleton pattern
  AvatarService._internal();

  static final AvatarService _instance = AvatarService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  /// Pick image from camera
  Future<File?> pickImageFromCamera({
    int maxWidth = 800,
    int maxHeight = 800,
    int imageQuality = 80,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error picking image from camera: $e');
      }
      throw ApiException('Failed to pick image from camera: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({
    int maxWidth = 800,
    int maxHeight = 800,
    int imageQuality = 80,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error picking image from gallery: $e');
      }
      throw ApiException('Failed to pick image from gallery: $e');
    }
  }

  /// Upload avatar to server
  Future<String> uploadAvatar(File imageFile) async {
    try {
      if (kDebugMode) {
        print('Uploading avatar: ${imageFile.path}');
      }

      // Compress the image before uploading
      final compressedFile = await compressImage(imageFile);

      // Upload the compressed image using the media upload endpoint
      final response = await _apiService.uploadMedia(compressedFile);

      // Extract the avatar URL from the response
      final avatarUrl =
          response['url'] as String? ?? response['avatar_url'] as String?;

      if (avatarUrl == null) {
        throw ApiException('No avatar URL returned from server');
      }

      if (kDebugMode) {
        print('Avatar uploaded successfully: $avatarUrl');
      }

      return avatarUrl;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar: $e');
      }
      throw ApiException('Failed to upload avatar: $e');
    }
  }

  /// Delete avatar from server
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      if (kDebugMode) {
        print('Deleting avatar: $avatarUrl');
      }

      // Extract the media ID from the avatar URL
      // Assuming the URL format is something like: https://api.lostfound.com/media/{id}
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) {
        throw ApiException('Invalid avatar URL format');
      }

      // Get the media ID from the last path segment
      final mediaId = pathSegments.last;

      // Call the delete media endpoint
      await _apiService.deleteMedia(mediaId);

      if (kDebugMode) {
        print('Avatar deleted successfully');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error deleting avatar: $e');
      }
      throw ApiException('Failed to delete avatar: $e');
    }
  }

  /// Compress image file
  Future<File> compressImage(
    File imageFile, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 80,
  }) async {
    try {
      if (kDebugMode) {
        print('Compressing image: ${imageFile.path}');
      }

      // Read the image file
      final imageBytes = await imageFile.readAsBytes();

      // Decode the image
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw ApiException('Failed to decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      var newWidth = originalImage.width;
      var newHeight = originalImage.height;

      if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
        final aspectRatio = originalImage.width / originalImage.height;

        if (originalImage.width > originalImage.height) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Resize the image
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final compressedPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Encode and save the compressed image
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      if (kDebugMode) {
        final originalSize = await imageFile.length();
        final compressedSize = await compressedFile.length();
        final compressionRatio =
            ((originalSize - compressedSize) / originalSize * 100).round();
        print(
          'Image compressed: ${originalSize}B -> ${compressedSize}B ($compressionRatio% reduction)',
        );
      }

      return compressedFile;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error compressing image: $e');
      }
      throw ApiException('Failed to compress image: $e');
    }
  }

  /// Get image file size in bytes
  Future<int> getImageFileSize(File imageFile) async {
    try {
      return await imageFile.length();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting image file size: $e');
      }
      return 0;
    }
  }

  /// Check if image file size is within limits
  bool isImageSizeValid(File imageFile, {int maxSizeInMB = 5}) {
    final fileSize = imageFile.lengthSync();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSize <= maxSizeInBytes;
  }

  /// Validate image file format
  bool isValidImageFormat(File imageFile) {
    final extension = imageFile.path.toLowerCase().split('.').last;
    const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    return validExtensions.contains(extension);
  }

  /// Get image dimensions
  Future<Map<String, int>> getImageDimensions(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw ApiException('Failed to decode image');
      }

      return {'width': image.width, 'height': image.height};
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting image dimensions: $e');
      }
      throw ApiException('Failed to get image dimensions: $e');
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('compressed_')) {
          await file.delete();
        }
      }

      if (kDebugMode) {
        print('Temporary files cleaned up');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error cleaning up temp files: $e');
      }
    }
  }
}
