import 'package:flutter/material.dart';
import '../services/preferences_storage_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialType;
  final Function(Map<String, dynamic>) onApply;
  final Map<String, dynamic>? initialFilters;

  const FilterBottomSheet({
    super.key,
    this.initialType,
    required this.onApply,
    this.initialFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedType = 'lost';
  String _selectedTime = 'Any Time';
  String _selectedDistance = 'Any Distance';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedSortBy = 'Date';
  String _selectedSortOrder = 'Newest First';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late PreferencesStorageService _preferencesService;

  final List<String> _timeOptions = [
    'Any Time',
    'Last 24 hours',
    'Last 7 days',
    'Last 30 days',
  ];

  final List<String> _distanceOptions = [
    'Any Distance',
    '0.5 mi',
    '1 mi',
    '5 mi',
    '10 mi',
  ];

  final List<String> _categoryOptions = [
    'All',
    'Electronics',
    'Bags',
    'Accessories',
    'Documents',
    'Clothing',
    'Keys',
    'Books',
    'Toys',
    'Sports',
    'Other',
  ];

  final List<String> _statusOptions = [
    'All',
    'Active',
    'Resolved',
    'Pending',
  ];

  final List<String> _sortByOptions = [
    'Date',
    'Distance',
    'Title',
    'Category',
  ];

  final List<String> _sortOrderOptions = [
    'Newest First',
    'Oldest First',
    'Closest First',
    'Farthest First',
  ];

  @override
  void initState() {
    super.initState();
    _preferencesService = PreferencesStorageService.getInstance();
    _loadSavedFilters();

    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    if (widget.initialFilters != null) {
      _applyInitialFilters(widget.initialFilters!);
    }
  }

  Future<void> _loadSavedFilters() async {
    final savedFilters = await _preferencesService.getFilters();
    if (savedFilters.isNotEmpty) {
      _applyInitialFilters(savedFilters);
    }
  }

  void _applyInitialFilters(Map<String, dynamic> filters) {
    setState(() {
      _selectedType = filters['type'] ?? 'lost';
      _selectedTime = filters['time'] ?? 'Any Time';
      _selectedDistance = filters['distance'] ?? 'Any Distance';
      _selectedCategory = filters['category'] ?? 'All';
      _selectedStatus = filters['status'] ?? 'All';
      _selectedSortBy = filters['sortBy'] ?? 'Date';
      _selectedSortOrder = filters['sortOrder'] ?? 'Newest First';
      _locationController.text = filters['location'] ?? '';
      _searchController.text = filters['search'] ?? '';
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Lost/Found Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              'Lost',
                              _selectedType == 'lost',
                              () => setState(() => _selectedType = 'lost'),
                            ),
                          ),
                          Expanded(
                            child: _buildToggleButton(
                              'Found',
                              _selectedType == 'found',
                              () => setState(() => _selectedType = 'found'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Filter
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Filter
                    _buildDropdownFilter(
                      'Time',
                      _selectedTime,
                      _timeOptions,
                      (value) => setState(() => _selectedTime = value!),
                    ),
                    const SizedBox(height: 16),

                    // Distance Filter
                    _buildDropdownFilter(
                      'Distance',
                      _selectedDistance,
                      _distanceOptions,
                      (value) => setState(() => _selectedDistance = value!),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter
                    _buildDropdownFilter(
                      'Category',
                      _selectedCategory,
                      _categoryOptions,
                      (value) => setState(() => _selectedCategory = value!),
                    ),
                    const SizedBox(height: 16),

                    // Status Filter
                    _buildDropdownFilter(
                      'Status',
                      _selectedStatus,
                      _statusOptions,
                      (value) => setState(() => _selectedStatus = value!),
                    ),
                    const SizedBox(height: 16),

                    // Sort By Filter
                    _buildDropdownFilter(
                      'Sort By',
                      _selectedSortBy,
                      _sortByOptions,
                      (value) => setState(() => _selectedSortBy = value!),
                    ),
                    const SizedBox(height: 16),

                    // Sort Order Filter
                    _buildDropdownFilter(
                      'Sort Order',
                      _selectedSortOrder,
                      _sortOrderOptions,
                      (value) => setState(() => _selectedSortOrder = value!),
                    ),
                    const SizedBox(height: 16),

                    // Location Input
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter Location',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side:
                                  BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _applyFilters,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[700]),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = 'lost';
      _selectedTime = 'Any Time';
      _selectedDistance = 'Any Distance';
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedSortBy = 'Date';
      _selectedSortOrder = 'Newest First';
      _locationController.clear();
      _searchController.clear();
    });
  }

  void _applyFilters() async {
    final filters = {
      'type': _selectedType,
      'time': _selectedTime,
      'distance': _selectedDistance,
      'category': _selectedCategory,
      'status': _selectedStatus,
      'sortBy': _selectedSortBy,
      'sortOrder': _selectedSortOrder,
      'location': _locationController.text,
      'search': _searchController.text,
    };

    // Save filters to preferences
    await _preferencesService.setFilters(filters);

    // Convert filters to backend format
    final backendFilters = _convertToBackendFilters(filters);

    widget.onApply(backendFilters);
    Navigator.pop(context);
  }

  Map<String, dynamic> _convertToBackendFilters(Map<String, dynamic> filters) {
    final backendFilters = <String, dynamic>{};

    // Convert type filter
    if (filters['type'] != null && filters['type'] != 'lost') {
      backendFilters['type'] = filters['type'];
    }

    // Convert time filter
    if (filters['time'] != null && filters['time'] != 'Any Time') {
      final now = DateTime.now();
      switch (filters['time']) {
        case 'Last 24 hours':
          backendFilters['dateFrom'] =
              now.subtract(const Duration(hours: 24)).toIso8601String();
          break;
        case 'Last 7 days':
          backendFilters['dateFrom'] =
              now.subtract(const Duration(days: 7)).toIso8601String();
          break;
        case 'Last 30 days':
          backendFilters['dateFrom'] =
              now.subtract(const Duration(days: 30)).toIso8601String();
          break;
      }
    }

    // Convert distance filter
    if (filters['distance'] != null && filters['distance'] != 'Any Distance') {
      final distanceStr = filters['distance'].toString().replaceAll(' mi', '');
      final distance = double.tryParse(distanceStr);
      if (distance != null) {
        backendFilters['maxDistance'] =
            distance * 1609.34; // Convert miles to meters
      }
    }

    // Convert category filter
    if (filters['category'] != null && filters['category'] != 'All') {
      backendFilters['category'] = filters['category'].toLowerCase();
    }

    // Convert status filter
    if (filters['status'] != null && filters['status'] != 'All') {
      backendFilters['status'] = filters['status'].toLowerCase();
    }

    // Convert search filter
    if (filters['search'] != null && filters['search'].toString().isNotEmpty) {
      backendFilters['search'] = filters['search'];
    }

    // Convert location filter
    if (filters['location'] != null &&
        filters['location'].toString().isNotEmpty) {
      backendFilters['location'] = filters['location'];
    }

    // Convert sort filters
    if (filters['sortBy'] != null && filters['sortBy'] != 'Date') {
      backendFilters['sortBy'] = filters['sortBy'].toLowerCase();
    }

    if (filters['sortOrder'] != null &&
        filters['sortOrder'] != 'Newest First') {
      backendFilters['sortOrder'] =
          filters['sortOrder'].contains('First') ? 'asc' : 'desc';
    }

    return backendFilters;
  }
}
