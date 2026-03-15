import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/session_model.dart';
import 'models/report_model.dart';

class ReportGenerator {
  static const String _apiKey = 'AIzaSyDK9kEIIToblpmkI66Cp2z9V4eThDPqtV8';
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Calls Gemini and returns a fully populated ReportModel.
  /// Falls back to rule-based generation if the API call fails.
  static Future<ReportModel> generate({
    required SessionModel current,
    SessionModel? previous,
    Duration? timeout,
  }) async {
    final improvement = previous != null && previous.recoveryScore > 0
        ? ((current.recoveryScore - previous.recoveryScore) /
            previous.recoveryScore *
            100)
        : 0.0;

    try {
      final future = _generateWithGemini(current, previous, improvement);
      return timeout == null ? await future : await future.timeout(timeout);
    } catch (e) {
      // Fallback so app never crashes during demo
      return _generateFallback(current, previous, improvement);
    }
  }

  // ── Gemini path ────────────────────────────────────────────────────────────

  static Future<ReportModel> _generateWithGemini(
    SessionModel current,
    SessionModel? previous,
    double improvement,
  ) async {
    final prompt = _buildPrompt(current, previous, improvement);

    // Retry logic for rate limits
    int retries = 0;
    const maxRetries = 2;
    while (retries < maxRetries) {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.4,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawText = decoded['candidates'][0]['content']['parts'][0]['text'] as String;

        // Strip markdown fences if Gemini wraps in ```json ... ```
        final clean = rawText
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        final Map<String, dynamic> parsed = jsonDecode(clean);

        return ReportModel(
          summary: parsed['summary'] ?? '',
          improvementPercentage: improvement,
          abnormalities: List<String>.from(parsed['abnormalities'] ?? []),
          exerciseSuggestions: List<String>.from(parsed['exercise_suggestions'] ?? []),
          riskAssessment: parsed['risk_assessment'] ?? '',
        );
      } else if (response.statusCode == 429) {
        // Rate limited, wait and retry
        retries++;
        if (retries < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retries)); // Exponential backoff
          continue;
        }
      }
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }
    throw Exception('Gemini API rate limit exceeded after retries');
  }

  static String _buildPrompt(
    SessionModel current,
    SessionModel? previous,
    double improvement,
  ) {
    final prevBlock = previous != null
        ? '''
Previous session (for comparison):
- Recovery Score: ${previous.recoveryScore.toStringAsFixed(1)}/100
- Cadence: ${previous.cadence.toStringAsFixed(1)} steps/min
- Gait Symmetry: ${previous.symmetry.toStringAsFixed(1)}%
- Stride Consistency: ${previous.strideConsistency.toStringAsFixed(1)}%
- Joint Deviation: ${previous.jointDeviation.toStringAsFixed(1)}%
- Fall Risk: ${previous.fallRisk}
Score change since last session: ${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%
'''
        : 'This is the patient\'s first recorded session.';

    return '''
You are a clinical physiotherapy AI assistant specialising in stroke rehabilitation and gait analysis.

Analyse the following gait session data and return a JSON report. Be specific, clinical, and personalised — reference the actual numbers in your response. Do NOT use generic sentences.

Current session metrics:
- Recovery Score: ${current.recoveryScore.toStringAsFixed(1)}/100
- Fall Risk: ${current.fallRisk.toUpperCase()}
- Session Duration: ${(current.durationSeconds / 60).toStringAsFixed(1)} minutes
- Cadence: ${current.cadence.toStringAsFixed(1)} steps/min (normal: 80–120)
- Gait Symmetry Index: ${current.symmetry.toStringAsFixed(1)}% (normal: >80%)
- Stride Consistency: ${current.strideConsistency.toStringAsFixed(1)}% (normal: >75%)
- Stride Length: ${current.strideLength.toStringAsFixed(2)} m (normal: 0.6–0.8 m)
- Joint Deviation Score: ${current.jointDeviation.toStringAsFixed(1)}% (lower = better; normal: <15%)

$prevBlock

Return ONLY valid JSON — no markdown, no explanation outside the JSON. Use this exact structure:

{
  "summary": "2–3 sentence clinical narrative referencing the actual scores. Mention improvement or decline if comparison data exists.",
  "abnormalities": [
    "Specific finding 1 with the actual metric value",
    "Specific finding 2 with the actual metric value"
  ],
  "exercise_suggestions": [
    "Specific exercise 1 tailored to the detected issues — include sets/reps or duration",
    "Specific exercise 2",
    "Specific exercise 3"
  ],
  "risk_assessment": "1–2 sentence risk summary referencing fall risk level and key contributing metrics. Include a clear action recommendation."
}

Rules:
- abnormalities: empty array [] if all metrics are within normal range
- exercise_suggestions: always include 3–5 exercises specific to this patient's deficits
- Never use placeholder text
- Never repeat the same sentence from summary in risk_assessment
''';
  }

  // ── Rule-based fallback ────────────────────────────────────────────────────

  static ReportModel _generateFallback(
    SessionModel current,
    SessionModel? previous,
    double improvement,
  ) {
    final abnormalities = <String>[];
    final suggestions = <String>[];

    if (current.symmetry < 60) {
      abnormalities.add(
          'Significant gait asymmetry detected (${current.symmetry.toStringAsFixed(1)}% — normal >80%).');
      suggestions.add(
          'Single-leg stance: hold 30 sec each side, 3 sets. Focus on the weaker leg.');
    }
    if (current.jointDeviation > 40) {
      abnormalities.add(
          'Elevated joint deviation (${current.jointDeviation.toStringAsFixed(1)}%) — reduced knee ROM.');
      suggestions
          .add('Seated knee flexion/extension: 3 × 15 reps, full available range.');
    }
    if (current.cadence < 60) {
      abnormalities.add(
          'Below-normal cadence (${current.cadence.toStringAsFixed(1)} steps/min — normal 80–120).');
      suggestions.add('Walk to a metronome at 80 BPM for 10 min daily.');
    }
    if (current.strideConsistency < 60) {
      abnormalities.add(
          'High stride variability (consistency ${current.strideConsistency.toStringAsFixed(1)}% — normal >75%).');
      suggestions.add(
          'Straight-line walking drill: focus on equal step size, 5 × 20 m.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('Maintain current rehab routine — metrics look stable.');
    }
    if (current.fallRisk == 'high') {
      suggestions.add(
          'Use a walking aid during home sessions until fall risk is reclassified as moderate.');
    }

    final scoreLabel = current.recoveryScore >= 70
        ? 'Good'
        : current.recoveryScore >= 40
            ? 'Moderate'
            : 'Needs Improvement';

    final improvementText = previous == null
        ? 'First session recorded — baseline established. '
        : improvement > 0
            ? 'Recovery improved by ${improvement.toStringAsFixed(1)}% since last session. '
            : 'Score decreased by ${improvement.abs().toStringAsFixed(1)}% — fluctuations are normal; consistency is key. ';

    final summary =
        '${improvementText}Recovery score: ${current.recoveryScore.toStringAsFixed(1)}/100 ($scoreLabel). '
        'Cadence ${current.cadence.toStringAsFixed(0)} steps/min, symmetry ${current.symmetry.toStringAsFixed(1)}%, '
        'stride consistency ${current.strideConsistency.toStringAsFixed(1)}%.';

    return ReportModel(
      summary: summary,
      improvementPercentage: improvement,
      abnormalities: abnormalities,
      exerciseSuggestions: suggestions,
      riskAssessment:
          'Fall risk is ${current.fallRisk.toUpperCase()}. '
          '${current.fallRisk == 'high' ? 'Consult your physiotherapist before the next session.' : 'Continue current rehabilitation plan and monitor cadence and symmetry.'}',
    );
  }
}
