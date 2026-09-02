import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/room_model.dart';
import '../../domain/entities/clinic_absence.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../auth/domain/entities/app_user.dart';

class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<RoomModel>> watchRooms({required String clinicId}) {
    return _firestore
        .collection('rooms')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Inicializar salas por defecto para la clínica en la colección global 'rooms'
        final defaults = [
          RoomModel(id: '', clinicId: clinicId, name: 'Consultorio 1', colorHex: '#0F766E'),
          RoomModel(id: '', clinicId: clinicId, name: 'Consultorio 2 (Electroterapia)', colorHex: '#14B8A6'),
          RoomModel(id: '', clinicId: clinicId, name: 'Sala de Kinesiología y Gimnasio', colorHex: '#6366F1'),
        ];
        for (var room in defaults) {
          final doc = _firestore.collection('rooms').doc();
          await doc.set(room.copyWith(id: doc.id).toMap());
        }
        // Volver a hacer consulta para devolver los nuevos datos cargados
        final freshDocs = await _firestore
            .collection('rooms')
            .where('clinicId', isEqualTo: clinicId)
            .get();
        return freshDocs.docs
            .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
            .toList();
      }
      return snapshot.docs
          .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> saveRoom(RoomModel room) async {
    final ref = _firestore.collection('rooms');
    if (room.id.isEmpty) {
      final doc = ref.doc();
      await doc.set(room.copyWith(id: doc.id).toMap());
    } else {
      await ref.doc(room.id).set(room.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteRoom({required String roomId}) async {
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  @override
  Stream<List<AppUser>> watchStaff({required String clinicId}) {
    return _firestore
        .collection('users')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> saveStaffUser(AppUser user, String password) async {
    final ref = _firestore.collection('users');
    String finalUid = user.uid;

    if (finalUid.isEmpty) {
      final doc = ref.doc();
      finalUid = doc.id;
      
      final newUserMap = user.copyWith(uid: finalUid).toMap();
      newUserMap['tempPassword'] = password;
      newUserMap['pendingAuth'] = true;
      
      await doc.set(newUserMap);
    } else {
      await ref.doc(finalUid).set(user.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> toggleStaffStatus({required String uid, required bool isActive}) async {
    await _firestore.collection('users').doc(uid).update({'isActive': isActive});
  }

  @override
  Future<void> deleteStaffUser({required String uid}) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  @override
  Future<void> updateUserWorkSchedule({
    required String uid,
    required List<String> workDays,
    required String workHoursStart,
    required String workHoursEnd,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'workDays': workDays,
      'workHoursStart': workHoursStart,
      'workHoursEnd': workHoursEnd,
    });
  }

  @override
  Stream<List<ClinicAbsence>> watchAbsences({required String clinicId}) {
    return _firestore
        .collection('clinic_absences')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClinicAbsence.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> saveAbsence(ClinicAbsence absence) async {
    final ref = _firestore.collection('clinic_absences');
    if (absence.id.isEmpty) {
      final doc = ref.doc();
      await doc.set(absence.copyWith(id: doc.id).toMap());
    } else {
      await ref.doc(absence.id).set(absence.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteAbsence({required String absenceId}) async {
    await _firestore.collection('clinic_absences').doc(absenceId).delete();
  }
}
