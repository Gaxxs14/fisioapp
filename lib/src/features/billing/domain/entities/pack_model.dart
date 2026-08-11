class PackModel {
  final String id;
  final String clinicId;
  final String name;
  final String serviceId;
  final int totalSessions;
  final double price;
  final int expirationMonths;
  final bool isActive;

  const PackModel({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.serviceId,
    required this.totalSessions,
    required this.price,
    required this.expirationMonths,
    this.isActive = true,
  });

  PackModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? serviceId,
    int? totalSessions,
    double? price,
    int? expirationMonths,
    bool? isActive,
  }) {
    return PackModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      serviceId: serviceId ?? this.serviceId,
      totalSessions: totalSessions ?? this.totalSessions,
      price: price ?? this.price,
      expirationMonths: expirationMonths ?? this.expirationMonths,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'name': name,
      'serviceId': serviceId,
      'totalSessions': totalSessions,
      'price': price,
      'expirationMonths': expirationMonths,
      'isActive': isActive,
    };
  }

  factory PackModel.fromMap(Map<String, dynamic> map, String docId) {
    return PackModel(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      name: map['name'] ?? '',
      serviceId: map['serviceId'] ?? '',
      totalSessions: map['totalSessions'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      expirationMonths: map['expirationMonths'] ?? 12,
      isActive: map['isActive'] ?? true,
    );
  }
}
