import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../../billing/domain/entities/transaction_model.dart';
import '../../../appointments/domain/entities/appointment.dart';

class FirestoreReportsRepository implements ReportsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>> getConsolidatedMetrics({
    required String clinicId,
    required DateTime start,
    required DateTime end,
  }) async {
    // 1. Obtener transacciones en el período
    final txSnap = await _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final transactions = txSnap.docs
        .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
        .toList();

    // 2. Obtener citas en el período
    final appSnap = await _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final appointments = appSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Appointment.fromMap(data);
    }).toList();

    // 3. Procesar Ingresos Totales
    double cash = 0;
    double card = 0;
    double transfer = 0;
    int bonosSold = 0;
    int bonosConsumed = 0;
    final Map<String, double> revenueByProfessional = {};

    double fisioterapia = 0;
    double evaluaciones = 0;
    double bonos = 0;
    double otros = 0;

    for (var tx in transactions) {
      if (tx.paymentMethod == 'cash') cash += tx.amount;
      if (tx.paymentMethod == 'card') card += tx.amount;
      if (tx.paymentMethod == 'transfer') transfer += tx.amount;
      
      if (tx.isBonoSale == true) {
        bonosSold++;
      }
      if (tx.paymentMethod == 'bono') {
        bonosConsumed++;
      }
      
      final name = tx.patientName;
      revenueByProfessional[name] = (revenueByProfessional[name] ?? 0.0) + tx.amount;

      final concept = tx.concept.toLowerCase();
      if (tx.isBonoSale == true || concept.contains('bono') || concept.contains('paquete')) {
        bonos += tx.amount;
      } else if (concept.contains('evaluacion') || concept.contains('reevaluacion') || concept.contains('diagnostico')) {
        evaluaciones += tx.amount;
      } else if (concept.contains('sesion') || concept.contains('fisioterapia') || concept.contains('terapia') || concept.contains('rehabilitacion')) {
        fisioterapia += tx.amount;
      } else {
        otros += tx.amount;
      }
    }

    // 4. Procesar Asistencia de Citas
    int totalCitas = appointments.length;
    int completed = 0;
    int pending = 0;
    int cancelled = 0;
    int absent = 0;

    for (var app in appointments) {
      if (app.status == AppointmentStatus.completed) completed++;
      if (app.status == AppointmentStatus.pending) pending++;
      if (app.status == AppointmentStatus.cancelled) cancelled++;
      if (app.status == AppointmentStatus.noShow) absent++;
    }

    // Calcular Ocupación (estimación del tiempo agendado frente a 8 horas diarias promedio por profesional)
    double occupancyRate = 0.8; // Ocupación por defecto si no hay datos
    if (totalCitas > 0) {
      final totalWorkMinutes = 8 * 60.0;
      final agendados = appointments.fold<double>(0.0, (prev, app) => prev + app.durationMinutes);
      occupancyRate = agendados / (totalWorkMinutes * 3); // Para 3 profesionales promedio
      if (occupancyRate > 1.0) occupancyRate = 1.0;
    }

    return {
      'totalRevenue': cash + card + transfer,
      'cashRevenue': cash,
      'cardRevenue': card,
      'transferRevenue': transfer,
      'totalAppointments': totalCitas,
      'completedAppointments': completed,
      'pendingAppointments': pending,
      'cancelledAppointments': cancelled,
      'absentAppointments': absent,
      'occupancyRate': occupancyRate,
      'revenueByProfessional': revenueByProfessional,
      'bonosSold': bonosSold,
      'bonosConsumed': bonosConsumed,
      'revenueByCategory': {
        'Fisioterapia': fisioterapia,
        'Evaluaciones': evaluaciones,
        'Bonos y Paquetes': bonos,
        'Otros': otros,
      },
      'rawTransactions': transactions.map((t) => t.toMap()).toList(),
      'rawAppointments': appointments.map((a) => a.toMap()).toList(),
    };
  }
}
