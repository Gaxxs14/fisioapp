import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_model.dart';
import '../../domain/entities/pack_model.dart';
import '../../domain/entities/transaction_model.dart';
import '../../domain/entities/patient_bono.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../data/repositories/firestore_billing_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return FirestoreBillingRepository();
});

// Stream para los servicios de la clínica
final servicesStreamProvider = StreamProvider<List<ServiceModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(billingRepositoryProvider).watchServices(clinicId: clinicId);
});

// Stream para los paquetes/bonos de la clínica
final packsStreamProvider = StreamProvider<List<PackModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(billingRepositoryProvider).watchPacks(clinicId: clinicId);
});

// Stream para los bonos del paciente
final patientBonosStreamProvider = StreamProvider.family<List<PatientBono>, String>((ref, patientId) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return Stream.value([]);
  return ref.watch(billingRepositoryProvider).watchPatientBonos(clinicId: clinicId, patientId: patientId);
});

// Stream para transacciones de un día
final transactionsStreamProvider = StreamProvider.family<List<TransactionModel>, DateTime>((ref, date) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(billingRepositoryProvider).watchTransactions(clinicId: clinicId, date: date);
});

// Stream para todas las transacciones históricas de un paciente
final patientTransactionsStreamProvider = StreamProvider.family<List<TransactionModel>, String>((ref, patientId) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();
  return ref.watch(billingRepositoryProvider).watchPatientTransactions(clinicId: clinicId, patientId: patientId);
});

// Estado de la UI para operaciones
class BillingUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const BillingUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  BillingUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return BillingUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class BillingController extends Notifier<BillingUiState> {
  @override
  BillingUiState build() {
    return const BillingUiState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearSuccess() {
    state = state.copyWith(success: false);
  }

  Future<void> addService({
    required String name,
    required int durationMinutes,
    required double price,
    required String colorHex,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(billingRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      final service = ServiceModel(
        id: '',
        clinicId: clinicId,
        name: name,
        durationMinutes: durationMinutes,
        price: price,
        colorHex: colorHex,
      );
      await repository.saveService(service);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addPack({
    required String name,
    required String serviceId,
    required int totalSessions,
    required double price,
    required int expirationMonths,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(billingRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      final pack = PackModel(
        id: '',
        clinicId: clinicId,
        name: name,
        serviceId: serviceId,
        totalSessions: totalSessions,
        price: price,
        expirationMonths: expirationMonths,
      );
      await repository.savePack(pack);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> sellBonoToPatient({
    required String patientId,
    required String patientName,
    required PackModel pack,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(billingRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      
      final bono = PatientBono(
        id: '',
        clinicId: clinicId,
        patientId: patientId,
        serviceId: pack.serviceId,
        serviceName: pack.name,
        purchasedSessions: pack.totalSessions,
        remainingSessions: pack.totalSessions,
        expirationDate: DateTime.now().add(Duration(days: pack.expirationMonths * 30)),
        isPaid: true,
      );

      await repository.savePatientBono(bono);

      // Registrar transacción
      final transaction = TransactionModel(
        id: '',
        clinicId: clinicId,
        patientId: patientId,
        patientName: patientName,
        date: DateTime.now(),
        concept: 'Venta de Bono: ${pack.name}',
        amount: pack.price,
        paymentMethod: 'cash',
        isBonoSale: true,
      );

      await repository.saveTransaction(transaction);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> registerPayment({
    required String patientId,
    required String patientName,
    required String concept,
    required double amount,
    required String paymentMethod,
    String? referenceCode,
    String? useBonoId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(billingRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      final user = ref.read(authControllerProvider).user;

      final transaction = TransactionModel(
        id: '',
        clinicId: clinicId,
        patientId: patientId,
        patientName: patientName,
        date: DateTime.now(),
        concept: concept,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceCode: referenceCode,
        bonoId: useBonoId,
      );

      await repository.saveTransaction(transaction);

      if (paymentMethod == 'bono' && useBonoId != null) {
        await repository.consumeBonoSession(
          clinicId: clinicId,
          patientId: patientId,
          bonoId: useBonoId,
          therapistName: user?.name ?? 'Fisioterapeuta',
        );
      }

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> performClosing({
    required double expectedAmount,
    required double countedAmount,
    required String notes,
    required String signatureBase64,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    try {
      final repository = ref.read(billingRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      final user = ref.read(authControllerProvider).user;

      await repository.saveCashClosing(
        clinicId: clinicId,
        date: DateTime.now(),
        closingUser: user?.name ?? 'Usuario',
        expectedAmount: expectedAmount,
        countedAmount: countedAmount,
        notes: notes,
        signatureUrl: signatureBase64,
      );

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final billingControllerProvider = NotifierProvider<BillingController, BillingUiState>(() {
  return BillingController();
});
