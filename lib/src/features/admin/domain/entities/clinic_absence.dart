class ClinicAbsence {
  final String id;
  final String clinicId;
  final String userId;
  final String userName;
  final DateTime startDate;
  final DateTime endDate;
  final String reason; // 'vacaciones', 'enfermedad', 'personal', 'otro'
  final String notes;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedByAdminId;

  ClinicAbsence({
    required this.id,
    required this.clinicId,
    required this.userId,
    required this.userName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.notes = '',
    this.status = 'approved',
    this.approvedByAdminId,
  });

  ClinicAbsence copyWith({
    String? id,
    String? clinicId,
    String? userId,
    String? userName,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? notes,
    String? status,
    String? approvedByAdminId,
  }) {
    return ClinicAbsence(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      approvedByAdminId: approvedByAdminId ?? this.approvedByAdminId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'userId': userId,
      'userName': userName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'notes': notes,
      'status': status,
      'approvedByAdminId': approvedByAdminId,
    };
  }

  factory ClinicAbsence.fromMap(Map<String, dynamic> map, String docId) {
    return ClinicAbsence(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : DateTime.now(),
      reason: map['reason'] ?? 'otro',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'approved',
      approvedByAdminId: map['approvedByAdminId'],
    );
  }
}
