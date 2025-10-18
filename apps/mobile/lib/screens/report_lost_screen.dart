import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../core/theme/design_tokens.dart';
import '../core/routing/app_routes.dart';
import '../providers/reports_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/form_field_wrapper.dart';
import '../widgets/photo_picker.dart';
import '../widgets/location_picker.dart';

class ReportLostScreen extends StatefulWidget {
  const ReportLostScreen({super.key});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form data
  String _title = '';
  String _description = '';
  String _category = '';
  String _city = '';
  DateTime? _occurredAt;
  final List<String> _colors = [];
  String? _locationAddress;
  double? _latitude;
  double? _longitude;
  List<File> _photos = [];

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Accessories',
    'Documents',
    'Keys',
    'Bag/Backpack',
    'Jewelry',
    'Sports Equipment',
    'Books',
    'Other',
  ];

  final List<String> _colorOptions = [
    'Black',
    'White',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Brown',
    'Gray',
    'Silver',
    'Gold',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );

    final success = await reportsProvider.createReport(
      type: 'lost',
      title: _title,
      description: _description,
      category: _category,
      city: _city,
      occurredAt: _occurredAt ?? DateTime.now(),
      colors: _colors.isNotEmpty ? _colors : null,
      locationAddress: _locationAddress,
      latitude: _latitude,
      longitude: _longitude,
      photos: _photos.isNotEmpty ? _photos : null,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.success,
        arguments: {'type': 'lost', 'title': _title},
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportsProvider.error ?? 'Failed to create report'),
          backgroundColor: DT.c.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Report Lost Item'),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(DT.s.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 80, color: DT.c.textMuted),
                    SizedBox(height: DT.s.lg),
                    Text(
                      'Authentication Required',
                      style: DT.t.headline2,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DT.s.md),
                    Text(
                      'Please log in to report lost items',
                      style: DT.t.bodyLarge.copyWith(color: DT.c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DT.s.xl),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.login);
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildReportForm(context);
      },
    );
  }

  Widget _buildReportForm(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: const Text('Report Lost Item'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _currentStep == 0 ? null : _previousStep,
            child: Text(
              'Back',
              style: TextStyle(
                color: _currentStep == 0 ? DT.c.textMuted : DT.c.brand,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step Indicator
          Container(
            padding: EdgeInsets.all(DT.s.lg),
            child: StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: const [
                'Basic Info',
                'Description',
                'Category',
                'Location',
                'Photos',
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildDescriptionStep(),
                  _buildCategoryStep(),
                  _buildLocationStep(),
                  _buildPhotosStep(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(DT.s.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: DT.c.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: DT.s.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == _totalSteps - 1
                        ? _submitReport
                        : _nextStep,
                    child: Text(
                      _currentStep == _totalSteps - 1
                          ? 'Submit Report'
                          : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What did you lose?', style: DT.t.headline2),
          SizedBox(height: DT.s.sm),
          Text(
            'Provide a clear title for your lost item',
            style: DT.t.bodyMuted,
          ),
          SizedBox(height: DT.s.xl),

          FormFieldWrapper(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Item Title',
                hintText: 'e.g., iPhone 13 Pro, Black Backpack',
                prefixIcon: Icon(Icons.title),
              ),
              onChanged: (value) => _title = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: DT.s.lg),

          FormFieldWrapper(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Where did you lose it?',
                prefixIcon: Icon(Icons.location_city),
              ),
              onChanged: (value) => _city = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the city';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: DT.s.lg),

          FormFieldWrapper(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _occurredAt = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'When did you lose it?',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _occurredAt != null
                      ? '${_occurredAt!.day}/${_occurredAt!.month}/${_occurredAt!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: _occurredAt != null ? DT.c.text : DT.c.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe your item', style: DT.t.headline2),
          SizedBox(height: DT.s.sm),
          Text(
            'Add details that will help others identify your item',
            style: DT.t.bodyMuted,
          ),
          SizedBox(height: DT.s.xl),

          FormFieldWrapper(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText:
                    'Describe the item, its condition, any distinctive features...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 6,
              onChanged: (value) => _description = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
          ),

          SizedBox(height: DT.s.lg),

          Text('Colors', style: DT.t.title),
          SizedBox(height: DT.s.md),

          Wrap(
            spacing: DT.s.sm,
            runSpacing: DT.s.sm,
            children: _colorOptions.map((color) {
              final isSelected = _colors.contains(color);
              return FilterChip(
                label: Text(color),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _colors.add(color);
                    } else {
                      _colors.remove(color);
                    }
                  });
                },
                selectedColor: DT.c.brand.withValues(alpha: 0.2),
                checkmarkColor: DT.c.brand,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Category', style: DT.t.headline2),
          SizedBox(height: DT.s.sm),
          Text(
            'Choose the category that best describes your item',
            style: DT.t.bodyMuted,
          ),
          SizedBox(height: DT.s.xl),

          ..._categories.map((category) {
            final isSelected = _category == category;
            return Container(
              margin: EdgeInsets.only(bottom: DT.s.sm),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _category = category;
                  });
                },
                borderRadius: BorderRadius.circular(DT.r.md),
                child: Container(
                  padding: EdgeInsets.all(DT.s.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? DT.c.brand.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(DT.r.md),
                    border: Border.all(
                      color: isSelected ? DT.c.brand : DT.c.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? DT.c.brand : DT.c.textMuted,
                      ),
                      SizedBox(width: DT.s.md),
                      Expanded(
                        child: Text(
                          category,
                          style: DT.t.body.copyWith(
                            color: isSelected ? DT.c.brand : DT.c.text,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: DT.c.brand),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location Details', style: DT.t.headline2),
          SizedBox(height: DT.s.sm),
          Text(
            'Help others know where to look for your item',
            style: DT.t.bodyMuted,
          ),
          SizedBox(height: DT.s.xl),

          LocationPicker(
            onLocationSelected: (address, lat, lng) {
              setState(() {
                _locationAddress = address;
                _latitude = lat;
                _longitude = lng;
              });
            },
          ),

          if (_locationAddress != null) ...[
            SizedBox(height: DT.s.lg),
            Container(
              padding: EdgeInsets.all(DT.s.md),
              decoration: BoxDecoration(
                color: DT.c.successBg,
                borderRadius: BorderRadius.circular(DT.r.md),
                border: Border.all(
                  color: DT.c.successFg.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: DT.c.successFg),
                  SizedBox(width: DT.s.sm),
                  Expanded(
                    child: Text(
                      'Location selected: $_locationAddress',
                      style: DT.t.body.copyWith(color: DT.c.successFg),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Photos', style: DT.t.headline2),
          SizedBox(height: DT.s.sm),
          Text(
            'Photos help others identify your item (optional)',
            style: DT.t.bodyMuted,
          ),
          SizedBox(height: DT.s.xl),

          PhotoPicker(
            photos: _photos,
            onPhotosChanged: (photos) {
              setState(() {
                _photos = photos;
              });
            },
            maxPhotos: 5,
          ),

          SizedBox(height: DT.s.lg),

          Container(
            padding: EdgeInsets.all(DT.s.lg),
            decoration: BoxDecoration(
              color: DT.c.blueTint,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(color: DT.c.brand.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: DT.c.brand),
                    SizedBox(width: DT.s.sm),
                    Text(
                      'Photo Tips',
                      style: DT.t.title.copyWith(color: DT.c.brand),
                    ),
                  ],
                ),
                SizedBox(height: DT.s.md),
                Text(
                  '• Take clear, well-lit photos\n'
                  '• Include different angles\n'
                  '• Show any distinctive features\n'
                  '• Avoid blurry or dark images',
                  style: DT.t.body.copyWith(color: DT.c.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.phone_android;
      case 'Clothing':
        return Icons.checkroom;
      case 'Accessories':
        return Icons.watch;
      case 'Documents':
        return Icons.description;
      case 'Keys':
        return Icons.vpn_key;
      case 'Bag/Backpack':
        return Icons.backpack;
      case 'Jewelry':
        return Icons.diamond;
      case 'Sports Equipment':
        return Icons.sports_soccer;
      case 'Books':
        return Icons.menu_book;
      default:
        return Icons.category;
    }
  }
}
