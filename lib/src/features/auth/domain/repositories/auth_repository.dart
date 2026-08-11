import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser?> getCurrentUser();

  // Nuevo: login por nombre de usuario (sin dropdown de clínica)
  Future<AppUser> signInWithUsername({
    required String username,
    required String password,
  });

  Future<AppUser> registerClinic({
    required String clinicName,
    required String ownerName,
    required String username,   // Nuevo campo: nombre de usuario único
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  });

  Future<void> signOut();

  Future<void> updatePassword(String newPassword);

  Future<void> verifyAndResetPassword({
    required String username,
    required String securityAnswer,
    required String newPassword,
  });

  Future<String> getSecurityQuestion(String username);

  Future<void> updateUserProfile(AppUser user);
}
