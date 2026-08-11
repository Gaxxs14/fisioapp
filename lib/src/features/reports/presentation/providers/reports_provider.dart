import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../data/repositories/firestore_reports_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return FirestoreReportsRepository();
});

class ReportsState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic> metrics;
  final DateTime startDate;
  final DateTime endDate;

  ReportsState({
    this.isLoading = false,
    this.errorMessage,
    this.metrics = const {},
    required this.startDate,
    required this.endDate,
  });

  ReportsState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? metrics,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      metrics: metrics ?? this.metrics,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class ReportsController extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Ejecutar la carga inicial en el siguiente frame
    Future.microtask(() => loadMetrics(start, end));

    return ReportsState(
      startDate: start,
      endDate: end,
    );
  }

  Future<void> loadMetrics(DateTime start, DateTime end) async {
    state = state.copyWith(isLoading: true, errorMessage: null, startDate: start, endDate: end);
    try {
      final repository = ref.read(reportsRepositoryProvider);
      final clinicId = ref.read(authControllerProvider).user?.clinicId ?? '';
      
      if (clinicId.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'Usuario no autenticado');
        return;
      }

      final data = await repository.getConsolidatedMetrics(
        clinicId: clinicId,
        start: start,
        end: end,
      );

      state = state.copyWith(isLoading: false, metrics: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final reportsControllerProvider = NotifierProvider<ReportsController, ReportsState>(() {
  return ReportsController();
});
