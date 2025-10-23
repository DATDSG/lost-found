import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';

/// Enhanced search bar with modern design and animations
class EnhancedSearchBar extends StatefulWidget {
  /// Creates a new [EnhancedSearchBar] instance
  const EnhancedSearchBar({
    super.key,
    this.onSearch,
    this.onFilterTap,
    this.placeholder = 'Enter item name, category, Locat..',
    this.isFilterActive = false,
  });

  /// Callback when search text changes
  final void Function(String)? onSearch;

  /// Callback when filter button is tapped
  final VoidCallback? onFilterTap;

  /// Placeholder text for the search field
  final String placeholder;

  /// Whether filters are currently active
  final bool isFilterActive;

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _focusController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.02).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scaleAnimation,
    builder: (context, child) => Transform.scale(
      scale: _scaleAnimation.value,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: DT.s.md),
        child: Row(
          children: [
            // Search input field
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: DT.c.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DT.r.xl),
                  border: Border.all(
                    color: _isFocused
                        ? DT.c.brand
                        : DT.c.brand.withValues(alpha: 0.3),
                    width: _isFocused ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearch,
                  onTap: () {
                    setState(() => _isFocused = true);
                    _focusController.forward();
                    HapticFeedback.lightImpact();
                  },
                  onSubmitted: (_) {
                    setState(() => _isFocused = false);
                    _focusController.reverse();
                  },
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
                    prefixIcon: Icon(Icons.search, color: DT.c.brand, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: DT.s.md,
                      vertical: DT.s.sm,
                    ),
                  ),
                  style: DT.t.bodyMedium.copyWith(color: DT.c.text),
                ),
              ),
            ),

            SizedBox(width: DT.s.sm),

            // Filter button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onFilterTap?.call();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isFilterActive
                      ? DT.c.brand
                      : DT.c.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DT.r.xl),
                  border: Border.all(
                    color: widget.isFilterActive
                        ? DT.c.brand
                        : DT.c.brand.withValues(alpha: 0.3),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.tune,
                        color: widget.isFilterActive
                            ? DT.c.textOnBrand
                            : DT.c.brand,
                        size: 20,
                      ),
                    ),
                    if (widget.isFilterActive)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: DT.c.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
