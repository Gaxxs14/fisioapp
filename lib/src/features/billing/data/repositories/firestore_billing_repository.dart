import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/entities/service_model.dart';
import '../../domain/entities/pack_model.dart';
import '../../domain/entities/transaction_model.dart';
import '../../domain/entities/patient_bono.dart';

class FirestoreBillingRepository implements BillingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ServiceModel>> watchServices({required String clinicId}) {
    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('services')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Inicializar catálogo de servicios básicos por defecto para la clínica
        final defaults = [
          ServiceModel(id: '', clinicId: clinicId, name: 'Fisioterapia General', durationMinutes: 45, price: 40.0, colorHex: '#0F766E'),
          ServiceModel(id: '', clinicId: clinicId, name: 'Rehabilitación Traumatológica', durationMinutes: 60, price: 50.0, colorHex: '#14B8A6'),
          ServiceModel(id: '', clinicId: clinicId, name: 'Osteopatía / Terapia Manual', durationMinutes: 50, price: 55.0, colorHex: '#6366F1'),
          ServiceModel(id: '', clinicId: clinicId, name: 'Pilates Clínico (Sesión Individual)', durationMinutes: 45, price: 35.0, colorHex: '#EC4899'),
        ];
        for (var service in defaults) {
          final doc = _firestore.collection('clinics').doc(clinicId).collection('services').doc();
          await doc.set(service.copyWith(id: doc.id).toMap());
        }
      }
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> saveService(ServiceModel service) async {
    final ref = _firestore.collection('clinics').doc(service.clinicId).collection('services');
    if (service.id.isEmpty) {
      final doc = ref.doc();
      await doc.set(service.copyWith(id: doc.id).toMap());
    } else {
      await ref.doc(service.id).set(service.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deleteService({required String serviceId}) async {
    // Nota: en producción haríamos soft delete, aquí hacemos delete directo por simplicidad
  }

  @override
  Stream<List<PackModel>> watchPacks({required String clinicId}) {
    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('packs')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Inicializar bonos por defecto si no existen
        // Buscamos algún servicio para vincularlo
        final servicesSnap = await _firestore.collection('clinics').doc(clinicId).collection('services').get();
        if (servicesSnap.docs.isNotEmpty) {
          final serviceId = servicesSnap.docs.first.id;
          final serviceName = servicesSnap.docs.first.data()['name'] ?? 'Fisioterapia';
          final defaults = [
            PackModel(id: '', clinicId: clinicId, name: 'Bono 5 Sesiones $serviceName', serviceId: serviceId, totalSessions: 5, price: 180.0, expirationMonths: 6),
            PackModel(id: '', clinicId: clinicId, name: 'Bono 10 Sesiones $serviceName', serviceId: serviceId, totalSessions: 10, price: 340.0, expirationMonths: 12),
          ];
          for (var pack in defaults) {
            final doc = _firestore.collection('clinics').doc(clinicId).collection('packs').doc();
            await doc.set(pack.copyWith(id: doc.id).toMap());
          }
        }
      }
      return snapshot.docs
          .map((doc) => PackModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> savePack(PackModel pack) async {
    final ref = _firestore.collection('clinics').doc(pack.clinicId).collection('packs');
    if (pack.id.isEmpty) {
      final doc = ref.doc();
      await doc.set(pack.copyWith(id: doc.id).toMap());
    } else {
      await ref.doc(pack.id).set(pack.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> deletePack({required String packId}) async {}

  @override
  Stream<List<TransactionModel>> watchTransactions({required String clinicId, required DateTime date}) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Stream<List<TransactionModel>> watchPatientTransactions({required String clinicId, required String patientId}) {
    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('transactions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    final ref = _firestore.collection('clinics').doc(transaction.clinicId).collection('transactions');
    final doc = ref.doc();
    await doc.set(transaction.copyWith(id: doc.id).toMap());
  }

  @override
  Future<List<TransactionModel>> getTransactionsForPeriod({
    required String clinicId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = await _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<PatientBono>> watchPatientBonos({
    required String clinicId,
    required String patientId,
  }) {
    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('patients')
        .doc(patientId)
        .collection('bonos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientBono.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> savePatientBono(PatientBono bono) async {
    final ref = _firestore
        .collection('clinics')
        .doc(bono.clinicId)
        .collection('patients')
        .doc(bono.patientId)
        .collection('bonos');

    if (bono.id.isEmpty) {
      final doc = ref.doc();
      await doc.set(bono.copyWith(id: doc.id).toMap());
    } else {
      await ref.doc(bono.id).set(bono.toMap(), SetOptions(merge: true));
    }
  }

  @override
  Future<void> consumeBonoSession({
    required String clinicId,
    required String patientId,
    required String bonoId,
    required String therapistName,
  }) async {
    final docRef = _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('patients')
        .doc(patientId)
        .collection('bonos')
        .doc(bonoId);

    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final currentSessions = doc.data()!['remainingSessions'] as int? ?? 0;
      if (currentSessions > 0) {
        await docRef.update({'remainingSessions': currentSessions - 1});
      }
    }
  }

  @override
  Future<void> saveCashClosing({
    required String clinicId,
    required DateTime date,
    required String closingUser,
    required double expectedAmount,
    required double countedAmount,
    required String notes,
    required String signatureUrl,
  }) async {
    final ref = _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('cash_closings');

    final doc = ref.doc();
    await doc.set({
      'id': doc.id,
      'date': Timestamp.fromDate(date),
      'closingUser': closingUser,
      'expectedAmount': expectedAmount,
      'countedAmount': countedAmount,
      'notes': notes,
      'signatureUrl': signatureUrl,
      'createdAt': Timestamp.now(),
    });
  }
}
