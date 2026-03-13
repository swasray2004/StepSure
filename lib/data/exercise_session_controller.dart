import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gait_rehab/domain/models/exercise_model.dart';

import 'voice_guidance_service.dart';

enum ExercisePhase { warmup, active, rest, complete }

/// Drives the guided exercise session for ONE exercise.
/// Use [ExerciseSessionController] for a multi-exercise playlist.
class SingleExerciseController extends ChangeNotifier {
  final ExerciseModel exercise;
  final VoidCallback? onComplete;

  SingleExerciseController({required this.exercise, this.onComplete});

  // ── State ──────────────────────────────────────────────────────────────────
  ExercisePhase _phase = ExercisePhase.warmup;
  int _currentSet = 1;
  int _currentRep = 0;
  double _secondsLeft = 5;
  DateTime? _endTime;
  int _restSecondsLeft = 0;
  bool _paused = false;
  bool _disposed = false;

  Timer? _timer;
  final _voice = VoiceGuidanceService();

  // ── Getters ─────────────────────────────────────────────────────────────────
  ExercisePhase get phase => _phase;
  int get currentSet => _currentSet;
  int get currentRep => _currentRep;
  int get secondsLeft => _secondsLeft.ceil();
  double get secondsLeftPrecise => _secondsLeft;
  int get restSecondsLeft => _restSecondsLeft;
  bool get isPaused => _paused;
  bool get isTimeBased => exercise.reps == 0;

  double get exerciseProgress {
    if (_phase == ExercisePhase.warmup) return 0;
    if (_phase == ExercisePhase.complete) return 1;
    if (isTimeBased) {
      final total = exercise.durationSeconds;
      return (1 - (_secondsLeft / total)).clamp(0.0, 1.0);
    }
    final totalReps = exercise.sets * exercise.reps;
    final done = (_currentSet - 1) * exercise.reps + _currentRep;
    return (done / totalReps).clamp(0.0, 1.0);
  }

