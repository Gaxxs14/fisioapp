import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/body_pain_map_widget.dart';
import 'orthopedic_tests_screen.dart';

class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Herramientas Clínicas',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0D2137) : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2DD4BF),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Pruebas Ortopédicas', icon: Icon(Icons.pan_tool_alt_rounded, size: 20)),
            Tab(text: 'Mapa de Dolor', icon: Icon(Icons.accessibility_new_rounded, size: 20)),
            Tab(text: 'Rangos Goniométricos', icon: Icon(Icons.square_foot_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── PESTAÑA 1: BIBLIOTECA DE PRUEBAS ORTOPÉDICAS ───────────
          const OrthopedicTestsScreen(),

          // ── PESTAÑA 2: MAPA CORPORAL INTERACTIVO ───────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassBox(
                    isDark: isDark,
                    customColor: isDark
                        ? const Color(0xFF131B2E)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.touch_app_rounded, color: AppTheme.accentColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explorador Anatómico Rápido',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toca los puntos en la silueta para marcar contracturas y escala de dolor EVA (1-10).',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const BodyPainMapWidget(),
              ],
            ),
          ),

          // ── PESTAÑA 3: RANGOS GONIOMÉTRICOS DE REFERENCIA ───────────
          _buildGoniometryGuide(isDark),
        ],
      ),
    );
  }

  Widget _buildGoniometryGuide(bool isDark) {
    final ranges = [
      {
        'joint': 'Hombro',
        'icon': Icons.sports_tennis_rounded,
        'movements': [
          {'name': 'Flexión', 'normal': '160° - 180°'},
          {'name': 'Extensión', 'normal': '50° - 60°'},
          {'name': 'Abducción', 'normal': '160° - 180°'},
          {'name': 'Rotación Interna', 'normal': '70° - 90°'},
          {'name': 'Rotación Externa', 'normal': '80° - 90°'},
        ]
      },
      {
        'joint': 'Rodilla',
        'icon': Icons.directions_walk_rounded,
        'movements': [
          {'name': 'Flexión', 'normal': '135° - 145°'},
          {'name': 'Extensión', 'normal': '0° (Hiperextensión hasta 5°-10°)'},
        ]
      },
      {
        'joint': 'Cadera',
        'icon': Icons.airline_seat_legroom_extra_rounded,
        'movements': [
          {'name': 'Flexión', 'normal': '115° - 125°'},
          {'name': 'Extensión', 'normal': '15° - 20°'},
          {'name': 'Abducción', 'normal': '40° - 45°'},
          {'name': 'Aducción', 'normal': '20° - 30°'},
          {'name': 'Rotación Interna', 'normal': '35° - 45°'},
          {'name': 'Rotación Externa', 'normal': '40° - 50°'},
        ]
      },
      {
        'joint': 'Codo y Antebrazo',
        'icon': Icons.fitness_center_rounded,
        'movements': [
          {'name': 'Flexión', 'normal': '140° - 150°'},
          {'name': 'Extensión', 'normal': '0°'},
          {'name': 'Pronación', 'normal': '80° - 90°'},
          {'name': 'Supinación', 'normal': '80° - 90°'},
        ]
      },
      {
        'joint': 'Tobillo y Pie',
        'icon': Icons.accessibility_rounded,
        'movements': [
          {'name': 'Dorsiflexión', 'normal': '20°'},
          {'name': 'Flexión Plantar', 'normal': '45° - 50°'},
          {'name': 'Inversión', 'normal': '30° - 35°'},
          {'name': 'Eversión', 'normal': '15° - 20°'},
        ]
      },
      {
        'joint': 'Columna Cervical',
        'icon': Icons.airline_seat_recline_normal_rounded,
        'movements': [
          {'name': 'Flexión', 'normal': '45° - 50°'},
          {'name': 'Extensión', 'normal': '45° - 60°'},
          {'name': 'Inclinación Lateral', 'normal': '45°'},
          {'name': 'Rotación', 'normal': '60° - 80°'},
        ]
      },
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: ranges.length,
      itemBuilder: (context, index) {
        final item = ranges[index];
        final movements = item['movements'] as List<Map<String, String>>;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isDark ? const Color(0xFF2DD4BF) : AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item['joint'] as String,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...movements.map((m) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m['normal']!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF2DD4BF) : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.06, end: 0);
      },
    );
  }
}
