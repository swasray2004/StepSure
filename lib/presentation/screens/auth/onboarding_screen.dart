import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/design_systems.dart';
import '../../../core/widgets/widgets.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  DateTime? _strokeDate;
  String _side = 'left';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_strokeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select your stroke date'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser!.id;
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': uid,
        'full_name': _nameCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text.trim()),
        'stroke_date': DateFormat('yyyy-MM-dd').format(_strokeDate!),
        'affected_side': _side,
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
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
              // ── Hero ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: HeroCard(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TealPill(
                        label: 'Step 2 of 2',
                        bgColor: Colors.white.withValues(alpha: 0.2),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 14),
                      const Text('Your Profile', style: AppText.heroTitle),
                      const SizedBox(height: 6),
                      const Text(
                        'Help us personalise your rehab analysis',
                        style: AppText.heroSubtitle,
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1.0,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                        const Text('Patient Information', style: AppText.h3),
                        const SizedBox(height: 18),

                        // Name
                        _buildField(
                          ctrl: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          caps: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Age
                        _buildField(
                          ctrl: _ageCtrl,
                          label: 'Age',
                          icon: Icons.cake_outlined,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1 || n > 120) {
                              return 'Enter a valid age';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Stroke date
                        Text('Date of Stroke',
                            style: AppText.label.copyWith(fontSize: 13)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              firstDate: DateTime(1990),
                              lastDate: DateTime.now(),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.teal,
                                    onPrimary: Colors.white,
                                    surface: AppColors.white,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (d != null) setState(() => _strokeDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _strokeDate != null
                                    ? AppColors.teal
                                    : AppColors.inputBorder,
                                width: _strokeDate != null ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: _strokeDate != null
                                      ? AppColors.teal
                                      : AppColors.textLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _strokeDate == null
                                      ? 'Select date'
                                      : DateFormat('d MMMM yyyy')
                                          .format(_strokeDate!),
                                  style: TextStyle(
                                    fontFamily: AppText.fontFamily,
                                    fontSize: 14,
                                    color: _strokeDate == null
                                        ? AppColors.textHint
                                        : AppColors.textDark,
                                    fontWeight: _strokeDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textHint, size: 18),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Affected side
                        Text('Affected Side',
                            style: AppText.label.copyWith(fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(
                          children: ['left', 'right', 'both'].map((s) {
                            final sel = _side == s;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _side = s),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: s == 'both'
                                      ? EdgeInsets.zero
                                      : const EdgeInsets.only(right: 8),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.teal
                                        : AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.teal
                                          : AppColors.inputBorder,
                                      width: sel ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${s[0].toUpperCase()}${s.substring(1)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppText.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textMid,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 28),

                        TealButton(
                          label: 'Get Started',
                          icon: Icons.rocket_launch_outlined,
                          loading: _loading,
                          onTap: _save,
                        ),

                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Your data is private and encrypted.',
                            style: AppText.bodySmall,
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

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      style: const TextStyle(
          fontFamily: AppText.fontFamily,
          fontSize: 14,
          color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
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
      ),
      validator: validator,
    );
  }
}
