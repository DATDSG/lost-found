import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/design_tokens.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _page = 0;
  String _selectedLang = 'en';
  bool _depsInitialized = false;
  final _pc = PageController();

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      final code = EasyLocalization.of(context)?.locale.languageCode ??
          Localizations.localeOf(context).languageCode;
      _selectedLang = code;
      _depsInitialized = true;
    }
  }

  Future<void> _setLang(String code) async {
    await context.setLocale(Locale(code));
    if (!mounted) return;
    setState(() => _selectedLang = code);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(tr('language_changed', args: [code.toUpperCase()])),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: DT.c.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(DT.s.lg, DT.s.lg, DT.s.lg, DT.s.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration (PageView + dots)
              SizedBox(
                height: w * 0.9,
                child: Stack(
                  children: [
                    PageView(
                      controller: _pc,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: const [
                        _HeroImage('assets/images/landing_illustration.png'),
                        _HeroImage('assets/images/landing_illustration2.png'),
                        _HeroImage('assets/images/landing_illustration3.png'),
                      ],
                    ),
                    Positioned(
                      bottom: 18,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: active ? 18 : 8,
                            decoration: BoxDecoration(
                              color: active ? DT.c.brand : DT.c.blueTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: DT.s.xl),

              Text("Find what’s lost, near you",
                  style: DT.t.h1.copyWith(fontSize: 34)),
              SizedBox(height: DT.s.md),
              Text(
                "Lost something? Find it fast with our location-based search. "
                "We’ll show you items found nearby, making your search quick and easy.",
                style: DT.t.body.copyWith(
                  fontSize: 16,
                  height: 1.6,
                  color: DT.c.textMuted,
                ),
              ),
              SizedBox(height: DT.s.xl),

              // Language chips
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LangChip(
                    label: 'Sinhala',
                    selected: _selectedLang == 'si',
                    onTap: () => _setLang('si'),
                  ),
                  _LangChip(
                    label: 'Tamil',
                    selected: _selectedLang == 'ta',
                    onTap: () => _setLang('ta'),
                  ),
                  _LangChip(
                    label: 'English',
                    selected: _selectedLang == 'en',
                    onTap: () => _setLang('en'),
                  ),
                ],
              ),
              const Spacer(),

              _GradientButton(
                text: 'Start',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String asset;
  const _HeroImage(this.asset);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.network(
          'https://images.unsplash.com/photo-1512353250303-3cf587709c98?q=80&w=1200&auto=format&fit=crop',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? DT.c.blueTint : Colors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: DT.c.brand),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: DT.t.body.copyWith(
            fontWeight: FontWeight.w700,
            color: DT.c.text,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _GradientButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Ink(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5D79D3), Color(0xFF0F3E5A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Center(
          child: Text(
            text,
            style: DT.t.title.copyWith(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
