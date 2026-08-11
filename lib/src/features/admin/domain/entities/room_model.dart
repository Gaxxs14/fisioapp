class RoomModel {
  final String id;
  final String clinicId;
  final String name;
  final String colorHex;
  final bool isActive;

  const RoomModel({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.colorHex,
    this.isActive = true,
  });

  RoomModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? colorHex,
    bool? isActive,
  }) {
    return RoomModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'name': name,
      'colorHex': colorHex,
      'isActive': isActive,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, String docId) {
    return RoomModel(
      id: docId,
      clinicId: map['clinicId'] ?? '',
      name: map['name'] ?? '',
      colorHex: map['colorHex'] ?? '#0F766E',
      isActive: map['isActive'] ?? true,
    );
  }
}
