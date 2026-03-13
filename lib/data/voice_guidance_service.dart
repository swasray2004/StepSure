import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts with cooldown logic and exercise-specific cue sequencing.
class VoiceGuidanceService {
  static final VoiceGuidanceService _instance =
      VoiceGuidanceService._internal();
  factory VoiceGuidanceService() => _instance;
  VoiceGuidanceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialised = false;
  DateTime? _lastSpoke;
  static const _minGap = Duration(seconds: 5);

  Future<void> init() async {
    if (_initialised) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slow & clear for rehab patients
    await _tts.setVolume(0.9);
    await _tts.setPitch(1.0);
    _initialised = true;
  }

  /// Speak [text] only if cooldown has passed.
  Future<void> speak(String text, {bool force = false}) async {
    await init();
    final now = DateTime.now();
    if (!force && _lastSpoke != null && now.difference(_lastSpoke!) < _minGap)
      return;
    _lastSpoke = now;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();

  Future<void> speakCountdown(int secondsLeft) async {
    if (secondsLeft <= 3 && secondsLeft > 0) {
      await speak(secondsLeft.toString(), force: true);
    }
  }

  Future<void> announceRep(int rep, int total) async {
    await speak('Rep $rep', force: true);
  }

  Future<void> announceSet(int set, int total) async {
    if (set <= total) {
      await speak('Set $set of $total. Begin.', force: true);
    }
  }

  Future<void> announceRest(int restSeconds) async {
    await speak('Good work. Rest for $restSeconds seconds.', force: true);
  }

  Future<void> announceComplete() async {
    await speak('Exercise complete. Well done! Take a moment to rest.',
        force: true);
  }

  Future<void> announceSessionComplete() async {
    await speak(
        'Session complete. Excellent effort. Your physiotherapist would be proud.',
        force: true);
  }

  void dispose() {
    _tts.stop();
  }
}
