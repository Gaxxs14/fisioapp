import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/soap_template.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../billing/domain/entities/transaction_model.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../domain/repositories/session_repository.dart';
import '../../data/repositories/firestore_session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FirestoreSessionRepository();
});

// Stream de todas las sesiones de un paciente específico
final sessionsStreamProvider = StreamProvider.family<List<Session>, String>((ref, patientId) {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(sessionRepositoryProvider);
  return repository.watchSessions(user.clinicId, patientId);
});

// Stream de todas las plantillas SOAP de la clínica
final soapTemplatesStreamProvider = StreamProvider<List<SoapTemplate>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(sessionRepositoryProvider);
  return repository.watchSoapTemplates(user.clinicId);
});

// Provider para obtener una sesión existente por ID (modo edición)
final sessionByIdProvider = FutureProvider.family<Session?, String>((ref, sessionId) async {
  if (sessionId.isEmpty) return null;
  final repository = ref.read(sessionRepositoryProvider);
  return repository.getSessionById(sessionId);
});

// Estado de UI para sesiones
class SessionUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  SessionUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  SessionUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return SessionUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

// Controlador de Sesiones Clínicas y Plantillas SOAP
class SessionController extends Notifier<SessionUiState> {
  @override
  SessionUiState build() {
    return SessionUiState();
  }

  // Guardar una sesión clínica y marcar la cita como realizada (si aplica)
  Future<void> saveSession(Session session) async {
    state = SessionUiState(isLoading: true);
    try {
      final repository = ref.read(sessionRepositoryProvider);
      await repository.saveSession(session);

      // Obtener el nombre del paciente real para la transacción
      String patientName = 'Paciente';
      try {
        final patientRepo = ref.read(patientRepositoryProvider);
        final patientsList = await patientRepo.getPatients(clinicId: session.clinicId);
        final patientMatch = patientsList.where((p) => p.id == session.patientId);
        if (patientMatch.isNotEmpty) {
          patientName = patientMatch.first.name;
        }
      } catch (_) {}

      // Si viene vinculada a una cita, marcarla como realizada (completed)
      if (session.appointmentId != null && session.appointmentId!.isNotEmpty) {
        final appointmentRepo = ref.read(appointmentRepositoryProvider);
        final appointments = await appointmentRepo.getAppointments(clinicId: session.clinicId);
        final matchIndex = appointments.indexWhere((a) => a.id == session.appointmentId);
        if (matchIndex != -1) {
          final matchedAppointment = appointments[matchIndex];
          if (patientName == 'Paciente') {
            patientName = matchedAppointment.patientName ?? 'Paciente';
          }
          final updated = matchedAppointment.copyWith(status: AppointmentStatus.completed);
          await appointmentRepo.updateAppointment(updated);
        }
      }

      // Descuento automático del bono al marcar sesión realizada
      if (session.serviceId != null) {
        final billingRepo = ref.read(billingRepositoryProvider);
        final bonos = await billingRepo.watchPatientBonos(
          clinicId: session.clinicId,
          patientId: session.patientId,
        ).first;
        
        final activeMatches = bonos.where((b) =>
            b.serviceId == session.serviceId &&
            b.remainingSessions > 0 &&
            b.expirationDate.isAfter(DateTime.now()));

        if (activeMatches.isNotEmpty) {
          final matchedBono = activeMatches.first;
          
          // 1. Decrementar 1 sesión del bono
          await billingRepo.consumeBonoSession(
            clinicId: session.clinicId,
            patientId: session.patientId,
            bonoId: matchedBono.id,
            therapistName: session.therapistName,
          );

          // 2. Registrar transacción contable de consumo de bono (monto $0.00)
          final transaction = TransactionModel(
            id: '',
            clinicId: session.clinicId,
            patientId: session.patientId,
            patientName: patientName,
            date: DateTime.now(),
            concept: 'Consumo de Bono: ${session.serviceName ?? 'Servicio'}',
            amount: 0.0,
            paymentMethod: 'bono',
            bonoId: matchedBono.id,
          );
          await billingRepo.saveTransaction(transaction);
        }
      }

      state = SessionUiState(success: true);
    } catch (e) {
      state = SessionUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Actualizar una sesión existente (modo edición — no reasigna cita ni bono)
  Future<void> updateSession(Session session) async {
    state = SessionUiState(isLoading: true);
    try {
      final repository = ref.read(sessionRepositoryProvider);
      final updated = session.copyWith(updatedAt: DateTime.now());
      await repository.saveSession(updated);
      state = SessionUiState(success: true);
    } catch (e) {
      state = SessionUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Eliminar una sesión
  Future<void> deleteSession(String sessionId) async {
    state = SessionUiState(isLoading: true);
    try {
      await ref.read(sessionRepositoryProvider).deleteSession(sessionId);
      state = SessionUiState(success: true);
    } catch (e) {
      state = SessionUiState(errorMessage: e.toString());
    }
  }

  // Guardar una nueva plantilla SOAP
  Future<void> saveSoapTemplate(SoapTemplate template) async {
    state = SessionUiState(isLoading: true);
    try {
      await ref.read(sessionRepositoryProvider).saveSoapTemplate(template);
      state = SessionUiState(success: true);
    } catch (e) {
      state = SessionUiState(errorMessage: e.toString());
    }
  }

  // Eliminar una plantilla SOAP
  Future<void> deleteSoapTemplate(String templateId) async {
    state = SessionUiState(isLoading: true);
    try {
      await ref.read(sessionRepositoryProvider).deleteSoapTemplate(templateId);
      state = SessionUiState(success: true);
    } catch (e) {
      state = SessionUiState(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Proveedor global para el controlador
final sessionControllerProvider = NotifierProvider<SessionController, SessionUiState>(() {
  return SessionController();
});
