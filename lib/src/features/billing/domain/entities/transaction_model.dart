import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String patientName;
  final DateTime date;
  final String concept;
  final double amount;
  final String paymentMethod; // cash, card, transfer, pending, bono
  final String? referenceCode;
  final bool isBonoSale;
  final String? bonoId;

  const TransactionModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.concept,
    required this.amount,
    required this.paymentMethod,
    this.referenceCode,
    this.isBonoSale = false,
    this.bonoId,
  });

  TransactionModel copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? patientName,
    DateTime? date,
    String? concept,
    double? amount,
    String? paymentMethod,
    String? referenceCode,
    bool? isBonoSale,
    String? bonoId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      concept: concept ?? this.concept,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceCode: referenceCode ?? this.referenceCode,
      isBonoSale: isBonoSale ?? this.isBonoSale,
      bonoId: bonoId ?? this.bonoId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'patientId': patientId,
      'patientName': patientName,
      'date': Timestamp.fromDate(date),
      'concept': concept,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'referenceCode': referenceCode,
      'isBonoSale': isBonoSale,
      'bonoId': bonoId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TransactionModel(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      concept: map['concept'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'cash',
      referenceCode: map['referenceCode'],
      isBonoSale: map['isBonoSale'] ?? false,
      bonoId: map['bonoId'],
    );
  }
}
