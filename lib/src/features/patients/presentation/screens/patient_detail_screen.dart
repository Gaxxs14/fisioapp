import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../sessions/presentation/providers/session_provider.dart';
import '../../../sessions/domain/entities/session.dart';
import '../providers/patient_provider.dart';
import '../../domain/entities/patient.dart';
import '../../domain/entities/clinical_history.dart';
import '../../domain/entities/patient_evaluation.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/app_user.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  // Controladores para la pestaña Historia Clínica
  final _historyFormKey = GlobalKey<FormState>();
  final _antecedentsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _surgeriesController = TextEditingController();

  // Controladores para la firma de consentimiento
  late SignatureController _signatureController;
  bool _isSignatureCanvasEmpty = true;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _signatureController.onDrawEnd = () {
      setState(() {
        _isSignatureCanvasEmpty = _signatureController.isEmpty;
      });
    };
  }

  @override
  void dispose() {
    _antecedentsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _surgeriesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null && mounted) {
      final fileName = 'file_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileType = source == ImageSource.camera ? 'Foto evolución' : 'Estudio / Radiografía';

      await ref.read(patientControllerProvider.notifier).uploadAttachment(
            patientId: widget.patientId,
            filePath: pickedFile.path,
            fileName: fileName,
            fileType: fileType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo adjuntado correctamente.'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitConsent() async {
    if (_signatureController.isEmpty) return;

    final Uint8List? signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes != null && mounted) {
      const consentText = 'Por medio del presente documento, otorgo mi consentimiento libre e informado para recibir el tratamiento fisioterapéutico propuesto, habiendo comprendido los objetivos, riesgos y beneficios informados por el profesional a cargo.';
      
      await ref.read(patientControllerProvider.notifier).saveConsent(
            patientId: widget.patientId,
            signatureBytes: signatureBytes,
            consentText: consentText,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consentimiento firmado y guardado.'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveHistory() async {
    if (!_historyFormKey.currentState!.validate()) return;

    final updatedHistory = ClinicalHistory(
      patientId: widget.patientId,
      antecedents: _antecedentsController.text.trim(),
      medications: _medicationsController.text.trim(),
      allergies: _allergiesController.text.trim(),
      surgeries: _surgeriesController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await ref.read(patientControllerProvider.notifier).saveClinicalHistory(updatedHistory);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historia clínica actualizada.'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeactivatePatient(BuildContext context, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                'Inactivar Paciente',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas inactivar a ${patient.name}?\n\nSu expediente clínico se conservará por motivos legales, pero ya no aparecerá en el listado activo ni en la agenda.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Inactivar',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(patientControllerProvider.notifier).deactivatePatient(patient);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.name} ha sido inactivado.'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Volver a la lista de pacientes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar el flujo de pacientes
    final patientsAsync = ref.watch(patientsStreamProvider);
    final historyAsync = ref.watch(clinicalHistoryProvider(widget.patientId));
    final evaluationsAsync = ref.watch(evaluationsProvider(widget.patientId));
    final attachmentsAsync = ref.watch(attachmentsProvider(widget.patientId));
    final consentAsync = ref.watch(consentProvider(widget.patientId));

    final authStateAsync = ref.watch(authStateProvider);
    final user = authStateAsync.value;
    final l10n = ref.watch(l10nProvider);

    // Si la lista de pacientes ya cargó y este paciente no se encuentra en ella (o se desactivó)
    final bool isLoaded = patientsAsync.hasValue;
    final bool patientNotFound = isLoaded && 
        !(patientsAsync.value?.any((p) => p.id == widget.patientId) ?? false);

    if (patientNotFound) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.locale == 'es' ? 'Paciente no encontrado' : 'Patient not found'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n.locale == 'es' 
                      ? 'El paciente no existe, se encuentra inactivo o pertenece a otra clínica.'
                      : 'The patient does not exist, is inactive, or belongs to another clinic.',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.locale == 'es' ? 'Volver a la lista' : 'Back to list'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Buscar al paciente en la lista cargada
    final patient = patientsAsync.value?.firstWhere(
      (p) => p.id == widget.patientId,
      orElse: () => Patient(
        id: '',
        clinicId: '',
        name: 'Cargando...',
        dni: '',
        email: '',
        phone: '',
        birthDate: DateTime.now(),
        gender: '',
        contactPersonName: '',
        contactPersonPhone: '',
        createdAt: DateTime.now(),
      ),
    );

    // Cargar controladores con datos existentes de historia clínica
    ref.listen<AsyncValue<ClinicalHistory>>(clinicalHistoryProvider(widget.patientId), (previous, next) {
      if (next.hasValue) {
        final history = next.value!;
        _antecedentsController.text = history.antecedents;
        _medicationsController.text = history.medications;
        _allergiesController.text = history.allergies;
        _surgeriesController.text = history.surgeries;
      }
    });

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patient?.name ?? 'Detalle del Paciente'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (user?.role == UserRole.admin && patient != null && patient.id.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                tooltip: 'Inactivar Paciente',
                onPressed: () => _confirmDeactivatePatient(context, patient),
              ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Exportar a PDF',
              onPressed: () => context.push('/patients/pdf/${widget.patientId}'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Historia Clínica'),
              Tab(text: 'Evaluación'),
              Tab(text: 'Sesiones'),
              Tab(text: 'Archivos'),
              Tab(text: 'Consentimiento'),
              Tab(text: 'Pagos y Bonos'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // 1. Resumen
              _buildResumenTab(patient),

              // 2. Historia Clínica
              _buildHistoryTab(historyAsync),

              // 3. Evaluaciones
              _buildEvaluacionesTab(evaluationsAsync),

              // 4. Sesiones (SOAP)
              _buildSessionsTab(l10n),

              // 5. Archivos
              _buildAttachmentsTab(attachmentsAsync),

              // 6. Consentimiento
              _buildConsentTab(consentAsync),

              // 7. Pagos y Bonos
              _buildPaymentTab(patient),
            ],
          ),
        ),
      ),
    );
  }

  // Pestaña 1: Resumen General
  Widget _buildResumenTab(Patient? patient) {
    if (patient == null || patient.id.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = patient.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta Principal (Hero Header)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0D2137), const Color(0xFF0A3D5C)]
                    : [AppTheme.primaryColor, const Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: patient.photoUrl != null ? NetworkImage(patient.photoUrl!) : null,
                    child: patient.photoUrl == null
                        ? Text(
                            initials,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  patient.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'DNI: ${patient.dni}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          const SizedBox(height: 24),
          
          _buildSectionHeader(Icons.contact_mail_outlined, 'Información del Paciente'),
          const SizedBox(height: 10),
          _buildCardWrapper(
            isDark: isDark,
            child: Column(
              children: [
                _buildInfoRow(Icons.cake_outlined, 'Edad', '${patient.age} años (${DateFormat('dd/MM/yyyy').format(patient.birthDate)})'),
                const Divider(height: 16),
                _buildInfoRow(Icons.wc_outlined, 'Género', patient.gender),
                const Divider(height: 16),
                _buildInfoRow(Icons.phone_outlined, 'Teléfono', patient.phone),
                const Divider(height: 16),
                _buildInfoRow(Icons.email_outlined, 'Correo', patient.email),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(Icons.contact_phone_outlined, 'Contacto de Emergencia'),
          const SizedBox(height: 10),
          _buildCardWrapper(
            isDark: isDark,
            child: Column(
              children: [
                _buildInfoRow(Icons.person_pin_outlined, 'Contacto', patient.contactPersonName),
                const Divider(height: 16),
                _buildInfoRow(Icons.phone_android_outlined, 'Teléfono', patient.contactPersonPhone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // Pestaña 2: Historia Clínica (Editable)
  Widget _buildHistoryTab(AsyncValue<ClinicalHistory> historyAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return historyAsync.when(
      data: (history) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _historyFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCardWrapper(
                  isDark: isDark,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _antecedentsController,
                        maxLines: 4,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Antecedentes médicos (Médicos, Familiares, etc.)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _medicationsController,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Medicamentos bajo consumo',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _allergiesController,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Alergias conocidas',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _surgeriesController,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Cirugías o cirugías previas',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveHistory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Actualizar Historia Clínica',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: GoogleFonts.inter())),
    );
  }

  // Pestaña 3: Evaluaciones y Reevaluaciones
  Widget _buildEvaluacionesTab(AsyncValue<List<PatientEvaluation>> evaluationsAsync) {
    return evaluationsAsync.when(
      data: (evaluations) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Evaluación'),
                      onPressed: () => context.push('/patients/evaluation/${widget.patientId}/false'),
                    ),
                  ),
                  if (evaluations.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('Reevaluar'),
                        onPressed: () => context.push('/patients/evaluation/${widget.patientId}/true'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: evaluations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No hay evaluaciones registradas aún.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: evaluations.length,
                      itemBuilder: (context, index) {
                        final eval = evaluations[index];
                        final isRe = eval.isReevaluation;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isRe ? AppTheme.accentColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Icon(
                                isRe ? Icons.autorenew : Icons.assignment,
                                color: isRe ? AppTheme.accentColor : AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(
                              isRe ? 'Reevaluación de Progreso' : 'Evaluación Inicial',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(eval.date)}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Motivo de consulta: ${eval.chiefComplaint}'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text('Escala EVA (Dolor): ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: eval.painScaleEva > 6
                                                ? Colors.red.shade100
                                                : eval.painScaleEva > 3
                                                    ? Colors.amber.shade100
                                                    : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('${eval.painScaleEva}/10', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Diagnóstico: ${eval.physioDiagnosis}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 8),
                                    Text('Objetivos a Corto Plazo: ${eval.shortTermGoals}'),
                                    Text('Objetivos a Mediano Plazo: ${eval.mediumTermGoals}'),
                                    Text('Objetivos a Largo Plazo: ${eval.longTermGoals}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  // Pestaña 4: Adjuntos
  Widget _buildAttachmentsTab(AsyncValue<List<Map<String, dynamic>>> attachmentsAsync) {
    return attachmentsAsync.when(
      data: (attachments) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                      onPressed: () => _pickImageAndUpload(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Tomar Foto'),
                      onPressed: () => _pickImageAndUpload(ImageSource.camera),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: attachments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No hay radiografías ni fotos de evolución cargadas.', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: attachments.length,
                      itemBuilder: (context, index) {
                        final item = attachments[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.network(
                                  item['fileUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['fileType'] ?? 'Adjunto',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yy').format(DateTime.parse(item['uploadedAt'])),
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  // Pestaña 5: Consentimiento Informado (Lienzo táctil)
  Widget _buildConsentTab(AsyncValue<Map<String, dynamic>?> consentAsync) {
    return consentAsync.when(
      data: (consent) {
        if (consent != null && consent['isSigned'] == true) {
          // Ya firmado
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.accentColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Consentimiento Firmado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Firmado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(consent['signedAt']))}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      consent['consentText'] ?? '',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Firma Digital:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Image.network(consent['signatureImageUrl']),
                ),
              ],
            ),
          );
        }

        // Si no está firmado, mostrar lienzo
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Consentimiento de Tratamiento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por medio del presente documento, otorgo mi consentimiento libre e informado para recibir el tratamiento fisioterapéutico propuesto, habiendo comprendido los objetivos, riesgos y beneficios informados por el profesional a cargo.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Firme en el lienzo a continuación:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Signature(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar Lienzo'),
                    onPressed: () {
                      _signatureController.clear();
                      setState(() {
                        _isSignatureCanvasEmpty = true;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isSignatureCanvasEmpty ? null : _submitConsent,
                child: const Text('Guardar y Confirmar Firma'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSessionsTab(AppLocalizations l10n) {
    final sessionsAsync = ref.watch(sessionsStreamProvider(widget.patientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newSessionBtn),
                  onPressed: () => context.push('/patients/detail/${widget.patientId}/session/new'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                icon: const Icon(Icons.paste_outlined, size: 18, color: AppTheme.primaryColor),
                label: const Text('Plantillas', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                onPressed: () => context.push('/sessions/templates'),
              ),
            ],
          ),
        ),
        Expanded(
          child: sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noSessions,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Ordenar por fecha descendente
              final sortedSessions = List<Session>.from(sessions)
                ..sort((a, b) => b.date.compareTo(a.date));

              return ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                itemCount: sortedSessions.length,
                itemBuilder: (context, index) {
                  final session = sortedSessions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: const Icon(Icons.fitness_center, color: AppTheme.primaryColor),
                      ),
                      title: Text(
                        '${l10n.sessionTitle} - ${DateFormat('dd/MM/yyyy HH:mm').format(session.date)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${session.therapistName} · ${session.durationMinutes} min',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                          // Indicador dolor pre → post
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPainColor(session.painLevelPre).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${session.painLevelPre}→${session.painLevelPost}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPainColor(session.painLevelPost),
                              ),
                            ),
                          ),
                          if (session.photoUrls.isNotEmpty || session.photoPaths.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.photo_camera_outlined, size: 14, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón editar
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
                            tooltip: 'Editar sesión',
                            onPressed: () => context.push(
                              '/patients/detail/${widget.patientId}/session/edit/${session.id}',
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Comparativa de Dolor
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          l10n.locale == 'es' ? 'Dolor Inicial' : 'Pre-Session Pain',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${session.painLevelPre}/10',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getPainColor(session.painLevelPre),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_forward, color: Colors.grey),
                                    Column(
                                      children: [
                                        Text(
                                          l10n.locale == 'es' ? 'Dolor Final' : 'Post-Session Pain',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${session.painLevelPost}/10',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _getPainColor(session.painLevelPost),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Notas SOAP
                              _buildSoapSection('S - Subjetivo', session.subjective),
                              _buildSoapSection('O - Objetivo', session.objective),
                              _buildSoapSection('A - Evaluación', session.assessment),
                              _buildSoapSection('P - Plan', session.plan),

                              // Técnicas
                              if (session.techniques.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Técnicas Aplicadas:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: session.techniques.map((tech) {
                                    return Chip(
                                      label: Text(tech, style: const TextStyle(fontSize: 11)),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                              ],

                              // Notas internas
                              if (session.observations.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildSoapSection(l10n.internalNotesLabel, session.observations, isPrivate: true),
                              ],

                              // Fotos desde Firebase Storage (URLs)
                              if (session.photoUrls.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  l10n.photoEvolutionLabel,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: session.photoUrls.length,
                                    itemBuilder: (context, photoIndex) {
                                      final url = session.photoUrls[photoIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Image.network(url, fit: BoxFit.contain),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Image.network(
                                              url,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                width: 120,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Fotos locales (solo si aún están en el dispositivo)
                              if (session.photoPaths.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  l10n.photoEvolutionLabel,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: session.photoPaths.length,
                                    itemBuilder: (context, photoIndex) {
                                      final path = session.photoPaths[photoIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Image.file(File(path), fit: BoxFit.contain),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Image.file(
                                              File(path),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                width: 120,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildSoapSection(String title, String content, {bool isPrivate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isPrivate ? Colors.deepPurple : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content.isEmpty ? 'Sin registro' : content,
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab(Patient? patient) {
    if (patient == null || patient.id.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bonosAsync = ref.watch(patientBonosStreamProvider(widget.patientId));
    final transactionsAsync = ref.watch(patientTransactionsStreamProvider(widget.patientId));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Acciones Rápidas
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: Text('Registrar Pago', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => context.push(
                    '/billing/pay?patientId=${patient.id}&patientName=${Uri.encodeComponent(patient.name)}&amount=40.0',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección 1: Bonos Activos
          _buildSectionHeader(Icons.card_membership_rounded, 'Bonos y Paquetes Activos'),
          const SizedBox(height: 12),
          bonosAsync.when(
            data: (bonos) {
              if (bonos.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.card_membership_rounded,
                  message: 'El paciente no posee ningún bono o paquete contratado actualmente.',
                );
              }
              return Column(
                children: bonos.map((bono) {
                  final remaining = bono.remainingSessions;
                  final total = bono.purchasedSessions;
                  final percentage = total > 0 ? remaining / total : 0.0;
                  final isExpired = bono.expirationDate.isBefore(DateTime.now());

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                            Expanded(
                              child: Text(
                                bono.serviceName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Text(
                              '$remaining / $total',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isExpired
                                  ? 'Expirado'
                                  : 'Vence: ${DateFormat('dd/MM/yyyy').format(bono.expirationDate)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isExpired ? Colors.red : Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: bono.isPaid ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bono.isPaid ? 'Pagado' : 'Pendiente de Cobro',
                                style: GoogleFonts.inter(
                                  color: bono.isPaid ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error al consultar bonos: $e', style: GoogleFonts.inter()),
          ),
          const SizedBox(height: 28),

          // Sección 2: Historial de Transacciones
          _buildSectionHeader(Icons.receipt_long_rounded, 'Historial de Cobros Recientes'),
          const SizedBox(height: 12),
          transactionsAsync.when(
            data: (patientTxs) {
              if (patientTxs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.receipt_long_rounded,
                  message: 'No se registran transacciones para este paciente.',
                );
              }

              return Column(
                children: patientTxs.map((tx) {
                  IconData icon = Icons.money_rounded;
                  Color iconColor = Colors.green;

                  if (tx.paymentMethod == 'card') {
                    icon = Icons.credit_card_rounded;
                    iconColor = Colors.blue;
                  } else if (tx.paymentMethod == 'transfer') {
                    icon = Icons.account_balance_rounded;
                    iconColor = Colors.purple;
                  } else if (tx.paymentMethod == 'pending') {
                    icon = Icons.hourglass_bottom_rounded;
                    iconColor = Colors.orange;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131B2E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.concept,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(tx.date),
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${tx.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error al cargar historial: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(icon, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Color _getPainColor(int pain) {
    if (pain <= 3) return Colors.green.shade600;
    if (pain <= 7) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
