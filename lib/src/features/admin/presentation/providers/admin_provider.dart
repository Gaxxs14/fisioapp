import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/room_model.dart';
import '../../domain/entities/clinic_absence.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/repositories/firestore_admin_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../sessions/domain/entities/session.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirestoreAdminRepository();
});

// Stream para las salas de la clínica
final roomsStreamProvider = StreamProvider<List<RoomModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(adminRepositoryProvider).watchRooms(clinicId: clinicId);
});

// Stream para los profesionales de la clínica
final professionalsStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(adminRepositoryProvider).watchStaff(clinicId: clinicId);
});

// Stream para las ausencias de la clínica
final absencesStreamProvider = StreamProvider<List<ClinicAbsence>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(adminRepositoryProvider).watchAbsences(clinicId: clinicId);
});

// Future para todas las sesiones de la clínica (métricas)
final adminClinicSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('sessions')
      .where('clinicId', isEqualTo: clinicId)
      .get();

  return snapshot.docs
      .map((doc) => Session.fromMap(doc.data()))
      .toList();
});


// Estado de la UI para administración
class AdminUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const AdminUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  AdminUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return AdminUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class AdminController extends Notifier<AdminUiState> {
  @override
  AdminUiState build() {
    return const AdminUiState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearSuccess() {
    state = state.copyWith(success: false);
  }

  Future<void> addRoom({
    required String name,
    required String colorHex,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      
      final room = RoomModel(
        id: '',
        clinicId: clinicId,
        name: name,
        colorHex: colorHex,
      );

      await repository.saveRoom(room);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteRoom({required String roomId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      await repository.deleteRoom(roomId: roomId);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addStaffUser({
    required String name,
    required String username,
    required String email,
    required String specialty,
    required UserRole role,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      
      final newUser = AppUser(
        uid: '',
        clinicId: clinicId,
        name: name,
        email: email,
        username: username,
        role: role,
        specialty: specialty,
        lastPasswordChange: DateTime.now(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      await repository.saveStaffUser(newUser, password);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleProfessionalStatus({
    required String uid,
    required bool isActive,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      await repository.toggleStaffStatus(uid: uid, isActive: isActive);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateStaffWorkSchedule({
    required String uid,
    required List<String> workDays,
    required String workHoursStart,
    required String workHoursEnd,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      await repository.updateUserWorkSchedule(
        uid: uid,
        workDays: workDays,
        workHoursStart: workHoursStart,
        workHoursEnd: workHoursEnd,
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addAbsence({
    required String userId,
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';

      final absence = ClinicAbsence(
        id: '',
        clinicId: clinicId,
        userId: userId,
        userName: userName,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        notes: notes,
        status: 'approved', // Por defecto aprobada ya que la registra el administrador
      );

      await repository.saveAbsence(absence);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteAbsence({required String absenceId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(adminRepositoryProvider);
      await repository.deleteAbsence(absenceId: absenceId);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final adminControllerProvider = NotifierProvider<AdminController, AdminUiState>(() {
  return AdminController();
});
