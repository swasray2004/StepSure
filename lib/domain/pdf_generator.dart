import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/session_model.dart';
import '../domain/models/report_model.dart';

class PdfExporter {
  static Future<void> exportReport({
    required SessionModel session,
    required ReportModel report,
    String patientName = 'Patient',
  }) async {
    final doc = pw.Document();

    // Colour palette
    const headerColor = PdfColor.fromInt(0xFF1565C0);   // deep blue
    const accentColor = PdfColor.fromInt(0xFF0288D1);
    const lowColor = PdfColor.fromInt(0xFF2E7D32);
    const modColor = PdfColor.fromInt(0xFFF57F17);
    const highColor = PdfColor.fromInt(0xFFC62828);

    final riskColor = session.fallRisk == 'low'
        ? lowColor
        : session.fallRisk == 'moderate'
            ? modColor
            : highColor;

    final scoreColor = session.recoveryScore >= 70
        ? lowColor
        : session.recoveryScore >= 40
            ? modColor
            : highColor;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(context, headerColor),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // ── Patient & session info bar ──────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Patient',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(patientName,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Session Date',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(
                      _formatDate(session.sessionDate),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Session ID',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(
                      session.id != null && session.id!.length > 8
                          ? session.id!.substring(0, 8).toUpperCase()
                          : (session.id ?? 'N/A').toUpperCase(),
                      style: pw.TextStyle(
                          font: pw.Font.courier(),
                          fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Duration',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(
                        '${(session.durationSeconds / 60).toStringAsFixed(1)} min',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Score + Risk banner ────────────────────────────────────────
          pw.Row(children: [
            _scoreBox('Recovery Score',
                '${session.recoveryScore.toStringAsFixed(1)}/100', scoreColor),
            pw.SizedBox(width: 12),
            _scoreBox('Fall Risk', session.fallRisk.toUpperCase(), riskColor),
          ]),

          pw.SizedBox(height: 16),

          // ── Metrics table ──────────────────────────────────────────────
          pw.Text('Session Metrics',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _metricsTable(session),

          pw.SizedBox(height: 16),

          // ── Summary ────────────────────────────────────────────────────
          _sectionTitle('Clinical Summary', accentColor),
          pw.Text(report.summary,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 4)),

          pw.SizedBox(height: 14),

          // ── Abnormalities ──────────────────────────────────────────────
          _sectionTitle('Identified Issues', accentColor),
          if (report.abnormalities.isEmpty)
            pw.Text('No significant gait abnormalities detected.',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.green800))
          else
            ...report.abnormalities.map((a) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                          child: pw.Text(a,
                              style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                )),

          pw.SizedBox(height: 14),

          // ── Exercise suggestions ───────────────────────────────────────
          _sectionTitle('Exercise Suggestions', accentColor),
          ...report.exerciseSuggestions.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${e.key + 1}. ',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                        child: pw.Text(e.value,
                            style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              )),

          pw.SizedBox(height: 14),

          // ── Risk assessment ────────────────────────────────────────────
          _sectionTitle('Risk Assessment', accentColor),
          pw.Text(report.riskAssessment,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 4)),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'stepsure_report_${session.sessionDate.millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(pw.Context context, PdfColor color) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
      padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: color)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  padding: const pw.EdgeInsets.only(bottom: 3, left: 30),
                  height: 30,
                  child: pw.Text(
                    'StepSure Report',
                    style: pw.TextStyle(
                      color: color,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  padding: const pw.EdgeInsets.only(left: 30),
                  height: 20,
                  child: pw.Text(
                    'Gait Analysis & Fall Risk Assessment',
                    style: pw.TextStyle(
                      color: PdfColors.grey600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 60,
            height: 60,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: 'https://stepsure.com',
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
      ),
    );
  }

  static pw.Widget _scoreBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );
  }

  static pw.Widget _metricsTable(SessionModel session) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableCell('Metric', isHeader: true),
            _tableCell('Value', isHeader: true),
            _tableCell('Normal Range', isHeader: true),
          ],
        ),
        pw.TableRow(children: [
          _tableCell('Cadence (steps/min)'),
          _tableCell('${session.cadence.toStringAsFixed(1)}'),
          _tableCell('80-120'),
        ]),
        pw.TableRow(children: [
          _tableCell('Gait Symmetry'),
          _tableCell('${session.symmetry.toStringAsFixed(1)}%'),
          _tableCell('>80%'),
        ]),
        pw.TableRow(children: [
          _tableCell('Stride Consistency'),
          _tableCell('${session.strideConsistency.toStringAsFixed(1)}%'),
          _tableCell('>75%'),
        ]),
        pw.TableRow(children: [
          _tableCell('Stride Length (m)'),
          _tableCell('${session.strideLength.toStringAsFixed(2)}'),
          _tableCell('0.6-0.8'),
        ]),
        pw.TableRow(children: [
          _tableCell('Joint Deviation'),
          _tableCell('${session.jointDeviation.toStringAsFixed(1)}%'),
          _tableCell('<15%'),
        ]),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isHeader ? pw.FontWeight.bold : null)),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
