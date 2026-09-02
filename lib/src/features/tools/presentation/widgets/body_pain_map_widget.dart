import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class PainPoint {
  final String id;
  final String name;
  final String view; // 'anterior' | 'posterior'
  final Offset relativePos; // (x, y) de 0.0 a 1.0
  int evaPain; // 1 - 10
  String type; // 'Miofascial', 'Articular', 'Neural', 'Inflamatorio'

  PainPoint({
    required this.id,
    required this.name,
    required this.view,
    required this.relativePos,
    this.evaPain = 5,
    this.type = 'Miofascial',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'view': view,
    'evaPain': evaPain,
    'type': type,
  };
}

class BodyPainMapWidget extends StatefulWidget {
  final List<PainPoint> initialPoints;
  final ValueChanged<List<PainPoint>>? onPointsChanged;
  final bool readOnly;

  const BodyPainMapWidget({
    super.key,
    this.initialPoints = const [],
    this.onPointsChanged,
    this.readOnly = false,
  });

  @override
  State<BodyPainMapWidget> createState() => _BodyPainMapWidgetState();
}

class _BodyPainMapWidgetState extends State<BodyPainMapWidget> {
  String _currentView = 'anterior'; // 'anterior' | 'posterior'
  late List<PainPoint> _points;
  PainPoint? _selectedPoint;

  // Zonas anatómicas predefinidas para selección táctil intuitiva
  static final List<PainPoint> _presetAnterior = [
    PainPoint(id: 'cervical_ant', name: 'Cuello Anterior', view: 'anterior', relativePos: const Offset(0.50, 0.16)),
    PainPoint(id: 'hombro_der_ant', name: 'Hombro Derecho', view: 'anterior', relativePos: const Offset(0.26, 0.22)),
    PainPoint(id: 'hombro_izq_ant', name: 'Hombro Izquierdo', view: 'anterior', relativePos: const Offset(0.74, 0.22)),
    PainPoint(id: 'pectoral', name: 'Tórax / Pectoral', view: 'anterior', relativePos: const Offset(0.50, 0.28)),
    PainPoint(id: 'codo_der_ant', name: 'Codo Derecho', view: 'anterior', relativePos: const Offset(0.18, 0.36)),
    PainPoint(id: 'codo_izq_ant', name: 'Codo Izquierdo', view: 'anterior', relativePos: const Offset(0.82, 0.36)),
    PainPoint(id: 'abdomen', name: 'Abdomen / Core', view: 'anterior', relativePos: const Offset(0.50, 0.40)),
    PainPoint(id: 'cadera_der_ant', name: 'Cadera Derecha', view: 'anterior', relativePos: const Offset(0.36, 0.49)),
    PainPoint(id: 'cadera_izq_ant', name: 'Cadera Izquierda', view: 'anterior', relativePos: const Offset(0.64, 0.49)),
    PainPoint(id: 'cuadriceps_der', name: 'Cuádriceps Derecho', view: 'anterior', relativePos: const Offset(0.36, 0.60)),
    PainPoint(id: 'cuadriceps_izq', name: 'Cuádriceps Izquierdo', view: 'anterior', relativePos: const Offset(0.64, 0.60)),
    PainPoint(id: 'rodilla_der_ant', name: 'Rodilla Derecha', view: 'anterior', relativePos: const Offset(0.36, 0.72)),
    PainPoint(id: 'rodilla_izq_ant', name: 'Rodilla Izquierda', view: 'anterior', relativePos: const Offset(0.64, 0.72)),
    PainPoint(id: 'tobillo_der_ant', name: 'Tobillo Derecho', view: 'anterior', relativePos: const Offset(0.38, 0.88)),
    PainPoint(id: 'tobillo_izq_ant', name: 'Tobillo Izquierdo', view: 'anterior', relativePos: const Offset(0.62, 0.88)),
  ];

  static final List<PainPoint> _presetPosterior = [
    PainPoint(id: 'cervical_post', name: 'Cervical / Nuca', view: 'posterior', relativePos: const Offset(0.50, 0.16)),
    PainPoint(id: 'trapecio_der', name: 'Trapecio Superior Dcho', view: 'posterior', relativePos: const Offset(0.32, 0.21)),
    PainPoint(id: 'trapecio_izq', name: 'Trapecio Superior Izq', view: 'posterior', relativePos: const Offset(0.68, 0.21)),
    PainPoint(id: 'escapula_der', name: 'Escápula Derecha', view: 'posterior', relativePos: const Offset(0.34, 0.29)),
    PainPoint(id: 'escapula_izq', name: 'Escápula Izquierda', view: 'posterior', relativePos: const Offset(0.66, 0.29)),
    PainPoint(id: 'dorsal', name: 'Columna Dorsal', view: 'posterior', relativePos: const Offset(0.50, 0.32)),
    PainPoint(id: 'lumbar', name: 'Columna Lumbar', view: 'posterior', relativePos: const Offset(0.50, 0.44)),
    PainPoint(id: 'gluteo_der', name: 'Glúteo / Piramidal Dcho', view: 'posterior', relativePos: const Offset(0.35, 0.52)),
    PainPoint(id: 'gluteo_izq', name: 'Glúteo / Piramidal Izq', view: 'posterior', relativePos: const Offset(0.65, 0.52)),
    PainPoint(id: 'isquio_der', name: 'Isquiotibiales Dcho', view: 'posterior', relativePos: const Offset(0.36, 0.62)),
    PainPoint(id: 'isquio_izq', name: 'Isquiotibiales Izq', view: 'posterior', relativePos: const Offset(0.64, 0.62)),
    PainPoint(id: 'hueco_popliteo_der', name: 'Fosa Poplítea Dcha', view: 'posterior', relativePos: const Offset(0.36, 0.72)),
    PainPoint(id: 'hueco_popliteo_izq', name: 'Fosa Poplítea Izq', view: 'posterior', relativePos: const Offset(0.64, 0.72)),
    PainPoint(id: 'gemelo_der', name: 'Gemelo / Sóleo Dcho', view: 'posterior', relativePos: const Offset(0.36, 0.80)),
    PainPoint(id: 'gemelo_izq', name: 'Gemelo / Sóleo Izq', view: 'posterior', relativePos: const Offset(0.64, 0.80)),
    PainPoint(id: 'aquiles_der', name: 'Tendón de Aquiles Dcho', view: 'posterior', relativePos: const Offset(0.38, 0.90)),
    PainPoint(id: 'aquiles_izq', name: 'Tendón de Aquiles Izq', view: 'posterior', relativePos: const Offset(0.62, 0.90)),
  ];

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.initialPoints);
  }

  Color _getPainColor(int eva) {
    if (eva <= 3) return const Color(0xFF10B981); // Verde
    if (eva <= 6) return const Color(0xFFF59E0B); // Ámbar
    return const Color(0xFFEF4444); // Rojo intenso
  }

  void _onZoneTapped(PainPoint preset) {
    if (widget.readOnly) return;
    HapticFeedback.mediumImpact();

    final existingIndex = _points.indexWhere((p) => p.id == preset.id);
    setState(() {
      if (existingIndex >= 0) {
        // Ya existe, abrir edición
        _selectedPoint = _points[existingIndex];
      } else {
        // Añadir nuevo punto activo
        final newPoint = PainPoint(
          id: preset.id,
          name: preset.name,
          view: preset.view,
          relativePos: preset.relativePos,
          evaPain: 6,
          type: 'Miofascial',
        );
        _points.add(newPoint);
        _selectedPoint = newPoint;
        widget.onPointsChanged?.call(_points);
      }
    });
  }

  void _removePoint(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _points.removeWhere((p) => p.id == id);
      if (_selectedPoint?.id == id) _selectedPoint = null;
      widget.onPointsChanged?.call(_points);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPresets = _currentView == 'anterior' ? _presetAnterior : _presetPosterior;

    return Column(
      children: [
        // Selector de vista Anterior / Posterior
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewTab('anterior', 'Vista Frontal', isDark),
              _buildViewTab('posterior', 'Vista Dorsal', isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lienzo Anatómico
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth > 340 ? 320.0 : constraints.maxWidth;
            const canvasHeight = 440.0;

            return Container(
              width: canvasWidth,
              height: canvasHeight,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Silueta Anatómica estilizada de fondo
                  Center(
                    child: CustomPaint(
                      size: Size(canvasWidth * 0.70, canvasHeight * 0.85),
                      painter: _SilhouettePainter(isDark: isDark, isAnterior: _currentView == 'anterior'),
                    ),
                  ),

                  // Nodos interactivos de evaluación
                  ...currentPresets.map((preset) {
                    final activeIndex = _points.indexWhere((p) => p.id == preset.id);
                    final isActive = activeIndex >= 0;
                    final activePoint = isActive ? _points[activeIndex] : null;

                    final left = preset.relativePos.dx * canvasWidth - 16;
                    final top = preset.relativePos.dy * canvasHeight - 16;

                    return Positioned(
                      left: left,
                      top: top,
                      child: GestureDetector(
                        onTap: () => _onZoneTapped(preset),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? _getPainColor(activePoint!.evaPain)
                                : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08)),
                            border: Border.all(
                              color: isActive ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: _getPainColor(activePoint!.evaPain).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isActive
                                ? Text(
                                    '${activePoint!.evaPain}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  )
                                : Icon(
                                    Icons.add,
                                    size: 14,
                                    color: isDark ? Colors.white54 : Colors.black38,
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Editor del punto seleccionado
        if (_selectedPoint != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedPoint!.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _removePoint(_selectedPoint!.id),
                      tooltip: 'Eliminar punto',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Escala de Dolor EVA
                Row(
                  children: [
                    Text(
                      'Dolor EVA: ',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPainColor(_selectedPoint!.evaPain),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedPoint!.evaPain} / 10',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _selectedPoint!.evaPain.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: _getPainColor(_selectedPoint!.evaPain),
                  onChanged: widget.readOnly
                      ? null
                      : (val) {
                          setState(() {
                            _selectedPoint!.evaPain = val.round();
                            widget.onPointsChanged?.call(_points);
                          });
                        },
                ),

                // Tipo de Dolor / Hallazgo
                Text(
                  'Tipo de Hallazgo:',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['Miofascial', 'Articular', 'Neural', 'Inflamatorio'].map((type) {
                    final isSel = _selectedPoint!.type == type;
                    return ChoiceChip(
                      label: Text(type, style: GoogleFonts.inter(fontSize: 11)),
                      selected: isSel,
                      onSelected: widget.readOnly
                          ? null
                          : (sel) {
                              if (sel) {
                                setState(() {
                                  _selectedPoint!.type = type;
                                  widget.onPointsChanged?.call(_points);
                                });
                              }
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        // Lista de puntos marcados
        if (_points.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Puntos Activos (${_points.length}):',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _points.map((p) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: _getPainColor(p.evaPain),
                  child: Text(
                    '${p.evaPain}',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                label: Text(p.name, style: GoogleFonts.inter(fontSize: 11)),
                onDeleted: widget.readOnly ? null : () => _removePoint(p.id),
                deleteIconColor: Colors.red.shade400,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildViewTab(String view, String label, bool isDark) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentView = view;
          _selectedPoint = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F766E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : AppTheme.primaryColor)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

// Pintor de la silueta anatómica médica minimalista
class _SilhouettePainter extends CustomPainter {
  final bool isDark;
  final bool isAnterior;

  _SilhouettePainter({required this.isDark, required this.isAnterior});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.45)
          : Colors.grey.shade200.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    // Cabeza
    path.addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.08), width: w * 0.22, height: h * 0.12));

    // Cuello
    path.moveTo(w * 0.44, h * 0.14);
    path.lineTo(w * 0.44, h * 0.17);
    path.lineTo(w * 0.28, h * 0.21); // Hombro dcho
    path.lineTo(w * 0.22, h * 0.38); // Codo dcho
    path.lineTo(w * 0.18, h * 0.52); // Muñeca dcha
    path.lineTo(w * 0.24, h * 0.50);
    path.lineTo(w * 0.28, h * 0.38);
    path.lineTo(w * 0.36, h * 0.25); // Axila dcha
    path.lineTo(w * 0.36, h * 0.48); // Tronco lateral dcho
    path.lineTo(w * 0.32, h * 0.72); // Rodilla dcha externa
    path.lineTo(w * 0.34, h * 0.94); // Tobillo dcho
    path.lineTo(w * 0.42, h * 0.94); // Pie interior dcho
    path.lineTo(w * 0.43, h * 0.72); // Rodilla dcha interna
    path.lineTo(w * 0.48, h * 0.54); // Ingle dcha
    path.lineTo(w * 0.50, h * 0.52); // Centro periné
    path.lineTo(w * 0.52, h * 0.54); // Ingle izq
    path.lineTo(w * 0.57, h * 0.72); // Rodilla izq interna
    path.lineTo(w * 0.58, h * 0.94); // Pie interior izq
    path.lineTo(w * 0.66, h * 0.94); // Tobillo izq
    path.lineTo(w * 0.68, h * 0.72); // Rodilla izq externa
    path.lineTo(w * 0.64, h * 0.48); // Tronco lateral izq
    path.lineTo(w * 0.64, h * 0.25); // Axila izq
    path.lineTo(w * 0.72, h * 0.38);
    path.lineTo(w * 0.76, h * 0.50);
    path.lineTo(w * 0.82, h * 0.52); // Muñeca izq
    path.lineTo(w * 0.78, h * 0.38); // Codo izq
    path.lineTo(w * 0.72, h * 0.21); // Hombro izq
    path.lineTo(w * 0.56, h * 0.17);
    path.lineTo(w * 0.56, h * 0.14);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.isAnterior != isAnterior;
  }
}