  double get setProgress {
    if (isTimeBased) {
      return (1 - (_secondsLeft / exercise.durationSeconds)).clamp(0.0, 1.0);
    }
    return (_currentRep / exercise.reps).clamp(0.0, 1.0);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  Future<void> start() async {
    await _voice.init();
    _startWarmup();
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
    _voice.stop();
    notifyListeners();
  }

  void resume() {
    _paused = false;
    _resumeCurrentPhase();
    notifyListeners();
  }

  void togglePause() => _paused ? resume() : pause();

  // ── Warmup phase (5-second countdown) ────────────────────────────────────────
  void _startWarmup() {
    _phase = ExercisePhase.warmup;
    _secondsLeft = 5;
    _endTime = DateTime.now().add(const Duration(seconds: 5));
    _voice.speak('Get ready for ${exercise.name}. Starting in 5 seconds.',
        force: true);
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_paused || _disposed) return;
      final now = DateTime.now();
      _secondsLeft = _endTime!.difference(now).inMilliseconds / 1000.0;
      if (_secondsLeft <= 3 &&
          _secondsLeft > 0 &&
          _secondsLeft.ceil() == _secondsLeft) {
        _voice.speak('${_secondsLeft.ceil()}', force: true);
      }
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _startActivePhase();
      }
      notifyListeners();
    });
  }

  // ── Active phase ──────────────────────────────────────────────────────────────
  void _startActivePhase() {
    _phase = ExercisePhase.active;
    _currentRep = 0;

    if (isTimeBased) {
      _secondsLeft = exercise.durationSeconds.toDouble();
      _endTime =
          DateTime.now().add(Duration(seconds: exercise.durationSeconds));
      _voice.speak(exercise.voiceInstruction, force: true);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (_paused || _disposed) return;
        final now = DateTime.now();
        _secondsLeft = _endTime!.difference(now).inMilliseconds / 1000.0;
        // Speak coaching cue at halfway
        if (_secondsLeft.ceil() == (exercise.durationSeconds ~/ 2)) {
          _voice.speak(exercise.voiceInstruction);
        }
        if (_secondsLeft <= 3 &&
            _secondsLeft > 0 &&
            _secondsLeft.ceil() == _secondsLeft) {
          _voice.speak('${_secondsLeft.ceil()}', force: true);
        }
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          _onSetComplete();
        }
        notifyListeners();
      });
    } else {
      // Rep-based: announce set start
      _voice.speak(
          'Set $_currentSet of ${exercise.sets}. ${exercise.voiceInstruction}',
          force: true);
      notifyListeners();
      // Rep ticks are driven externally via [completeRep]
    }
  }

  /// Call this from the UI when the user taps "✓ Rep Done" in rep-based mode.
  void completeRep() {
    if (_phase != ExercisePhase.active || _paused) return;
    _currentRep++;
    _voice.speak('Rep $_currentRep', force: true);
    if (_currentRep >= exercise.reps) {
      _onSetComplete();
    }
    notifyListeners();
  }

  void _onSetComplete() {
    if (_currentSet >= exercise.sets) {
      _finishExercise();
      return;
    }
    // Start rest before next set
    _phase = ExercisePhase.rest;
    final restSecs = _parseRestSeconds(exercise.restBetweenSets);
    _restSecondsLeft = restSecs;
    _voice.speak('Set $_currentSet complete. Rest for $restSecs seconds.',
        force: true);
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || _disposed) return;
      _restSecondsLeft--;
      if (_restSecondsLeft == 3) {
        _voice.speak('3, 2, 1. Begin next set.', force: true);
      }
      if (_restSecondsLeft <= 0) {
        _timer?.cancel();
        _currentSet++;
        _startActivePhase();
      }
      notifyListeners();
    });
  }

  void _finishExercise() {
    _phase = ExercisePhase.complete;
    _timer?.cancel();
    _voice.announceComplete();
    notifyListeners();
    onComplete?.call();
  }

  void _resumeCurrentPhase() {
    switch (_phase) {
      case ExercisePhase.warmup:
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_paused || _disposed) return;
          _secondsLeft--;
          if (_secondsLeft <= 0) {
            _timer?.cancel();
            _startActivePhase();
          }
          notifyListeners();
        });
        break;
      case ExercisePhase.active:
        if (isTimeBased) {
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (_paused || _disposed) return;
            _secondsLeft--;
            if (_secondsLeft <= 0) {
              _timer?.cancel();
              _onSetComplete();
            }
            notifyListeners();
          });
        }
        break;
      case ExercisePhase.rest:
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_paused || _disposed) return;
          _restSecondsLeft--;
          if (_restSecondsLeft <= 0) {
            _timer?.cancel();
            _currentSet++;
            _startActivePhase();
          }
          notifyListeners();
        });
        break;
      case ExercisePhase.complete:
        break;
    }
  }

  int _parseRestSeconds(String text) {
    final n = RegExp(r'\d+').firstMatch(text);
    return n != null ? int.parse(n.group(0)!) : 30;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _voice.stop();
    super.dispose();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PLAYLIST controller — sequences multiple exercises
// ═════════════════════════════════════════════════════════════════════════════
class ExerciseSessionController extends ChangeNotifier {
  final List<ExerciseModel> exercises;
  late SingleExerciseController _current;
  int _exerciseIndex = 0;
  bool _sessionComplete = false;
  final _voice = VoiceGuidanceService();

  ExerciseSessionController({required this.exercises}) {
    _current = SingleExerciseController(
      exercise: exercises.isNotEmpty
          ? exercises[0]
          : throw Exception('No exercises provided'),
      onComplete: _onExerciseComplete,
    );
  }

  int get exerciseIndex => _exerciseIndex;
  int get totalExercises => exercises.length;
  bool get sessionComplete => _sessionComplete;
  ExerciseModel get currentExercise => exercises[_exerciseIndex];
  SingleExerciseController get currentController => _current;

  Future<void> start() async {
    await _voice.init();
    _buildCurrent();
    await _current.start();
  }

  void _buildCurrent() {
    _current = SingleExerciseController(
      exercise: exercises[_exerciseIndex],
      onComplete: _onExerciseComplete,
    );
    notifyListeners();
  }

  void _onExerciseComplete() {
    if (_exerciseIndex + 1 >= exercises.length) {
      _sessionComplete = true;
      _voice.announceSessionComplete();
      notifyListeners();
      return;
    }
    _exerciseIndex++;
    _current.dispose();
    _buildCurrent();
    // Short break between exercises
    Future.delayed(const Duration(seconds: 2), () {
      _voice.speak('Next up: ${exercises[_exerciseIndex].name}', force: true);
      Future.delayed(const Duration(seconds: 3), () => _current.start());
    });
  }

  void skipToNext() {
    if (_exerciseIndex + 1 < exercises.length) {
      _current.dispose();
      _exerciseIndex++;
      _buildCurrent();
      _current.start();
    }
  }

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }
}
