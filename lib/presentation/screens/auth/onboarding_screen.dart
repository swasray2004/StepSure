import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../home/home_screen.dart';
import '../../../core/widgets/profile_completion_confetti.dart';
import 'page_transitions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  DateTime? _strokeDate;
  String _affectedSide = 'left';

  bool _loading = false;
  bool _showConfetti = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_strokeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your stroke date')),
      );
      return;
    }

    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not authenticated. Please log in again.'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _loading = false);
      }
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'stroke_date': _strokeDate!.toIso8601String(),
        'affected_side': _affectedSide,
      });

      if (mounted) {
        setState(() => _showConfetti = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          /// Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    /// Progress
                    LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Step 2 of 2 — Your Profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Tell us about yourself',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'This helps us personalise your recovery plan and analysis.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    /// Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          _inputDecoration('Full Name', Icons.person_outline),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your name' : null,
                    ),

                    const SizedBox(height: 16),

                    /// Age
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Age', Icons.cake_outlined),
                      validator: (v) {
                        final age = int.tryParse(v ?? '');
                        if (age == null || age < 1 || age > 120) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Stroke Date Picker
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          helpText: 'When did your stroke occur?',
                        );

                        if (date != null) {
                          setState(() => _strokeDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              _strokeDate == null
                                  ? 'Date of Stroke'
                                  : '${_strokeDate!.day}/${_strokeDate!.month}/${_strokeDate!.year}',
                              style: TextStyle(
                                color: _strokeDate == null
                                    ? Colors.grey[600]
                                    : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Affected Side
                    const Text(
                      'Affected Side',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: ['left', 'right', 'both'].map((side) {
                        final selected = _affectedSide == side;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _affectedSide = side),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color:
                                    selected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  side[0].toUpperCase() + side.substring(1),
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    /// Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 🎉 CONFETTI OVERLAY
          if (_showConfetti)
            ProfileCompletionConfetti(
              onDone: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  SmoothPageRoute(page: HomeScreen()),
                  (_) => false,
                );
              },
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
