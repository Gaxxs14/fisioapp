import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_error_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/soap_template.dart';
import '../../../billing/presentation/providers/billing_provider.dart';
import '../../tools/presentation/widgets/body_pain_map_widget.dart';

// Mapa de etiquetas de patología para mostrar en la UI
const Map<String, String> _pathologyLabels = {
  'general': 'General',
  'lumbar': 'Lumbar',
  'cervical': 'Cervical',
  'hombro': 'Hombro',
  'rodilla': 'Rodilla',
  'deportivo': 'Deportivo',
  'neurologico': 'Neurológico',
};

const Map<String, Color> _pathologyColors = {
  'general': Color(0xFF6B7280),
  'lumbar': Color(0xFF7C3AED),
  'cervical': Color(0xFF2563EB),
  'hombro': Color(0xFF059669),
  'rodilla': Color(0xFFD97706),
  'deportivo': Color(0xFFDC2626),
  'neurologico': Color(0xFF0F766E),
};

class SessionFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? appointmentId;
  /// Si se pasa sessionId, la pantalla entra en modo edición
  final String? sessionId;

  const SessionFormScreen({
    super.key,
    required this.patientId,
    this.appointmentId,
    this.sessionId,
  });

  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectiveController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _assessmentController = TextEditingController();
  final _planController = TextEditingController();
  final _observationsController = TextEditingController();
  final _templateNameController = TextEditingController();
  final _customTechniqueController = TextEditingController();

  double _painLevelPre = 3.0;
  double _painLevelPost = 1.0;
  int _durationMinutes = 45;

  // Técnicas predefinidas
  final List<String> _techniquesList = [
    'Masoterapia',
    'Kinesioterapia',
    'Electroterapia',
    'Ultrasonido',
    'Punción Seca',
    'Estiramientos',
    'Termoterapia',
    'Magnetoterapia',
    'Drenaje Linfático',
    'Presoterapia',
    'Crioterapia',
    'Tracción Cervical',
  ];
  final List<String> _selectedTechniques = [];
  final List<String> _customTechniques = []; // técnicas añadidas por el usuario
  final List<String> _photoPaths = [];       // rutas locales (solo sesión activa)
  final List<String> _photoUrls = [];        // URLs Firebase Storage (persistidas)

  bool _saveAsTemplate = false;
  SoapTemplate? _selectedTemplate;
  String? _selectedServiceId;
  String? _selectedServiceName;
  String _selectedPathologyFilter = 'todas';

  // Para modo edición
  bool _isEditMode = false;
  bool _isLoadingSession = false;
  String? _existingSessionId;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      _isEditMode = true;
      _existingSessionId = widget.sessionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingSession();
      });
    }
  }

  Future<void> _loadExistingSession() async {
    setState(() => _isLoadingSession = true);
    try {
      final session = await ref.read(sessionByIdProvider(widget.sessionId!).future);
      if (session != null && mounted) {
        setState(() {
          _subjectiveController.text = session.subjective;
          _objectiveController.text = session.objective;
          _assessmentController.text = session.assessment;
          _planController.text = session.plan;
          _observationsController.text = session.observations;
          _painLevelPre = session.painLevelPre.toDouble();
          _painLevelPost = session.painLevelPost.toDouble();
          _durationMinutes = session.durationMinutes;
          _selectedServiceId = session.serviceId;
          _selectedServiceName = session.serviceName;
          _photoUrls.addAll(session.photoUrls);
          // Cargar técnicas: separar predefinidas de personalizadas
          for (final tech in session.techniques) {
            if (_techniquesList.contains(tech)) {
              _selectedTechniques.add(tech);
            } else {
              _customTechniques.add(tech);
            }
          }
          _isLoadingSession = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSession = false);
    }
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _observationsController.dispose();
    _templateNameController.dispose();
    _customTechniqueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _photoPaths.add(pickedFile.path);
      });
    }
  }

  void _openPainMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0A0F1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mapa Anatómico de Puntos de Dolor',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  child: const BodyPainMapWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addCustomTechnique() {
    final name = _customTechniqueController.text.trim();
    if (name.isEmpty) return;
    if (_techniquesList.contains(name) || _customTechniques.contains(name)) return;
    setState(() {
      _customTechniques.add(name);
      _selectedTechniques.add(name);
      _customTechniqueController.clear();
    });
  }

  void _onTemplateSelected(SoapTemplate? template) {
    if (template == null) {
      setState(() {
        _selectedTemplate = null;
      });
      return;
    }

    setState(() {
      _selectedTemplate = template;
      _subjectiveController.text = template.subjective;
      _objectiveController.text = template.objective;
      _assessmentController.text = template.assessment;
      _planController.text = template.plan;

      _selectedTechniques.clear();
      for (var tech in template.defaultTechniques) {
        if (_techniquesList.contains(tech) && !_selectedTechniques.contains(tech)) {
          _selectedTechniques.add(tech);
        }
      }

      if (template.defaultDurationMinutes != null) {
        _durationMinutes = template.defaultDurationMinutes!;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plantilla "${template.name}" cargada con éxito', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authControllerProvider);
    final user = authState.user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Sesión de usuario no activa', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_saveAsTemplate) {
      final templateName = _templateNameController.text.trim();
      if (templateName.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor ingresa un nombre para la plantilla', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final allTechniques = [..._selectedTechniques];
      final newTemplate = SoapTemplate(
        id: '',
        clinicId: user.clinicId,
        name: templateName,
        pathologyTag: _selectedTemplate?.pathologyTag ?? 'general',
        subjective: _subjectiveController.text.trim(),
        objective: _objectiveController.text.trim(),
        assessment: _assessmentController.text.trim(),
        plan: _planController.text.trim(),
        defaultTechniques: allTechniques,
      );

      await ref.read(sessionControllerProvider.notifier).saveSoapTemplate(newTemplate);
    }

    if (!mounted) return;

    if (_selectedServiceId == null && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona el servicio realizado', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final allTechniques = [..._selectedTechniques];

    if (_isEditMode && _existingSessionId != null) {
      // MODO EDICIÓN: cargar sesión existente y actualizar campos
      final existingSession = await ref.read(sessionByIdProvider(_existingSessionId!).future);
      if (!mounted) return;
      if (existingSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se encontró la sesión original', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor),
        );
        return;
      }
      final updated = existingSession.copyWith(
        subjective: _subjectiveController.text.trim(),
        objective: _objectiveController.text.trim(),
        assessment: _assessmentController.text.trim(),
        plan: _planController.text.trim(),
        painLevelPre: _painLevelPre.toInt(),
        painLevelPost: _painLevelPost.toInt(),
        durationMinutes: _durationMinutes,
        techniques: allTechniques,
        observations: _observationsController.text.trim(),
        photoUrls: _photoUrls,
        serviceId: _selectedServiceId ?? existingSession.serviceId,
        serviceName: _selectedServiceName ?? existingSession.serviceName,
        updatedAt: DateTime.now(),
      );
      await ref.read(sessionControllerProvider.notifier).updateSession(updated);
    } else {
      // MODO CREACIÓN
      final session = Session(
        id: '',
        clinicId: user.clinicId,
        patientId: widget.patientId,
        therapistId: user.uid,
        therapistName: user.name,
        appointmentId: widget.appointmentId,
        date: DateTime.now(),
        subjective: _subjectiveController.text.trim(),
        objective: _objectiveController.text.trim(),
        assessment: _assessmentController.text.trim(),
        plan: _planController.text.trim(),
        painLevelPre: _painLevelPre.toInt(),
        painLevelPost: _painLevelPost.toInt(),
        durationMinutes: _durationMinutes,
        techniques: allTechniques,
        observations: _observationsController.text.trim(),
        photoPaths: _photoPaths,
        photoUrls: _photoUrls,
        serviceId: _selectedServiceId,
        serviceName: _selectedServiceName,
      );

      await ref.read(sessionControllerProvider.notifier).saveSession(session);
    }
  }

  Color _getPainColor(double value) {
    if (value <= 3.0) return Colors.green;
    if (value <= 7.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final templatesAsync = ref.watch(soapTemplatesStreamProvider);
    final sessionState = ref.watch(sessionControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final servicesAsync = ref.watch(servicesStreamProvider);
    final bonosAsync = ref.watch(patientBonosStreamProvider(widget.patientId));

    ref.listen<SessionUiState>(sessionControllerProvider, (previous, next) {
      if (next.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Sesión actualizada con éxito' : l10n.sessionSavedSuccess,
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (mounted) context.pop();
      } else if (next.errorMessage != null) {
        if (!mounted) return;
        final formattedError = FirebaseErrorFormatter.format(next.errorMessage!, l10n.locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formattedError, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(sessionControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Editar Sesión Clínica' : l10n.sessionTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('Editando', style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: (_isLoadingSession || sessionState.isLoading)
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── SELECTOR DE PLANTILLA CON FILTRO ────────────────
                      _buildSectionHeader(Icons.paste_outlined, 'Plantilla de Sesión'),
                      const SizedBox(height: 12),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: templatesAsync.when(
                          data: (templates) {
                            // Filtrar plantillas por categoría seleccionada
                            final filtered = _selectedPathologyFilter == 'todas'
                                ? templates
                                : templates.where((t) => t.pathologyTag == _selectedPathologyFilter).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Filtros de patología
                                SizedBox(
                                  height: 36,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _buildPathologyFilterChip('todas', 'Todas', const Color(0xFF374151), isDark),
                                      ..._pathologyLabels.entries.map((e) =>
                                          _buildPathologyFilterChip(e.key, e.value, _pathologyColors[e.key]!, isDark)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<SoapTemplate>(
                                  initialValue: _selectedTemplate,
                                  decoration: InputDecoration(
                                    labelText: l10n.selectTemplateLabel,
                                    prefixIcon: const Icon(Icons.paste_outlined, color: AppTheme.primaryColor),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  items: [
                                    DropdownMenuItem<SoapTemplate>(
                                      value: null,
                                      child: Text(l10n.defaultTemplateChoice, style: GoogleFonts.inter(fontSize: 13)),
                                    ),
                                    ...filtered.map(
                                      (t) => DropdownMenuItem<SoapTemplate>(
                                        value: t,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (_pathologyColors[t.pathologyTag] ?? const Color(0xFF6B7280)).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _pathologyLabels[t.pathologyTag] ?? t.pathologyTag,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _pathologyColors[t.pathologyTag] ?? const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(child: Text(t.name, style: GoogleFonts.inter(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) => _onTemplateSelected(value),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('Error al cargar plantillas: $err', style: GoogleFonts.inter()),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── SELECTOR DE SERVICIO REALIZADO ─────────────────
                      _buildSectionHeader(Icons.medical_services_outlined, 'Servicio Realizado'),
                      const SizedBox(height: 12),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: servicesAsync.when(
                          data: (services) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedServiceId,
                                  decoration: const InputDecoration(
                                    labelText: 'Seleccionar Servicio Realizado',
                                    prefixIcon: Icon(Icons.medical_services_outlined, color: AppTheme.primaryColor),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  items: services.map(
                                    (s) => DropdownMenuItem<String>(
                                      value: s.id,
                                      child: Text('${s.name} (\$${s.price.toStringAsFixed(2)})', style: GoogleFonts.inter(fontSize: 13)),
                                    ),
                                  ).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedServiceId = val;
                                      final service = services.firstWhere((s) => s.id == val);
                                      _selectedServiceName = service.name;
                                    });
                                  },
                                ),
                                if (_selectedServiceId != null) ...[
                                  bonosAsync.when(
                                    data: (bonos) {
                                      final activeMatches = bonos.where((b) =>
                                          b.serviceId == _selectedServiceId &&
                                          b.remainingSessions > 0 &&
                                          b.expirationDate.isAfter(DateTime.now()));

                                      if (activeMatches.isNotEmpty) {
                                        final matchedBono = activeMatches.first;
                                        return Container(
                                          margin: const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  '✓ Bono activo detectado para este servicio (${matchedBono.remainingSessions} sesiones restantes). Se descontará automáticamente al guardar.',
                                                  style: GoogleFonts.inter(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        final service = services.firstWhere((s) => s.id == _selectedServiceId);
                                        return Container(
                                          margin: const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'ℹ Paciente sin bono activo. Se deberá registrar cobro de \$${service.price.toStringAsFixed(2)} manualmente en Cobranza.',
                                                  style: GoogleFonts.inter(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    loading: () => const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: LinearProgressIndicator(),
                                    ),
                                    error: (e, s) => const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('Error al cargar servicios: $err', style: GoogleFonts.inter()),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── REGISTRO CLINICO SOAP ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildSectionHeader(Icons.edit_note_outlined, 'Notas SOAP (Registro Clínico)')),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.accessibility_new_rounded, size: 16),
                            label: Text('Mapa de Dolor', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _openPainMapModal(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _subjectiveController,
                              maxLines: 3,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: l10n.subjectiveLabel,
                                alignLabelWithHint: true,
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _objectiveController,
                              maxLines: 3,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: l10n.objectiveLabel,
                                alignLabelWithHint: true,
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _assessmentController,
                              maxLines: 3,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: l10n.assessmentLabel,
                                alignLabelWithHint: true,
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _planController,
                              maxLines: 3,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: l10n.planLabel,
                                alignLabelWithHint: true,
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Este campo es obligatorio'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── PARAMETROS (DOLOR Y TIEMPO) ────────────────────
                      _buildSectionHeader(Icons.analytics_outlined, 'Parámetros de la Sesión'),
                      const SizedBox(height: 12),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dolor Pre
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.painLevelPreLabel,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPainColor(_painLevelPre).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_painLevelPre.toInt()}/10',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _getPainColor(_painLevelPre),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _painLevelPre,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              activeColor: _getPainColor(_painLevelPre),
                              inactiveColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                              onChanged: (val) => setState(() => _painLevelPre = val),
                            ),
                            const SizedBox(height: 16),

                            // Dolor Post
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.painLevelPostLabel,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPainColor(_painLevelPost).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_painLevelPost.toInt()}/10',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _getPainColor(_painLevelPost),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _painLevelPost,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              activeColor: _getPainColor(_painLevelPost),
                              inactiveColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                              onChanged: (val) => setState(() => _painLevelPost = val),
                            ),
                            const SizedBox(height: 8),

                            // Comparador de Alivio de Dolor en la Sesión
                            if (_painLevelPre > 0)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: (_painLevelPost < _painLevelPre)
                                      ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1)
                                      : Colors.grey.withValues(alpha: isDark ? 0.15 : 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_painLevelPost < _painLevelPre)
                                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      (_painLevelPost < _painLevelPre) ? Icons.trending_down_rounded : Icons.info_outline_rounded,
                                      color: (_painLevelPost < _painLevelPre) ? const Color(0xFF10B981) : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        (_painLevelPost < _painLevelPre)
                                            ? '¡Evolución Favorable! Reducción de ${(_painLevelPre - _painLevelPost).toInt()} puntos (${(((_painLevelPre - _painLevelPost) / _painLevelPre) * 100).toInt()}% de alivio inmediato).'
                                            : (_painLevelPost == _painLevelPre)
                                                ? 'Dolor estable sin variaciones tras la intervención.'
                                                : 'Aumento de dolor post-sesión. Ajustar dosificación de carga.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: (_painLevelPost < _painLevelPre)
                                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),

                            // Duración (mejorada a 180 min, pasos de 15 min)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.durationRealLabel,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '$_durationMinutes min',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                            Slider(
                              value: _durationMinutes.toDouble(),
                              min: 15,
                              max: 180,
                              divisions: 11,
                              activeColor: AppTheme.primaryColor,
                              inactiveColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                              onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── TECNICAS APLICADAS (con input personalizado) ──
                      _buildSectionHeader(Icons.fitness_center_outlined, l10n.techniquesAppliedLabel),
                      const SizedBox(height: 12),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Chips predefinidos
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _techniquesList.map((technique) {
                                final isSelected = _selectedTechniques.contains(technique);
                                return ChoiceChip(
                                  label: Text(technique, style: GoogleFonts.inter(fontSize: 11)),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  checkmarkColor: AppTheme.primaryColor,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedTechniques.add(technique);
                                      } else {
                                        _selectedTechniques.remove(technique);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            // Chips personalizados
                            if (_customTechniques.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _customTechniques.map((tech) {
                                  final isSelected = _selectedTechniques.contains(tech);
                                  return ChoiceChip(
                                    label: Text(tech, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryColor)),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    checkmarkColor: AppTheme.primaryColor,
                                    side: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedTechniques.add(tech);
                                        } else {
                                          _selectedTechniques.remove(tech);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                            // Campo para agregar técnica personalizada
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customTechniqueController,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Agregar técnica personalizada...',
                                      hintStyle: GoogleFonts.inter(fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      isDense: true,
                                    ),
                                    onFieldSubmitted: (_) => _addCustomTechnique(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _addCustomTechnique,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── OBSERVACIONES INTERNAS (PRIVADAS) ────────────
                      _buildSectionHeader(Icons.lock_person_outlined, 'Observaciones Internas'),
                      const SizedBox(height: 12),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: TextFormField(
                          controller: _observationsController,
                          maxLines: 3,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: l10n.internalNotesLabel,
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
                            helperText: 'Solo visible para el personal de la clínica',
                            helperStyle: GoogleFonts.inter(fontSize: 11, color: Colors.deepPurple),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── FOTOS DE EVOLUCION ───────────────────────────
                      _buildSectionHeader(Icons.add_a_photo_outlined, l10n.photoEvolutionLabel),
                      const SizedBox(height: 12),
                      _buildCardWrapper(
                        isDark: isDark,
                        child: Column(
                          children: [
                            // Mostrar fotos guardadas en Firebase Storage
                            if (_photoUrls.isNotEmpty) ...[
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _photoUrls.length,
                                  itemBuilder: (context, idx) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              _photoUrls[idx],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey.shade300,
                                                child: const Icon(Icons.image_not_supported),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => setState(() => _photoUrls.removeAt(idx)),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Mostrar fotos locales tomadas en esta sesión
                            if (_photoPaths.isNotEmpty) ...[
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _photoPaths.length,
                                  itemBuilder: (context, idx) {
                                    final path = _photoPaths[idx];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.file(
                                              File(path),
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => setState(() => _photoPaths.removeAt(idx)),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                    label: Text(l10n.addPhotoBtn, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                    onPressed: () => _pickImage(ImageSource.camera),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                                    label: Text('Galería', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── GUARDAR COMO PLANTILLA (solo en modo creación) ─
                      if (!_isEditMode) ...[
                        _buildSectionHeader(Icons.bookmark_border_outlined, 'Autoguardado de Plantilla'),
                        const SizedBox(height: 12),
                        _buildCardWrapper(
                          isDark: isDark,
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.saveAsTemplateLabel,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                activeThumbColor: AppTheme.primaryColor,
                                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                value: _saveAsTemplate,
                                onChanged: (val) => setState(() => _saveAsTemplate = val),
                              ),
                              if (_saveAsTemplate) ...[
                                const Divider(),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _templateNameController,
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: l10n.templateNameLabel,
                                    prefixIcon: const Icon(Icons.label_outline),
                                  ),
                                  validator: (value) => _saveAsTemplate && (value == null || value.trim().isEmpty)
                                      ? 'Nombre de plantilla obligatorio'
                                      : null,
                                ).animate().slideY(begin: -0.2, end: 0, duration: 200.ms).fadeIn(),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── BOTON ENVIAR / CONFIRMAR ─────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF0EA5E9)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _submitForm(),
                          child: Text(
                            _isEditMode ? 'Guardar Cambios' : l10n.saveBtn,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPathologyFilterChip(String key, String label, Color color, bool isDark) {
    final isSelected = _selectedPathologyFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedPathologyFilter = key;
          _selectedTemplate = null;
        }),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
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
}
