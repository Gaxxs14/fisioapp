import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_model.dart';
import 'patient_portal_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Stream de notificaciones para el paciente actual
final patientNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final patientId = ref.watch(currentPatientIdProvider);
  if (patientId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('notifications')
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) {
      return NotificationModel.fromMap(doc.data(), doc.id);
    }).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  });
});

// Contador de notificaciones no leídas para el paciente
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(patientNotificationsProvider);
  return notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;
});

// Controlador de Notificaciones (para marcar como leídas, enviar comunicados, etc.)
class NotificationController extends Notifier<void> {
  @override
  void build() {}

  // Marcar todas como leídas para el paciente actual
  Future<void> markAllAsRead() async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final unreadSnap = await firestore
        .collection('patients')
        .doc(patientId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = firestore.batch();
    for (var doc in unreadSnap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Enviar una notificación específica
  Future<void> sendPatientNotification({
    required String patientId,
    required String title,
    required String body,
    required String type,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore
        .collection('patients')
        .doc(patientId)
        .collection('notifications')
        .doc();

    final notif = NotificationModel(
      id: docRef.id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );

    await docRef.set(notif.toMap());
  }

  // Enviar comunicado masivo a todos los pacientes de la clínica
  Future<void> sendMassAnnouncement({
    required String title,
    required String body,
  }) async {
    final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
    if (clinicId.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    
    // Obtener todos los pacientes de la clínica
    final patientsSnap = await firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .get();

    final batch = firestore.batch();
    for (var patientDoc in patientsSnap.docs) {
      final notifRef = firestore
          .collection('patients')
          .doc(patientDoc.id)
          .collection('notifications')
          .doc();

      final notif = NotificationModel(
        id: notifRef.id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        isRead: false,
        type: 'announcement',
      );

      batch.set(notifRef, notif.toMap());
    }

    await batch.commit();
  }
}

final notificationControllerProvider = NotifierProvider<NotificationController, void>(() {
  return NotificationController();
});
