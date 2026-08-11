import '../entities/patient.dart';
import '../entities/clinical_history.dart';
import '../entities/patient_evaluation.dart';

abstract class PatientRepository {
  Stream<List<Patient>> streamPatients({required String clinicId});

  Future<List<Patient>> getPatients({required String clinicId});

  Future<void> addPatient(Patient patient);

  Future<void> updatePatient(Patient patient);

  Future<ClinicalHistory> getClinicalHistory({required String patientId});

  Future<void> updateClinicalHistory(ClinicalHistory history);

  Future<List<PatientEvaluation>> getEvaluations({required String patientId});

  Future<void> addEvaluation({
    required String patientId,
    required PatientEvaluation evaluation,
  });

  Future<List<Map<String, dynamic>>> getAttachments({required String patientId});

  Future<void> addAttachment({
    required String patientId,
    required Map<String, dynamic> attachment,
  });

  Future<Map<String, dynamic>?> getConsent({required String patientId});

  Future<void> saveConsent({
    required String patientId,
    required String signatureImageUrl,
    required String consentText,
  });
}
