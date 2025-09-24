import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/auth/auth_service.dart';
import '../../shell/ui/app_shell.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dial = TextEditingController(text: '+94');
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide1 = true, _hide2 = true, _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _dial.dispose();
    _phone.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Passwords do not match.')),
      );
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.lightImpact();
    final ok = await AuthService.I.signUpWithPassword(
      fullName: _name.text.trim(),
      phone: '${_dial.text.trim()} ${_phone.text.trim()}',
      password: _pass.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Could not create account.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/App Logo.png',
      height: 86,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.location_searching, size: 86),
    );

    return Scaffold(
      backgroundColor: DT.c.surface,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: DT.scroll,
              padding: EdgeInsets.fromLTRB(DT.s.lg, 28, DT.s.lg, DT.s.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: logo),
                  SizedBox(height: DT.s.xl),
                  Text('Create New Account', style: DT.t.h1.copyWith(fontSize: 30)),
                  SizedBox(height: DT.s.xl),

                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('Full Name'),
                          validator: (v) =>
                              (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
                        ),
                        SizedBox(height: DT.s.lg),

                        Row(
                          children: [
                            SizedBox(
                              width: 92,
                              child: TextFormField(
                                controller: _dial,
                                decoration: _decoration('+94'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                decoration: _decoration('XXX XX XX'),
                                validator: (v) => (v == null || v.trim().length < 6)
                                    ? 'Enter a valid number'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: DT.s.lg),

                        TextFormField(
                          controller: _pass,
                          obscureText: _hide1,
                          decoration: _decoration('Must include 8 characters').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_hide1 ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hide1 = !_hide1),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'At least 8 characters'
                              : null,
                        ),
                        SizedBox(height: 8),
                        _StrengthBar(value: _strengthOf(_pass.text)),
                        SizedBox(height: DT.s.lg),

                        TextFormField(
                          controller: _confirm,
                          obscureText: _hide2,
                          decoration: _decoration('Enter Password to Confirm').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_hide2 ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hide2 = !_hide2),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please retype password'
                              : null,
                        ),
                        SizedBox(height: DT.s.xl),

                        _PrimaryButton(text: 'Sign Up', onPressed: _submit),
                        SizedBox(height: DT.s.lg),
                        _OrDivider(),
                        SizedBox(height: DT.s.lg),
                        _GoogleButton(onTap: () async {
                          setState(() => _loading = true);
                          final ok = await AuthService.I.signInWithGoogle();
                          if (!mounted) return;
                          setState(() => _loading = false);
                          if (ok) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AppShell()),
                              (_) => false,
                            );
                          }
                        }),
                        SizedBox(height: DT.s.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Have an account?  '),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text('Log In',
                                  style: TextStyle(color: DT.c.brand, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loading) const _LoadingBackdrop(),
          ],
        ),
      ),
    );
  }

  double _strengthOf(String pwd) {
    if (pwd.isEmpty) return 0;
    double s = 0;
    if (pwd.length >= 8) s += .34;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) s += .22;
    if (RegExp(r'[0-9]').hasMatch(pwd)) s += .22;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) s += .22;
    return s.clamp(0, 1);
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: DT.c.blueTint.withValues(alpha: .35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: DT.c.blueTint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: DT.c.brand, width: 1.5),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final double value;
  const _StrengthBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final c = value < .34
        ? DT.c.danger
        : (value < .68 ? Colors.orange : DT.c.success);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: DT.c.blueTint,
        valueColor: AlwaysStoppedAnimation(c),
      ),
    );
  }
}

// Reuse from login:
class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Ink(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5D79D3), Color(0xFF0F3E5A)],
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Center(
          child: Text(text, style: DT.t.title.copyWith(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: DT.c.blueTint)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('Or', style: DT.t.body.copyWith(color: DT.c.textMuted)),
      ),
      Expanded(child: Divider(color: DT.c.blueTint)),
    ]);
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Image.asset(
        'assets/images/google.png',
        height: 20,
        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: DT.t.title,
        side: BorderSide(color: DT.c.blueTint),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _LoadingBackdrop extends StatelessWidget {
  const _LoadingBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: .15),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
