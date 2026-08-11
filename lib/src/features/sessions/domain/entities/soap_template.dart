class SoapTemplate {
  final String id;
  final String clinicId;
  final String name;
  final String pathologyTag; // e.g. 'lumbar','hombro','rodilla','cervical','neurologico','deportivo','general'
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final List<String> defaultTechniques;
  final int? defaultDurationMinutes;

  SoapTemplate({
    required this.id,
    required this.clinicId,
    required this.name,
    this.pathologyTag = 'general',
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    required this.defaultTechniques,
    this.defaultDurationMinutes,
  });

  SoapTemplate copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? pathologyTag,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    List<String>? defaultTechniques,
    int? defaultDurationMinutes,
  }) {
    return SoapTemplate(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      pathologyTag: pathologyTag ?? this.pathologyTag,
      subjective: subjective ?? this.subjective,
      objective: objective ?? this.objective,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
      defaultTechniques: defaultTechniques ?? this.defaultTechniques,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'name': name,
      'pathologyTag': pathologyTag,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
      'defaultTechniques': defaultTechniques,
      'defaultDurationMinutes': defaultDurationMinutes,
    };
  }

  factory SoapTemplate.fromMap(Map<String, dynamic> map) {
    return SoapTemplate(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      name: map['name'] ?? '',
      pathologyTag: map['pathologyTag'] ?? 'general',
      subjective: map['subjective'] ?? '',
      objective: map['objective'] ?? '',
      assessment: map['assessment'] ?? '',
      plan: map['plan'] ?? '',
      defaultTechniques: List<String>.from(map['defaultTechniques'] ?? []),
      defaultDurationMinutes: map['defaultDurationMinutes'] as int?,
    );
  }
}
