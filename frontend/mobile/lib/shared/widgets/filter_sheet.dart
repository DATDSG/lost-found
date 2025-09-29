import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ---------- Model ----------
class FilterState {
  bool lost;
  bool found;
  String time;
  String distance;
  String category;
  String location;
  bool nearbyOnly;

  FilterState({
    this.lost = true,
    this.found = false,
    this.time = 'Any Time',
    this.distance = 'Any Distance',
    this.category = 'All',
    this.location = '',
    this.nearbyOnly = false,
  });

  FilterState copy() => FilterState(
        lost: lost,
        found: found,
        time: time,
        distance: distance,
        category: category,
        location: location,
        nearbyOnly: nearbyOnly,
      );

  void reset() {
    lost = true; found = false;
    time = 'Any Time';
    distance = 'Any Distance';
    category = 'All';
    location = '';
    nearbyOnly = false;
  }

  bool get isActive =>
      !lost || found || time != 'Any Time' || distance != 'Any Distance' ||
      category != 'All' || location.trim().isNotEmpty || nearbyOnly;
}

/// ---------- Sheet ----------
class FilterSheet extends StatefulWidget {
  final FilterState initial;
  const FilterSheet({super.key, required this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterState f;

  static const _timeOptions = <String>[
    'Any Time','Last 24 hours','Last 3 days','Last week','Last month'
  ];
  static const _distanceOptions = <String>[
    'Any Distance','1 km','5 km','10 km','25 km','50 km'
  ];
  static const _categoryOptions = <String>[
    'All','Phone','Wallet','Bag','Keys','Laptop','Other'
  ];

  @override
  void initState() {
    super.initState();
    f = widget.initial.copy();
    if (f.lost == f.found) { f.lost = true; f.found = false; } // one active
  }

  Future<void> _pick(String title, List<String> options, ValueChanged<String> onSelected) async {
    final v = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OptionPicker(title: title, options: options, initial: options.contains(title) ? title : null),
    );
    if (v != null) onSelected(v);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: DT.s.lg, right: DT.s.lg, top: DT.s.lg, bottom: bottom + DT.s.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(child: Text('Filter', style: DT.t.h1.copyWith(fontSize: 28))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            SizedBox(height: DT.s.lg),

            // Segmented Lost | Found
            Container(
              decoration: BoxDecoration(color: DT.c.blueTint, borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _SegmentChip(
                    label: 'Lost',
                    selected: f.lost && !f.found,
                    onTap: () => setState(() { f.lost = true; f.found = false; }),
                  ),
                  const SizedBox(width: 6),
                  _SegmentChip(
                    label: 'Found',
                    selected: f.found && !f.lost,
                    onTap: () => setState(() { f.lost = false; f.found = true; }),
                  ),
                ],
              ),
            ),
            SizedBox(height: DT.s.lg),

            _FieldTile(
              label: 'Time',
              value: f.time,
              onTap: () => _pick('Time', _timeOptions, (v) => setState(() => f.time = v)),
            ),
            SizedBox(height: DT.s.md),

            _FieldTile(
              label: 'Distance',
              value: f.distance,
              onTap: () => _pick('Distance', _distanceOptions, (v) => setState(() => f.distance = v)),
            ),
            SizedBox(height: DT.s.md),

            _FieldTile(
              label: 'Category',
              value: f.category,
              onTap: () => _pick('Category', _categoryOptions, (v) => setState(() => f.category = v)),
            ),
            SizedBox(height: DT.s.md),

            _LocationField(
              label: 'Location',
              hint: 'Enter Location',
              initial: f.location,
              onChanged: (v) => f.location = v,
            ),

            SizedBox(height: DT.s.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(f.reset),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: DT.c.brand, width: 1.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      foregroundColor: DT.c.brand,
                      textStyle: DT.t.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, f),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: DT.c.brand,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: DT.t.title.copyWith(fontWeight: FontWeight.w800),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Bits ----------

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: DT.t.title.copyWith(
                color: selected ? DT.c.text : DT.c.brand,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _FieldTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: DT.c.blueTint, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Text(label, style: DT.t.title),
            const Spacer(),
            Text(value, style: DT.t.title.copyWith(color: DT.c.text.withValues(alpha: .8), fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;
  const _LocationField({required this.label, required this.hint, required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: DT.c.blueTint, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text(label, style: DT.t.title),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: initial,
              onChanged: onChanged,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: DT.t.body.copyWith(color: DT.c.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Option list that never overflows (max ~60% screen height)
class _OptionPicker extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? initial;
  const _OptionPicker({required this.title, required this.options, this.initial});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Text(title, style: DT.t.h1),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final o = options[i];
                    final selected = o == initial;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(o, style: DT.t.title.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
                      trailing: selected ? Icon(Icons.check_circle_rounded, color: DT.c.brand) : null,
                      onTap: () => Navigator.pop(context, o),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
