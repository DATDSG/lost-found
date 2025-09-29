import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/auth/auth_service.dart';
import '../../shell/ui/app_shell.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    HapticFeedback.lightImpact();
    final ok = await AuthService.I.signInWithPassword(
      _username.text.trim(),
      _password.text.trim(),
      remember: _remember,
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
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Invalid credentials.'),
        ),
      );
    }
  }

  Future<void> _google() async {
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
                  Text('Sign in to your Account', style: DT.t.h1.copyWith(fontSize: 30)),
                  SizedBox(height: DT.s.sm),
                  Text(
                    'Enter your mobile number or username and password to log in',
                    style: DT.t.body.copyWith(color: DT.c.textMuted, fontSize: 16),
                  ),
                  SizedBox(height: DT.s.xl),

                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('Enter mobile number or user name'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'This field is required' : null,
                        ),
                        SizedBox(height: DT.s.lg),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _decoration('********')
                              .copyWith(suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              )),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                        ),
                        SizedBox(height: DT.s.lg),

                        Row(
                          children: [
                            Checkbox(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v ?? true),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text('Remember me'),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Password reset is not configured in demo.'),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password ?'),
                            ),
                          ],
                        ),
                        SizedBox(height: DT.s.lg),
                        _PrimaryButton(text: 'Sign In', onPressed: _submit),
                      ],
                    ),
                  ),

                  SizedBox(height: DT.s.xl),
                  _OrDivider(),
                  SizedBox(height: DT.s.lg),
                  _GoogleButton(onTap: _google),
                  SizedBox(height: DT.s.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account?  "),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        ),
                        child: Text('Sign Up', style: TextStyle(color: DT.c.brand, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_loading)
              const _LoadingBackdrop(),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: DT.c.blueTint.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: DT.c.blueTint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.24)),
      ),
    );
  }
}

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

class _LoadingBackdrop extends StatelessWidget {
  const _LoadingBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.15),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
