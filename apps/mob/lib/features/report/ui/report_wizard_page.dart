import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/design_tokens.dart';

enum ReportType { found, lost }

class ReportWizardPage extends StatefulWidget {
  final ReportType type;
  const ReportWizardPage({super.key, required this.type});

  @override
  State<ReportWizardPage> createState() => _ReportWizardPageState();
}

class _ReportWizardPageState extends State<ReportWizardPage> {
  int _step = 0;

  final _category = ValueNotifier<String?>(null);
  final _brandCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _marksCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();

  final _images = <File>[];
  final _picker = ImagePicker();

  LatLng? _pin = const LatLng(6.933, 79.85);
  double _fuzz = 200; // meters
  DateTime? _when;
  bool _confirm = false;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _colorCtrl.dispose();
    _marksCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  String get _title =>
      widget.type == ReportType.found ? 'Report Found Item' : 'Report Lost Item';

  String get _whereLabel => widget.type == ReportType.found
      ? 'Where did you Found it?'
      : 'Where did you lose it?';

  String get _whenLabel => widget.type == ReportType.found
      ? 'When  did you Found it ?'
      : 'When  did you lost it ?';

  Future<void> _pickPhoto() async {
    if (_images.length >= 4) return;
    final XFile? x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    if (x != null) setState(() => _images.add(File(x.path)));
  }

  Future<void> _useCurrent() async {
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _pin = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );
    if (!mounted) return;
    if (d == null) return;

    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted) return;
    if (t == null) return;

    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _next() {
    if (_step < 3) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _submit() {
    if (!_confirm) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const _ReportSuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        centerTitle: false,
        title: Text(_title, style: DT.t.h1.copyWith(fontSize: 20)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.md, DT.s.lg, DT.s.xl),
        children: [
          _Dots(step: _step),
          SizedBox(height: DT.s.lg),

          if (_step == 0)
            _DetailsStep(
              type: widget.type,
              category: _category,
              brandCtrl: _brandCtrl,
              colorCtrl: _colorCtrl,
              marksCtrl: _marksCtrl,
              rewardCtrl: _rewardCtrl,
            ),

          if (_step == 1)
            _PhotosStep(
              files: _images,
              onAdd: _pickPhoto,
              onRemove: (i) => setState(() => _images.removeAt(i)),
            ),

          if (_step == 2)
            _WhereWhenStep(
              labelWhere: _whereLabel,
              labelWhen: _whenLabel, // used now
              pin: _pin,
              fuzz: _fuzz,
              onFuzz: (v) => setState(() => _fuzz = v),
              onUseCurrent: _useCurrent,
              when: _when,
              onPickWhen: _pickWhen,
            ),

          if (_step == 3)
            _ReviewStep(
              type: widget.type,
              title: _brandCtrl.text.isEmpty ? 'Item' : _brandCtrl.text,
              location: 'near selected location',
              image: _images.isNotEmpty ? _images.first : null,
              confirm: _confirm,
              onToggle: (v) => setState(() => _confirm = v),
            ),

          SizedBox(height: DT.s.lg),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: DT.c.brand),
                      foregroundColor: DT.c.brand,
                    ),
                  ),
                ),
              if (_step > 0) SizedBox(width: DT.s.md),
              Expanded(
                child: FilledButton(
                  onPressed: _step == 3 ? _submit : _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: DT.c.brand,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_step == 3 ? 'Submit Report' : 'Next',
                      style: DT.t.title.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------- STEP WIDGETS ---------- */

class _DetailsStep extends StatelessWidget {
  final ReportType type;
  final ValueNotifier<String?> category;
  final TextEditingController brandCtrl, colorCtrl, marksCtrl, rewardCtrl;

  const _DetailsStep({
    required this.type,
    required this.category,
    required this.brandCtrl,
    required this.colorCtrl,
    required this.marksCtrl,
    required this.rewardCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cats = const [
      'Phone', 'Wallet', 'Bag', 'Keys', 'Laptop', 'Watch', 'Jewelry'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add photos  of the item', style: DT.t.h1.copyWith(fontSize: 22)),
        SizedBox(height: DT.s.lg),
        Text('Category', style: DT.t.title),
        SizedBox(height: DT.s.xs),
        ValueListenableBuilder<String?>(
          valueListenable: category,
          builder: (_, v, __) {
            return InkWell(
              onTap: () async {
                final res = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => ListView(
                    children: [
                      for (final c in cats)
                        ListTile(
                          title: Text(c),
                          onTap: () => Navigator.pop(context, c),
                        )
                    ],
                  ),
                );
                if (res != null) category.value = res;
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: DT.c.blueTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(v ?? 'Select Item Category')),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: DT.s.lg),

        Text('Brand / Model', style: DT.t.title),
        SizedBox(height: DT.s.xs),
        _input(brandCtrl, hint: 'eg - I Phone 15 pro'),

        SizedBox(height: DT.s.lg),
        Text('Color', style: DT.t.title),
        SizedBox(height: DT.s.xs),
        _input(colorCtrl, hint: 'eg - Red'),
        SizedBox(height: DT.s.md),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final c in [
              Colors.black,
              Colors.white,
              Colors.red,
              Colors.greenAccent.shade400,
              Colors.blue.shade800,
              Colors.yellow,
              Colors.purpleAccent,
              Colors.cyanAccent.shade400,
            ])
              _ColorDot(
                color: c,
                onTap: () => colorCtrl.text =
                    '#${c.value.toRadixString(16).padLeft(8, '0')}',
              ),
          ],
        ),

        SizedBox(height: DT.s.lg),
        Text('Unique marks', style: DT.t.title),
        SizedBox(height: DT.s.xs),
        _input(marksCtrl,
            hint:
                'Any distinguishing features? (e.g., scratches, stickers)',
            minLines: 2,
            maxLines: 4),

        if (type == ReportType.lost) ...[
          SizedBox(height: DT.s.lg),
          Text('Reward (Optional)', style: DT.t.title),
          SizedBox(height: DT.s.xs),
          _input(rewardCtrl, hint: 'Amount',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
        ],
      ],
    );
  }

  Widget _input(TextEditingController c,
      {String? hint,
      int minLines = 1,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: DT.c.blueTint,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DT.c.blueTint)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DT.c.brand, width: 1.6)),
      ),
    );
  }
}

