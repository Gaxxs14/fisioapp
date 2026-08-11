import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Stream de suscripción de la clínica
final subscriptionStreamProvider = StreamProvider<SubscriptionModel>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();

  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('clinics')
      .doc(clinicId)
      .snapshots()
      .asyncMap((snapshot) async {
    final data = snapshot.data();
    if (data == null || data['subscription'] == null) {
      // Inicializar sub por defecto (14 días gratis)
      final sub = SubscriptionModel(
        clinicId: clinicId,
        planName: 'Básico',
        status: 'trialing',
        trialEndsAt: DateTime.now().add(const Duration(days: 14)),
        currentPeriodEnd: DateTime.now().add(const Duration(days: 14)),
        price: 29.0,
      );
      await firestore.collection('clinics').doc(clinicId).set({
        'subscription': sub.toMap(),
      }, SetOptions(merge: true));
      return sub;
    }

    return SubscriptionModel.fromMap(Map<String, dynamic>.from(data['subscription']));
  });
});

// Stream de Facturas Históricas
final invoicesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final clinicId = authState.user?.clinicId ?? '';
  if (clinicId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('clinics')
      .doc(clinicId)
      .collection('invoices')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  });
});

// Estado de la UI
class SubscriptionUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const SubscriptionUiState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  SubscriptionUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return SubscriptionUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      success: success ?? this.success,
    );
  }
}

class SubscriptionController extends Notifier<SubscriptionUiState> {
  @override
  SubscriptionUiState build() {
    return const SubscriptionUiState();
  }

  // Validación de Tarjeta (Algoritmo de Luhn)
  bool _validateCardNumber(String number) {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 13 || clean.length > 19) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int n = int.parse(clean[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  Future<void> checkout({
    required String planName,
    required double price,
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
    required String cvv,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);

    // Simular un retardo del procesador de pagos (Stripe/MercadoPago)
    await Future.delayed(const Duration(seconds: 2));

    if (!_validateCardNumber(cardNumber)) {
      state = state.copyWith(isLoading: false, errorMessage: 'El número de tarjeta no supera la validación matemática (Luhn).');
      return;
    }

    final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
    if (clinicId.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Clínica no válida.');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final updatedSub = SubscriptionModel(
        clinicId: clinicId,
        planName: planName,
        status: 'active',
        trialEndsAt: DateTime.now(), // La prueba termina al pagar
        currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
        price: price,
      );

      // Guardar Suscripción
      await firestore.collection('clinics').doc(clinicId).set({
        'subscription': updatedSub.toMap(),
      }, SetOptions(merge: true));

      // Guardar Factura en el historial
      final invoiceDoc = firestore.collection('clinics').doc(clinicId).collection('invoices').doc();
      await invoiceDoc.set({
        'id': invoiceDoc.id,
        'date': DateTime.now().toIso8601String(),
        'planName': planName,
        'amount': price,
        'cardNumber': '•••• •••• •••• ${cardNumber.substring(cardNumber.length - 4)}',
        'status': 'Pagado',
      });

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> cancelSubscription() async {
    state = state.copyWith(isLoading: true, errorMessage: null, success: false);
    final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
    if (clinicId.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Obtener actual
      final snap = await firestore.collection('clinics').doc(clinicId).get();
      final data = snap.data();
      if (data == null || data['subscription'] == null) return;

      final sub = SubscriptionModel.fromMap(Map<String, dynamic>.from(data['subscription']));
      final updatedSub = sub.copyWith(status: 'cancelled');

      await firestore.collection('clinics').doc(clinicId).set({
        'subscription': updatedSub.toMap(),
      }, SetOptions(merge: true));

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final subscriptionControllerProvider = NotifierProvider<SubscriptionController, SubscriptionUiState>(() {
  return SubscriptionController();
});
