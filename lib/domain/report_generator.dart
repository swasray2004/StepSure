import 'models/session_model.dart';

class ReportGenerator {
  static Map<String, dynamic> generate({
    required SessionModel current,
    SessionModel? previous,
  }) {
    final improvement = previous != null
        ? ((current.recoveryScore - previous.recoveryScore) /
            previous.recoveryScore *
            100)
        : 0.0;

    final abnormalities = <String>[];
    final suggestions = <String>[];

    // Detect abnormalities
    if (current.symmetry < 60) {
      abnormalities.add('Significant left-right gait asymmetry detected.');
      suggestions.add(
          'Practice single-leg stance exercises for 30 seconds each side.');
    }
    if (current.jointDeviation > 40) {
      abnormalities.add('Reduced knee flexion range compared to normal gait.');
      suggestions.add('Perform seated knee flexion/extension exercises daily.');
    }
    if (current.cadence < 60) {
      abnormalities.add('Below-normal walking cadence observed.');
      suggestions
          .add('Try rhythmic auditory cueing — walk to a metronome at 80 BPM.');
    }
    if (current.strideConsistency < 60) {
      abnormalities.add('Inconsistent stride length variability detected.');
      suggestions.add(
          'Practice walking in a straight line focusing on equal step size.');
    }
    if (current.fallRisk == 'high') {
      suggestions.add(
          'Consider using a walking aid during home sessions until risk improves.');
    }

    // Summary
    final scoreLabel = current.recoveryScore >= 70
        ? 'Good'
        : current.recoveryScore >= 40
            ? 'Moderate'
            : 'Needs Improvement';

    final improvementText = improvement > 0
        ? 'Your recovery score improved by ${improvement.toStringAsFixed(1)}% since your last session. '
        : improvement < 0
            ? 'Your score decreased by ${improvement.abs().toStringAsFixed(1)}% — this is normal; consistency matters. '
            : 'This is your first session — great start! ';

    final summary = '''
$improvementText
Your current recovery score is ${current.recoveryScore.toStringAsFixed(1)}/100 ($scoreLabel).
Session duration: ${(current.durationSeconds / 60).toStringAsFixed(1)} minutes.
Stride length: ${current.strideLength.toStringAsFixed(2)}m | Cadence: ${current.cadence.toStringAsFixed(0)} steps/min.
Fall risk level: ${current.fallRisk.toUpperCase()}.
${abnormalities.isEmpty ? 'No significant gait abnormalities detected this session.' : ''}
    '''
        .trim();

    return {
      'summary': summary,
      'improvement_percentage': improvement,
      'abnormalities': abnormalities,
      'exercise_suggestions': suggestions,
      'risk_assessment': 'Current fall risk is ${current.fallRisk}. '
          '${current.fallRisk == 'high' ? 'Please consult your physiotherapist before next session.' : 'Continue your current rehab plan.'}',
    };
  }
}
