class ClinicalHistory {
  final String patientId;
  final String antecedents;
  final String medications;
  final String allergies;
  final String surgeries;
  final DateTime updatedAt;

  ClinicalHistory({
    required this.patientId,
    required this.antecedents,
    required this.medications,
    required this.allergies,
    required this.surgeries,
    required this.updatedAt,
  });

  ClinicalHistory copyWith({
    String? patientId,
    String? antecedents,
    String? medications,
    String? allergies,
    String? surgeries,
    DateTime? updatedAt,
  }) {
    return ClinicalHistory(
      patientId: patientId ?? this.patientId,
      antecedents: antecedents ?? this.antecedents,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      surgeries: surgeries ?? this.surgeries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'antecedents': antecedents,
      'medications': medications,
      'allergies': allergies,
      'surgeries': surgeries,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClinicalHistory.fromMap(Map<String, dynamic> map, String patientId) {
    return ClinicalHistory(
      patientId: patientId,
      antecedents: map['antecedents'] ?? '',
      medications: map['medications'] ?? '',
      allergies: map['allergies'] ?? '',
      surgeries: map['surgeries'] ?? '',
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}
