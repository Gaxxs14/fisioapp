enum AppointmentStatus {
  pending,
  confirmed,
  ongoing,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.ongoing:
        return 'En Curso';
      case AppointmentStatus.completed:
        return 'Realizada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.noShow:
        return 'Ausente';
    }
  }
}

class Appointment {
  final String id;
  final String clinicId;
  final String? patientId;
  final String? patientName;
  final String physioId;
  final String physioName;
  final String? roomId;
  final String? roomName;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final bool isBlocked;
  final String? blockReason;
  final bool isRecurring;
  final String? recurrencePattern; // e.g. "weekly", "biweekly"
  final String? recurrenceParentId;

  Appointment({
    required this.id,
    required this.clinicId,
    this.patientId,
    this.patientName,
    required this.physioId,
    required this.physioName,
    this.roomId,
    this.roomName,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    required this.isBlocked,
    this.blockReason,
    required this.isRecurring,
    this.recurrencePattern,
    this.recurrenceParentId,
  });

  Appointment copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? patientName,
    String? physioId,
    String? physioName,
    String? roomId,
    String? roomName,
    DateTime? dateTime,
    int? durationMinutes,
    AppointmentStatus? status,
    bool? isBlocked,
    String? blockReason,
    bool? isRecurring,
    String? recurrencePattern,
    String? recurrenceParentId,
  }) {
    return Appointment(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      physioId: physioId ?? this.physioId,
      physioName: physioName ?? this.physioName,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceParentId: recurrenceParentId ?? this.recurrenceParentId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'patientId': patientId,
      'patientName': patientName,
      'physioId': physioId,
      'physioName': physioName,
      'roomId': roomId,
      'roomName': roomName,
      'dateTime': dateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status.name,
      'isBlocked': isBlocked,
      'blockReason': blockReason,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'recurrenceParentId': recurrenceParentId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      patientId: map['patientId'],
      patientName: map['patientName'],
      physioId: map['physioId'] ?? '',
      physioName: map['physioName'] ?? '',
      roomId: map['roomId'],
      roomName: map['roomName'],
      dateTime: map['dateTime'] != null ? DateTime.parse(map['dateTime']) : DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 30,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      isBlocked: map['isBlocked'] ?? false,
      blockReason: map['blockReason'],
      isRecurring: map['isRecurring'] ?? false,
      recurrencePattern: map['recurrencePattern'],
      recurrenceParentId: map['recurrenceParentId'],
    );
  }
}
