class Patient {
  final String id;
  final String clinicId;
  final String name;
  final String dni;
  final String email;
  final String phone;
  final DateTime birthDate;
  final String gender;
  final String contactPersonName;
  final String contactPersonPhone;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isInactive;

  Patient({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.dni,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.contactPersonName,
    required this.contactPersonPhone,
    this.photoUrl,
    required this.createdAt,
    this.isInactive = false,
  });

  Patient copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? dni,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? contactPersonName,
    String? contactPersonPhone,
    String? photoUrl,
    DateTime? createdAt,
    bool? isInactive,
  }) {
    return Patient(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      dni: dni ?? this.dni,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonPhone: contactPersonPhone ?? this.contactPersonPhone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isInactive: isInactive ?? this.isInactive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'name': name,
      'dni': dni,
      'email': email,
      'phone': phone,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'contactPersonName': contactPersonName,
      'contactPersonPhone': contactPersonPhone,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isInactive': isInactive,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      name: map['name'] ?? '',
      dni: map['dni'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : DateTime.now(),
      gender: map['gender'] ?? '',
      contactPersonName: map['contactPersonName'] ?? '',
      contactPersonPhone: map['contactPersonPhone'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      isInactive: map['isInactive'] ?? false,
    );
  }

  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
