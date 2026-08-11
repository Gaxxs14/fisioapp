class ServiceModel {
  final String id;
  final String clinicId;
  final String name;
  final int durationMinutes;
  final double price;
  final String colorHex;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.colorHex,
    this.isActive = true,
  });

  ServiceModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    int? durationMinutes,
    double? price,
    String? colorHex,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'name': name,
      'durationMinutes': durationMinutes,
      'price': price,
      'colorHex': colorHex,
      'isActive': isActive,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceModel(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      name: map['name'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      colorHex: map['colorHex'] ?? '#0F766E',
      isActive: map['isActive'] ?? true,
    );
  }
}
