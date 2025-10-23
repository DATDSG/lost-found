import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_picker_service.dart';
import '../../core/services/minio_service.dart';
import '../../core/theme/design_tokens.dart';

/// Reusable image picker widget with upload functionality
class ImagePickerWidget extends StatefulWidget {
  /// Creates a new image picker widget
  const ImagePickerWidget({
    super.key,
    this.maxImages = 5,
    this.onImagesChanged,
    this.initialImages = const [],
    this.enabled = true,
  });

  /// Maximum number of images allowed
  final int maxImages;

  /// Callback when images change
  final void Function(List<File> images)? onImagesChanged;

  /// Initial images to display
  final List<File> initialImages;

  /// Whether the widget is enabled
  final bool enabled;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  List<File> _selectedImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedImages = List.from(widget.initialImages);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header
      Row(
        children: [
          Icon(Icons.image, color: DT.c.brand, size: 20),
          SizedBox(width: DT.s.sm),
          Text(
            'Photos',
            style: DT.t.labelLarge.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_selectedImages.isNotEmpty)
            Text(
              '${_selectedImages.length}/${widget.maxImages}',
              style: DT.t.labelSmall.copyWith(color: DT.c.textMuted),
            ),
        ],
      ),

      SizedBox(height: DT.s.sm),

      Text(
        'Add photos to help identify the item (up to ${widget.maxImages} photos)',
        style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
      ),

      SizedBox(height: DT.s.md),

      // Image Grid
      _buildImageGrid(),

      SizedBox(height: DT.s.md),

      // Upload Status
      if (_isUploading) _buildUploadStatus(),
    ],
  );

  Widget _buildImageGrid() {
    final totalSlots = widget.maxImages;
    final filledSlots = _selectedImages.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < filledSlots) {
          return _buildImageItem(_selectedImages[index], index);
        } else {
          return _buildAddButton(index - filledSlots);
        }
      },
    );
  }

  Widget _buildImageItem(File image, int index) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.border),
    ),
    child: Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(DT.r.md),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: DT.c.surfaceVariant,
              child: Icon(Icons.broken_image, color: DT.c.textMuted, size: 24),
            ),
          ),
        ),

        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: DT.c.error.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: DT.c.textOnBrand, size: 12),
            ),
          ),
        ),

        // File size indicator
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(DT.r.xs),
            ),
            child: Text(
              formatFileSizeFromMinIO(getFileSizeFromMinIO(image)),
              style: DT.t.labelSmall.copyWith(color: Colors.white, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAddButton(int emptySlotIndex) => GestureDetector(
    onTap: widget.enabled ? _showImageSourceDialog : null,
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.enabled
              ? DT.c.border
              : DT.c.border.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(DT.r.md),
        color: widget.enabled
            ? DT.c.surfaceVariant
            : DT.c.surfaceVariant.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: widget.enabled
                  ? DT.c.textMuted
                  : DT.c.textMuted.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: DT.t.labelSmall.copyWith(
                color: widget.enabled
                    ? DT.c.textMuted
                    : DT.c.textMuted.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildUploadStatus() => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.infoBg,
      borderRadius: BorderRadius.circular(DT.r.sm),
      border: Border.all(color: DT.c.infoBorder),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(DT.c.info),
          ),
        ),
        SizedBox(width: DT.s.sm),
        Expanded(
          child: Text(
            'Uploading images...',
            style: DT.t.bodySmall.copyWith(color: DT.c.infoFg),
          ),
        ),
      ],
    ),
  );

  void _showImageSourceDialog() {
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DT.s.lg),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ),
                SizedBox(width: DT.s.md),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: DT.s.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.surfaceVariant,
        borderRadius: BorderRadius.circular(DT.r.md),
        border: Border.all(color: DT.c.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: DT.c.brand, size: 32),
          SizedBox(height: DT.s.sm),
          Text(
            label,
            style: DT.t.bodyMedium.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickFromGallery() async {
    final images = await ImagePickerService.pickMultipleImages(
      limit: widget.maxImages - _selectedImages.length,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      await _addImages(images);
    }
  }

  Future<void> _pickFromCamera() async {
    final image = await ImagePickerService.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      await _addImages([image]);
    }
  }

  Future<void> _addImages(List<File> images) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final validImages = <File>[];

      for (final image in images) {
        if (ImagePickerService.isValidImageFile(image)) {
          // Compress if needed
          final compressedImage =
              await ImagePickerService.compressImageIfNeeded(image);
          if (compressedImage != null) {
            validImages.add(compressedImage);
          }
        }
      }

      if (validImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(validImages);
        });

        widget.onImagesChanged?.call(_selectedImages);
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedImages.removeAt(index);
    });

    widget.onImagesChanged?.call(_selectedImages);
  }
}
