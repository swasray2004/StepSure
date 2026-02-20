import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates a structured PDF rehab report and exposes a share helper.
/// Accepts [session] as a Map (matching SessionModel.toMap() keys) so the
/// presentation layer can call this without re-importing SessionModel.
class PdfGenerator {
  // ─── Colors matching AppColors ───────────────────────────────────────────
  static const _primary = PdfColor.fromInt(0xFF2196F3);
  static const _success = PdfColor.fromInt(0xFF4CAF50);
  static const _warning = PdfColor.fromInt(0xFFFF9800);
  static const _danger = PdfColor.fromInt(0xFFF44336);
  static const _bgLight = PdfColor.fromInt(0xFFF5F7FA);
  static const _textPrimary = PdfColor.fromInt(0xFF1A1A2E);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7280);

  static PdfColor _scoreColor(double s) =>
      s >= 70 ? _success : s >= 40 ? _warning : _danger;

  static PdfColor _riskColor(String r) =>
      r == 'low' ? _success : r == 'moderate' ? _warning : _danger;

  static PdfColor _riskBg(String r) => r == 'high'
      ? const PdfColor.fromInt(0xFFFFEBEE)
      : r == 'moderate'
          ? const PdfColor.fromInt(0xFFFFF3E0)
          : const PdfColor.fromInt(0xFFE8F5E9);

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Renders the session report as an A4 PDF and returns the raw bytes.
  static Future<Uint8List> generateSessionReport(
    Map<String, dynamic> session,
    Map<String, dynamic> report,
  ) async {
    // Extract session values ------------------------------------------------
    final score = (session['recovery_score'] as num?)?.toDouble() ?? 0;
    final risk = session['fall_risk'] as String? ?? 'moderate';
    final cadence = (session['cadence'] as num?)?.toDouble() ?? 0;
    final symmetry = (session['symmetry'] as num?)?.toDouble() ?? 0;
    final consistency =
        (session['stride_consistency'] as num?)?.toDouble() ?? 0;
    final jointDev = (session['joint_deviation'] as num?)?.toDouble() ?? 0;
    final strideLen = (session['stride_length'] as num?)?.toDouble() ?? 0;
    final durationSec = (session['duration_seconds'] as int?) ?? 0;

    final sessionDate = session['session_date'] != null
        ? DateTime.tryParse(session['session_date'].toString()) ?? DateTime.now()
        : DateTime.now();

    final dateStr =
        DateFormat('MMMM d, yyyy — h:mm a').format(sessionDate.toLocal());
    final durationStr = '${(durationSec / 60).toStringAsFixed(1)} min';

    // Extract report values ------------------------------------------------
    final summary = report['summary'] as String? ?? '';
    final abnormalities =
        (report['abnormalities'] as List<dynamic>?)?.cast<String>() ?? [];
    final suggestions =
        (report['exercise_suggestions'] as List<dynamic>?)?.cast<String>() ??
            [];
    final riskAssessment = report['risk_assessment'] as String? ?? '';
    final improvement =
        (report['improvement_percentage'] as num?)?.toDouble() ?? 0;

    final scoreColor = _scoreColor(score);
    final riskColor = _riskColor(risk);

    // Build document -------------------------------------------------------
    final doc = pw.Document(
      title: 'StepSure Gait Report',
      author: 'StepSure AI',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _footer(),
        build: (context) => [
          // ── Header bar ─────────────────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'StepSure',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Gait Analysis Report',
                      style: pw.TextStyle(
                          color: PdfColors.white, fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(
                          color: PdfColors.white, fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Duration: $durationStr',
                      style: pw.TextStyle(
                          color: PdfColors.white, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Score / Risk Banner ─────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _bgLight,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Recovery Score',
                          style: pw.TextStyle(
                              color: _textSecondary, fontSize: 11),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          score.toStringAsFixed(1),
                          style: pw.TextStyle(
                            color: scoreColor,
                            fontSize: 40,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '/ 100',
                          style: pw.TextStyle(
                              color: _textSecondary, fontSize: 11),
                        ),
                        if (improvement != 0) ...[
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: improvement > 0
                                  ? const PdfColor.fromInt(0xFFE8F5E9)
                                  : const PdfColor.fromInt(0xFFFFEBEE),
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            child: pw.Text(
                              '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}% vs last session',
                              style: pw.TextStyle(
                                color:
                                    improvement > 0 ? _success : _danger,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.Container(
                    width: 1,
                    height: 90,
                    color: const PdfColor.fromInt(0xFFE0E0E0)),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Fall Risk',
                          style: pw.TextStyle(
                              color: _textSecondary, fontSize: 11),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: riskColor,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            risk.toUpperCase(),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Metrics Table ───────────────────────────────────────────────
          _sectionHeading('Gait Metrics'),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFE0E0E0),
              width: 0.5,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _primary),
                children: [
                  _tableCell('Metric', header: true),
                  _tableCell('Value', header: true),
                  _tableCell('Status', header: true),
                ],
              ),
              _metricRow('Cadence', '${cadence.toStringAsFixed(0)} steps/min',
                  cadence >= 80 ? 'Normal' : cadence >= 50 ? 'Reduced' : 'Low',
                  cadence >= 80 ? _success : cadence >= 50 ? _warning : _danger,
                  even: false),
              _metricRow(
                  'Step Symmetry',
                  '${symmetry.toStringAsFixed(1)}%',
                  symmetry >= 70 ? 'Good' : symmetry >= 50 ? 'Fair' : 'Poor',
                  symmetry >= 70 ? _success : symmetry >= 50 ? _warning : _danger,
                  even: true),
              _metricRow(
                  'Stride Consistency',
                  '${consistency.toStringAsFixed(1)}%',
                  consistency >= 70
                      ? 'Good'
                      : consistency >= 50
                          ? 'Fair'
                          : 'Poor',
                  consistency >= 70
                      ? _success
                      : consistency >= 50
                          ? _warning
                          : _danger,
                  even: false),
              _metricRow(
                  'Joint Deviation',
                  jointDev.toStringAsFixed(1),
                  jointDev < 20 ? 'Normal' : jointDev < 40 ? 'Moderate' : 'High',
                  jointDev < 20 ? _success : jointDev < 40 ? _warning : _danger,
                  even: true),
              _metricRow(
                  'Stride Length',
                  '${strideLen.toStringAsFixed(2)} m',
                  strideLen >= 1.0 ? 'Normal' : 'Reduced',
                  strideLen >= 1.0 ? _success : _warning,
                  even: false),
              _metricRow('Duration', durationStr, '—', _textSecondary,
                  even: true),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── AI Summary ──────────────────────────────────────────────────
          _sectionHeading('AI Analysis Summary'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              borderRadius: pw.BorderRadius.circular(8),
              border: const pw.Border(
                left: pw.BorderSide(color: _primary, width: 3),
              ),
            ),
            child: pw.Text(
              summary,
              style: pw.TextStyle(
                  color: _textPrimary, fontSize: 11, lineSpacing: 4),
            ),
          ),

          // ── Abnormalities ───────────────────────────────────────────────
          if (abnormalities.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Identified Gait Issues'),
            pw.SizedBox(height: 8),
            ...abnormalities.map(
              (a) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFEBEE),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFFFCDD2)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('! ',
                        style: pw.TextStyle(
                            color: _danger,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(a,
                          style: pw.TextStyle(
                              color: _textPrimary,
                              fontSize: 10,
                              lineSpacing: 3)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Exercise Suggestions ────────────────────────────────────────
          if (suggestions.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionHeading('Recommended Exercises'),
            pw.SizedBox(height: 8),
            ...suggestions.asMap().entries.map(
              (entry) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE8F5E9),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFC8E6C9)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      decoration: pw.BoxDecoration(
                        color: _success,
                        shape: pw.BoxShape.circle,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '${entry.key + 1}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(entry.value,
                          style: pw.TextStyle(
                              color: _textPrimary,
                              fontSize: 10,
                              lineSpacing: 3)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Risk Assessment ─────────────────────────────────────────────
          pw.SizedBox(height: 18),
          _sectionHeading('Risk Assessment'),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _riskBg(risk),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: riskColor),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: riskColor,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    risk.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(riskAssessment,
                      style: pw.TextStyle(
                          color: _textPrimary, fontSize: 10, lineSpacing: 3)),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),
        ],
      ),
    );

    return doc.save();
  }

  /// Opens the system share sheet so the user can save or send the PDF.
  static Future<void> sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static pw.Widget _sectionHeading(String title) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
          ),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  static pw.Widget _tableCell(String text, {bool header = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: header ? PdfColors.white : _textPrimary,
            fontSize: 10,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.TableRow _metricRow(
    String label,
    String value,
    String status,
    PdfColor statusColor, {
    required bool even,
  }) =>
      pw.TableRow(
        decoration: pw.BoxDecoration(
            color: even ? _bgLight : PdfColors.white),
        children: [
          _tableCell(label),
          _tableCell(value),
          pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(
              status,
              style: pw.TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      );

  static pw.Widget _footer() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(
                color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
          ),
        ),
        child: pw.Text(
          'This report is generated by StepSure AI and is for informational '
          'purposes only. It does not constitute medical advice. Consult your '
          'physiotherapist before making changes to your rehabilitation programme.',
          style: pw.TextStyle(
            color: _textSecondary,
            fontSize: 7,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
}
