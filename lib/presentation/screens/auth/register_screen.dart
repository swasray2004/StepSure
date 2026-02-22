import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/design_systems.dart';
import 'package:gait_rehab/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: HeroCard(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Create Account', style: AppText.heroTitle),
                      const SizedBox(height: 6),
                      const Text('Step 1 of 2 — Account setup',
                          style: AppText.heroSubtitle),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Form ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your credentials',
                            style:
                                AppText.h3.copyWith(color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        Text("You'll use these to sign in.",
                            style: AppText.body),
                        const SizedBox(height: 22),
                        _Field(
                          ctrl: _emailCtrl,
                          label: 'Email address',
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          ctrl: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onToggle: () => setState(() => _obscure = !_obscure),
                          helper: 'Minimum 6 characters',
                          validator: (v) => v == null || v.length < 6
                              ? 'Min 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          ctrl: _confirmCtrl,
                          label: 'Confirm password',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                          validator: (v) => v != _passCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        TealButton(
                          label: 'Continue',
                          icon: Icons.arrow_forward_rounded,
                          loading: _loading,
                          onTap: _register,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: AppText.body,
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: AppText.body.copyWith(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  final bool obscure;
  final VoidCallback? onToggle;
  final FormFieldValidator<String>? validator;
  final String? helper;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.onToggle,
    this.validator,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(
          fontFamily: AppText.fontFamily,
          fontSize: 14,
          color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: AppColors.inputBg,
        prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger)),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textLight,
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
      validator: validator,
    );
  }
}
