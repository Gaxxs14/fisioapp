enum UserRole {
  admin,
  physio,
  receptionist,
  superadmin;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.physio:
        return 'Fisioterapeuta';
      case UserRole.receptionist:
        return 'Recepcionista';
      case UserRole.superadmin:
        return 'Super-Administrador';
    }
  }
}

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String username; // Nombre de usuario único para login
  final String clinicId;
  final UserRole role;
  final String? specialty;
  final String? photoUrl;
  final List<String>? workDays;
  final String? workHoursStart;
  final String? workHoursEnd;
  final DateTime lastPasswordChange;
  final Map<String, String>? securityQuestions;
  final DateTime createdAt;
  final bool isActive;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.username,
    required this.clinicId,
    required this.role,
    this.specialty,
    this.photoUrl,
    this.workDays,
    this.workHoursStart,
    this.workHoursEnd,
    required this.lastPasswordChange,
    this.securityQuestions,
    required this.createdAt,
    this.isActive = true,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? username,
    String? clinicId,
    UserRole? role,
    String? specialty,
    String? photoUrl,
    List<String>? workDays,
    String? workHoursStart,
    String? workHoursEnd,
    DateTime? lastPasswordChange,
    Map<String, String>? securityQuestions,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      clinicId: clinicId ?? this.clinicId,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      photoUrl: photoUrl ?? this.photoUrl,
      workDays: workDays ?? this.workDays,
      workHoursStart: workHoursStart ?? this.workHoursStart,
      workHoursEnd: workHoursEnd ?? this.workHoursEnd,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      securityQuestions: securityQuestions ?? this.securityQuestions,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'username': username,
      'clinicId': clinicId,
      'role': role.name,
      'specialty': specialty,
      'photoUrl': photoUrl,
      'workDays': workDays,
      'workHoursStart': workHoursStart,
      'workHoursEnd': workHoursEnd,
      'lastPasswordChange': lastPasswordChange.toIso8601String(),
      'securityQuestions': securityQuestions,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppUser(
      uid: docId ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? map['email'] ?? '',
      clinicId: map['clinicId'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.physio,
      ),
      specialty: map['specialty'],
      photoUrl: map['photoUrl'],
      workDays: map['workDays'] != null ? List<String>.from(map['workDays']) : null,
      workHoursStart: map['workHoursStart'],
      workHoursEnd: map['workHoursEnd'],
      lastPasswordChange: map['lastPasswordChange'] != null
          ? DateTime.parse(map['lastPasswordChange'])
          : DateTime.now(),
      securityQuestions: map['securityQuestions'] != null
          ? Map<String, String>.from(map['securityQuestions'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  bool get isPasswordExpired {
    final difference = DateTime.now().difference(lastPasswordChange).inDays;
    return difference >= 30;
  }
}
