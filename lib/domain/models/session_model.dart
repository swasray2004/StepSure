class SessionModel {
  SessionModel copyWith({
    String? id,
    String? userId,
    DateTime? sessionDate,
    int? durationSeconds,
    double? recoveryScore,
    String? fallRisk,
    double? strideLength,
    double? cadence,
    double? symmetry,
    double? strideConsistency,
    double? jointDeviation,
    String? videoUrl,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionDate: sessionDate ?? this.sessionDate,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      fallRisk: fallRisk ?? this.fallRisk,
      strideLength: strideLength ?? this.strideLength,
      cadence: cadence ?? this.cadence,
      symmetry: symmetry ?? this.symmetry,
      strideConsistency: strideConsistency ?? this.strideConsistency,
      jointDeviation: jointDeviation ?? this.jointDeviation,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  final String? id;
  final String userId;
  final DateTime sessionDate;
  final int durationSeconds;
  final double recoveryScore;
  final String fallRisk;
  final double strideLength;
  final double cadence;
  final double symmetry;
  final double strideConsistency;
  final double jointDeviation;
  final String? videoUrl;

  SessionModel({
    this.id,
    required this.userId,
    required this.sessionDate,
    required this.durationSeconds,
    required this.recoveryScore,
    required this.fallRisk,
    required this.strideLength,
    required this.cadence,
    required this.symmetry,
    required this.strideConsistency,
    required this.jointDeviation,
    this.videoUrl,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'session_date': sessionDate.toIso8601String(),
        'duration_seconds': durationSeconds,
        'recovery_score': recoveryScore,
        'fall_risk': fallRisk,
        'stride_length': strideLength,
        'cadence': cadence,
        'symmetry': symmetry,
        'stride_consistency': strideConsistency,
        'joint_deviation': jointDeviation,
        'video_url': videoUrl,
      };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
        id: map['id'],
        userId: map['user_id'],
        sessionDate: DateTime.parse(map['session_date']),
        durationSeconds: map['duration_seconds'],
        recoveryScore: (map['recovery_score'] as num).toDouble(),
        fallRisk: map['fall_risk'],
        strideLength: (map['stride_length'] as num).toDouble(),
        cadence: (map['cadence'] as num).toDouble(),
        symmetry: (map['symmetry'] as num).toDouble(),
        strideConsistency: (map['stride_consistency'] as num).toDouble(),
        jointDeviation: (map['joint_deviation'] as num).toDouble(),
        videoUrl: map['video_url'],
      );
}
