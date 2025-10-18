import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/design_tokens.dart';

class PhotoPicker extends StatefulWidget {
  final List<File> photos;
  final Function(List<File>) onPhotosChanged;
  final int maxPhotos;

  const PhotoPicker({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final updatedPhotos = List<File>.from(widget.photos)..add(imageFile);
        widget.onPhotosChanged(updatedPhotos);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: DT.c.error,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    final updatedPhotos = List<File>.from(widget.photos)..removeAt(index);
    widget.onPhotosChanged(updatedPhotos);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DT.r.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: DT.s.sm),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: DT.c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(DT.s.lg),
              child: Column(
                children: [
                  Text('Select Image Source', style: DT.t.title),
                  SizedBox(height: DT.s.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _ImageSourceButton(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ),
                      SizedBox(width: DT.s.md),
                      Expanded(
                        child: _ImageSourceButton(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo Grid
        if (widget.photos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DT.r.md),
                      border: Border.all(color: DT.c.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DT.r.md),
                      child: Image.file(
                        widget.photos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: DT.c.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: DT.s.lg),
        ],

        // Add Photo Button
        if (widget.photos.length < widget.maxPhotos)
          InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(DT.r.md),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: DT.c.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DT.r.md),
                border: Border.all(
                  color: DT.c.brand.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: DT.c.brand, size: 32),
                  SizedBox(height: DT.s.sm),
                  Text(
                    'Add Photo',
                    style: DT.t.body.copyWith(
                      color: DT.c.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.photos.length}/${widget.maxPhotos}',
                    style: DT.t.caption.copyWith(color: DT.c.textMuted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DT.r.md),
      child: Container(
        padding: EdgeInsets.all(DT.s.lg),
        decoration: BoxDecoration(
          color: DT.c.brand.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DT.r.md),
          border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: DT.c.brand, size: 32),
            SizedBox(height: DT.s.sm),
            Text(
              label,
              style: DT.t.body.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
