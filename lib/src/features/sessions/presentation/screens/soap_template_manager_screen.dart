import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/soap_template.dart';

// Configuración de patologías
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

const Map<String, IconData> _pathologyIcons = {
  'general': Icons.medical_services_outlined,
  'lumbar': Icons.accessible_forward_outlined,
  'cervical': Icons.self_improvement_outlined,
  'hombro': Icons.sports_martial_arts_outlined,
  'rodilla': Icons.directions_walk_outlined,
  'deportivo': Icons.sports_soccer_outlined,
  'neurologico': Icons.psychology_outlined,
};

const List<String> _defaultTechniquesList = [
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

class SoapTemplateManagerScreen extends ConsumerStatefulWidget {
  const SoapTemplateManagerScreen({super.key});

  @override
  ConsumerState<SoapTemplateManagerScreen> createState() => _SoapTemplateManagerScreenState();
}

class _SoapTemplateManagerScreenState extends ConsumerState<SoapTemplateManagerScreen> {
  String _filterTag = 'todas';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templatesAsync = ref.watch(soapTemplatesStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Plantillas Clínicas',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('¿Qué son las plantillas?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  content: Text(
                    'Las plantillas SOAP te permiten pre-cargar el formulario de sesión con los datos clínicos más comunes para una patología específica. Esto ahorra tiempo y garantiza consistencia en los registros.',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Entendido', style: GoogleFonts.inter()),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nueva Plantilla', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showTemplateForm(context, isDark, null),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros de patología
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('todas', 'Todas', const Color(0xFF374151), isDark),
                    ..._pathologyLabels.entries.map(
                      (e) => _buildFilterChip(e.key, e.value, _pathologyColors[e.key]!, isDark),
                    ),
                  ],
                ),
              ),
            ),
            // Lista de plantillas
            Expanded(
              child: templatesAsync.when(
                data: (templates) {
                  final filtered = _filterTag == 'todas'
                      ? templates
                      : templates.where((t) => t.pathologyTag == _filterTag).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.paste_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _filterTag == 'todas'
                                ? 'No tienes plantillas creadas aún'
                                : 'No hay plantillas para esta categoría',
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pulsa el botón (+) para crear una nueva',
                            style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final template = filtered[index];
                      final tagColor = _pathologyColors[template.pathologyTag] ?? const Color(0xFF6B7280);
                      final tagLabel = _pathologyLabels[template.pathologyTag] ?? template.pathologyTag;
                      final tagIcon = _pathologyIcons[template.pathologyTag] ?? Icons.medical_services_outlined;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: tagColor, width: 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: tagColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(tagIcon, color: tagColor, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template.name,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tagColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tagLabel,
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
                                              ),
                                            ),
                                            if (template.defaultDurationMinutes != null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '· ${template.defaultDurationMinutes} min',
                                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón editar
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: AppTheme.primaryColor,
                                    onPressed: () => _showTemplateForm(context, isDark, template),
                                  ),
                                  // Botón eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                    color: Colors.red,
                                    onPressed: () => _confirmDelete(context, template),
                                  ),
                                ],
                              ),
                              if (template.defaultTechniques.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: template.defaultTechniques.take(5).map((tech) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(tech, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
                                    );
                                  }).toList(),
                                ),
                              ],
                              // Subjetivo preview
                              if (template.subjective.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  template.subjective,
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error al cargar plantillas: $e', style: GoogleFonts.inter()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color color, bool isDark) {
    final isSelected = _filterTag == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterTag = key),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SoapTemplate template) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar Plantilla', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar la plantilla "${template.name}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(sessionControllerProvider.notifier).deleteSoapTemplate(template.id);
            },
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTemplateForm(BuildContext context, bool isDark, SoapTemplate? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateFormSheet(
        isDark: isDark,
        existing: existing,
        onSave: (template) {
          ref.read(sessionControllerProvider.notifier).saveSoapTemplate(template);
        },
      ),
    );
  }
}

