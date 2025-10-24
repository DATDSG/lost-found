import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/repositories/repositories.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/matching_models.dart';
import '../../../../shared/widgets/image_picker_widget.dart';
import '../../../../shared/widgets/location_widget.dart';
import '../../../../shared/widgets/main_layout.dart';

/// Comprehensive found item report form with design science principles
class FoundItemReportForm extends ConsumerStatefulWidget {
  /// Creates a new found item report form widget
  const FoundItemReportForm({super.key});

  @override
  ConsumerState<FoundItemReportForm> createState() =>
      _FoundItemReportFormState();
}

class _FoundItemReportFormState extends ConsumerState<FoundItemReportForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _foundCircumstancesController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _handlingInstructionsController = TextEditingController();

  String _selectedCategory = '';
  String _selectedColor = '';
  String _selectedCondition = '';
  String _selectedSize = '';
  String _selectedMaterial = '';
  String _selectedValue = '';
  DateTime? _foundDate;
  TimeOfDay? _foundTime;
  List<File> _selectedImages = const [];
  bool _isSafe = true;
  String _safetyStatus = 'Safe';
  bool _hasSerialNumber = false;
  bool _isValuable = false;
  bool _needsSpecialHandling = false;
  bool _turnedIntoPolice = false;
  bool _isSubmitting = false;

  // Location data
  double? _currentLatitude;
  double? _currentLongitude;

  final List<String> _categories = [
    // Electronics & Technology
    'Phone',
    'Laptop',
    'Tablet',
    'Headphones',
    'Charger',
    'Camera',
    'Watch',
    'Electronics',
    // Personal Items
    'Wallet', 'Keys', 'Bag/Purse', 'Backpack', 'Glasses', 'Umbrella',
    // Clothing & Accessories
    'Jacket', 'Shirt', 'Pants', 'Shoes', 'Hat', 'Scarf', 'Belt', 'Jewelry',
    // Documents & Books
    'Passport',
    'ID Card',
    "Driver's License",
    'Credit Card',
    'Book',
    'Notebook',
    'Documents',
    // Sports & Recreation
    'Bicycle', 'Skateboard', 'Sports Equipment', 'Toy',
    // Tools & Equipment
    'Tools', 'Equipment',
    // Miscellaneous
    'Pet', 'Vehicle', 'Other',
  ];

  final List<String> _colors = [
    // Primary Colors
    'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple',
    // Neutral Colors
    'Black', 'White', 'Gray', 'Brown', 'Beige', 'Tan',
    // Secondary Colors
    'Pink', 'Cyan', 'Magenta', 'Lime', 'Navy', 'Maroon',
    // Metallic Colors
    'Silver', 'Gold', 'Bronze', 'Copper',
    // Pastel Colors
    'Light Blue', 'Light Green', 'Light Pink', 'Lavender',
    // Dark Colors
    'Dark Blue', 'Dark Green', 'Dark Red', 'Dark Gray',
    // Special Colors
    'Transparent', 'Multicolored', 'Patterned',
  ];

  final List<String> _conditions = [
    'Excellent',
    'Good',
    'Fair',
    'Poor',
    'Damaged',
    'Broken',
    'Unknown',
  ];

  final List<String> _sizes = [
    'Extra Small (XS)',
    'Small (S)',
    'Medium (M)',
    'Large (L)',
    'Extra Large (XL)',
    'XXL',
    'XXXL',
    'Custom Size',
    'Not Applicable',
  ];

  final List<String> _materials = [
    'Metal',
    'Plastic',
    'Leather',
    'Fabric',
    'Wood',
    'Glass',
    'Ceramic',
    'Rubber',
    'Silicon',
    'Carbon Fiber',
    'Mixed Materials',
    'Unknown',
  ];

  final List<String> _values = [
    r'Under $50',
    r'$50 - $100',
    r'$100 - $500',
    r'$500 - $1,000',
    r'$1,000 - $5,000',
    r'$5,000 - $10,000',
    r'Over $10,000',
    'Sentimental Value',
    'Unknown',
  ];

  final List<String> _safetyStatuses = [
    'Safe',
    'Needs Attention',
    'Damaged',
    'Broken',
    'Potentially Dangerous',
    'Requires Professional Handling',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _additionalInfoController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _foundCircumstancesController.dispose();
    _storageLocationController.dispose();
    _handlingInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: MainLayout(
      currentIndex: 1, // Reports is index 1
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader()),

          // Form Content
          SliverToBoxAdapter(child: _buildForm()),

          // Bottom spacing
          SliverToBoxAdapter(child: SizedBox(height: DT.s.xl)),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DT.c.accentGreen,
          DT.c.accentGreen.withValues(alpha: 0.8),
          DT.c.accentGreen.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(DT.r.xl),
        bottomRight: Radius.circular(DT.r.xl),
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DT.c.textOnBrand.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DT.r.md),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: DT.c.textOnBrand,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: DT.s.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Found Item',
                        style: DT.t.headlineSmall.copyWith(
                          color: DT.c.textOnBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: DT.s.xs),
                      Text(
                        'Help reunite someone with their item',
                        style: DT.t.bodyMedium.copyWith(
                          color: DT.c.textOnBrand.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: DT.c.textOnBrand.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DT.r.lg),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: DT.c.textOnBrand,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Padding(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safety Status
          _buildSafetyStatus(),

          SizedBox(height: DT.s.lg),

          // Item Title
          _buildFormField(
            controller: _titleController,
            label: 'Item Title',
            hint: 'What did you find? (e.g., Black iPhone 13)',
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the item title';
              }
              if (value.length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.lg),

          // Category Selection
          _buildDropdownField(
            label: 'Category',
            value: _selectedCategory,
            items: _categories,
            icon: Icons.category,
            onChanged: (value) =>
                setState(() => _selectedCategory = value ?? ''),
            validator: (value) {
              if (_selectedCategory.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.lg),

          // Color Selection
          _buildDropdownField(
            label: 'Color',
            value: _selectedColor,
            items: _colors,
            icon: Icons.palette,
            onChanged: (value) => setState(() => _selectedColor = value ?? ''),
            validator: (value) {
              if (_selectedColor.isEmpty) {
                return 'Please select a color';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.lg),

          // Condition Selection
          _buildDropdownField(
            label: 'Condition',
            value: _selectedCondition,
            items: _conditions,
            icon: Icons.star,
            onChanged: (value) =>
                setState(() => _selectedCondition = value ?? ''),
          ),

          SizedBox(height: DT.s.lg),

          // Brand and Model (for electronics and other items)
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _brandController,
                  label: 'Brand',
                  hint: 'e.g., Apple, Samsung, Nike',
                  icon: Icons.business,
                ),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: _buildFormField(
                  controller: _modelController,
                  label: 'Model',
                  hint: 'e.g., iPhone 13, Galaxy S21',
                  icon: Icons.model_training,
                ),
              ),
            ],
          ),

          SizedBox(height: DT.s.lg),

          // Size and Material
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Size',
                  value: _selectedSize,
                  items: _sizes,
                  icon: Icons.straighten,
                  onChanged: (value) =>
                      setState(() => _selectedSize = value ?? ''),
                ),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: _buildDropdownField(
                  label: 'Material',
                  value: _selectedMaterial,
                  items: _materials,
                  icon: Icons.texture,
                  onChanged: (value) =>
                      setState(() => _selectedMaterial = value ?? ''),
                ),
              ),
            ],
          ),

          SizedBox(height: DT.s.lg),

          // Estimated Value
          _buildDropdownField(
            label: 'Estimated Value',
            value: _selectedValue,
            items: _values,
            icon: Icons.attach_money,
            onChanged: (value) => setState(() => _selectedValue = value ?? ''),
          ),

          SizedBox(height: DT.s.lg),

          // Serial Number Section
          _buildSerialNumberSection(),

          SizedBox(height: DT.s.lg),

          // Value and Handling Section
          _buildValueHandlingSection(),

          SizedBox(height: DT.s.lg),

          // Found Date & Time
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Found Date',
                  value: _foundDate,
                  icon: Icons.calendar_today,
                  onChanged: (date) => setState(() => _foundDate = date),
                  validator: (value) {
                    if (_foundDate == null) {
                      return 'Please select when you found the item';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: _buildTimeField(
                  label: 'Found Time',
                  value: _foundTime,
                  icon: Icons.access_time,
                  onChanged: (time) => setState(() => _foundTime = time),
                ),
              ),
            ],
          ),

          SizedBox(height: DT.s.lg),

          // Location
          _buildFormField(
            controller: _locationController,
            label: 'Location',
            hint: 'Where did you find it? (e.g., Central Park, NYC)',
            icon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the location';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.md),

          // Current Location Widget
          LocationWidget(
            onLocationChanged: (latitude, longitude, address) {
              // Store coordinates for API submission
              _currentLatitude = latitude;
              _currentLongitude = longitude;

              // Auto-fill location field if empty
              if (_locationController.text.isEmpty && address != null) {
                _locationController.text = address;
              }
            },
          ),

          SizedBox(height: DT.s.lg),

          // Description
          _buildFormField(
            controller: _descriptionController,
            label: 'Description',
            hint:
                'Describe the found item in detail. Include any unique features, damage, or identifying marks...',
            icon: Icons.description,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide a description';
              }
              if (value.length < 10) {
                return 'Description must be at least 10 characters';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.lg),

          // Contact Information
          _buildFormField(
            controller: _contactController,
            label: 'Contact Information',
            hint: 'Phone number or email for contact',
            icon: Icons.contact_phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter contact information';
              }
              return null;
            },
          ),

          SizedBox(height: DT.s.lg),

          // Additional Information
          _buildFormField(
            controller: _additionalInfoController,
            label: 'Additional Information',
            hint:
                'Any additional details that might help identify the owner...',
            icon: Icons.info_outline,
          ),

          SizedBox(height: DT.s.lg),

          // Found Circumstances
          _buildFormField(
            controller: _foundCircumstancesController,
            label: 'Found Circumstances',
            hint:
                'How and where did you find this item? What was the situation?',
            icon: Icons.search,
          ),

          SizedBox(height: DT.s.lg),

          // Storage Location
          _buildFormField(
            controller: _storageLocationController,
            label: 'Current Storage Location',
            hint:
                'Where is the item currently stored? (e.g., home, office, police station)',
            icon: Icons.location_on,
          ),

          SizedBox(height: DT.s.lg),

          // Handling Instructions
          _buildFormField(
            controller: _handlingInstructionsController,
            label: 'Handling Instructions',
            hint:
                'Any special instructions for handling or returning this item?',
            icon: Icons.assignment,
            maxLines: 2,
          ),

          SizedBox(height: DT.s.lg),

          // Images Section
          ImagePickerWidget(
            initialImages: _selectedImages,
            onImagesChanged: (images) {
              setState(() {
                _selectedImages = images;
              });
            },
          ),

          SizedBox(height: DT.s.xl),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    ),
  );

  Widget _buildSafetyStatus() => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.accentGreen.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.accentGreen.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security, color: DT.c.accentGreen, size: 24),
            SizedBox(width: DT.s.sm),
            Text(
              'Safety Status',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.sm),
        _buildDropdownField(
          label: 'Item Safety',
          value: _safetyStatus,
          items: _safetyStatuses,
          icon: Icons.shield,
          onChanged: (value) => setState(() => _safetyStatus = value ?? 'Safe'),
        ),
        SizedBox(height: DT.s.sm),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _isSafe,
                onChanged: (value) => setState(() => _isSafe = value ?? true),
                title: Text(
                  'Item is safe to handle',
                  style: DT.t.bodyMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: DT.c.accentGreen,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: DT.c.brand, size: 20),
          SizedBox(width: DT.s.sm),
          Text(
            label,
            style: DT.t.labelLarge.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: DT.s.sm),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.brand, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.error),
          ),
          contentPadding: EdgeInsets.all(DT.s.md),
        ),
      ),
    ],
  );

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: DT.c.brand, size: 20),
          SizedBox(width: DT.s.sm),
          Text(
            label,
            style: DT.t.labelLarge.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: DT.s.sm),
      DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        items: items.isEmpty
            ? [
                const DropdownMenuItem<String>(
                  child: Text('No options available'),
                ),
              ]
            : items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
        selectedItemBuilder: (context) => items
            .map(
              (item) => Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: DT.t.bodyMedium.copyWith(color: DT.c.textPrimary),
              ),
            )
            .toList(),
        onChanged: items.isEmpty ? null : onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: items.isEmpty ? 'No options available' : 'Select $label',
          hintStyle: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DT.r.md),
            borderSide: BorderSide(color: DT.c.brand, width: 2),
          ),
          contentPadding: EdgeInsets.all(DT.s.md),
        ),
      ),
    ],
  );

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required void Function(DateTime?) onChanged,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: DT.c.brand, size: 20),
          SizedBox(width: DT.s.sm),
          Text(
            label,
            style: DT.t.labelLarge.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: DT.s.sm),
      GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            onChanged(date);
          }
        },
        child: Container(
          padding: EdgeInsets.all(DT.s.md),
          decoration: BoxDecoration(
            border: Border.all(color: DT.c.border),
            borderRadius: BorderRadius.circular(DT.r.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : 'Select date',
                  style: DT.t.bodyMedium.copyWith(
                    color: value != null ? DT.c.text : DT.c.textMuted,
                  ),
                ),
              ),
              Icon(Icons.calendar_today, color: DT.c.textMuted),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required IconData icon,
    required void Function(TimeOfDay?) onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: DT.c.brand, size: 20),
          SizedBox(width: DT.s.sm),
          Text(
            label,
            style: DT.t.labelLarge.copyWith(
              color: DT.c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: DT.s.sm),
      GestureDetector(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: value ?? TimeOfDay.now(),
          );
          if (time != null) {
            onChanged(time);
          }
        },
        child: Container(
          padding: EdgeInsets.all(DT.s.md),
          decoration: BoxDecoration(
            border: Border.all(color: DT.c.border),
            borderRadius: BorderRadius.circular(DT.r.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value != null
                      ? '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
                      : 'Select time',
                  style: DT.t.bodyMedium.copyWith(
                    color: value != null ? DT.c.text : DT.c.textMuted,
                  ),
                ),
              ),
              Icon(Icons.access_time, color: DT.c.textMuted),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildSerialNumberSection() => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.brand.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.brand.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code, color: DT.c.brand, size: 24),
            SizedBox(width: DT.s.sm),
            Text(
              'Serial Number Information',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.sm),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _hasSerialNumber,
                onChanged: (value) =>
                    setState(() => _hasSerialNumber = value ?? false),
                title: Text(
                  'Has Serial Number',
                  style: DT.t.bodyMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: DT.c.brand,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_hasSerialNumber) ...[
          SizedBox(height: DT.s.sm),
          _buildFormField(
            controller: _serialNumberController,
            label: 'Serial Number',
            hint: 'Enter the serial number or device ID',
            icon: Icons.qr_code_scanner,
          ),
        ],
      ],
    ),
  );

  Widget _buildValueHandlingSection() => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.accentTeal.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.accentTeal.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, color: DT.c.accentTeal, size: 24),
            SizedBox(width: DT.s.sm),
            Text(
              'Value & Handling Information',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.accentTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.sm),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _isValuable,
                onChanged: (value) =>
                    setState(() => _isValuable = value ?? false),
                title: Text(
                  'High Value Item',
                  style: DT.t.bodyMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: DT.c.accentTeal,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.sm),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _needsSpecialHandling,
                onChanged: (value) =>
                    setState(() => _needsSpecialHandling = value ?? false),
                title: Text(
                  'Needs Special Handling',
                  style: DT.t.bodyMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: DT.c.accentTeal,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.sm),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _turnedIntoPolice,
                onChanged: (value) =>
                    setState(() => _turnedIntoPolice = value ?? false),
                title: Text(
                  'Turned Into Police',
                  style: DT.t.bodyMedium.copyWith(
                    color: DT.c.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: DT.c.accentTeal,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: DT.c.accentGreen,
        padding: EdgeInsets.symmetric(vertical: DT.s.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DT.r.md),
        ),
        elevation: 0,
      ),
      child: _isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(DT.c.textOnBrand),
              ),
            )
          : Text(
              'Submit Found Item Report',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.textOnBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );

  Future<void> _submitForm() async {
    if (kDebugMode) {
      print('Submit button pressed');
      print('Form key current state: ${_formKey.currentState}');
    }

    if (_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print('Form validation passed');
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        await HapticFeedback.lightImpact();

        final reportService = ref.read(reportServiceProvider);

        // Create combined date and time
        var occurredAt = _foundDate ?? DateTime.now();
        if (_foundTime != null) {
          occurredAt = DateTime(
            occurredAt.year,
            occurredAt.month,
            occurredAt.day,
            _foundTime!.hour,
            _foundTime!.minute,
          );
        }

        if (kDebugMode) {
          print('Submitting report with data:');
          print('Title: ${_titleController.text.trim()}');
          print('Description: ${_descriptionController.text.trim()}');
          print('Category: $_selectedCategory');
          print('Location: ${_locationController.text.trim()}');
          print('Occurred at: $occurredAt');
        }

        // Submit the report
        await reportService.createReport(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: ReportType.found,
          category: _selectedCategory,
          location: _locationController.text.trim(),
          occurredAt: occurredAt,
          colors: _selectedColor.isNotEmpty ? [_selectedColor] : [],
          images: _selectedImages.isNotEmpty ? _selectedImages : null,
          latitude: _currentLatitude,
          longitude: _currentLongitude,
        );

        if (kDebugMode) {
          print('Report submitted successfully');
        }

        // Show success dialog
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Report Submitted'),
              content: const Text(
                "Your found item report has been submitted successfully. We'll help you find the owner.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          print('Report submission error: $e');
        }

        // Show error dialog
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Submission Failed'),
              content: Text(
                'Failed to submit your report. Please check your internet connection and try again.\n\nError: ${e.toString()}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      if (kDebugMode) {
        print('Form validation failed');
      }
    }
  }
}
