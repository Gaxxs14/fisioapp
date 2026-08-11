class HomeExerciseModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String title;
  final String instructions;
  final String? videoUrl;
  final String repetitions;
  final bool isCompleted;
  final DateTime assignedDate;

  const HomeExerciseModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.title,
    required this.instructions,
    this.videoUrl,
    required this.repetitions,
    this.isCompleted = false,
    required this.assignedDate,
  });

  HomeExerciseModel copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? title,
    String? instructions,
    String? videoUrl,
    String? repetitions,
    bool? isCompleted,
    DateTime? assignedDate,
  }) {
    return HomeExerciseModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      repetitions: repetitions ?? this.repetitions,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedDate: assignedDate ?? this.assignedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'patientId': patientId,
      'title': title,
      'instructions': instructions,
      'videoUrl': videoUrl,
      'repetitions': repetitions,
      'isCompleted': isCompleted,
      'assignedDate': assignedDate.toIso8601String(),
    };
  }

  factory HomeExerciseModel.fromMap(Map<String, dynamic> map, String docId) {
    return HomeExerciseModel(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      patientId: map['patientId'] ?? '',
      title: map['title'] ?? '',
      instructions: map['instructions'] ?? '',
      videoUrl: map['videoUrl'],
      repetitions: map['repetitions'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      assignedDate: map['assignedDate'] != null ? DateTime.parse(map['assignedDate']) : DateTime.now(),
    );
  }
}
