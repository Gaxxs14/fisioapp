import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/clinical_history.dart';
import '../../domain/entities/patient_evaluation.dart';
import '../../domain/repositories/patient_repository.dart';
import '../../data/repositories/firestore_patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return FirestorePatientRepository();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Stream de pacientes ligados a la clínica activa del usuario logueado
final patientsStreamProvider = StreamProvider<List<Patient>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final user = authStateAsync.value;
  if (user == null) return Stream.value([]);
  
  final repository = ref.watch(patientRepositoryProvider);
  return repository.streamPatients(clinicId: user.clinicId);
});

// Futuro para cargar el expediente clínico de un paciente específico
final clinicalHistoryProvider = FutureProvider.family<ClinicalHistory, String>((ref, patientId) async {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getClinicalHistory(patientId: patientId);
});

// Futuro para cargar todas las evaluaciones de un paciente específico
final evaluationsProvider = FutureProvider.family<List<PatientEvaluation>, String>((ref, patientId) async {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getEvaluations(patientId: patientId);
});

// Futuro para cargar los adjuntos (radiografías/estudios) de un paciente
final attachmentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, patientId) async {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getAttachments(patientId: patientId);
});

// Futuro para cargar el estado del consentimiento informado de un paciente
final consentProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, patientId) async {
  final repository = ref.watch(patientRepositoryProvider);
  return repository.getConsent(patientId: patientId);
});

// Estado de UI de Pacientes
class PatientUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  PatientUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  PatientUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return PatientUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se limpia si es null
      success: success ?? this.success,
    );
  }
}

// Controlador de Pacientes
class PatientController extends Notifier<PatientUiState> {
  @override
  PatientUiState build() {
    return PatientUiState();
  }

  // 1. Crear Paciente
  Future<void> createPatient({
    required String name,
    required String dni,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String gender,
    required String contactPersonName,
    required String contactPersonPhone,
  }) async {
    state = PatientUiState(isLoading: true);
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('No hay un usuario activo en sesión.');

      final patientId = const Uuid().v4();
      final newPatient = Patient(
        id: patientId,
        clinicId: user.clinicId,
        name: name,
        dni: dni,
        email: email,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        contactPersonName: contactPersonName,
        contactPersonPhone: contactPersonPhone,
        createdAt: DateTime.now(),
      );

      await ref.read(patientRepositoryProvider).addPatient(newPatient);
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 2. Actualizar Paciente
  Future<void> updatePatient(Patient patient) async {
    state = PatientUiState(isLoading: true);
    try {
      await ref.read(patientRepositoryProvider).updatePatient(patient);
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString());
    }
  }

  // 3. Guardar Historia Clínica
  Future<void> saveClinicalHistory(ClinicalHistory history) async {
    state = PatientUiState(isLoading: true);
    try {
      await ref.read(patientRepositoryProvider).updateClinicalHistory(history);
      ref.invalidate(clinicalHistoryProvider(history.patientId)); // Forzar refresco
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString());
    }
  }

  // 4. Agregar Evaluación
  Future<void> addEvaluation({
    required String patientId,
    required String chiefComplaint,
    required int painScaleEva,
    required Map<String, int> jointRangeOfMotion,
    required String strengthTest,
    required String flexibilityTest,
    required String balanceTest,
    required String physioDiagnosis,
    required String shortTermGoals,
    required String mediumTermGoals,
    required String longTermGoals,
    required bool isReevaluation,
    String? comparedToEvaluationId,
  }) async {
    state = PatientUiState(isLoading: true);
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('No hay un fisioterapeuta activo.');

      final evaluationId = const Uuid().v4();
      final newEvaluation = PatientEvaluation(
        id: evaluationId,
        patientId: patientId,
        date: DateTime.now(),
        chiefComplaint: chiefComplaint,
        painScaleEva: painScaleEva,
        jointRangeOfMotion: jointRangeOfMotion,
        strengthTest: strengthTest,
        flexibilityTest: flexibilityTest,
        balanceTest: balanceTest,
        physioDiagnosis: physioDiagnosis,
        shortTermGoals: shortTermGoals,
        mediumTermGoals: mediumTermGoals,
        longTermGoals: longTermGoals,
        isReevaluation: isReevaluation,
        comparedToEvaluationId: comparedToEvaluationId,
        physioId: user.uid,
        createdAt: DateTime.now(),
      );

      await ref.read(patientRepositoryProvider).addEvaluation(
            patientId: patientId,
            evaluation: newEvaluation,
          );
          
      ref.invalidate(evaluationsProvider(patientId)); // Forzar refresco
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 5. Cargar Estudio / Adjunto
  Future<void> uploadAttachment({
    required String patientId,
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    state = PatientUiState(isLoading: true);
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('No hay un usuario activo.');

      final storagePath = 'clinics/${user.clinicId}/patients/$patientId/attachments/$fileName';
      final downloadUrl = await ref.read(storageServiceProvider).uploadFile(
            path: storagePath,
            filePath: filePath,
          );

      final attachmentId = const Uuid().v4();
      final attachment = {
        'id': attachmentId,
        'fileName': fileName,
        'fileType': fileType,
        'fileUrl': downloadUrl,
        'uploadedAt': DateTime.now().toIso8601String(),
      };

      await ref.read(patientRepositoryProvider).addAttachment(
            patientId: patientId,
            attachment: attachment,
          );

      ref.invalidate(attachmentsProvider(patientId)); // Refrescar lista
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 6. Firmar Consentimiento Informado
  Future<void> saveConsent({
    required String patientId,
    required Uint8List signatureBytes,
    required String consentText,
  }) async {
    state = PatientUiState(isLoading: true);
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('No hay un usuario activo.');

      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = 'clinics/${user.clinicId}/patients/$patientId/consents/$fileName';
      
      final signatureUrl = await ref.read(storageServiceProvider).uploadBytes(
            path: storagePath,
            bytes: signatureBytes,
          );

      await ref.read(patientRepositoryProvider).saveConsent(
            patientId: patientId,
            signatureImageUrl: signatureUrl,
            consentText: consentText,
          );

      ref.invalidate(consentProvider(patientId)); // Refrescar estado del consentimiento
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 7. Inactivar Paciente (Soft Delete)
  Future<void> deactivatePatient(Patient patient) async {
    state = PatientUiState(isLoading: true);
    try {
      final updatedPatient = patient.copyWith(isInactive: true);
      await ref.read(patientRepositoryProvider).updatePatient(updatedPatient);
      ref.invalidate(patientsStreamProvider); // Refrescar lista de pacientes
      state = PatientUiState(success: true);
    } catch (e) {
      state = PatientUiState(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Proveedor del controlador
final patientControllerProvider = NotifierProvider<PatientController, PatientUiState>(() {
  return PatientController();
});
