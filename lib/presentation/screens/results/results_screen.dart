import 'package:flutter/material.dart';
import 'package:gait_rehab/core/constants/app_colors.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/risk_badge.dart';
import '../home/metric_card.dart';
import '../instructions/primary_button.dart';
import '../../../domain/pdf_generator.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  final Map<String, dynamic> report;

  const ResultsScreen({
    super.key,
    required this.session,
    required this.report,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideUp;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _slideUp = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final bytes = await PdfGenerator.generateSessionReport(
        widget.session,
        widget.report,
      );
      final sessionId = widget.session['id'] as String? ?? 'session';
      await PdfGenerator.sharePdf(bytes, 'StepSure_$sessionId.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.session['recovery_score'] as num?)?.toDouble() ?? 0;
    final risk = widget.session['fall_risk'] as String? ?? 'moderate';
    final symmetry = (widget.session['symmetry'] as num?)?.toDouble() ?? 0;
    final cadence = (widget.session['cadence'] as num?)?.toDouble() ?? 0;
    final consistency =
        (widget.session['stride_consistency'] as num?)?.toDouble() ?? 0;
    final strideLen =
        (widget.session['stride_length'] as num?)?.toDouble() ?? 0;
    final duration = (widget.session['duration_seconds'] as int?) ?? 0;
    final improvement =
        (widget.report['improvement_percentage'] as num?)?.toDouble() ?? 0;
    final abnormalities =
        (widget.report['abnormalities'] as List<dynamic>?)?.cast<String>() ??
            [];
    final suggestions =
        (widget.report['exercise_suggestions'] as List<dynamic>?)
                ?.cast<String>() ??
            [];

    final scoreColor = AppColors.scoreColor(score);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _slideUp,
        builder: (_, child) => FadeTransition(
          opacity: _slideUp,
          child: child,
        ),
        child: CustomScrollView(
          slivers: [
            // ── Hero ──
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withOpacity(0.85),
                      scoreColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
                child: Column(
                  children: [
                    const Text(
                      'Session Complete! 🎉',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(duration / 60).toStringAsFixed(1)} minutes recorded',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    // Score ring
                    ScoreRing(score: score, size: 160, strokeWidth: 14),

                    const SizedBox(height: 20),

                    // Improvement chip
                    if (improvement != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              improvement > 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}% vs last session',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    RiskBadge(risk: risk, large: true),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Metrics Grid ──
                    const SectionHeader(
                      title: 'Gait Metrics',
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        MetricCard(
                          label: 'Step Symmetry',
                          value: symmetry.toStringAsFixed(0),
                          unit: '%',
                          icon: Icons.balance_rounded,
                          color: AppColors.primary,
                        ),
                        MetricCard(
                          label: 'Cadence',
                          value: cadence.toStringAsFixed(0),
                          unit: 'spm',
                          icon: Icons.speed_rounded,
                          color: AppColors.primary,
                        ),
                        MetricCard(
                          label: 'Consistency',
                          value: consistency.toStringAsFixed(0),
                          unit: '%',
                          icon: Icons.timeline_rounded,
                          color: AppColors.primary,
                        ),
                        MetricCard(
                          label: 'Stride Length',
                          value: strideLen.toStringAsFixed(2),
                          unit: 'm',
                          icon: Icons.straighten_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── AI Summary ──
                    const SectionHeader(title: 'AI Analysis'),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: Text(
                        widget.report['summary'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),

                    // ── Abnormalities ──
                    if (abnormalities.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Identified Issues'),
                      const SizedBox(height: 12),
                      ...abnormalities.map(
                        (a) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.danger.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.danger, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(a,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Exercise Suggestions ──
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const SectionHeader(
                        title: 'Recommended Exercises',
                      ),
                      const SizedBox(height: 12),
                      ...suggestions.asMap().entries.map(
                            (entry) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.success.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.success.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(entry.value,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                            height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],

                    // ── Risk Assessment ──
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Risk Assessment'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.riskColor(risk).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.riskColor(risk).withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          RiskBadge(risk: risk),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.report['risk_assessment'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Action Buttons ──
                    PrimaryButton(
                      label: _exportingPdf
                          ? 'Generating PDF...'
                          : 'Export PDF Report',
                      icon: _exportingPdf
                          ? null
                          : Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      onTap: _exportingPdf ? () {} : _exportPdf,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.popUntil(
                            context, (route) => route.isFirst),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Back to Home'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.textPrimary,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
