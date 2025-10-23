import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/models/matching_models.dart';
import '../../../../shared/providers/api_providers.dart';
import '../../../../shared/widgets/image_picker_widget.dart';
import '../../../../shared/widgets/location_widget.dart';
import '../../../../shared/widgets/main_layout.dart';

/// Comprehensive lost item report form with design science principles
class LostItemReportForm extends ConsumerStatefulWidget {
  /// Creates a new lost item report form widget
  const LostItemReportForm({super.key});

  @override
  ConsumerState<LostItemReportForm> createState() => _LostItemReportFormState();
}

class _LostItemReportFormState extends ConsumerState<LostItemReportForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _rewardController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  final _lastSeenController = TextEditingController();
  final _circumstancesController = TextEditingController();

  String _selectedCategory = '';
  String _selectedColor = '';
  String _selectedCondition = '';
  String _selectedSize = '';
  String _selectedMaterial = '';
  String _selectedValue = '';
  DateTime? _lostDate;
  TimeOfDay? _lostTime;
  List<File> _selectedImages = const [];
  bool _isUrgent = false;
  bool _offerReward = false;
  bool _hasSerialNumber = false;
  bool _isInsured = false;
  bool _hasReceipt = false;
  bool _isSubmitting = false;

  // Location data
  double? _currentLatitude;
  double? _currentLongitude;

  final List<String> _categories = [
    'Phone',
    'Laptop',
    'Tablet',
    'Headphones',
    'Charger',
    'Camera',
    'Smart Watch',
    'Other Electronics',
    'Wallet',
    'Keys',
    'Bag/Purse',
    'Backpack',
    'Glasses',
    'Umbrella',
    'Jacket',
    'Shirt',
    'Pants',
    'Shoes',
    'Hat',
    'Scarf',
    'Belt',
    'Jewelry',
    'Passport',
    'ID Card',
    "Driver's License",
    'Credit Card',
    'Book',
    'Notebook',
    'Other Documents',
    'Bicycle',
    'Skateboard',
    'Sports Equipment',
    'Toy',
    'Tools',
    'Equipment',
    'Pet',
    'Vehicle',
    'Other',
  ];

  final List<String> _colors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Black',
    'White',
    'Gray',
    'Brown',
    'Beige',
    'Tan',
    'Pink',
    'Cyan',
    'Magenta',
    'Lime',
    'Navy',
    'Maroon',
    'Silver',
    'Gold',
    'Bronze',
    'Copper',
    'Light Blue',
    'Light Green',
    'Light Pink',
    'Lavender',
    'Dark Blue',
    'Dark Green',
    'Dark Red',
    'Dark Gray',
    'Transparent',
    'Multicolored',
    'Patterned',
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
    _rewardController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _additionalDetailsController.dispose();
    _lastSeenController.dispose();
    _circumstancesController.dispose();
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
          DT.c.accentRed,
          DT.c.accentRed.withValues(alpha: 0.8),
          DT.c.accentRed.withValues(alpha: 0.6),
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
                        'Report Lost Item',
                        style: DT.t.headlineSmall.copyWith(
                          color: DT.c.textOnBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: DT.s.xs),
                      Text(
                        'Help others find your lost item',
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
                    Icons.search_off_rounded,
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
          // Urgent Toggle
          _buildUrgentToggle(),

          SizedBox(height: DT.s.lg),

          // Item Title
          _buildFormField(
            controller: _titleController,
            label: 'Item Title',
            hint: 'What did you lose? (e.g., iPhone 13 Pro Max)',
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

          // Insurance and Receipt Section
          _buildInsuranceSection(),

          SizedBox(height: DT.s.lg),

          // Lost Date & Time
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Lost Date',
                  value: _lostDate,
                  icon: Icons.calendar_today,
                  onChanged: (date) => setState(() => _lostDate = date),
                  validator: (value) {
                    if (_lostDate == null) {
                      return 'Please select when you lost the item';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: DT.s.md),
              Expanded(
                child: _buildTimeField(
                  label: 'Lost Time',
                  value: _lostTime,
                  icon: Icons.access_time,
                  onChanged: (time) => setState(() => _lostTime = time),
                ),
              ),
            ],
          ),

          SizedBox(height: DT.s.lg),

          // Location
          _buildFormField(
            controller: _locationController,
            label: 'Location',
            hint: 'Where did you lose it? (e.g., Central Park, NYC)',
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
                'Describe your lost item in detail. Include any unique features, damage, or identifying marks...',
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

          // Last Seen Location
          _buildFormField(
            controller: _lastSeenController,
            label: 'Last Seen Location',
            hint:
                'Where did you last see the item? (e.g., coffee shop, park, office)',
            icon: Icons.location_searching,
          ),

          SizedBox(height: DT.s.lg),

          // Circumstances of Loss
          _buildFormField(
            controller: _circumstancesController,
            label: 'Circumstances of Loss',
            hint:
                'How did you lose it? What were you doing? Any suspicious activity?',
            icon: Icons.help_outline,
            maxLines: 3,
          ),

          SizedBox(height: DT.s.lg),

          // Additional Details
          _buildFormField(
            controller: _additionalDetailsController,
            label: 'Additional Details',
            hint:
                'Any other important information that might help identify your item...',
            icon: Icons.info_outline,
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

          // Reward Section
          _buildRewardSection(),

          SizedBox(height: DT.s.xl),

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

  Widget _buildUrgentToggle() => Container(
    padding: EdgeInsets.all(DT.s.md),
    decoration: BoxDecoration(
      color: DT.c.accentRed.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DT.r.md),
      border: Border.all(color: DT.c.accentRed.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.priority_high, color: DT.c.accentRed, size: 24),
        SizedBox(width: DT.s.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urgent Report',
                style: DT.t.titleMedium.copyWith(
                  color: DT.c.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mark as urgent if this is a critical item',
                style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: _isUrgent,
          onChanged: (value) => setState(() => _isUrgent = value),
          activeThumbColor: DT.c.accentRed,
        ),
      ],
    ),
  );

  Widget _buildRewardSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.monetization_on, color: DT.c.brand, size: 20),
          SizedBox(width: DT.s.sm),
          Text(
            'Reward Information',
            style: DT.t.labelLarge.copyWith(
              color: DT.c.text,
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
              value: _offerReward,
              onChanged: (value) =>
                  setState(() => _offerReward = value ?? false),
              title: Text(
                'Offer Reward',
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
      if (_offerReward) ...[
        SizedBox(height: DT.s.sm),
        _buildFormField(
          controller: _rewardController,
          label: 'Reward Amount',
          hint: 'Enter reward amount (optional)',
          icon: Icons.attach_money,
        ),
      ],
    ],
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

  Widget _buildInsuranceSection() => Container(
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
              'Insurance & Documentation',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.accentGreen,
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
                value: _isInsured,
                onChanged: (value) =>
                    setState(() => _isInsured = value ?? false),
                title: Text(
                  'Item is Insured',
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
        SizedBox(height: DT.s.sm),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _hasReceipt,
                onChanged: (value) =>
                    setState(() => _hasReceipt = value ?? false),
                title: Text(
                  'Have Purchase Receipt',
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

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: DT.c.accentRed,
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
              'Submit Lost Item Report',
              style: DT.t.titleMedium.copyWith(
                color: DT.c.textOnBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await HapticFeedback.lightImpact();

        final reportService = ref.read(reportServiceProvider);

        // Create combined date and time
        var occurredAt = _lostDate ?? DateTime.now();
        if (_lostTime != null) {
          occurredAt = DateTime(
            occurredAt.year,
            occurredAt.month,
            occurredAt.day,
            _lostTime!.hour,
            _lostTime!.minute,
          );
        }

        // Submit the report
        await reportService.createReport(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: ReportType.lost,
          category: _selectedCategory,
          location: _locationController.text.trim(),
          occurredAt: occurredAt,
          colors: _selectedColor.isNotEmpty ? [_selectedColor] : [],
          isUrgent: _isUrgent,
          rewardOffered: _offerReward,
          rewardAmount: _offerReward && _rewardController.text.trim().isNotEmpty
              ? _rewardController.text.trim()
              : null,
          images: _selectedImages.isNotEmpty ? _selectedImages : null,
          latitude: _currentLatitude,
          longitude: _currentLongitude,
        );

        // Show success dialog
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Report Submitted'),
              content: const Text(
                "Your lost item report has been submitted successfully. We'll notify you if someone finds it.",
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
    }
  }
}
