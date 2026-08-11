import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/clinical_history.dart';
import '../../domain/entities/patient_evaluation.dart';
import '../../domain/repositories/patient_repository.dart';

class FirestorePatientRepository implements PatientRepository {
  final FirebaseFirestore _firestore;

  FirestorePatientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Patient>> streamPatients({required String clinicId}) {
    return _firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snapshot) {
      final patients = snapshot.docs
          .map((doc) => Patient.fromMap(doc.data()))
          .where((p) => !p.isInactive)
          .toList();
      patients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return patients;
    });
  }

  @override
  Future<List<Patient>> getPatients({required String clinicId}) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('clinicId', isEqualTo: clinicId)
          .get();
      final patients = snapshot.docs
          .map((doc) => Patient.fromMap(doc.data()))
          .where((p) => !p.isInactive)
          .toList();
      patients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return patients;
    } catch (e) {
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  @override
  Future<void> addPatient(Patient patient) async {
    try {
      // 1. Crear el documento del paciente
      await _firestore.collection('patients').doc(patient.id).set(patient.toMap());

      // 2. Inicializar la historia clínica con campos vacíos
      final blankHistory = ClinicalHistory(
        patientId: patient.id,
        antecedents: '',
        medications: '',
        allergies: '',
        surgeries: '',
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('patients')
          .doc(patient.id)
          .collection('clinical_history')
          .doc('details')
          .set(blankHistory.toMap());
    } catch (e) {
      throw Exception('Error al agregar el paciente: $e');
    }
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    try {
      await _firestore.collection('patients').doc(patient.id).update(patient.toMap());
    } catch (e) {
      throw Exception('Error al actualizar el paciente: $e');
    }
  }

  @override
  Future<ClinicalHistory> getClinicalHistory({required String patientId}) async {
    try {
      final doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('clinical_history')
          .doc('details')
          .get();

      if (doc.exists && doc.data() != null) {
        return ClinicalHistory.fromMap(doc.data()!, patientId);
      } else {
        // Retornar un historial vacío si por algún motivo no existe
        return ClinicalHistory(
          patientId: patientId,
          antecedents: '',
          medications: '',
          allergies: '',
          surgeries: '',
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Error al obtener la historia clínica: $e');
    }
  }

  @override
  Future<void> updateClinicalHistory(ClinicalHistory history) async {
    try {
      await _firestore
          .collection('patients')
          .doc(history.patientId)
          .collection('clinical_history')
          .doc('details')
          .set(history.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al guardar la historia clínica: $e');
    }
  }

  @override
  Future<List<PatientEvaluation>> getEvaluations({required String patientId}) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('evaluations')
          .get();

      return snapshot.docs
          .map((doc) => PatientEvaluation.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw Exception('Error al obtener evaluaciones: $e');
    }
  }

  @override
  Future<void> addEvaluation({
    required String patientId,
    required PatientEvaluation evaluation,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('evaluations')
          .doc(evaluation.id)
          .set(evaluation.toMap());
    } catch (e) {
      throw Exception('Error al agregar evaluación: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAttachments({required String patientId}) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('attachments')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList()
        ..sort((a, b) {
          final aDate = a['uploadedAt'] as String? ?? '';
          final bDate = b['uploadedAt'] as String? ?? '';
          return bDate.compareTo(aDate);
        });
    } catch (e) {
      throw Exception('Error al obtener archivos adjuntos: $e');
    }
  }

  @override
  Future<void> addAttachment({
    required String patientId,
    required Map<String, dynamic> attachment,
  }) async {
    try {
      final docId = attachment['id'] ?? _firestore.collection('patients').doc().id;
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('attachments')
          .doc(docId)
          .set(attachment);
    } catch (e) {
      throw Exception('Error al adjuntar archivo: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getConsent({required String patientId}) async {
    try {
      final doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('consent')
          .doc('form')
          .get();
      return doc.data();
    } catch (e) {
      throw Exception('Error al obtener el consentimiento: $e');
    }
  }

  @override
  Future<void> saveConsent({
    required String patientId,
    required String signatureImageUrl,
    required String consentText,
  }) async {
    try {
      final consentData = {
        'signedAt': DateTime.now().toIso8601String(),
        'signatureImageUrl': signatureImageUrl,
        'consentText': consentText,
        'isSigned': true,
      };

      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('consent')
          .doc('form')
          .set(consentData);
    } catch (e) {
      throw Exception('Error al guardar consentimiento: $e');
    }
  }
}
