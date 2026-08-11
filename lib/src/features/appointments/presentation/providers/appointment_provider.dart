import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/waiting_list_entry.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../data/repositories/firestore_appointment_repository.dart';
import '../../../patients/presentation/providers/notification_provider.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return FirestoreAppointmentRepository();
});

// Stream de todas las citas de la clínica del usuario logueado
final appointmentsStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.streamAppointments(clinicId: user.clinicId);
});

// Stream de la lista de espera
final waitingListStreamProvider = StreamProvider<List<WaitingListEntry>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.streamWaitingList(clinicId: user.clinicId);
});

// Futuro para obtener los terapeutas
final therapistsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return [];

  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getTherapists(clinicId: user.clinicId);
});

// Futuro para obtener las salas
final roomsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return [];

  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getRooms(clinicId: user.clinicId);
});

// Estado de UI de Citas
class AppointmentUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  AppointmentUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  AppointmentUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return AppointmentUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

// Controlador de Citas
class AppointmentController extends Notifier<AppointmentUiState> {
  @override
  AppointmentUiState build() {
    return AppointmentUiState();
  }

  // 1. Crear Cita / Bloqueo / Recurrente
  Future<void> bookAppointment({
    required String? patientId,
    required String? patientName,
    required String physioId,
    required String physioName,
    required String? roomId,
    required String? roomName,
    required DateTime dateTime,
    required int durationMinutes,
    required bool isBlocked,
    String? blockReason,
    required bool isRecurring,
    String? recurrencePattern,
  }) async {
    state = AppointmentUiState(isLoading: true);
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('No hay un usuario activo.');

      final repository = ref.read(appointmentRepositoryProvider);

      // A. Calcular todas las fechas a guardar (recurrentes o simple)
      final int intervalDays = (isRecurring && recurrencePattern != null)
          ? (recurrencePattern == 'weekly' ? 7 : 14)
          : 0;
      final int numInstances = (isRecurring && recurrencePattern != null) ? 4 : 1;

      final List<DateTime> datesToBook = List.generate(
        numInstances,
        (i) => dateTime.add(Duration(days: intervalDays * i)),
      );

      // B. Validar colisión para TODAS las instancias antes de guardar ninguna
      final appointments = await repository.getAppointments(clinicId: user.clinicId);

      for (final instanceDate in datesToBook) {
        final newStart = instanceDate;
        final newEnd = instanceDate.add(Duration(minutes: durationMinutes));

        for (var existing in appointments) {
          if (existing.status == AppointmentStatus.cancelled) continue;

          final start = existing.dateTime;
          final end = existing.dateTime.add(Duration(minutes: existing.durationMinutes));
          final overlaps = newStart.isBefore(end) && newEnd.isAfter(start);

          if (overlaps) {
            // Colisión de Fisioterapeuta
            if (existing.physioId == physioId) {
              throw Exception(
                'El fisioterapeuta ya tiene una cita el ${instanceDate.day}/${instanceDate.month} a las ${instanceDate.hour.toString().padLeft(2, '0')}:${instanceDate.minute.toString().padLeft(2, '0')}.',
              );
            }
            // Colisión de Sala
            if (roomId != null && existing.roomId == roomId) {
              throw Exception(
                'El consultorio ya está ocupado el ${instanceDate.day}/${instanceDate.month} a las ${instanceDate.hour.toString().padLeft(2, '0')}:${instanceDate.minute.toString().padLeft(2, '0')}.',
              );
            }
          }
        }
      }

      // C. Guardar Cita(s) en Firestore (sin colisiones)
      final parentId = const Uuid().v4();

      if (isRecurring && recurrencePattern != null) {
        for (int i = 0; i < numInstances; i++) {
          final instanceId = i == 0 ? parentId : const Uuid().v4();
          final app = Appointment(
            id: instanceId,
            clinicId: user.clinicId,
            patientId: patientId,
            patientName: patientName,
            physioId: physioId,
            physioName: physioName,
            roomId: roomId,
            roomName: roomName,
            dateTime: datesToBook[i],
            durationMinutes: durationMinutes,
            status: AppointmentStatus.pending,
            isBlocked: isBlocked,
            blockReason: blockReason,
            isRecurring: true,
            recurrencePattern: recurrencePattern,
            recurrenceParentId: i == 0 ? null : parentId,
          );
          await repository.addAppointment(app);
        }
        if (!isBlocked) {
          await ref.read(notificationControllerProvider.notifier).sendPatientNotification(
            patientId: patientId ?? '',
            title: 'Nuevas Citas Recurrentes',
            body: 'Se han programado $numInstances citas recurrentes con $physioName a partir del ${DateFormat('dd/MM/yyyy HH:mm').format(datesToBook.first)}.',
            type: 'appointment',
          );
        }
      } else {
        final app = Appointment(
          id: parentId,
          clinicId: user.clinicId,
          patientId: patientId,
          patientName: patientName,
          physioId: physioId,
          physioName: physioName,
          roomId: roomId,
          roomName: roomName,
          dateTime: dateTime,
          durationMinutes: durationMinutes,
          status: AppointmentStatus.pending,
          isBlocked: isBlocked,
          blockReason: blockReason,
          isRecurring: false,
        );
        await repository.addAppointment(app);
        if (!isBlocked) {
          await ref.read(notificationControllerProvider.notifier).sendPatientNotification(
            patientId: patientId ?? '',
            title: 'Nueva Cita Programada',
            body: 'Tu cita ha sido programada con $physioName para el ${DateFormat('dd/MM/yyyy HH:mm').format(dateTime)}.',
            type: 'appointment',
          );
        }
      }

      state = AppointmentUiState(success: true);
    } catch (e) {
      state = AppointmentUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 2. Cambiar Estado de Cita
  Future<void> updateAppointmentStatus(Appointment appointment, AppointmentStatus newStatus) async {
    state = AppointmentUiState(isLoading: true);
    try {
      final updated = appointment.copyWith(status: newStatus);
      await ref.read(appointmentRepositoryProvider).updateAppointment(updated);
      
      String statusMsg = '';
      if (newStatus == AppointmentStatus.completed) {
        statusMsg = 'completada y registrada';
      } else if (newStatus == AppointmentStatus.cancelled) {
        statusMsg = 'cancelada';
      } else if (newStatus == AppointmentStatus.confirmed) {
        statusMsg = 'confirmada';
      }
      
      if (statusMsg.isNotEmpty) {
        await ref.read(notificationControllerProvider.notifier).sendPatientNotification(
          patientId: appointment.patientId ?? '',
          title: 'Actualización de Cita',
          body: 'Tu cita del ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)} ha sido $statusMsg.',
          type: 'appointment',
        );
      }

      state = AppointmentUiState(success: true);
    } catch (e) {
      state = AppointmentUiState(errorMessage: e.toString());
    }
  }

  // 3. Eliminar / Cancelar Cita
  Future<void> cancelAppointment(String appointmentId) async {
    state = AppointmentUiState(isLoading: true);
    try {
      await ref.read(appointmentRepositoryProvider).deleteAppointment(appointmentId: appointmentId);
      state = AppointmentUiState(success: true);
    } catch (e) {
      state = AppointmentUiState(errorMessage: e.toString());
    }
  }

  // 4. Agregar a Lista de Espera
  Future<void> addPatientToWaitingList({
    required String patientId,
    required String patientName,
    String? preferredPhysioId,
    String? preferredRoomId,
    String? notes,
  }) async {
    state = AppointmentUiState(isLoading: true);
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('No hay un usuario activo.');

      final entryId = const Uuid().v4();
      final entry = WaitingListEntry(
        id: entryId,
        clinicId: user.clinicId,
        patientId: patientId,
        patientName: patientName,
        preferredPhysioId: preferredPhysioId,
        preferredRoomId: preferredRoomId,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await ref.read(appointmentRepositoryProvider).addToWaitingList(entry);
      state = AppointmentUiState(success: true);
    } catch (e) {
      state = AppointmentUiState(errorMessage: e.toString());
    }
  }

  // 5. Remover de Lista de Espera
  Future<void> removePatientFromWaitingList(String entryId) async {
    state = AppointmentUiState(isLoading: true);
    try {
      await ref.read(appointmentRepositoryProvider).removeFromWaitingList(entryId: entryId);
      state = AppointmentUiState(success: true);
    } catch (e) {
      state = AppointmentUiState(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Proveedor del controlador
final appointmentControllerProvider = NotifierProvider<AppointmentController, AppointmentUiState>(() {
  return AppointmentController();
});