class _TemplateFormSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final SoapTemplate? existing;
  final void Function(SoapTemplate) onSave;

  const _TemplateFormSheet({
    required this.isDark,
    required this.existing,
    required this.onSave,
  });

  @override
  ConsumerState<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends ConsumerState<_TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _subjectiveCtrl;
  late final TextEditingController _objectiveCtrl;
  late final TextEditingController _assessmentCtrl;
  late final TextEditingController _planCtrl;
  final TextEditingController _customTechCtrl = TextEditingController();

  late String _selectedTag;
  late int? _durationMinutes;
  late List<String> _selectedTechniques;
  final List<String> _customTechniques = [];

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _subjectiveCtrl = TextEditingController(text: t?.subjective ?? '');
    _objectiveCtrl = TextEditingController(text: t?.objective ?? '');
    _assessmentCtrl = TextEditingController(text: t?.assessment ?? '');
    _planCtrl = TextEditingController(text: t?.plan ?? '');
    _selectedTag = t?.pathologyTag ?? 'general';
    _durationMinutes = t?.defaultDurationMinutes;
    _selectedTechniques = List<String>.from(t?.defaultTechniques ?? []);
    // Separar técnicas personalizadas
    for (final tech in _selectedTechniques) {
      if (!_defaultTechniquesList.contains(tech)) {
        _customTechniques.add(tech);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectiveCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    _customTechCtrl.dispose();
    super.dispose();
  }

  void _addCustomTech() {
    final name = _customTechCtrl.text.trim();
    if (name.isEmpty || _customTechniques.contains(name)) return;
    setState(() {
      _customTechniques.add(name);
      _selectedTechniques.add(name);
      _customTechCtrl.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authControllerProvider);
    final user = authState.user;
    if (user == null) return;

    final template = SoapTemplate(
      id: widget.existing?.id ?? '',
      clinicId: user.clinicId,
      name: _nameCtrl.text.trim(),
      pathologyTag: _selectedTag,
      subjective: _subjectiveCtrl.text.trim(),
      objective: _objectiveCtrl.text.trim(),
      assessment: _assessmentCtrl.text.trim(),
      plan: _planCtrl.text.trim(),
      defaultTechniques: _selectedTechniques,
      defaultDurationMinutes: _durationMinutes,
    );

    widget.onSave(template);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF131B2E) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existing == null ? 'Nueva Plantilla' : 'Editar Plantilla',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nameCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Nombre de la plantilla *',
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 16),

                    // Patología
                    Text('Categoría / Patología', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _pathologyLabels.entries.map((e) {
                        final isSelected = _selectedTag == e.key;
                        final color = _pathologyColors[e.key]!;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTag = e.key),
                          child: AnimatedContainer(
                            duration: 150.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? color : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              e.value,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Duración sugerida
                    Text('Duración Sugerida', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: (_durationMinutes ?? 45).toDouble(),
                            min: 15,
                            max: 180,
                            divisions: 11,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (v) => setState(() => _durationMinutes = v.toInt()),
                          ),
                        ),
                        Text('${_durationMinutes ?? 45} min', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // SOAP Fields
                    TextFormField(
                      controller: _subjectiveCtrl,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'S — Subjetivo *', alignLabelWithHint: true),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _objectiveCtrl,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'O — Objetivo *', alignLabelWithHint: true),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _assessmentCtrl,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'A — Evaluación *', alignLabelWithHint: true),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _planCtrl,
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'P — Plan *', alignLabelWithHint: true),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 16),

                    // Técnicas
                    Text('Técnicas por Defecto', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _defaultTechniquesList.map((tech) {
                        final isSelected = _selectedTechniques.contains(tech);
                        return ChoiceChip(
                          label: Text(tech, style: GoogleFonts.inter(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                          checkmarkColor: AppTheme.primaryColor,
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _selectedTechniques.add(tech);
                            } else {
                              _selectedTechniques.remove(tech);
                            }
                          }),
                        );
                      }).toList(),
                    ),
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
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _selectedTechniques.add(tech);
                              } else {
                                _selectedTechniques.remove(tech);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customTechCtrl,
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Agregar técnica personalizada...',
                              hintStyle: GoogleFonts.inter(fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            onFieldSubmitted: (_) => _addCustomTech(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _addCustomTech,
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
                    const SizedBox(height: 32),
                    // Botón guardar al final también
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: Text(
                        'Guardar Plantilla',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
