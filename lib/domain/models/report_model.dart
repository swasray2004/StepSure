class ReportModel {
  final String summary;
  final double improvementPercentage;
  final List<String> abnormalities;
  final List<String> exerciseSuggestions;
  final String riskAssessment;

  ReportModel({
    required this.summary,
    required this.improvementPercentage,
    required this.abnormalities,
    required this.exerciseSuggestions,
    required this.riskAssessment,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      summary: map['summary'] ?? '',
      improvementPercentage:
          (map['improvement_percentage'] as num?)?.toDouble() ?? 0.0,
      abnormalities:
          (map['abnormalities'] as List<dynamic>?)?.cast<String>() ?? [],
      exerciseSuggestions:
          (map['exercise_suggestions'] as List<dynamic>?)?.cast<String>() ?? [],
      riskAssessment: map['risk_assessment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'improvement_percentage': improvementPercentage,
      'abnormalities': abnormalities,
      'exercise_suggestions': exerciseSuggestions,
      'risk_assessment': riskAssessment,
    };
  }
}
