import 'package:cloud_firestore/cloud_firestore.dart';

class PatientBono {
  final String id;
  final String clinicId;
  final String patientId;
  final String serviceId;
  final String serviceName;
  final int purchasedSessions;
  final int remainingSessions;
  final DateTime expirationDate;
  final bool isPaid;

  const PatientBono({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.serviceId,
    required this.serviceName,
    required this.purchasedSessions,
    required this.remainingSessions,
    required this.expirationDate,
    this.isPaid = true,
  });

  PatientBono copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? serviceId,
    String? serviceName,
    int? purchasedSessions,
    int? remainingSessions,
    DateTime? expirationDate,
    bool? isPaid,
  }) {
    return PatientBono(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      purchasedSessions: purchasedSessions ?? this.purchasedSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      expirationDate: expirationDate ?? this.expirationDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'patientId': patientId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'purchasedSessions': purchasedSessions,
      'remainingSessions': remainingSessions,
      'expirationDate': Timestamp.fromDate(expirationDate),
      'isPaid': isPaid,
    };
  }

  factory PatientBono.fromMap(Map<String, dynamic> map, String docId) {
    return PatientBono(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      patientId: map['patientId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      purchasedSessions: map['purchasedSessions'] ?? 0,
      remainingSessions: map['remainingSessions'] ?? 0,
      expirationDate: (map['expirationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: map['isPaid'] ?? true,
    );
  }
}
