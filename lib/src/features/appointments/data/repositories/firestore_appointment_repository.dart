import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/waiting_list_entry.dart';
import '../../domain/repositories/appointment_repository.dart';

class FirestoreAppointmentRepository implements AppointmentRepository {
  final FirebaseFirestore _firestore;

  FirestoreAppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Appointment>> streamAppointments({required String clinicId}) {
    return _firestore
        .collection('appointments')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<List<Appointment>> getAppointments({required String clinicId}) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .get();
      return snapshot.docs.map((doc) => Appointment.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Error al obtener citas: $e');
    }
  }

  @override
  Future<void> addAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());
    } catch (e) {
      throw Exception('Error al agendar la cita: $e');
    }
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .update(appointment.toMap());
    } catch (e) {
      throw Exception('Error al actualizar la cita: $e');
    }
  }

  @override
  Future<void> deleteAppointment({required String appointmentId}) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Error al cancelar la cita: $e');
    }
  }

  @override
  Stream<List<WaitingListEntry>> streamWaitingList({required String clinicId}) {
    return _firestore
        .collection('waiting_list')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaitingListEntry.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> addToWaitingList(WaitingListEntry entry) async {
    try {
      await _firestore
          .collection('waiting_list')
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      throw Exception('Error al agregar a la lista de espera: $e');
    }
  }

  @override
  Future<void> removeFromWaitingList({required String entryId}) async {
    try {
      await _firestore.collection('waiting_list').doc(entryId).delete();
    } catch (e) {
      throw Exception('Error al remover de la lista de espera: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTherapists({required String clinicId}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('clinicId', isEqualTo: clinicId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data())
          .where((data) => (data['role'] == 'physio' || data['role'] == 'admin') && (data['isActive'] ?? true))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener terapeutas: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRooms({required String clinicId}) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .where('clinicId', isEqualTo: clinicId)
          .get();

      if (snapshot.docs.isEmpty) {
        // Auto-seed: Crear 2 salas por defecto
        final room1Id = _firestore.collection('rooms').doc().id;
        final room2Id = _firestore.collection('rooms').doc().id;

        final rooms = [
          {'id': room1Id, 'clinicId': clinicId, 'name': 'Consultorio Fisioterapia 1', 'color': '0xFF0E7490'},
          {'id': room2Id, 'clinicId': clinicId, 'name': 'Consultorio Fisioterapia 2', 'color': '0xFF0D9488'},
        ];

        for (var r in rooms) {
          await _firestore.collection('rooms').doc(r['id'] as String).set(r);
        }

        return rooms;
      }

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error al obtener salas: $e');
    }
  }
}
