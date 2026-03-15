import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';

class FeedbackEngine {
  final FlutterTts _tts = FlutterTts();
  final Map<String, DateTime> _lastSpoken = {};
  final Random _rand = Random();
  static const Duration _cooldown = Duration(seconds: 7);

  bool textOnly = false;
  final List<String> feedbackMessages = [];

  // ── Variation pools ────────────────────────────────────────────────────────

  static const _symmetryBad = [
    'Try to maintain equal step length on both sides.',
    'Your left and right steps seem uneven — focus on matching them.',
    'Notice the difference between your two sides and try to balance it out.',
    'Aim for symmetry — each step should feel the same on both legs.',
  ];

  static const _symmetryGood = [
    'Great symmetry — your steps are well balanced.',
    'Both sides are moving evenly, excellent control.',
    'Your symmetry is looking strong, keep that up.',
  ];

  static const _cadenceSlow = [
    'Try to walk a little faster if you can.',
    'Pick up the pace slightly — aim for a steady rhythm.',
    'A bit more speed will help your balance and recovery.',
    'Try taking quicker, lighter steps.',
  ];

  static const _cadenceFast = [
    'Slow down slightly for better balance.',
    'Take it a little easier — control matters more than speed.',
    'Ease the pace — focus on steady, deliberate steps.',
  ];

  static const _posture = [
    'Straighten your posture and stand tall.',
    'Try to keep your back upright as you walk.',
    'Engage your core and lift your chest slightly.',
    'Keep your shoulders back and your spine straight.',
    'Stand tall — imagine a string pulling the top of your head upward.',
  ];

  static const _kneeLeft = [
    'Try to lift your left leg a bit higher.',
    'Focus on bending your left knee more during the swing phase.',
    'Your left leg needs a little more lift — concentrate on it.',
    'Give your left knee a bit more flex as you step forward.',
  ];

  static const _kneeRight = [
    'Try to lift your right leg a bit higher.',
    'Focus on bending your right knee more during the swing phase.',
    'Your right leg needs a little more lift — concentrate on it.',
    'Give your right knee a bit more flex as you step forward.',
  ];

  static const _consistency = [
    'Try to keep your steps more even and rhythmic.',
    'Focus on making each step the same size.',
    'Imagine walking on equally spaced tiles — keep it consistent.',
    'Find a steady rhythm and try to hold it.',
    'Each step should feel like the last — smooth and even.',
  ];

  static const _good = [
    'Good balance — keep going!',
    'Looking strong, maintain that rhythm.',
    'Great work — your gait is improving.',
    'Excellent — stay focused and keep moving.',
    'That is solid form, keep it up.',
  ];

  static const _encouragement = [
    'You are doing well — stay consistent.',
    'Keep going — every step counts.',
    'Good effort — stay focused.',
    'You are making progress — keep moving.',
  ];

  // ── Init ───────────────────────────────────────────────────────────────────

  FeedbackEngine({this.textOnly = false}) {
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // TTS unavailable on this platform — text feedback still works
    }
  }

  // ── Main analysis ──────────────────────────────────────────────────────────

  void analyze({
    required double symmetry,
    required double cadence,
    required double leftKneeAngle,
    required double rightKneeAngle,
    required double trunkLean,
    required double strideConsistency,
  }) {
    bool issueFlagged = false;
    final kneeDiff = (leftKneeAngle - rightKneeAngle).abs();

    // Priority order: worst issues spoken first

    if (symmetry < 50) {
      _emit('symmetry_bad', _symmetryBad);
      issueFlagged = true;
    } else if (symmetry > 75) {
      _emit('symmetry_good', _symmetryGood);
    }

    if (trunkLean.abs() > 10) {
      _emit('posture', _posture);
      issueFlagged = true;
    }

    if (kneeDiff > 20) {
      final pool = leftKneeAngle < rightKneeAngle ? _kneeLeft : _kneeRight;
      _emit('knee', pool);
      issueFlagged = true;
    }

    if (cadence < 50) {
      _emit('cadence_slow', _cadenceSlow);
      issueFlagged = true;
    } else if (cadence > 110) {
      _emit('cadence_fast', _cadenceFast);
      issueFlagged = true;
    }

    if (strideConsistency < 50) {
      _emit('consistency', _consistency);
      issueFlagged = true;
    }

    // Positive reinforcement only when no issues this frame
    if (!issueFlagged &&
        symmetry >= 70 &&
        cadence >= 50 &&
        trunkLean.abs() < 8 &&
        strideConsistency >= 60) {
      _emit('good', _good);
    }

    // Periodic encouragement regardless of issues (long cooldown)
    _emit('encourage', _encouragement, cooldown: const Duration(seconds: 30));
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _emit(
    String key,
    List<String> pool, {
    Duration cooldown = _cooldown,
  }) {
    final now = DateTime.now();
    final last = _lastSpoken[key];
    if (last != null && now.difference(last) < cooldown) return;

    _lastSpoken[key] = now;
    final message = pool[_rand.nextInt(pool.length)];

    feedbackMessages.add(message);
    if (feedbackMessages.length > 50) feedbackMessages.removeAt(0);

    if (!textOnly) {
      try {
        _tts.speak(message);
      } catch (_) {}
    }
  }

  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
  }
}