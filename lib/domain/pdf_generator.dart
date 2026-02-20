// lib/domain/pdf_generator.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/models/session_model.dart';

class PdfExporter {
  static Future<void> exportReport({
    required SessionModel session,
    required Map<String, dynamic> report,
  }) async {
    final doc = pw.Document();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Gait Rehab AI — Session Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Date: ${session.sessionDate.toString().substring(0, 16)}'),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Text('Recovery Score: ${session.recoveryScore.toStringAsFixed(1)}/100',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Fall Risk: ${session.fallRisk.toUpperCase()}'),
          pw.SizedBox(height: 16),
          pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(report['summary'] ?? ''),
          pw.SizedBox(height: 16),
          pw.Text('Identified Issues', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...(report['abnormalities'] as List<String>).map((e) =>
              pw.Bullet(text: e)),
          pw.SizedBox(height: 16),
          pw.Text('Exercise Suggestions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...(report['exercise_suggestions'] as List<String>).map((e) =>
              pw.Bullet(text: e)),
          pw.SizedBox(height: 16),
          pw.Text('Risk Assessment', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(report['risk_assessment'] ?? ''),
        ],
      ),
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'gait_report_${session.sessionDate.millisecondsSinceEpoch}.pdf',
    );
  }
}