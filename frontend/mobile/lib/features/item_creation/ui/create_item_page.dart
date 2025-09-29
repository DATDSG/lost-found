import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/models/item.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class CreateItemPage extends StatefulWidget {
  final ItemType itemType;

  const CreateItemPage({super.key, required this.itemType});

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();
  final _modelController = TextEditingController();
  final _rewardController = TextEditingController();

  String _selectedCategory = '';
  String _selectedSubcategory = '';
  String _selectedLanguage = 'en';
  DateTime _selectedDate = DateTime.now();
  Location? _selectedLocation;
  String _locationAddress = '';
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Personal Items',
    'Documents',
    'Clothing',
    'Jewelry',
    'Sports Equipment',
    'Bags & Luggage',
    'Keys',
    'Pets',
    'Other',
  ];

  final Map<String, List<String>> _subcategories = {
    'Electronics': [
      'Phone',
      'Laptop',
      'Tablet',
      'Camera',
      'Headphones',
      'Charger',
    ],
    'Personal Items': ['Wallet', 'Glasses', 'Watch', 'Umbrella'],
    'Documents': ['ID Card', 'Passport', 'License', 'Credit Card'],
    'Clothing': ['Jacket', 'Shoes', 'Hat', 'Scarf'],
    'Jewelry': ['Ring', 'Necklace', 'Bracelet', 'Earrings'],
    'Sports Equipment': ['Ball', 'Racket', 'Bicycle', 'Gym Equipment'],
    'Bags & Luggage': ['Backpack', 'Handbag', 'Suitcase', 'Briefcase'],
    'Keys': ['House Keys', 'Car Keys', 'Office Keys'],
    'Pets': ['Dog', 'Cat', 'Bird', 'Other Pet'],
    'Other': ['Miscellaneous'],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _modelController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: Text(
          widget.itemType == ItemType.lost
              ? 'Report Lost Item'
              : 'Report Found Item',
          style: DT.t.h2,
        ),
        backgroundColor: DT.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DT.s.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageSection(),
                  SizedBox(height: DT.s.xl),
                  _buildBasicInfoSection(),
                  SizedBox(height: DT.s.xl),
                  _buildCategorySection(),
                  SizedBox(height: DT.s.xl),
                  _buildDetailsSection(),
                  SizedBox(height: DT.s.xl),
                  _buildLocationSection(),
                  SizedBox(height: DT.s.xl),
                  _buildDateSection(),
                  SizedBox(height: DT.s.xl),
                  _buildLanguageSection(),
                  if (widget.itemType == ItemType.found) ...[
                    SizedBox(height: DT.s.xl),
                    _buildRewardSection(),
                  ],
                  SizedBox(height: DT.s.xl * 2),
                  CustomButton(
                    text: widget.itemType == ItemType.lost
                        ? 'Report Lost Item'
                        : 'Report Found Item',
                    onPressed: _submitForm,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: DT.s.xl),
                ],
              ),
            ),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Text(
          'Add photos to help identify the item. First photo will be the main image.',
          style: DT.t.body.copyWith(color: DT.c.textMuted),
        ),
        SizedBox(height: DT.s.md),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Container(
                  width: 120,
                  height: 120,
                  margin: EdgeInsets.only(right: DT.s.md),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DT.c.brand,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Main',
                              style: DT.t.caption.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_selectedImages.length < 5)
                GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: DT.c.blueTint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DT.c.blueTint,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: DT.c.brand,
                          size: 32,
                        ),
                        SizedBox(height: DT.s.sm),
                        Text(
                          'Add Photo',
                          style: DT.t.caption.copyWith(color: DT.c.brand),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        CustomTextField(
          controller: _titleController,
          label: 'Title',
          hint: 'Brief description of the item',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
        ),
        SizedBox(height: DT.s.lg),
        CustomTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Detailed description of the item',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value ?? '';
              _selectedSubcategory = '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        if (_selectedCategory.isNotEmpty &&
            _subcategories[_selectedCategory] != null) ...[
          SizedBox(height: DT.s.lg),
          DropdownButtonFormField<String>(
            initialValue: _selectedSubcategory.isEmpty
                ? null
                : _selectedSubcategory,
            decoration: InputDecoration(
              labelText: 'Subcategory',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _subcategories[_selectedCategory]!.map((subcategory) {
              return DropdownMenuItem(
                value: subcategory,
                child: Text(subcategory),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubcategory = value ?? '';
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Details', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        CustomTextField(
          controller: _brandController,
          label: 'Brand (Optional)',
          hint: 'e.g., Apple, Samsung, Nike',
        ),
        SizedBox(height: DT.s.lg),
        CustomTextField(
          controller: _colorController,
          label: 'Color (Optional)',
          hint: 'e.g., Black, Blue, Red',
        ),
        SizedBox(height: DT.s.lg),
        CustomTextField(
          controller: _modelController,
          label: 'Model (Optional)',
          hint: 'e.g., iPhone 13, Galaxy S21',
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Container(
          padding: EdgeInsets.all(DT.s.md),
          decoration: BoxDecoration(
            color: DT.c.blueTint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DT.c.blueTint),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: DT.c.brand),
                  SizedBox(width: DT.s.sm),
                  Expanded(
                    child: Text(
                      _locationAddress.isEmpty
                          ? 'No location selected'
                          : _locationAddress,
                      style: DT.t.body,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DT.s.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                    ),
                  ),
                  SizedBox(width: DT.s.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectLocationOnMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Select on Map'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.itemType == ItemType.lost
              ? 'When did you lose it?'
              : 'When did you find it?',
          style: DT.t.h3,
        ),
        SizedBox(height: DT.s.md),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              border: Border.all(color: DT.c.blueTint),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: DT.c.brand),
                SizedBox(width: DT.s.md),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: DT.t.body,
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: DT.c.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        Row(
          children: [
            _buildLanguageChip('English', 'en'),
            SizedBox(width: DT.s.md),
            _buildLanguageChip('සිංහල', 'si'),
            SizedBox(width: DT.s.md),
            _buildLanguageChip('தமிழ்', 'ta'),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageChip(String label, String code) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
        decoration: BoxDecoration(
          color: isSelected ? DT.c.brand : Colors.transparent,
          border: Border.all(color: DT.c.brand),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: DT.t.body.copyWith(
            color: isSelected ? Colors.white : DT.c.brand,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRewardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reward (Optional)', style: DT.t.h3),
        SizedBox(height: DT.s.md),
        CustomTextField(
          controller: _rewardController,
          label: 'Reward Amount',
          hint: 'Enter amount in LKR',
          keyboardType: TextInputType.number,
          prefixText: 'LKR ',
        ),
      ],
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Check permissions
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        throw Exception('Location permission denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
        ].whereType<String>().where((e) => e.isNotEmpty).join(', ');

        setState(() {
          _selectedLocation = Location(
            latitude: position.latitude,
            longitude: position.longitude,
            address: address,
          );
          _locationAddress = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLocationOnMap() async {
    // This would open a map picker
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map picker will be implemented')),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Here you would upload images and create the item
      // For now, show success message
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.itemType == ItemType.lost ? "Lost" : "Found"} item reported successfully!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating item: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
