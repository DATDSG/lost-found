import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import 'filter_sheet.dart';

/// Lightweight, fast search with a light-blue background and a stateful
/// Filter button that changes appearance when filters are applied.
class SearchBarWithFilter extends StatefulWidget {
  final void Function(String query, FilterState filters) onSubmit;
  final FilterState? initialFilters;
  final String hint;

  const SearchBarWithFilter({
    super.key,
    required this.onSubmit,
    this.initialFilters,
    this.hint = 'Enter item name, category, Locat..',
  });

  @override
  State<SearchBarWithFilter> createState() => _SearchBarWithFilterState();
}

class _SearchBarWithFilterState extends State<SearchBarWithFilter> {
  late final TextEditingController _controller;
  late FilterState _filters;
  Timer? _debounce;

  bool get _active => !_filters.isDefault;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _filters = widget.initialFilters?.copy() ?? FilterState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _submitNow() => widget.onSubmit(_controller.text.trim(), _filters);

  Future<void> _openFilter() async {
    final updated = await showFilterSheet(context, initial: _filters);
    if (!mounted || updated == null) return;
    setState(() => _filters = updated);
    _submitNow();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // SEARCH FIELD — light blue background
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: DT.c.blueTint.withOpacity(1), // lighter than before
              borderRadius: BorderRadius.circular(DT.r.xl),
            ),
            padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 22, color: Colors.black87),
                SizedBox(width: DT.s.md),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                    ),
                    onSubmitted: (_) => _submitNow(),
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 220), _submitNow);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: DT.s.md),

        // FILTER BUTTON — toggles style when filters active
        IconButton(
          onPressed: _openFilter,
          tooltip: 'Filter',
          icon: Icon(_active ? Icons.tune : Icons.tune_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: _active ? DT.c.brand : Colors.white,
            foregroundColor: _active ? Colors.white : DT.c.brand,
            side: _active ? BorderSide.none : BorderSide(color: DT.c.brand, width: 2),
          ),
        ),
      ],
    );
  }
}
