abstract class ReportsRepository {
  Future<Map<String, dynamic>> getConsolidatedMetrics({
    required String clinicId,
    required DateTime start,
    required DateTime end,
  });
}
