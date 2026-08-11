import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/patient_provider.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/clinical_history.dart';
import '../../domain/entities/patient_evaluation.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final String patientId;

  const PdfPreviewScreen({super.key, required this.patientId});

  Future<Uint8List> _generatePdf(
    Patient patient,
    ClinicalHistory history,
    List<PatientEvaluation> evaluations,
    Map<String, dynamic>? consent,
  ) async {
    final pdf = pw.Document();

    pw.MemoryImage? signatureImage;
    if (consent != null && consent['isSigned'] == true && consent['signatureImageUrl'] != null) {
      try {
        final response = await http.get(Uri.parse(consent['signatureImageUrl']));
        if (response.statusCode == 200) {
          signatureImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Error al descargar firma para el PDF: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabecera de la Clínica
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FisioApp - Historial Clínico',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F766E'),
                      ),
                    ),
                    pw.Text(
                      'Expediente Fisioterapéutico del Paciente',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0F766E')),
            pw.SizedBox(height: 16),

            // Sección 1: Datos Personales
            pw.Text(
              '1. DATOS PERSONALES',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
            ),
            pw.SizedBox(height: 8),
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.25,
              children: [
                pw.Text('Nombre: ${patient.name}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Identificación/DNI: ${patient.dni}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Edad: ${patient.age} años', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Género: ${patient.gender}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Teléfono: ${patient.phone}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Email: ${patient.email}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Emergencia: ${patient.contactPersonName}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Tel. Emergencia: ${patient.contactPersonPhone}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 24),

            // Sección 2: Historia Clínica
            pw.Text(
              '2. HISTORIA CLÍNICA ANAMNESIS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
            ),
            pw.SizedBox(height: 8),
            pw.Bullet(text: 'Antecedentes Médicos: ${history.antecedents.isNotEmpty ? history.antecedents : "Ninguno"}', style: const pw.TextStyle(fontSize: 11)),
            pw.Bullet(text: 'Medicamentos: ${history.medications.isNotEmpty ? history.medications : "Ninguno"}', style: const pw.TextStyle(fontSize: 11)),
            pw.Bullet(text: 'Alergias: ${history.allergies.isNotEmpty ? history.allergies : "Ninguna"}', style: const pw.TextStyle(fontSize: 11)),
            pw.Bullet(text: 'Cirugías: ${history.surgeries.isNotEmpty ? history.surgeries : "Ninguna"}', style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 24),

            // Sección 3: Historial de Evaluaciones
            pw.Text(
              '3. EVALUACIONES CLÍNICAS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
            ),
            pw.SizedBox(height: 8),
            if (evaluations.isEmpty)
              pw.Text('No se registran evaluaciones.', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic))
            else
              ...evaluations.map((eval) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            eval.isReevaluation ? 'Reevaluación de Progreso' : 'Evaluación Inicial',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                          ),
                          pw.Text(
                            DateFormat('dd/MM/yyyy').format(eval.date),
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                      pw.Text('Motivo de consulta: ${eval.chiefComplaint}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Nivel de Dolor (EVA): ${eval.painScaleEva}/10', style: const pw.TextStyle(fontSize: 10)),
                      if (eval.strengthTest.isNotEmpty)
                        pw.Text('Fuerza Muscular (Daniels): ${eval.strengthTest}', style: const pw.TextStyle(fontSize: 10)),
                      if (eval.flexibilityTest.isNotEmpty)
                        pw.Text('Flexibilidad: ${eval.flexibilityTest}', style: const pw.TextStyle(fontSize: 10)),
                      if (eval.balanceTest.isNotEmpty)
                        pw.Text('Equilibrio/Coordinación: ${eval.balanceTest}', style: const pw.TextStyle(fontSize: 10)),
                      if (eval.jointRangeOfMotion.isNotEmpty)
                        pw.Text(
                          'Rangos Articulares (ROM): ${eval.jointRangeOfMotion.entries.map((e) => '${e.key}: ${e.value}°').join(' · ')}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      pw.Text('Diagnóstico: ${eval.physioDiagnosis}', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                      pw.Text('Objetivos: ${eval.shortTermGoals}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 24),

            // Sección 4: Consentimiento Firmado
            if (consent != null && consent['isSigned'] == true) ...[
              pw.Text(
                '4. CONSENTIMIENTO INFORMADO Y FIRMA',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                consent['consentText'] ?? '',
                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 16),
              if (signatureImage != null)
                pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(signatureImage, width: 140, height: 60),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma del Paciente / Tutor', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(
                        'Firmado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(consent['signedAt']))}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final historyAsync = ref.watch(clinicalHistoryProvider(patientId));
    final evaluationsAsync = ref.watch(evaluationsProvider(patientId));
    final consentAsync = ref.watch(consentProvider(patientId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final patient = patientsAsync.value?.firstWhere((p) => p.id == patientId);

    if (patient == null || historyAsync.value == null || evaluationsAsync.value == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Exportar Reporte PDF',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: PdfPreview(
          build: (format) => _generatePdf(
            patient,
            historyAsync.value!,
            evaluationsAsync.value!,
            consentAsync.value,
          ),
          pdfFileName: 'Expediente_${patient.name.replaceAll(' ', '_')}.pdf',
          canChangePageFormat: false,
          canChangeOrientation: false,
          loadingWidget: const Center(child: CircularProgressIndicator()),
          actions: const [
            PdfPreviewAction(
              icon: Icon(Icons.share_rounded),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