class _PhotosStep extends StatelessWidget {
  final List<File> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotosStep(
      {required this.files, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < 4; i++) {
      if (i < files.length) {
        tiles.add(Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(files[i],
                  height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onRemove(i),
                ),
              ),
            ),
          ],
        ));
      } else {
        tiles.add(OutlinedButton(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(220),
            side: BorderSide(
                color: DT.c.brand.withValues(alpha: .5), width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Icon(Icons.camera_alt_outlined, size: 36),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add photos  of the item', style: DT.t.h1.copyWith(fontSize: 22)),
        SizedBox(height: DT.s.md),
        const _Rule(text: 'Add up to 4 photos.'),
        const _Rule(text: 'Should be clear and focused on the item.'),
        const _Rule(text: 'Crop the image to focus on the item.'),
        const _Rule(
            text: 'Avoid including personal information.', bad: true),
        SizedBox(height: DT.s.md),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: DT.s.md,
          crossAxisSpacing: DT.s.md,
          children: tiles,
        ),
      ],
    );
  }
}

class _WhereWhenStep extends StatelessWidget {
  final String labelWhere;
  final String labelWhen;
  final LatLng? pin;
  final double fuzz;
  final ValueChanged<double> onFuzz;
  final VoidCallback onUseCurrent;
  final DateTime? when;
  final VoidCallback onPickWhen;

  const _WhereWhenStep({
    required this.labelWhere,
    required this.labelWhen,
    required this.pin,
    required this.fuzz,
    required this.onFuzz,
    required this.onUseCurrent,
    required this.when,
    required this.onPickWhen,
  });

