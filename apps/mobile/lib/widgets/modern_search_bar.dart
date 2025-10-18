import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../models/search_models.dart';

/// Modern Search Bar with system UI integration
/// Blends seamlessly with the existing design system
class ModernSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(SearchFilters) onFiltersChanged;
  final SearchFilters currentFilters;
  final List<SearchSuggestion>? suggestions;
  final bool showSuggestions;
  final String hintText;
  final VoidCallback? onFilterTap;

  const ModernSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onFiltersChanged,
    required this.currentFilters,
    this.suggestions,
    this.showSuggestions = true,
    this.hintText = 'Search for lost or found items...',
    this.onFilterTap,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main search bar
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _isFocused ? Colors.white : DT.c.brandDeep,
                  borderRadius: BorderRadius.circular(DT.r.xl),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: DT.c.brand.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                  border: _isFocused
                      ? Border.all(color: DT.c.brand, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    // Search icon
                    Padding(
                      padding: EdgeInsets.only(left: DT.s.lg),
                      child: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: _isFocused ? DT.c.brand : Colors.black87,
                      ),
                    ),
                    SizedBox(width: DT.s.md),

                    // Search input
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        style: DT.t.body.copyWith(
                          color: _isFocused ? DT.c.text : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: DT.c.brand,
                        onChanged: (value) {
                          widget.onSearch(value);
                          setState(() {
                            _showSuggestions =
                                value.isNotEmpty &&
                                widget.suggestions != null &&
                                widget.showSuggestions;
                          });
                        },
                        onTap: () {
                          setState(() {
                            _isFocused = true;
                            _showSuggestions =
                                widget.controller.text.isNotEmpty &&
                                widget.suggestions != null &&
                                widget.showSuggestions;
                          });
                          _animationController.forward();
                        },
                        onSubmitted: (value) {
                          widget.onSearch(value);
                          setState(() {
                            _isFocused = false;
                            _showSuggestions = false;
                          });
                          _animationController.reverse();
                        },
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            color: _isFocused ? DT.c.textMuted : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Filter button
                    _buildFilterButton(),

                    // Clear button (when text is not empty)
                    if (widget.controller.text.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: DT.s.sm),
                        child: GestureDetector(
                          onTap: () {
                            widget.controller.clear();
                            widget.onSearch('');
                            setState(() {
                              _showSuggestions = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: DT.c.textMuted.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: DT.c.textMuted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Active filters chips
        if (_hasActiveFilters()) _buildActiveFilters(),

        // Search suggestions
        if (_showSuggestions && widget.suggestions != null) _buildSuggestions(),
      ],
    );
  }

  Widget _buildFilterButton() {
    final hasActiveFilters = _hasActiveFilters();

    return Padding(
      padding: EdgeInsets.only(right: DT.s.md),
      child: GestureDetector(
        onTap: widget.onFilterTap,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: hasActiveFilters ? DT.c.brand : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters ? DT.c.brand : DT.c.border,
              width: hasActiveFilters ? 0 : 1,
            ),
            boxShadow: hasActiveFilters
                ? [
                    BoxShadow(
                      color: DT.c.brand.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: hasActiveFilters ? Colors.white : DT.c.textMuted,
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: EdgeInsets.only(top: DT.s.md),
      child: Wrap(
        spacing: DT.s.sm,
        runSpacing: DT.s.sm,
        children: [
          if (widget.currentFilters.type != null)
            _buildFilterChip(
              'Type: ${widget.currentFilters.type!.toUpperCase()}',
              () => widget.onFiltersChanged(
                widget.currentFilters.copyWith(type: null),
              ),
            ),
          if (widget.currentFilters.category != null)
            _buildFilterChip(
              'Category: ${widget.currentFilters.category!.toUpperCase()}',
              () => widget.onFiltersChanged(
                widget.currentFilters.copyWith(category: null),
              ),
            ),
          if (widget.currentFilters.city != null &&
              widget.currentFilters.city!.isNotEmpty)
            _buildFilterChip(
              'City: ${widget.currentFilters.city!}',
              () => widget.onFiltersChanged(
                widget.currentFilters.copyWith(city: null),
              ),
            ),
          if (widget.currentFilters.colors != null &&
              widget.currentFilters.colors!.isNotEmpty)
            _buildFilterChip(
              'Colors: ${widget.currentFilters.colors!.join(', ')}',
              () => widget.onFiltersChanged(
                widget.currentFilters.copyWith(colors: null),
              ),
            ),
          if (widget.currentFilters.rewardOffered != null)
            _buildFilterChip(
              'Reward: ${widget.currentFilters.rewardOffered! ? 'Yes' : 'No'}',
              () => widget.onFiltersChanged(
                widget.currentFilters.copyWith(rewardOffered: null),
              ),
            ),
          if (widget.currentFilters.maxDistance != null)
            _buildFilterChip(
              'Distance: ${widget.currentFilters.maxDistance!.toStringAsFixed(1)}km',
              () => widget.onFiltersChanged(
                widget.currentFilters.copyWith(maxDistance: null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
      decoration: BoxDecoration(
        color: DT.c.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DT.c.brand.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: DT.t.label.copyWith(
              color: DT.c.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: DT.s.xs),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: DT.c.brand),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: EdgeInsets.only(top: DT.s.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DT.r.lg),
        boxShadow: [
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: widget.suggestions!.take(5).map((suggestion) {
          return ListTile(
            leading: Icon(
              _getSuggestionIcon(suggestion.type),
              size: 18,
              color: DT.c.textMuted,
            ),
            title: Text(
              suggestion.text,
              style: DT.t.body.copyWith(
                color: DT.c.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: suggestion.category != null
                ? Text(suggestion.category!, style: DT.t.bodySmall)
                : null,
            trailing: suggestion.count != null
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DT.s.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DT.c.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      suggestion.count.toString(),
                      style: DT.t.label.copyWith(
                        color: DT.c.brand,
                        fontSize: 10,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              widget.controller.text = suggestion.text;
              widget.onSearch(suggestion.text);
              setState(() {
                _showSuggestions = false;
                _isFocused = false;
              });
              _animationController.reverse();
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'recent':
        return Icons.history_rounded;
      case 'popular':
        return Icons.trending_up_rounded;
      case 'category':
        return Icons.category_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  bool _hasActiveFilters() {
    return widget.currentFilters.type != null ||
        widget.currentFilters.category != null ||
        (widget.currentFilters.colors != null &&
            widget.currentFilters.colors!.isNotEmpty) ||
        widget.currentFilters.rewardOffered != null ||
        widget.currentFilters.city != null ||
        widget.currentFilters.maxDistance != null ||
        widget.currentFilters.sortBy != null;
  }
}
