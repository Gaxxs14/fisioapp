class WaitingListEntry {
  final String id;
  final String clinicId;
  final String patientId;
  final String patientName;
  final String? preferredPhysioId;
  final String? preferredRoomId;
  final String? notes;
  final DateTime createdAt;

  WaitingListEntry({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.patientName,
    this.preferredPhysioId,
    this.preferredRoomId,
    this.notes,
    required this.createdAt,
  });

  WaitingListEntry copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? patientName,
    String? preferredPhysioId,
    String? preferredRoomId,
    String? notes,
    DateTime? createdAt,
  }) {
    return WaitingListEntry(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      preferredPhysioId: preferredPhysioId ?? this.preferredPhysioId,
      preferredRoomId: preferredRoomId ?? this.preferredRoomId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'patientId': patientId,
      'patientName': patientName,
      'preferredPhysioId': preferredPhysioId,
      'preferredRoomId': preferredRoomId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WaitingListEntry.fromMap(Map<String, dynamic> map) {
    return WaitingListEntry(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      preferredPhysioId: map['preferredPhysioId'],
      preferredRoomId: map['preferredRoomId'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
