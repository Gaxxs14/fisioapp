import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/reports_provider.dart';

class ReportsDashboardScreen extends ConsumerStatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  ConsumerState<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends ConsumerState<ReportsDashboardScreen> {
  String _selectedRange = 'Mes'; // Mes, Semana, Hoy

  void _changeRange(String val) {
    setState(() {
      _selectedRange = val;
    });

    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (val == 'Hoy') {
      start = DateTime(now.year, now.month, now.day);
    } else if (val == 'Semana') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else {
      start = DateTime(now.year, now.month, 1);
    }

    ref.read(reportsControllerProvider.notifier).loadMetrics(start, end);
  }

  Future<void> _exportPdf(Map<String, dynamic> metrics) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FisioApp - Reporte Operativo y Financiero',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Reporte consolidado del período: $_selectedRange', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0F766E')),
                pw.SizedBox(height: 20),

                pw.Text('1. Resumen de Ingresos', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Ingresos Totales: \$${(metrics['totalRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                pw.Bullet(text: 'Efectivo: \$${(metrics['cashRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                pw.Bullet(text: 'Tarjetas: \$${(metrics['cardRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                pw.Bullet(text: 'Transferencias: \$${(metrics['transferRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                pw.SizedBox(height: 20),

                pw.Text('2. Resumen de Agenda', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Total Citas: ${metrics['totalAppointments'] ?? 0}'),
                pw.Bullet(text: 'Asistidas: ${metrics['completedAppointments'] ?? 0}'),
                pw.Bullet(text: 'Canceladas: ${metrics['cancelledAppointments'] ?? 0}'),
                pw.Bullet(text: 'Ausentes: ${metrics['absentAppointments'] ?? 0}'),
                pw.Bullet(text: 'Tasa de Ocupación: ${(((metrics['occupancyRate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0)}%'),
                pw.SizedBox(height: 20),

                pw.Text('3. Resumen de Bonos y Paquetes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                pw.SizedBox(height: 8),
                pw.Bullet(text: 'Bonos Vendidos: ${metrics['bonosSold'] ?? 0}'),
                pw.Bullet(text: 'Sesiones de Bono Consumidas: ${metrics['bonosConsumed'] ?? 0}'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_FisioApp_$_selectedRange.pdf',
    );
  }

  Future<void> _exportExcel(Map<String, dynamic> metrics) async {
    try {
      final excel = Excel.createExcel();
      
      List<CellValue?> toCellValues(List<dynamic> row) {
        return row.map<CellValue?>((e) {
          if (e == null) return null;
          if (e is int) return IntCellValue(e);
          if (e is double) return DoubleCellValue(e);
          if (e is bool) return BoolCellValue(e);
          return TextCellValue(e.toString());
        }).toList();
      }

      // 1. Hoja de Resumen
      final sheet1 = excel['Resumen General'];
      sheet1.appendRow(toCellValues(['FisioApp - Reporte de Operaciones y Finanzas']));
      sheet1.appendRow(toCellValues(['Rango de consulta:', _selectedRange]));
      sheet1.appendRow(toCellValues(['Fecha de generación:', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())]));
      sheet1.appendRow([]);
      
      sheet1.appendRow(toCellValues(['Métrica', 'Valor']));
      sheet1.appendRow(toCellValues(['Ingresos Totales', '\$${(metrics['totalRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}']));
      sheet1.appendRow(toCellValues(['  Ingresos en Efectivo', '\$${(metrics['cashRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}']));
      sheet1.appendRow(toCellValues(['  Ingresos con Tarjeta', '\$${(metrics['cardRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}']));
      sheet1.appendRow(toCellValues(['  Ingresos con Transferencia', '\$${(metrics['transferRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}']));
      sheet1.appendRow([]);
      sheet1.appendRow(toCellValues(['Total de Citas', metrics['totalAppointments'] ?? 0]));
      sheet1.appendRow(toCellValues(['  Citas Completadas', metrics['completedAppointments'] ?? 0]));
      sheet1.appendRow(toCellValues(['  Citas Pendientes', metrics['pendingAppointments'] ?? 0]));
      sheet1.appendRow(toCellValues(['  Citas Canceladas', metrics['cancelledAppointments'] ?? 0]));
      sheet1.appendRow(toCellValues(['  Inasistencias (No Show)', metrics['absentAppointments'] ?? 0]));
      
      final total = metrics['totalAppointments'] as int? ?? 0;
      final completed = metrics['completedAppointments'] as int? ?? 0;
      final cancelled = metrics['cancelledAppointments'] as int? ?? 0;
      final absent = metrics['absentAppointments'] as int? ?? 0;
      final double cancellationRate = total > 0 ? (cancelled + absent) / total : 0.0;
      final double attendanceRate = total > 0 ? completed / total : 0.0;
      
      sheet1.appendRow(toCellValues(['Tasa de Asistencia', '${(attendanceRate * 100).toStringAsFixed(1)}%']));
      sheet1.appendRow(toCellValues(['Tasa de Cancelación / Ausencia', '${(cancellationRate * 100).toStringAsFixed(1)}%']));
      sheet1.appendRow(toCellValues(['Tasa de Ocupación Promedio', '${(((metrics['occupancyRate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%']));
      
      // 2. Hoja de Transacciones
      final sheet2 = excel['Detalle de Ingresos'];
      sheet2.appendRow(toCellValues(['Fecha', 'Paciente', 'Concepto', 'Método de Pago', 'Monto']));
      final rawTx = metrics['rawTransactions'] as List? ?? [];
      for (var tx in rawTx) {
        final dateVal = (tx['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        sheet2.appendRow(toCellValues([
          DateFormat('dd/MM/yyyy HH:mm').format(dateVal),
          tx['patientName'] ?? '',
          tx['concept'] ?? '',
          tx['paymentMethod'] ?? '',
          tx['amount'] ?? 0.0
        ]));
      }
      
      // 3. Hoja de Citas
      final sheet3 = excel['Detalle de Citas'];
      sheet3.appendRow(toCellValues(['Fecha', 'Paciente', 'Especialista', 'Estado', 'Duración (min)']));
      final rawApp = metrics['rawAppointments'] as List? ?? [];
      for (var app in rawApp) {
        final dateVal = (app['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        sheet3.appendRow(toCellValues([
          DateFormat('dd/MM/yyyy HH:mm').format(dateVal),
          app['patientName'] ?? '',
          app['professionalName'] ?? '',
          app['status'] ?? '',
          app['durationMinutes'] ?? 0
        ]));
      }
      
      excel.delete('Sheet1');
      
      final bytes = excel.encode();
      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/Reporte_Operativo_$_selectedRange.xlsx');
        await file.writeAsBytes(bytes);
        
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
            text: 'Reporte Operativo y Financiero de FisioApp ($_selectedRange)',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar Excel: $e', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsControllerProvider);
    final metrics = state.metrics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Reportes y Analíticas',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (metrics.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exportar Reporte PDF',
              onPressed: () => _exportPdf(metrics),
            ),
            IconButton(
              icon: const Icon(Icons.grid_on_outlined),
              tooltip: 'Exportar Reporte Excel',
              onPressed: () => _exportExcel(metrics),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  // Selector de Período
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRangeButton('Hoy'),
                      const SizedBox(width: 8),
                      _buildRangeButton('Semana'),
                      const SizedBox(width: 8),
                      _buildRangeButton('Mes'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (metrics.isEmpty)
                    const Center(child: Text('No hay datos suficientes para generar analíticas.'))
                  else ...[
                    // KPI Principal: Total Recaudado
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'INGRESOS TOTALES EN EL PERÍODO',
                            style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${(metrics['totalRevenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                    const SizedBox(height: 20),

                    // Ocupación y Asistencia Citas
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Ocupación de Agenda',
                            value: '${((metrics['occupancyRate'] as num?)?.toDouble() ?? 0.0 * 100).toStringAsFixed(0)}%',
                            subtitle: 'Citas vs Horario Lab.',
                            icon: Icons.pie_chart_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Tasa de Asistencia',
                            value: '${metrics['completedAppointments'] ?? 0} / ${metrics['totalAppointments'] ?? 0}',
                            subtitle: 'Citas realizadas',
                            icon: Icons.event_available_outlined,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Gráfico de Ingresos por Método
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingresos por Método de Pago',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          _buildProgressBar('Efectivo', metrics['cashRevenue'] ?? 0.0, metrics['totalRevenue'] ?? 1.0, Colors.green),
                          const SizedBox(height: 12),
                          _buildProgressBar('Tarjeta', metrics['cardRevenue'] ?? 0.0, metrics['totalRevenue'] ?? 1.0, Colors.blue),
                          const SizedBox(height: 12),
                          _buildProgressBar('Transferencia', metrics['transferRevenue'] ?? 0.0, metrics['totalRevenue'] ?? 1.0, Colors.purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Balance de Ingresos por Servicio
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance de Ingresos por Servicio',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ...((metrics['revenueByCategory'] as Map<dynamic, dynamic>?) ?? {}).entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildProgressBar(
                                e.key.toString(),
                                (e.value as num?)?.toDouble() ?? 0.0,
                                (metrics['totalRevenue'] as num?)?.toDouble() ?? 1.0,
                                e.key == 'Fisioterapia'
                                    ? Colors.teal
                                    : e.key == 'Evaluaciones'
                                        ? Colors.orange
                                        : e.key == 'Bonos y Paquetes'
                                            ? Colors.deepPurple
                                            : Colors.blueGrey,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gráfico de Citas por Estado
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distribución de Citas',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStateStat('Completadas', metrics['completedAppointments'] ?? 0, Colors.green),
                              _buildStateStat('Pendientes', metrics['pendingAppointments'] ?? 0, Colors.blue),
                              _buildStateStat('Canceladas', metrics['cancelledAppointments'] ?? 0, Colors.red),
                              _buildStateStat('Ausentes', metrics['absentAppointments'] ?? 0, Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta de Tasa de Cancelación y Recomendaciones
                    Builder(
                      builder: (context) {
                        final total = metrics['totalAppointments'] as int? ?? 0;
                        final cancelled = metrics['cancelledAppointments'] as int? ?? 0;
                        final absent = metrics['absentAppointments'] as int? ?? 0;
                        final double cancellationRate = total > 0 ? (cancelled + absent) / total : 0.0;
                        final isHigh = cancellationRate > 0.10;
                        
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131B2E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tasa de Cancelación y Ausencia',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isHigh ? Colors.red : Colors.green).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${(cancellationRate * 100).toStringAsFixed(1)}%',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: isHigh ? Colors.red : Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: cancellationRate,
                                  minHeight: 8,
                                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(isHigh ? Colors.red : Colors.green),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isHigh ? Colors.amber : Colors.teal).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: (isHigh ? Colors.amber : Colors.teal).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isHigh ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                      color: isHigh ? Colors.amber.shade700 : Colors.teal,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        isHigh
                                            ? 'Recomendación: Tu tasa de inasistencia supera el 10%. Activa los recordatorios automáticos por WhatsApp y notificaciones para reducir el ausentismo.'
                                            : '¡Felicidades! Mantienes una tasa de ausentismo excelente (menor al 10%). Tus pacientes están asistiendo puntualmente.',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Rendimiento de Bonos
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Control de Bonos y Paquetes',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.primaryColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Vendidos', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${metrics['bonosSold'] ?? 0} Paquetes',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1.5, height: 40, color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Consumidos', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${metrics['bonosConsumed'] ?? 0} Sesiones',
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildRangeButton(String value) {
    final isSelected = _selectedRange == value;
    return ChoiceChip(
      label: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
      selected: isSelected,
      onSelected: (_) => _changeRange(value),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
              Icon(icon, color: AppTheme.primaryColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double amount, double total, Color color) {
    final percentage = total > 0 ? amount / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('\$${amount.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(0)}%)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStateStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
