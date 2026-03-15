class ReportModel {
  final String summary;
  final double improvementPercentage;
  final List<String> abnormalities;
  final List<String> exerciseSuggestions;
  final String riskAssessment;

  const ReportModel({
    required this.summary,
    required this.improvementPercentage,
    required this.abnormalities,
    required this.exerciseSuggestions,
    required this.riskAssessment,
  });

  /// Create model from database map
  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      summary: map['summary'] ?? '',
      improvementPercentage:
          (map['improvement_percentage'] as num?)?.toDouble() ?? 0.0,
      abnormalities:
          (map['abnormalities'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      exerciseSuggestions:
          (map['exercise_suggestions'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      riskAssessment: map['risk_assessment'] ?? '',
    );
  }

  /// Convert model to database map
  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'improvement_percentage': improvementPercentage,
      'abnormalities': abnormalities,
      'exercise_suggestions': exerciseSuggestions,
      'risk_assessment': riskAssessment,
    };
  }

  /// JSON serializer (used by APIs / Supabase)
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Copy helper
  ReportModel copyWith({
    String? summary,
    double? improvementPercentage,
    List<String>? abnormalities,
    List<String>? exerciseSuggestions,
    String? riskAssessment,
  }) {
    return ReportModel(
      summary: summary ?? this.summary,
      improvementPercentage:
          improvementPercentage ?? this.improvementPercentage,
      abnormalities: abnormalities ?? this.abnormalities,
      exerciseSuggestions: exerciseSuggestions ?? this.exerciseSuggestions,
      riskAssessment: riskAssessment ?? this.riskAssessment,
    );
  }
}