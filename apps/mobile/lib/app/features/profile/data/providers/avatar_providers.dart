import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/avatar_service.dart';

/// Provider for avatar service
final avatarServiceProvider = Provider<AvatarService>((ref) => AvatarService());

/// Provider for avatar upload state
final avatarUploadProvider =
    StateNotifierProvider<AvatarUploadNotifier, AvatarUploadState>(
      (ref) => AvatarUploadNotifier(
        ref.read(avatarServiceProvider),
        ref.read(authServiceProvider),
      ),
    );

/// State for avatar upload operations
class AvatarUploadState {
  /// Creates a new avatar upload state
  const AvatarUploadState({
    this.isUploading = false,
    this.isSuccess = false,
    this.error,
    this.avatarUrl,
    this.selectedImage,
  });

  /// Whether an avatar is currently being uploaded
  final bool isUploading;

  /// Whether the last operation was successful
  final bool isSuccess;

  /// Error message if any operation failed
  final String? error;

  /// Current avatar URL
  final String? avatarUrl;

  /// Currently selected image file
  final File? selectedImage;

  /// Creates a copy of this state with updated values
  AvatarUploadState copyWith({
    bool? isUploading,
    bool? isSuccess,
    String? error,
    String? avatarUrl,
    File? selectedImage,
  }) => AvatarUploadState(
    isUploading: isUploading ?? this.isUploading,
    isSuccess: isSuccess ?? this.isSuccess,
    error: error,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    selectedImage: selectedImage ?? this.selectedImage,
  );
}

/// Notifier for managing avatar uploads
class AvatarUploadNotifier extends StateNotifier<AvatarUploadState> {
  /// Creates a new avatar upload notifier
  AvatarUploadNotifier(this._avatarService, this._authService)
    : super(const AvatarUploadState());

  final AvatarService _avatarService;
  final AuthService _authService;

  /// Selects an image from the camera
  Future<void> selectImageFromCamera() async {
    try {
      state = state.copyWith();

      final imageFile = await _avatarService.pickImageFromCamera();

      if (imageFile != null) {
        // Check file format
        if (!_avatarService.isValidImageFormat(imageFile)) {
          state = state.copyWith(
            error:
                'Invalid image format. Please select a JPG, PNG, or WebP image.',
          );
          return;
        }

        // Check file size
        if (!_avatarService.isImageSizeValid(imageFile)) {
          state = state.copyWith(
            error:
                'Image size is too large. Please select an image smaller than 5MB.',
          );
          return;
        }

        state = state.copyWith(selectedImage: imageFile);
      }
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Selects an image from the gallery
  Future<void> selectImageFromGallery() async {
    try {
      state = state.copyWith();

      final imageFile = await _avatarService.pickImageFromGallery();

      if (imageFile != null) {
        // Check file format
        if (!_avatarService.isValidImageFormat(imageFile)) {
          state = state.copyWith(
            error:
                'Invalid image format. Please select a JPG, PNG, or WebP image.',
          );
          return;
        }

        // Check file size
        if (!_avatarService.isImageSizeValid(imageFile)) {
          state = state.copyWith(
            error:
                'Image size is too large. Please select an image smaller than 5MB.',
          );
          return;
        }

        state = state.copyWith(selectedImage: imageFile);
      }
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Uploads the selected image
  Future<void> uploadSelectedImage() async {
    if (state.selectedImage == null) {
      return;
    }

    try {
      state = state.copyWith(isUploading: true);

      // Compress image if needed
      final compressedImage = await _avatarService.compressImage(
        state.selectedImage!,
      );

      // Upload to server
      final avatarUrl = await _avatarService.uploadAvatar(compressedImage);

      // Update user profile with new avatar URL
      await _authService.updateProfile(avatarUrl: avatarUrl);

      state = state.copyWith(
        isUploading: false,
        isSuccess: true,
        avatarUrl: avatarUrl,
      );

      // Clear success state after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isSuccess: false);
        }
      });
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Removes the current avatar
  Future<void> removeAvatar() async {
    try {
      state = state.copyWith(isUploading: true);

      if (state.avatarUrl != null) {
        await _avatarService.deleteAvatar(state.avatarUrl!);
      }

      // Update user profile to remove avatar
      await _authService.updateProfile();

      state = state.copyWith(isUploading: false, isSuccess: true);

      // Clear success state after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isSuccess: false);
        }
      });
    } on Exception catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Clears the selected image
  void clearSelectedImage() {
    state = state.copyWith();
  }

  /// Clears any error state
  void clearError() {
    state = state.copyWith();
  }

  /// Clears the success state
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    await _avatarService.cleanupTempFiles();
  }
}
