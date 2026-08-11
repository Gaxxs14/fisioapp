import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';
import '../../domain/entities/patient_evaluation.dart';

class EvaluationFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final bool isReevaluation;

  const EvaluationFormScreen({
    super.key,
    required this.patientId,
    required this.isReevaluation,
  });

  @override
  ConsumerState<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}
class _EvaluationFormScreenState extends ConsumerState<EvaluationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _complaintController = TextEditingController();
  final _flexibilityController = TextEditingController();
  final _balanceController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _shortGoalsController = TextEditingController();
  final _mediumGoalsController = TextEditingController();
  final _longGoalsController = TextEditingController();

  double _painEvaValue = 5.0;
  int? _danielsValue = 5;

  final Map<int, String> _danielsDescriptions = {
    0: '0/5 - Parálisis completa (sin contracción detectable)',
    1: '1/5 - Contracción visible/palpable sin movimiento articular',
    2: '2/5 - Movimiento completo activo eliminando la gravedad',
    3: '3/5 - Movimiento completo activo venciendo la gravedad',
    4: '4/5 - Movimiento completo contra gravedad + resistencia moderada',
    5: '5/5 - Fuerza muscular normal (contra gravedad + resistencia máxima)',
  };

  final List<String> _evaEmojis = ['😊', '😊', '🙂', '🙂', '😐', '😐', '🙁', '🙁', '😫', '😫', '😭'];
  final List<String> _evaDescriptions = [
    'Sin Dolor (0/10)',
    'Dolor Muy Leve (1/10)',
    'Dolor Leve (2/10)',
    'Dolor Leve-Moderado (3/10)',
    'Dolor Moderado (4/10)',
    'Dolor Moderado-Fuerte (5/10)',
    'Dolor Fuerte (6/10)',
    'Dolor Muy Fuerte (7/10)',
    'Dolor Severo (8/10)',
    'Dolor Muy Severo (9/10)',
    'Dolor Insoportable / Máximo (10/10)',
  ];

  final List<Color> _evaColors = [
    Colors.green.shade600,
    Colors.green.shade600,
    Colors.lightGreen.shade600,
    Colors.lightGreen.shade600,
    Colors.amber.shade700,
    Colors.amber.shade700,
    Colors.orange.shade700,
    Colors.orange.shade700,
    Colors.red.shade600,
    Colors.red.shade800,
    Colors.red.shade900,
  ];

  final Map<String, int> _normalRomValues = {
    'Hombro Flexión': 180,
    'Codo Flexión': 150,
    'Rodilla Flexión': 135,
    'Cadera Flexión': 120,
  };

  final Map<String, TextEditingController> _romControllers = {
    'Hombro Flexión': TextEditingController(text: '180'),
    'Codo Flexión': TextEditingController(text: '150'),
    'Rodilla Flexión': TextEditingController(text: '135'),
    'Cadera Flexión': TextEditingController(text: '120'),
  };

  PatientEvaluation? _previousEvaluation;

  @override
  void initState() {
    super.initState();
    if (widget.isReevaluation) {
      _loadPreviousEvaluation();
    }
  }

  Future<void> _loadPreviousEvaluation() async {
    final evaluations = await ref.read(patientRepositoryProvider).getEvaluations(patientId: widget.patientId);
    if (evaluations.isNotEmpty) {
      setState(() {
        _previousEvaluation = evaluations.first;
        
        _complaintController.text = _previousEvaluation!.chiefComplaint;
        _flexibilityController.text = _previousEvaluation!.flexibilityTest;
        _balanceController.text = _previousEvaluation!.balanceTest;
        _diagnosisController.text = _previousEvaluation!.physioDiagnosis;
        _shortGoalsController.text = _previousEvaluation!.shortTermGoals;
        _mediumGoalsController.text = _previousEvaluation!.mediumTermGoals;
        _longGoalsController.text = _previousEvaluation!.longTermGoals;
        _painEvaValue = _previousEvaluation!.painScaleEva.toDouble();
        
        // Parse Daniels Scale
        if (_previousEvaluation!.strengthTest.isNotEmpty) {
          final firstChar = _previousEvaluation!.strengthTest[0];
          _danielsValue = int.tryParse(firstChar) ?? 5;
        }

        for (var entry in _previousEvaluation!.jointRangeOfMotion.entries) {
          if (_romControllers.containsKey(entry.key)) {
            _romControllers[entry.key]!.text = entry.value.toString();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _flexibilityController.dispose();
    _balanceController.dispose();
    _diagnosisController.dispose();
    _shortGoalsController.dispose();
    _mediumGoalsController.dispose();
    _longGoalsController.dispose();
    for (var controller in _romControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildRomStatusBadge(String jointName, String enteredValueStr) {
    final normalVal = _normalRomValues[jointName]!;
    final val = int.tryParse(enteredValueStr) ?? 0;
    
    String label = 'Normal';
    Color color = Colors.green;
    
    if (val < normalVal * 0.7) {
      label = 'Limitación Severa';
      color = Colors.red;
    } else if (val < normalVal * 0.95) {
      label = 'Limitación Leve';
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, int> romMap = {};
    _romControllers.forEach((key, controller) {
      romMap[key] = int.tryParse(controller.text.trim()) ?? 0;
    });

    final String strengthTestString = _danielsValue != null 
        ? '$_danielsValue/5 - ${_danielsDescriptions[_danielsValue]}' 
        : '';

    await ref.read(patientControllerProvider.notifier).addEvaluation(
      patientId: widget.patientId,
      chiefComplaint: _complaintController.text.trim(),
      painScaleEva: _painEvaValue.toInt(),
      jointRangeOfMotion: romMap,
      strengthTest: strengthTestString,
      flexibilityTest: _flexibilityController.text.trim(),
      balanceTest: _balanceController.text.trim(),
      physioDiagnosis: _diagnosisController.text.trim(),
      shortTermGoals: _shortGoalsController.text.trim(),
      mediumTermGoals: _mediumGoalsController.text.trim(),
      longTermGoals: _longGoalsController.text.trim(),
      isReevaluation: widget.isReevaluation,
      comparedToEvaluationId: _previousEvaluation?.id,
    );

    final state = ref.read(patientControllerProvider);
    if (state.success && state.errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.isReevaluation
                      ? 'Reevaluación registrada exitosamente.'
                      : 'Evaluación inicial registrada exitosamente.',
                  style: GoogleFonts.inter(),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    }
  }  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(patientControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<PatientUiState>(patientControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(patientControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          widget.isReevaluation ? 'Reevaluación de Progreso' : 'Evaluación Inicial',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Comparativo de Progreso (solo en reevaluaciones)
                  if (widget.isReevaluation && _previousEvaluation != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.compare_arrows_rounded, color: AppTheme.accentColor),
                              const SizedBox(width: 8),
                              Text(
                                'Comparativa con Evaluación Anterior',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('EVA Anterior: ${_previousEvaluation!.painScaleEva}/10', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text('Rangos de movimiento anteriores:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: _previousEvaluation!.jointRangeOfMotion.entries.map((entry) {
                              return Text(
                                '• ${entry.key}: ${entry.value}°',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 24),
                  ],

                  // ── ANAMNESIS Y DOLOR ──────────────────────────────
                  _buildSectionHeader(Icons.healing_outlined, 'Anamnesis y Dolor'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _complaintController,
                          maxLines: 3,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Motivo de Consulta / Síntomas',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Escribe el motivo de consulta' : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Escala de Dolor Visual (EVA)',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Visual interactive indicator
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _evaColors[_painEvaValue.toInt()].withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _evaColors[_painEvaValue.toInt()].withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _evaEmojis[_painEvaValue.toInt()],
                                style: const TextStyle(fontSize: 36),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Intensidad del Dolor',
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _evaDescriptions[_painEvaValue.toInt()],
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _evaColors[_painEvaValue.toInt()],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: _painEvaValue,
                          min: 0.0,
                          max: 10.0,
                          divisions: 10,
                          activeColor: _evaColors[_painEvaValue.toInt()],
                          inactiveColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                          onChanged: (value) {
                            setState(() {
                              _painEvaValue = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sin Dolor (0)', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                            Text('Moderado (5)', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                            Text('Máximo (10)', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── RANGOS DE MOVIMIENTO (ROM) ──────────────────────
                  _buildSectionHeader(Icons.explore_outlined, 'Rangos de Movimiento (ROM en Grados)'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Hombro Flex. (Norm: 180°)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      _buildRomStatusBadge('Hombro Flexión', _romControllers['Hombro Flexión']!.text),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _romControllers['Hombro Flexión'],
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(fontSize: 13),
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Codo Flex. (Norm: 150°)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      _buildRomStatusBadge('Codo Flexión', _romControllers['Codo Flexión']!.text),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _romControllers['Codo Flexión'],
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(fontSize: 13),
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Rodilla Flex. (Norm: 135°)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      _buildRomStatusBadge('Rodilla Flexión', _romControllers['Rodilla Flexión']!.text),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _romControllers['Rodilla Flexión'],
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(fontSize: 13),
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cadera Flex. (Norm: 120°)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      _buildRomStatusBadge('Cadera Flexión', _romControllers['Cadera Flexión']!.text),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _romControllers['Cadera Flexión'],
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(fontSize: 13),
                                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── PRUEBAS FISICAS ────────────────────────────────
                  _buildSectionHeader(Icons.accessibility_new_outlined, 'Pruebas y Tests Físicos'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Daniels Scale Dropdown
                        DropdownButtonFormField<int>(
                          initialValue: _danielsValue,
                          decoration: const InputDecoration(
                            labelText: 'Fuerza Muscular (Escala Daniels)',
                            prefixIcon: Icon(Icons.fitness_center_outlined),
                          ),
                          items: _danielsDescriptions.entries.map((e) {
                            return DropdownMenuItem<int>(
                              value: e.key,
                              child: Text(e.value, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _danielsValue = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _flexibilityController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Test de Flexibilidad (Sit & Reach / Wells en cm)',
                            prefixIcon: Icon(Icons.swap_calls),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _balanceController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Test de Equilibrio / Coordinación (Tinetti / Berg / SLS en seg)',
                            prefixIcon: Icon(Icons.directions_walk_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── DIAGNOSTICO Y OBJETIVOS ─────────────────────────
                  _buildSectionHeader(Icons.playlist_add_check_outlined, 'Diagnóstico y Plan de Tratamiento'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _diagnosisController,
                          maxLines: 3,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Diagnóstico Fisioterapéutico (Texto Libre)',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Escribe el diagnóstico fisioterapéutico' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _shortGoalsController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Objetivos a Corto Plazo',
                            prefixIcon: Icon(Icons.alarm_on_outlined),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Escribe objetivos a corto plazo' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mediumGoalsController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Objetivos a Mediano Plazo',
                            prefixIcon: Icon(Icons.hourglass_empty_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _longGoalsController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Objetivos a Largo Plazo',
                            prefixIcon: Icon(Icons.stars_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Guardar
                  ElevatedButton(
                    onPressed: uiState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: uiState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.isReevaluation ? 'Registrar Reevaluación' : 'Registrar Evaluación Inicial',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
