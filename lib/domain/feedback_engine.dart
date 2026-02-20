import 'package:flutter_tts/flutter_tts.dart';

class FeedbackEngine {
  final FlutterTts _tts = FlutterTts();
  final Map<String, DateTime> _lastSpoken = {};
  static const Duration _cooldown = Duration(seconds: 6);

  FeedbackEngine() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void analyze({
    required double symmetry,
    required double cadence,
    required double leftKneeAngle,
    required double rightKneeAngle,
    required double trunkLean,
    required double strideConsistency,
  }) {
    if (symmetry < 50) {
      _speak('symmetry', 'Try to maintain equal step length on both sides.');
    } else if (symmetry > 75) {
      _speak('symmetry_good', 'Great symmetry, keep it up!');
    }

    if (cadence < 50) {
      _speak('cadence', 'Try to walk a little faster if you can.');
    } else if (cadence > 110) {
      _speak('cadence_fast', 'Slow down slightly for better balance.');
    }

    if (trunkLean.abs() > 10) {
      _speak('posture', 'Straighten your posture, stand tall.');
    }

    final kneeDiff = (leftKneeAngle - rightKneeAngle).abs();
    if (kneeDiff > 20) {
      final weaker = leftKneeAngle < rightKneeAngle ? 'left' : 'right';
      _speak('knee', 'Try to lift your $weaker leg a bit higher.');
    }

    if (strideConsistency < 50) {
      _speak('consistency', 'Try to keep your steps more even and rhythmic.');
    }

    if (symmetry > 70 && cadence >= 60 && trunkLean.abs() < 8) {
      _speak('good', 'Good balance, keep going!');
    }
  }

  void _speak(String key, String message) {
    final now = DateTime.now();
    final last = _lastSpoken[key];
    if (last == null || now.difference(last) >= _cooldown) {
      _lastSpoken[key] = now;
      _tts.speak(message);
    }
  }

  void dispose() {
    _tts.stop();
  }
}
