import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// Proveedor del repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Stream que vigila los cambios de sesión del usuario en tiempo real
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Estado de la UI de autenticación (Loading, Error o Éxito)
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AppUser? user;
  final bool isPasswordExpired;
  final bool success;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.isPasswordExpired = false,
    this.success = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AppUser? user,
    bool? isPasswordExpired,
    bool? success,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se limpia si es null explícito
      user: user ?? this.user,
      isPasswordExpired: isPasswordExpired ?? this.isPasswordExpired,
      success: success ?? this.success,
    );
  }
}

// Controlador de autenticación
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  /// Login con nombre de usuario y contraseña (sin selección de clínica)
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signInWithUsername(
        username: username,
        password: password,
      );

      state = AuthState(
        user: user,
        isPasswordExpired: user.isPasswordExpired,
        success: true,
      );
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Registro de nueva clínica con nombre de usuario único
  Future<void> registerClinic({
    required String clinicName,
    required String ownerName,
    required String username,
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.registerClinic(
        clinicName: clinicName,
        ownerName: ownerName,
        username: username,
        email: email,
        password: password,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      // Cerrar sesión inmediatamente para evitar el auto-login automático de Firebase
      await repository.signOut();
      state = AuthState(success: true);
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = AuthState();
    } catch (e) {
      state = AuthState(errorMessage: e.toString());
    }
  }

  Future<void> changePassword(String newPassword) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updatePassword(newPassword);
      final currentUser = await repository.getCurrentUser();
      state = AuthState(user: currentUser, success: true);
    } catch (e) {
      state = AuthState(
        user: state.user,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> verifyAndResetPassword({
    required String username,
    required String securityAnswer,
    required String newPassword,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.verifyAndResetPassword(
        username: username,
        securityAnswer: securityAnswer,
        newPassword: newPassword,
      );
      state = AuthState(success: true);
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<String?> getSecurityQuestion(String username) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final question = await repository.getSecurityQuestion(username);
      state = AuthState(success: true);
      return question;
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updateUserProfile(user);
      state = state.copyWith(user: user, success: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearSuccess() {
    state = state.copyWith(success: false);
  }
}

// Proveedor del controlador
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

// Notifier para rastrear el éxito de autenticación local (huella digital o password manual)
class LocalAuthSuccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
}

final localAuthSuccessProvider = NotifierProvider<LocalAuthSuccessNotifier, bool>(() {
  return LocalAuthSuccessNotifier();
});
