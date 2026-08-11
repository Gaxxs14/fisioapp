import '../entities/appointment.dart';
import '../entities/waiting_list_entry.dart';

abstract class AppointmentRepository {
  Stream<List<Appointment>> streamAppointments({required String clinicId});

  Future<List<Appointment>> getAppointments({required String clinicId});

  Future<void> addAppointment(Appointment appointment);

  Future<void> updateAppointment(Appointment appointment);

  Future<void> deleteAppointment({required String appointmentId});

  Stream<List<WaitingListEntry>> streamWaitingList({required String clinicId});

  Future<void> addToWaitingList(WaitingListEntry entry);

  Future<void> removeFromWaitingList({required String entryId});

  Future<List<Map<String, dynamic>>> getTherapists({required String clinicId});

  Future<List<Map<String, dynamic>>> getRooms({required String clinicId});
}
