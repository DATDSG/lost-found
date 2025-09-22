import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Public filter state to reuse across screens.
class FilterState {
  String status;      // 'Lost' | 'Found'
  String time;        // 'Any Time' | …
  String distance;    // 'Any Distance' | …
  String category;    // 'All' | …
  String location;    // free text

  FilterState({
    this.status = 'Lost',
    this.time = 'Any Time',
    this.distance = 'Any Distance',
    this.category = 'All',
    this.location = '',
  });

  FilterState copy() => FilterState(
        status: status,
        time: time,
        distance: distance,
        category: category,
        location: location,
      );

  bool get isDefault =>
      status == 'Lost' &&
      time == 'Any Time' &&
      distance == 'Any Distance' &&
      category == 'All' &&
      location.isEmpty;

  void clear() {
    status = 'Lost';
    time = 'Any Time';
    distance = 'Any Distance';
    category = 'All';
    location = '';
  }

  @override
  String toString() =>
      'status=$status, time=$time, distance=$distance, category=$category, location="$location"';
}

/// Opens the filter bottom sheet and returns the selected [FilterState] on Apply.
/// Returns null if cancelled/dismissed.
Future<FilterState?> showFilterSheet(
  BuildContext context, {
  required FilterState initial,
}) {
  return showModalBottomSheet<FilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _FilterSheet(initial: initial),
  );
}

class _FilterSheet extends StatefulWidget {
  final FilterState initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FilterState f;
  late final TextEditingController _locCtrl;

  static const _timeOptions = <String>[
    'Any Time',
    'Last 24 hours',
    'Last 3 days',
    'Last 7 days',
    'Last 30 days',
  ];

  static const _distanceOptions = <String>[
    'Any Distance',
    '< 0.5 mi',
    '< 1 mi',
    '< 2 mi',
    '< 5 mi',
    '< 10 mi',
  ];

  static const _categoryOptions = <String>[
    'All',
    'Phone',
    'Wallet',
    'Bag',
    'Keys',
    'Laptop',
    'Jewelry',
  ];

  @override
  void initState() {
    super.initState();
    f = widget.initial.copy();
    _locCtrl = TextEditingController(text: f.location);
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    super.dispose();
  }

  // ---------- UI helpers -----------

  Widget _row({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
        decoration: BoxDecoration(
          color: DT.c.blueTint.withOpacity(0.35), // pale blue like the mock
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(label, style: DT.t.title.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(value, style: DT.t.body),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    String title,
    List<String> options,
    ValueChanged<String> onSelected,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.sm),
                child: Row(children: [Text(title, style: DT.t.h1)]),
              ),
              ...options.map((o) => ListTile(
                    title: Text(o),
                    trailing: (title == 'Time' && o == f.time) ||
                            (title == 'Distance' && o == f.distance) ||
                            (title == 'Category' && o == f.category)
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(ctx, o),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    onSelected(selected);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.lg + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Filter', style: DT.t.h1.copyWith(fontSize: 24)),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          SizedBox(height: DT.s.md),

          // Segmented: Lost / Found
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DT.c.blueTint.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentChip(
                    label: 'Lost',
                    selected: f.status == 'Lost',
                    onTap: () => setState(() => f.status = 'Lost'),
                  ),
                ),
                Expanded(
                  child: _SegmentChip(
                    label: 'Found',
                    selected: f.status == 'Found',
                    onTap: () => setState(() => f.status = 'Found'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DT.s.lg),

          _row(
            label: 'Time',
            value: f.time,
            onTap: () => _pick('Time', _timeOptions, (v) => f.time = v),
          ),
          SizedBox(height: DT.s.md),

          _row(
            label: 'Distance',
            value: f.distance,
            onTap: () =>
                _pick('Distance', _distanceOptions, (v) => f.distance = v),
          ),
          SizedBox(height: DT.s.md),

          _row(
            label: 'Category',
            value: f.category,
            onTap: () =>
                _pick('Category', _categoryOptions, (v) => f.category = v),
          ),
          SizedBox(height: DT.s.md),

          // Location input
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
            decoration: BoxDecoration(
              color: DT.c.blueTint.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text('Location',
                    style: DT.t.title.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _locCtrl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'Enter Location',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => f.location = v,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: DT.s.xl),

          // Clear / Apply
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      f.clear();
                      _locCtrl.text = '';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: BorderSide(color: DT.c.brand, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: DT.c.brand,
                    textStyle: DT.t.title.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Clear'),
                ),
              ),
              SizedBox(width: DT.s.lg),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, f),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: DT.c.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: DT.t.title.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: DT.c.shadow10,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: DT.t.title.copyWith(
              color: selected ? DT.c.text : DT.c.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
