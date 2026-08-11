import '../entities/service_model.dart';
import '../entities/pack_model.dart';
import '../entities/transaction_model.dart';
import '../entities/patient_bono.dart';

abstract class BillingRepository {
  // Servicios (Tarifas)
  Stream<List<ServiceModel>> watchServices({required String clinicId});
  Future<void> saveService(ServiceModel service);
  Future<void> deleteService({required String serviceId});

  // Paquetes (Bonos)
  Stream<List<PackModel>> watchPacks({required String clinicId});
  Future<void> savePack(PackModel pack);
  Future<void> deletePack({required String packId});

  // Transacciones
  Stream<List<TransactionModel>> watchTransactions({
    required String clinicId,
    required DateTime date,
  });
  Stream<List<TransactionModel>> watchPatientTransactions({
    required String clinicId,
    required String patientId,
  });
  Future<void> saveTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getTransactionsForPeriod({
    required String clinicId,
    required DateTime start,
    required DateTime end,
  });

  // Bonos del Paciente
  Stream<List<PatientBono>> watchPatientBonos({
    required String clinicId,
    required String patientId,
  });
  Future<void> savePatientBono(PatientBono bono);
  Future<void> consumeBonoSession({
    required String clinicId,
    required String patientId,
    required String bonoId,
    required String therapistName,
  });

  // Cierre de caja
  Future<void> saveCashClosing({
    required String clinicId,
    required DateTime date,
    required String closingUser,
    required double expectedAmount,
    required double countedAmount,
    required String notes,
    required String signatureUrl,
  });
}
