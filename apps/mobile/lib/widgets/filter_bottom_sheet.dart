import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialType;
  final Function(Map<String, dynamic>) onApply;

  const FilterBottomSheet({
    super.key,
    this.initialType,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedType = 'lost';
  String _selectedTime = 'Any Time';
  String _selectedDistance = 'Any Distance';
  String _selectedCategory = 'All';
  final TextEditingController _locationController = TextEditingController();

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
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
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
      _locationController.clear();
    });
  }

  void _applyFilters() {
    final filters = {
      'type': _selectedType,
      'time': _selectedTime,
      'distance': _selectedDistance,
      'category': _selectedCategory,
      'location': _locationController.text,
    };
    widget.onApply(filters);
    Navigator.pop(context);
  }
}
