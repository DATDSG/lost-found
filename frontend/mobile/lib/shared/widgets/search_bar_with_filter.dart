import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import 'filter_sheet.dart';

/// Search bar + Filter button (light blue background, no suggestion list).
/// New extras:
///  - Clear text button when not empty
///  - Long-press filter icon to Reset filters
class SearchBarWithFilter extends StatefulWidget {
  final void Function(String query, FilterState filters) onSubmit;

  const SearchBarWithFilter({super.key, required this.onSubmit});

  @override
  State<SearchBarWithFilter> createState() => _SearchBarWithFilterState();
}

class _SearchBarWithFilterState extends State<SearchBarWithFilter> {
  final TextEditingController _controller = TextEditingController();
  final FilterState _filters = FilterState();
  bool _filterActive = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final updated = await showModalBottomSheet<FilterState>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterSheet(initial: _filters),
    );
    if (updated != null && mounted) {
      setState(() {
        _filters.lost = updated.lost;
        _filters.found = updated.found;
        _filters.category = updated.category;
        _filters.nearbyOnly = updated.nearbyOnly;
        _filterActive = _filters.category != 'All' || !_filters.lost || !_filters.found || _filters.nearbyOnly;
      });
      _submitNow();
    }
  }

  void _resetFilters() {
    setState(() {
      _filters
        ..lost = true
        ..found = true
        ..category = 'All'
        ..nearbyOnly = false;
      _filterActive = false;
    });
    _submitNow();
  }

  void _submitNow() => widget.onSubmit(_controller.text.trim(), _filters);

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Row(
      children: [
        // Search field
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: DT.c.blueTint, // light blue background per request
              borderRadius: BorderRadius.circular(DT.r.lg),
            ),
            padding: EdgeInsets.symmetric(horizontal: DT.s.md),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.black87),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Enter item name, category, location…',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitNow(),
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 250), _submitNow);
                      setState(() {}); // only to toggle clear button visibility
                    },
                  ),
                ),
                if (hasText)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                      _submitNow();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: DT.s.md),
        // Filter button (toggles icon style when active)
        GestureDetector(
          onLongPress: _resetFilters, // cool feature: long-press to reset
          child: IconButton.filledTonal(
            onPressed: _openFilterSheet,
            tooltip: _filterActive ? 'Edit filters' : 'Filter',
            icon: Icon(_filterActive ? Icons.tune_rounded : Icons.tune_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DT.c.brand,
              side: BorderSide(color: DT.c.brand, width: _filterActive ? 2 : 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(48, 48),
            ),
          ),
        ),
      ],
    );
  }
}
