import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/home_exercise_model.dart';
import '../../../appointments/domain/entities/appointment.dart';
import 'notification_provider.dart';

class _PatientIdNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String id) => state = id;
}

final currentPatientIdProvider = NotifierProvider<_PatientIdNotifier, String>(() {
  return _PatientIdNotifier();
});

// Stream de citas del paciente
final patientCitasStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collectionGroup('appointments')
      .where('patientId', isEqualTo: patientId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Appointment.fromMap(data);
    }).toList();
  });
});

// Stream de ejercicios en casa del paciente
final patientExercisesStreamProvider = StreamProvider<List<HomeExerciseModel>>((ref) {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId.isEmpty) return const Stream.empty();

  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('patients')
      .doc(patientId)
      .collection('exercises')
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) {
      // Inicializar ejercicios de demostración para evitar pantalla vacía
      final defaults = [
        HomeExerciseModel(
          id: '',
          clinicId: 'demo-clinic',
          patientId: patientId,
          title: 'Estiramiento Cervical Lateral',
          instructions: 'Inclina la cabeza lentamente hacia el hombro derecho y mantén presión leve con la mano. Repite hacia el lado izquierdo.',
          repetitions: '3 series de 15 segundos por lado',
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          assignedDate: DateTime.now(),
        ),
        HomeExerciseModel(
          id: '',
          clinicId: 'demo-clinic',
          patientId: patientId,
          title: 'Movilización de Escápula',
          instructions: 'Párate erguido, sube los hombros hacia las orejas, luego llévalos hacia atrás y abajo realizando círculos suaves.',
          repetitions: '3 series de 10 repeticiones',
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          assignedDate: DateTime.now(),
        ),
      ];

      for (var exercise in defaults) {
        final doc = firestore.collection('patients').doc(patientId).collection('exercises').doc();
        await doc.set(exercise.copyWith(id: doc.id).toMap());
      }

      await ref.read(notificationControllerProvider.notifier).sendPatientNotification(
        patientId: patientId,
        title: 'Nuevos Ejercicios Asignados',
        body: 'Se ha asignado tu rutina de rehabilitación para realizar en casa hoy.',
        type: 'exercise',
      );
    }

    return snapshot.docs
        .map((doc) => HomeExerciseModel.fromMap(doc.data(), doc.id))
        .toList();
  });
});

// Estado de la UI para el Portal
class PatientPortalUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const PatientPortalUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  PatientPortalUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return PatientPortalUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class PatientPortalController extends Notifier<PatientPortalUiState> {
  @override
  PatientPortalUiState build() {
    return const PatientPortalUiState();
  }

  Future<void> toggleExerciseCompletion(String exerciseId, bool completed) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('exercises')
          .doc(exerciseId)
          .update({'isCompleted': completed});
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, String clinicId, AppointmentStatus status) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status.name});
      
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final patientPortalControllerProvider = NotifierProvider<PatientPortalController, PatientPortalUiState>(() {
  return PatientPortalController();
});
