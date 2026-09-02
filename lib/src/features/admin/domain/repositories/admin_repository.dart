import '../entities/room_model.dart';
import '../entities/clinic_absence.dart';
import '../../../auth/domain/entities/app_user.dart';

abstract class AdminRepository {
  // Salas / Consultorios
  Stream<List<RoomModel>> watchRooms({required String clinicId});
  Future<void> saveRoom(RoomModel room);
  Future<void> deleteRoom({required String roomId});

  // Gestión de Personal (Terapeutas y Recepcionistas)
  Stream<List<AppUser>> watchStaff({required String clinicId});
  Future<void> saveStaffUser(AppUser user, String password);
  Future<void> toggleStaffStatus({required String uid, required bool isActive});
  Future<void> deleteStaffUser({required String uid});
  Future<void> updateUserWorkSchedule({
    required String uid,
    required List<String> workDays,
    required String workHoursStart,
    required String workHoursEnd,
  });

  // Ausencias
  Stream<List<ClinicAbsence>> watchAbsences({required String clinicId});
  Future<void> saveAbsence(ClinicAbsence absence);
  Future<void> deleteAbsence({required String absenceId});
}

