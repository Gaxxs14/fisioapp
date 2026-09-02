import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/orthopedic_test.dart';
import '../../data/repositories/orthopedic_tests_repository.dart';

class OrthopedicTestsScreen extends StatefulWidget {
  const OrthopedicTestsScreen({super.key});

  @override
  State<OrthopedicTestsScreen> createState() => _OrthopedicTestsScreenState();
}

class _OrthopedicTestsScreenState extends State<OrthopedicTestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  JointRegion? _selectedRegion;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrthopedicTest> get _filteredList {
    List<OrthopedicTest> list;
    if (_searchQuery.isNotEmpty) {
      list = OrthopedicTestsRepository.search(_searchQuery);
    } else if (_selectedRegion != null) {
      list = OrthopedicTestsRepository.getByRegion(_selectedRegion!);
    } else {
      list = OrthopedicTestsRepository.allTests;
    }

    if (_selectedRegion != null && _searchQuery.isNotEmpty) {
      list = list.where((t) => t.region == _selectedRegion).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tests = _filteredList;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SLIVER APP BAR ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D2137) : AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark ? AppTheme.darkHeroGradient : AppTheme.primaryGradient,
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pruebas Ortopédicas',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                '${OrthopedicTestsRepository.allTests.length} maniobras clínicas validadas',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Buscador
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.95),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por prueba, síntoma o ligamento (ej. Lachman)...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white60 : Colors.grey.shade500,
                            fontSize: 12.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FILTRO DE ARTICULACIONES ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('Todas', null, isDark),
                    const SizedBox(width: 8),
                    ...JointRegion.values.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(r.displayName, r, isDark),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // ── LISTADO DE PRUEBAS CLÍNICAS ──────────────────────────────
          if (tests.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 54, color: Colors.grey),
                      const SizedBox(height: 14),
                      Text(
                        'No se encontraron pruebas coincidentes',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Prueba buscando por articulación o nombre alternativo',
                        style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = tests[index];
                    return _OrthopedicTestCard(test: item, isDark: isDark, index: index);
                  },
                  childCount: tests.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, JointRegion? region, bool isDark) {
    final isSelected = _selectedRegion == region;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRegion = region;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

class _OrthopedicTestCard extends StatelessWidget {
  final OrthopedicTest test;
  final bool isDark;
  final int index;

  const _OrthopedicTestCard({
    required this.test,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pan_tool_alt_rounded,
              color: isDark ? const Color(0xFF2DD4BF) : AppTheme.primaryColor,
              size: 20,
            ),
          ),
          title: Text(
            test.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      test.region.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF2DD4BF) : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      test.targetStructure,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 16),

            // Sensibilidad y Especificidad
            Row(
              children: [
                Expanded(
                  child: _buildMetricBadge(
                    'Sensibilidad',
                    test.sensitivity,
                    const Color(0xFF0284C7),
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBadge(
                    'Especificidad',
                    test.specificity,
                    const Color(0xFF10B981),
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Posición del paciente
            _buildSection(
              title: 'Posición del Paciente',
              content: test.patientPosition,
              icon: Icons.person_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Maniobra del Examinador
            _buildSection(
              title: 'Ejecución de la Maniobra',
              content: test.examinerAction,
              icon: Icons.touch_app_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Signo Positivo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.amberAlert.withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.amberAlert.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.amberAlert, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Criterio de Positividad:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.amberAlert,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          test.positiveFinding,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Interpretación clínica
            _buildSection(
              title: 'Implicación Clínica',
              content: test.clinicalInterpretation,
              icon: Icons.health_and_safety_outlined,
              isDark: isDark,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * widget.index)).slideY(begin: 0.08, end: 0);
  }

  Widget _buildMetricBadge(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
