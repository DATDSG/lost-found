import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/design_tokens.dart';
import '../models/search_models.dart';

/// Modern Filter Sheet with comprehensive filtering options
/// Integrates seamlessly with the system UI design
class ModernFilterSheet extends StatefulWidget {
  final SearchFilters currentFilters;
  final Function(SearchFilters) onFiltersChanged;
  final List<FilterOption>? typeOptions;
  final List<FilterOption>? categoryOptions;
  final List<FilterOption>? colorOptions;
  final List<FilterOption>? sortOptions;

  const ModernFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
    this.typeOptions,
    this.categoryOptions,
    this.colorOptions,
    this.sortOptions,
  });

  @override
  State<ModernFilterSheet> createState() => _ModernFilterSheetState();
}

class _ModernFilterSheetState extends State<ModernFilterSheet>
    with TickerProviderStateMixin {
  late SearchFilters _filters;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            _slideAnimation.value * MediaQuery.of(context).size.height,
          ),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DT.c.shadow.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: DT.c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: EdgeInsets.all(DT.s.lg),
                    child: Row(
                      children: [
                        Text(
                          'Filters',
                          style: DT.t.h1.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_filters.hasActiveFilters)
                          GestureDetector(
                            onTap: _clearAllFilters,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: DT.s.md,
                                vertical: DT.s.sm,
                              ),
                              decoration: BoxDecoration(
                                color: DT.c.textMuted.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Clear All',
                                style: DT.t.label.copyWith(
                                  color: DT.c.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: DT.s.sm),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DT.c.textMuted.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: DT.c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: DT.c.brand,
                    unselectedLabelColor: DT.c.textMuted,
                    indicatorColor: DT.c.brand,
                    indicatorWeight: 3,
                    labelStyle: DT.t.body.copyWith(fontWeight: FontWeight.w600),
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Type'),
                      Tab(text: 'Category'),
                      Tab(text: 'Location'),
                      Tab(text: 'Time'),
                      Tab(text: 'Attributes'),
                      Tab(text: 'Sort'),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTypeFilter(),
                        _buildCategoryFilter(),
                        _buildLocationFilter(),
                        _buildTimeFilter(),
                        _buildAttributesFilter(),
                        _buildSortFilter(),
                      ],
                    ),
                  ),

                  // Apply button
                  Container(
                    padding: EdgeInsets.all(DT.s.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: DT.c.border.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearAllFilters,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: DT.c.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: DT.s.md),
                            ),
                            child: Text(
                              'Reset',
                              style: DT.t.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: DT.c.textMuted,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: DT.s.md),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DT.c.brand,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: DT.s.md),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply Filters',
                              style: DT.t.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeFilter() {
    final options = widget.typeOptions ?? _getDefaultTypeOptions();

    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Type',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),
          _buildOptionChip(
            'All Types',
            _filters.type == null,
            () => setState(() => _filters = _filters.copyWith(type: null)),
          ),
          SizedBox(height: DT.s.sm),
          ...options.map((option) {
            return Column(
              children: [
                _buildOptionChip(
                  option.label,
                  _filters.type == option.value,
                  () => setState(
                    () => _filters = _filters.copyWith(type: option.value),
                  ),
                  icon: option.icon,
                  color: option.color,
                ),
                SizedBox(height: DT.s.sm),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final options = widget.categoryOptions ?? _getDefaultCategoryOptions();

    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),
          _buildOptionChip(
            'All Categories',
            _filters.category == null,
            () => setState(() => _filters = _filters.copyWith(category: null)),
          ),
          SizedBox(height: DT.s.md),
          ...options.map((option) {
            return Column(
              children: [
                _buildOptionChip(
                  option.label,
                  _filters.category == option.value,
                  () => setState(
                    () => _filters = _filters.copyWith(category: option.value),
                  ),
                  icon: option.icon,
                ),
                SizedBox(height: DT.s.sm),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationFilter() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),

          // City input
          Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: DT.c.surface,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(color: DT.c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'City',
                  style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: DT.s.sm),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter city name...',
                    hintStyle: DT.t.body.copyWith(color: DT.c.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DT.c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DT.c.brand, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: DT.s.md,
                      vertical: DT.s.sm,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(
                        city: value.isEmpty ? null : value,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: DT.s.lg),

          // Distance filter
          Text(
            'Maximum Distance',
            style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.sm),
          Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: DT.c.surface,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(color: DT.c.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: DT.c.textMuted,
                    ),
                    SizedBox(width: DT.s.sm),
                    Text(
                      'Within ${_filters.maxDistance?.toStringAsFixed(1) ?? '10.0'} km',
                      style: DT.t.body.copyWith(color: DT.c.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: DT.s.sm),
                Slider(
                  value: _filters.maxDistance ?? 10.0,
                  min: 1.0,
                  max: 100.0,
                  divisions: 99,
                  activeColor: DT.c.brand,
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(maxDistance: value);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Range',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),

          // Quick time options
          _buildQuickTimeOptions(),

          SizedBox(height: DT.s.lg),

          // Custom date range
          Text(
            'Custom Date Range',
            style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.sm),
          Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: DT.c.surface,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(color: DT.c.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: DT.c.textMuted,
                    ),
                    SizedBox(width: DT.s.sm),
                    Text(
                      'From: ${_filters.startDate != null ? _formatDate(_filters.startDate!) : 'Any date'}',
                      style: DT.t.body.copyWith(color: DT.c.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: DT.s.sm),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: DT.c.textMuted,
                    ),
                    SizedBox(width: DT.s.sm),
                    Text(
                      'To: ${_filters.endDate != null ? _formatDate(_filters.endDate!) : 'Any date'}',
                      style: DT.t.body.copyWith(color: DT.c.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTimeOptions() {
    final now = DateTime.now();
    final options = [
      {'label': 'Last 24 hours', 'days': 1},
      {'label': 'Last week', 'days': 7},
      {'label': 'Last month', 'days': 30},
      {'label': 'Last 3 months', 'days': 90},
    ];

    return Wrap(
      spacing: DT.s.sm,
      runSpacing: DT.s.sm,
      children: options.map((option) {
        final days = option['days'] as int;
        final startDate = now.subtract(Duration(days: days));
        final isSelected =
            _filters.startDate != null &&
            _filters.startDate!.isAfter(
              startDate.subtract(const Duration(days: 1)),
            );

        return GestureDetector(
          onTap: () {
            setState(() {
              _filters = _filters.copyWith(startDate: startDate, endDate: now);
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DT.s.md,
              vertical: DT.s.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? DT.c.brand : DT.c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? DT.c.brand : DT.c.border),
            ),
            child: Text(
              option['label'] as String,
              style: DT.t.label.copyWith(
                color: isSelected ? Colors.white : DT.c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttributesFilter() {
    final colorOptions = widget.colorOptions ?? _getDefaultColorOptions();

    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reward filter
          Text(
            'Reward Offered',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),
          _buildOptionChip(
            'All',
            _filters.rewardOffered == null,
            () => setState(
              () => _filters = _filters.copyWith(rewardOffered: null),
            ),
          ),
          SizedBox(height: DT.s.sm),
          _buildOptionChip(
            'Yes',
            _filters.rewardOffered == true,
            () => setState(
              () => _filters = _filters.copyWith(rewardOffered: true),
            ),
            icon: Icons.monetization_on_rounded,
            color: DT.c.successFg,
          ),
          SizedBox(height: DT.s.sm),
          _buildOptionChip(
            'No',
            _filters.rewardOffered == false,
            () => setState(
              () => _filters = _filters.copyWith(rewardOffered: false),
            ),
            icon: Icons.money_off_rounded,
            color: DT.c.textMuted,
          ),

          SizedBox(height: DT.s.lg),

          // Color filter
          Text(
            'Colors',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),
          Wrap(
            spacing: DT.s.sm,
            runSpacing: DT.s.sm,
            children: colorOptions.map((option) {
              final isSelected =
                  _filters.colors?.contains(option.value) ?? false;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final colors = List<String>.from(_filters.colors ?? []);
                    if (isSelected) {
                      colors.remove(option.value);
                    } else {
                      colors.add(option.value);
                    }
                    _filters = _filters.copyWith(
                      colors: colors.isEmpty ? null : colors,
                    );
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DT.s.md,
                    vertical: DT.s.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? DT.c.brand : DT.c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? DT.c.brand : DT.c.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: option.color ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: DT.s.xs),
                      Text(
                        option.label,
                        style: DT.t.label.copyWith(
                          color: isSelected ? Colors.white : DT.c.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilter() {
    final sortOptions = widget.sortOptions ?? _getDefaultSortOptions();

    return SingleChildScrollView(
      padding: EdgeInsets.all(DT.s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DT.s.md),
          ...sortOptions.map((option) {
            return Column(
              children: [
                _buildOptionChip(
                  option.label,
                  _filters.sortBy == option.value,
                  () => setState(
                    () => _filters = _filters.copyWith(sortBy: option.value),
                  ),
                  icon: option.icon,
                ),
                SizedBox(height: DT.s.sm),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(DT.s.md),
        decoration: BoxDecoration(
          color: isSelected ? DT.c.brand : DT.c.surface,
          borderRadius: BorderRadius.circular(DT.r.md),
          border: Border.all(
            color: isSelected ? DT.c.brand : DT.c.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : (color ?? DT.c.textMuted),
              ),
              SizedBox(width: DT.s.sm),
            ],
            Expanded(
              child: Text(
                label,
                style: DT.t.body.copyWith(
                  color: isSelected ? Colors.white : DT.c.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filters = SearchFilters();
    });
    HapticFeedback.mediumImpact();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
    HapticFeedback.lightImpact();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Default options
  List<FilterOption> _getDefaultTypeOptions() {
    return [
      FilterOption(
        value: 'lost',
        label: 'Lost Items',
        icon: Icons.search_off_rounded,
        color: DT.c.dangerFg,
      ),
      FilterOption(
        value: 'found',
        label: 'Found Items',
        icon: Icons.search_rounded,
        color: DT.c.successFg,
      ),
    ];
  }

  List<FilterOption> _getDefaultCategoryOptions() {
    return [
      FilterOption(
        value: 'electronics',
        label: 'Electronics',
        icon: Icons.devices_rounded,
      ),
      FilterOption(
        value: 'personal_items',
        label: 'Personal Items',
        icon: Icons.person_rounded,
      ),
      FilterOption(
        value: 'clothing',
        label: 'Clothing',
        icon: Icons.checkroom_rounded,
      ),
      FilterOption(
        value: 'documents',
        label: 'Documents',
        icon: Icons.description_rounded,
      ),
      FilterOption(
        value: 'jewelry',
        label: 'Jewelry',
        icon: Icons.diamond_rounded,
      ),
      FilterOption(
        value: 'bags',
        label: 'Bags & Accessories',
        icon: Icons.shopping_bag_rounded,
      ),
      FilterOption(value: 'keys', label: 'Keys', icon: Icons.vpn_key_rounded),
      FilterOption(
        value: 'other',
        label: 'Other',
        icon: Icons.category_rounded,
      ),
    ];
  }

  List<FilterOption> _getDefaultColorOptions() {
    return [
      FilterOption(value: 'red', label: 'Red', color: Colors.red),
      FilterOption(value: 'blue', label: 'Blue', color: Colors.blue),
      FilterOption(value: 'green', label: 'Green', color: Colors.green),
      FilterOption(value: 'yellow', label: 'Yellow', color: Colors.yellow),
      FilterOption(value: 'black', label: 'Black', color: Colors.black),
      FilterOption(value: 'white', label: 'White', color: Colors.white),
      FilterOption(value: 'gray', label: 'Gray', color: Colors.grey),
      FilterOption(value: 'brown', label: 'Brown', color: Colors.brown),
    ];
  }

  List<FilterOption> _getDefaultSortOptions() {
    return [
      FilterOption(
        value: 'relevance',
        label: 'Most Relevant',
        icon: Icons.star_rounded,
      ),
      FilterOption(
        value: 'date_newest',
        label: 'Newest First',
        icon: Icons.schedule_rounded,
      ),
      FilterOption(
        value: 'date_oldest',
        label: 'Oldest First',
        icon: Icons.history_rounded,
      ),
      FilterOption(
        value: 'distance',
        label: 'Nearest First',
        icon: Icons.location_on_rounded,
      ),
      FilterOption(
        value: 'title',
        label: 'Alphabetical',
        icon: Icons.sort_by_alpha_rounded,
      ),
    ];
  }
}