  @override
  Widget build(BuildContext context) {
    final p = pin ?? const LatLng(6.933, 79.85);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelWhere, style: DT.t.h1.copyWith(fontSize: 22)),
        SizedBox(height: DT.s.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: p,
                initialZoom: 14,
                interactionOptions:
                    const InteractionOptions(flags: ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: p,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin,
                          size: 40, color: Colors.red),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: DT.s.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onUseCurrent,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Use Current'),
            style: FilledButton.styleFrom(
              backgroundColor: DT.c.brand,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        SizedBox(height: DT.s.lg),

        Text('Location privacy', style: DT.t.title.copyWith(fontSize: 18)),
        SizedBox(height: DT.s.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fuzzing', style: DT.t.body),
            Text('${fuzz.round()}m', style: DT.t.body),
          ],
        ),
        Slider(min: 50, max: 500, value: fuzz, onChanged: onFuzz),
        Text('Public sees fuzzy location until chat is approved',
            style: DT.t.body.copyWith(color: DT.c.brand)),

        SizedBox(height: DT.s.lg),
        Text(labelWhen, style: DT.t.title.copyWith(fontSize: 18)),
        SizedBox(height: DT.s.sm),
        InkWell(
          onTap: onPickWhen,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: DT.c.blueTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    when == null
                        ? 'Select date and time'
                        : '${when!.toLocal()}',
                  ),
                ),
                const Icon(Icons.event_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final ReportType type;
  final String title;
  final String location;
  final File? image;
  final bool confirm;
  final ValueChanged<bool> onToggle;

  const _ReviewStep({
    required this.type,
    required this.title,
    required this.location,
    required this.image,
    required this.confirm,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final label = type == ReportType.found ? 'Found Item' : 'Lost Item';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Submit', style: DT.t.h1.copyWith(fontSize: 22)),
        SizedBox(height: DT.s.lg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: DT.t.body.copyWith(color: DT.c.brand)),
                  SizedBox(height: DT.s.xs),
                  Text(title, style: DT.t.title.copyWith(fontSize: 20)),
                  SizedBox(height: DT.s.xs),
                  Text(location, style: DT.t.body.copyWith(color: DT.c.brand)),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 96,
                width: 120,
                color: DT.c.blueTint,
                child: image == null
                    ? const Icon(Icons.image, size: 36)
                    : Image.file(image!, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        SizedBox(height: DT.s.lg),
        Row(
          children: [
            Checkbox(value: confirm, onChanged: (v) => onToggle(v ?? false)),
            Expanded(
              child: Text(
                'I confirm that i have the right to share the photos and text in this report',
                style: DT.t.body,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int step;
  const _Dots({required this.step});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i <= step ? DT.c.brand : DT.c.blueTint,
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;
  final bool bad;
  const _Rule({required this.text, this.bad = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DT.s.sm),
      child: Row(
        children: [
          Icon(bad ? Icons.close_rounded : Icons.check_circle_rounded,
              color: bad ? Colors.red : Colors.green, size: 22),
          SizedBox(width: DT.s.md),
          Expanded(child: Text(text, style: DT.t.body)),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _ColorDot({required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12, width: 2),
        ),
      ),
    );
  }
}

class _ReportSuccessPage extends StatelessWidget {
  const _ReportSuccessPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: Text('Success', style: DT.t.h1.copyWith(fontSize: 20)),
      ),
      body: Padding(
        padding: EdgeInsets.all(DT.s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              'Report Submitted\nSuccessfully!',
              textAlign: TextAlign.center,
              style: DT.t.h1.copyWith(fontSize: 28),
            ),
            SizedBox(height: DT.s.md),
            Text(
              "Your report has been successfully submitted.\nWe'll notify you if any matches are found.",
              textAlign: TextAlign.center,
              style: DT.t.body.copyWith(color: DT.c.textMuted),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: DT.c.brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Share Report',
                  style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: DT.s.md),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: DT.c.brand, width: 1.6),
                foregroundColor: DT.c.brand,
              ),
              child: const Text('View Matches'),
            ),
          ],
        ),
      ),
    );
  }
}
