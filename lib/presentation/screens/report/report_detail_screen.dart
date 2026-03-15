import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gait_rehab/core/constants/app_colors.dart';
import 'package:gait_rehab/core/constants/app_text.dart';
import 'package:gait_rehab/domain/models/report_model.dart';
import 'package:gait_rehab/domain/models/session_model.dart';
import 'package:gait_rehab/domain/pdf_generator.dart';

class ReportDetailScreen extends StatelessWidget {
  final dynamic report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final session = report['sessions'] as Map<String, dynamic>?;
    final score = (session?['recovery_score'] as num?)?.toDouble() ?? 0;
    final risk = session?['fall_risk'] as String? ?? 'moderate';

    final date =
        DateTime.tryParse(report['generated_at'] ?? '') ?? DateTime.now();

    final summary = report['summary'] as String? ?? '';
    final riskText = report['risk_assessment'] as String? ?? '';

    final imp = (report['improvement_percentage'] as num?)?.toDouble() ?? 0;

    final abnorm = (report['abnormalities'] as List?)?.cast<String>() ?? [];

    final sugg =
        (report['exercise_suggestions'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.heroEnd,
        title: const Text('AI Rehab Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Text(
              DateFormat('EEE, d MMMM yyyy').format(date),
              style: AppText.heroSubtitle,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                _Pill('${score.toStringAsFixed(1)}/100'),
                const SizedBox(width: 8),
                _RiskBadge(risk: risk),

                if (imp != 0) ...[
                  const SizedBox(width: 8),
                  _Pill(
                    '${imp > 0 ? '+' : ''}${imp.toStringAsFixed(1)}%',
                    color: imp >= 0 ? AppColors.teal : AppColors.danger,
                  ),
                ]
              ],
            ),

            const SizedBox(height: 24),

            /// SUMMARY
            _Section(
              icon: Icons.summarize_rounded,
              title: 'Session Summary',
              child: Text(summary, style: AppText.body),
            ),

            const SizedBox(height: 20),

            /// ABNORMALITIES
            if (abnorm.isNotEmpty)
              _Section(
                icon: Icons.warning_amber_rounded,
                title: 'Gait Abnormalities',
                iconColor: AppColors.warning,
                child: Column(
                  children: abnorm
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: AppColors.warning),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(a, style: AppText.body),
                              )
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 20),

            /// EXERCISES
            if (sugg.isNotEmpty)
              _Section(
                icon: Icons.fitness_center_rounded,
                title: 'Recommended Exercises',
                iconColor: AppColors.teal,
                child: Column(
                  children: sugg
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: AppColors.tealPale,
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.value, style: AppText.body),
                              )
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 20),

            /// RISK
            _Section(
              icon: Icons.health_and_safety_rounded,
              title: 'Risk Assessment',
              iconColor: AppColors.riskColor(risk),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RiskBadge(risk: risk),
                  const SizedBox(height: 10),
                  Text(riskText, style: AppText.body),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// EXPORT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Export as PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final sessionId = report['session_id'] as String?;
                  if (sessionId == null || sessionId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No session linked to this report.'),
                      ),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Generating PDF...')),
                  );

                  try {
                    final client = Supabase.instance.client;
                    final sessionMap = await client
                        .from('sessions')
                        .select()
                        .eq('id', sessionId)
                        .single();

                    final sessionModel =
                        SessionModel.fromMap(sessionMap as Map<String, dynamic>);
                    final reportModel = ReportModel.fromMap(
                        report as Map<String, dynamic>);

                    await PdfExporter.exportReport(
                      session: sessionModel,
                      report: reportModel,
                      patientName: report['patient_name'] as String? ?? 'Patient',
                    );

                    if (!context.mounted) return;
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('PDF ready to share.')),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to export PDF. Try again.'),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? iconColor;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.black87),
              const SizedBox(width: 8),
              Text(title, style: AppText.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color? color;

  const _Pill(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String risk;

  const _RiskBadge({required this.risk});

  Color get _color {
    switch (risk.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'high':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        risk.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
