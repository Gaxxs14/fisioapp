class PatientEvaluation {
  final String id;
  final String patientId;
  final DateTime date;
  final String chiefComplaint;
  final int painScaleEva; // 0 to 10
  final Map<String, int> jointRangeOfMotion; // e.g. {"hombro_izq_flexion": 120}
  final String strengthTest;
  final String flexibilityTest;
  final String balanceTest;
  final String physioDiagnosis;
  final String shortTermGoals;
  final String mediumTermGoals;
  final String longTermGoals;
  final bool isReevaluation;
  final String? comparedToEvaluationId;
  final String physioId;
  final DateTime createdAt;

  PatientEvaluation({
    required this.id,
    required this.patientId,
    required this.date,
    required this.chiefComplaint,
    required this.painScaleEva,
    required this.jointRangeOfMotion,
    required this.strengthTest,
    required this.flexibilityTest,
    required this.balanceTest,
    required this.physioDiagnosis,
    required this.shortTermGoals,
    required this.mediumTermGoals,
    required this.longTermGoals,
    required this.isReevaluation,
    this.comparedToEvaluationId,
    required this.physioId,
    required this.createdAt,
  });

  PatientEvaluation copyWith({
    String? id,
    String? patientId,
    DateTime? date,
    String? chiefComplaint,
    int? painScaleEva,
    Map<String, int>? jointRangeOfMotion,
    String? strengthTest,
    String? flexibilityTest,
    String? balanceTest,
    String? physioDiagnosis,
    String? shortTermGoals,
    String? mediumTermGoals,
    String? longTermGoals,
    bool? isReevaluation,
    String? comparedToEvaluationId,
    String? physioId,
    DateTime? createdAt,
  }) {
    return PatientEvaluation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      painScaleEva: painScaleEva ?? this.painScaleEva,
      jointRangeOfMotion: jointRangeOfMotion ?? this.jointRangeOfMotion,
      strengthTest: strengthTest ?? this.strengthTest,
      flexibilityTest: flexibilityTest ?? this.flexibilityTest,
      balanceTest: balanceTest ?? this.balanceTest,
      physioDiagnosis: physioDiagnosis ?? this.physioDiagnosis,
      shortTermGoals: shortTermGoals ?? this.shortTermGoals,
      mediumTermGoals: mediumTermGoals ?? this.mediumTermGoals,
      longTermGoals: longTermGoals ?? this.longTermGoals,
      isReevaluation: isReevaluation ?? this.isReevaluation,
      comparedToEvaluationId: comparedToEvaluationId ?? this.comparedToEvaluationId,
      physioId: physioId ?? this.physioId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'date': date.toIso8601String(),
      'chiefComplaint': chiefComplaint,
      'painScaleEva': painScaleEva,
      'jointRangeOfMotion': jointRangeOfMotion,
      'strengthTest': strengthTest,
      'flexibilityTest': flexibilityTest,
      'balanceTest': balanceTest,
      'physioDiagnosis': physioDiagnosis,
      'shortTermGoals': shortTermGoals,
      'mediumTermGoals': mediumTermGoals,
      'longTermGoals': longTermGoals,
      'isReevaluation': isReevaluation,
      'comparedToEvaluationId': comparedToEvaluationId,
      'physioId': physioId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientEvaluation.fromMap(Map<String, dynamic> map) {
    return PatientEvaluation(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      chiefComplaint: map['chiefComplaint'] ?? '',
      painScaleEva: map['painScaleEva'] ?? 0,
      jointRangeOfMotion: map['jointRangeOfMotion'] != null
          ? Map<String, int>.from(map['jointRangeOfMotion'])
          : {},
      strengthTest: map['strengthTest'] ?? '',
      flexibilityTest: map['flexibilityTest'] ?? '',
      balanceTest: map['balanceTest'] ?? '',
      physioDiagnosis: map['physioDiagnosis'] ?? '',
      shortTermGoals: map['shortTermGoals'] ?? '',
      mediumTermGoals: map['mediumTermGoals'] ?? '',
      longTermGoals: map['longTermGoals'] ?? '',
      isReevaluation: map['isReevaluation'] ?? false,
      comparedToEvaluationId: map['comparedToEvaluationId'],
      physioId: map['physioId'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
