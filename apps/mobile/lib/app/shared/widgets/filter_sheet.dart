import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_tokens.dart';
import '../models/home_models.dart';
import '../providers/api_providers.dart';

/// Bottom sheet widget for filtering reports
class FilterSheet extends ConsumerStatefulWidget {
  /// Creates a new [FilterSheet] instance
  const FilterSheet({
    super.key,
    this.onApply,
    this.onClear,
    this.initialFilters,
  });

  /// Callback when apply button is pressed
  final void Function(FilterOptions)? onApply;

  /// Callback when clear button is pressed
  final VoidCallback? onClear;

  /// Initial filter values
  final FilterOptions? initialFilters;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet>
    with TickerProviderStateMixin {
  late FilterOptions _filters;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? FilterOptions();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: _slideAnimation,
    child: Container(
      decoration: BoxDecoration(
        color: DT.c.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: DT.e.lg,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: EdgeInsets.only(top: DT.s.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DT.c.border,
                borderRadius: BorderRadius.circular(DT.r.sm),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.all(DT.s.lg),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Reports',
                        style: DT.t.headlineSmall.copyWith(
                          color: DT.c.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: DT.s.xs),
                      Text(
                        'Refine your search results',
                        style: DT.t.bodySmall.copyWith(color: DT.c.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DT.c.surfaceVariant,
                        borderRadius: BorderRadius.circular(DT.r.md),
                      ),
                      child: Icon(Icons.close, color: DT.c.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Filter options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
              child: Column(
                children: [
                  // Lost/Found Toggle
                  _buildToggleFilter(),
                  SizedBox(height: DT.s.md),

                  // Time Filter
                  _buildDropdownFilter(
                    label: 'Time',
                    value: _filters.timeFilter ?? 'Any Time',
                    options: [
                      'Any Time',
                      'Today',
                      'This Week',
                      'This Month',
                      'Older',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(timeFilter: value);
                      });
                    },
                  ),
                  SizedBox(height: DT.s.md),

                  // Distance Filter
                  _buildDropdownFilter(
                    label: 'Distance',
                    value: _filters.distanceFilter ?? 'Any Distance',
                    options: [
                      'Any Distance',
                      'Within 1 mi',
                      'Within 5 mi',
                      'Within 10 mi',
                      'Within 25 mi',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(distanceFilter: value);
                      });
                    },
                  ),
                  SizedBox(height: DT.s.md),

                  // Category Filter
                  _buildApiDropdownFilter(
                    label: 'Category',
                    value: _filters.categoryFilter ?? 'All',
                    provider: categoriesProvider,
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(categoryFilter: value);
                      });
                    },
                  ),
                  SizedBox(height: DT.s.md),

                  // Color Filter
                  _buildApiDropdownFilter(
                    label: 'Color',
                    value: _filters.colorFilter ?? 'All',
                    provider: colorsProvider,
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(colorFilter: value);
                      });
                    },
                  ),
                  SizedBox(height: DT.s.md),

                  // Location Filter
                  _buildLocationFilter(),
                  SizedBox(height: DT.s.xl),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(DT.s.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _clearFilters();
                        widget.onClear?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: DT.c.brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DT.r.md),
                        ),
                        padding: EdgeInsets.symmetric(vertical: DT.s.md),
                      ),
                      child: Text(
                        'Clear',
                        style: DT.t.labelLarge.copyWith(color: DT.c.brand),
                      ),
                    ),
                  ),
                  SizedBox(width: DT.s.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onApply?.call(_filters);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DT.c.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DT.r.md),
                        ),
                        padding: EdgeInsets.symmetric(vertical: DT.s.md),
                      ),
                      child: Text(
                        'Apply',
                        style: DT.t.labelLarge.copyWith(
                          color: DT.c.textOnBrand,
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

  Widget _buildToggleFilter() => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
    ),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _filters = _filters.copyWith(itemType: ItemType.lost);
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: DT.s.sm),
              decoration: BoxDecoration(
                color: _filters.itemType == ItemType.lost
                    ? DT.c.card
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DT.r.sm),
                boxShadow: _filters.itemType == ItemType.lost ? DT.e.xs : null,
              ),
              child: Text(
                'Lost',
                textAlign: TextAlign.center,
                style: DT.t.labelLarge.copyWith(
                  color: _filters.itemType == ItemType.lost
                      ? DT.c.text
                      : DT.c.brand,
                  fontWeight: _filters.itemType == ItemType.lost
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _filters = _filters.copyWith(itemType: ItemType.found);
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: DT.s.sm),
              decoration: BoxDecoration(
                color: _filters.itemType == ItemType.found
                    ? DT.c.card
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DT.r.sm),
                boxShadow: _filters.itemType == ItemType.found ? DT.e.xs : null,
              ),
              child: Text(
                'Found',
                textAlign: TextAlign.center,
                style: DT.t.labelLarge.copyWith(
                  color: _filters.itemType == ItemType.found
                      ? DT.c.text
                      : DT.c.brand,
                  fontWeight: _filters.itemType == ItemType.found
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String) onChanged,
  }) => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: DT.t.labelLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        DropdownButton<String>(
          value: value,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          underline: const SizedBox(),
          items: options
              .map<DropdownMenuItem<String>>(
                (String option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _buildApiDropdownFilter({
    required String label,
    required String value,
    required FutureProvider<List<dynamic>> provider,
    required void Function(String) onChanged,
  }) => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: DT.t.labelLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Consumer(
          builder: (context, ref, child) {
            final asyncData = ref.watch(provider);
            return asyncData.when(
              data: (items) {
                final options = [
                  'All',
                  ...items.map((item) => item.name.toString()),
                ];
                return DropdownButton<String>(
                  value: value,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                  underline: const SizedBox(),
                  items: options
                      .map<DropdownMenuItem<String>>(
                        (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: DT.t.bodyMedium.copyWith(
                              color: DT.c.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => Text(
                'Loading...',
                style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              ),
              error: (error, stack) => Text(
                'Error',
                style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _buildLocationFilter() => Container(
    padding: EdgeInsets.all(DT.s.sm),
    decoration: BoxDecoration(
      color: DT.c.surfaceVariant,
      borderRadius: BorderRadius.circular(DT.r.md),
    ),
    child: Row(
      children: [
        Text(
          'Location',
          style: DT.t.labelLarge.copyWith(
            color: DT.c.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Expanded(
          child: TextField(
            controller: TextEditingController(
              text: _filters.locationFilter ?? '',
            ),
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(locationFilter: value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter Location',
              hintStyle: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
          ),
        ),
      ],
    ),
  );

  void _clearFilters() {
    setState(() {
      _filters = FilterOptions();
    });
  }
}
