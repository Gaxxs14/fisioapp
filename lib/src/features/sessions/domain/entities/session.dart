class Session {
  final String id;
  final String clinicId;
  final String patientId;
  final String therapistId;
  final String therapistName;
  final String? appointmentId;
  final DateTime date;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final int painLevelPre;
  final int painLevelPost;
  final int durationMinutes;
  final List<String> techniques;
  final String observations;
  final List<String> photoPaths;  // local paths (used during capture only)
  final List<String> photoUrls;   // Firebase Storage URLs (persisted)
  final String? serviceId;
  final String? serviceName;
  final DateTime? updatedAt;

  Session({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.therapistId,
    required this.therapistName,
    this.appointmentId,
    required this.date,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    required this.painLevelPre,
    required this.painLevelPost,
    required this.durationMinutes,
    required this.techniques,
    required this.observations,
    required this.photoPaths,
    this.photoUrls = const [],
    this.serviceId,
    this.serviceName,
    this.updatedAt,
  });

  Session copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? therapistId,
    String? therapistName,
    String? appointmentId,
    DateTime? date,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    int? painLevelPre,
    int? painLevelPost,
    int? durationMinutes,
    List<String>? techniques,
    String? observations,
    List<String>? photoPaths,
    List<String>? photoUrls,
    String? serviceId,
    String? serviceName,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      appointmentId: appointmentId ?? this.appointmentId,
      date: date ?? this.date,
      subjective: subjective ?? this.subjective,
      objective: objective ?? this.objective,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      painLevelPre: painLevelPre ?? this.painLevelPre,
      painLevelPost: painLevelPost ?? this.painLevelPost,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      techniques: techniques ?? this.techniques,
      observations: observations ?? this.observations,
      photoPaths: photoPaths ?? this.photoPaths,
      photoUrls: photoUrls ?? this.photoUrls,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'patientId': patientId,
      'therapistId': therapistId,
      'therapistName': therapistName,
      'appointmentId': appointmentId,
      'date': date.toIso8601String(),
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'painLevelPre': painLevelPre,
      'painLevelPost': painLevelPost,
      'durationMinutes': durationMinutes,
      'techniques': techniques,
      'observations': observations,
      'photoPaths': photoPaths,
      'photoUrls': photoUrls,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      patientId: map['patientId'] ?? '',
      therapistId: map['therapistId'] ?? '',
      therapistName: map['therapistName'] ?? '',
      appointmentId: map['appointmentId'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      subjective: map['subjective'] ?? '',
      objective: map['objective'] ?? '',
      assessment: map['assessment'] ?? '',
      plan: map['plan'] ?? '',
      painLevelPre: map['painLevelPre'] ?? 0,
      painLevelPost: map['painLevelPost'] ?? 0,
      durationMinutes: map['durationMinutes'] ?? 30,
      techniques: List<String>.from(map['techniques'] ?? []),
      observations: map['observations'] ?? '',
      photoPaths: List<String>.from(map['photoPaths'] ?? []),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      serviceId: map['serviceId'],
      serviceName: map['serviceName'],
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
