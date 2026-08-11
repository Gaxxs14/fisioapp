import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';
import '../../domain/entities/patient.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _genderFilter = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _filterPatients(List<Patient> patients) {
    return patients.where((patient) {
      final nameMatches = patient.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final dniMatches = patient.dni.toLowerCase().contains(_searchQuery.toLowerCase());
      final genderMatches = _genderFilter == 'Todos' || patient.gender == _genderFilter;
      return (nameMatches || dniMatches) && genderMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF14B8A6), const Color(0xFF0D9488)]
                : [AppTheme.primaryColor, const Color(0xFF14B8A6)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/patients/register'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white, size: 24),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── PREMIUM APP BAR WITH SEARCH INTEGRATION ──────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D2137) : AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0D2137), const Color(0xFF0A3D5C)]
                        : [const Color(0xFF0F766E), const Color(0xFF0EA5A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Expedientes Clínicos',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Buscador premium
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o DNI...',
                            hintStyle: GoogleFonts.inter(
                              color: isDark ? Colors.white60 : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FILTROS (GENDER FILTER CHIPS) ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('Todos', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Masculino', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Femenino', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Otro', isDark),
                  ],
                ),
              ),
            ),
          ),

          // ── LISTADO DE PACIENTES ─────────────────────────────────────
          patientsAsync.when(
            data: (patients) {
              final filtered = _filterPatients(patients);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(isDark),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final patient = filtered[index];
                      return _PatientCard(
                        patient: patient,
                        isDark: isDark,
                        index: index,
                        onTap: () => context.push('/patients/detail/${patient.id}'),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudo cargar la lista de pacientes.\nVerifica tu conexión a internet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _genderFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected 
              ? AppTheme.primaryColor 
              : (isDark ? Colors.white70 : Colors.grey.shade700),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _genderFilter = label;
          });
        }
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryColor,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_outlined,
                size: 56,
                color: isDark ? const Color(0xFF14B8A6) : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Sin resultados'
                  : 'No hay pacientes registrados',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Prueba modificando los filtros o el texto de tu búsqueda.'
                  : 'Registra a tu primer paciente pulsando el botón flotante.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TARJETA DE PACIENTE
// ────────────────────────────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final Patient patient;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Iniciales del paciente
    final initials = patient.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Avatar Premium con Gradiente
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Fila de chips de datos
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildMiniChip(Icons.badge_outlined, patient.dni),
                          _buildMiniChip(Icons.cake_outlined, '${patient.age} años'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icono navegar
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
    // Solo animar las primeras 8 tarjetas visibles para no saturar el buffer GPU
    if (index < 8) {
      return RepaintBoundary(
        child: card
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50), duration: 250.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic, duration: 250.ms),
      );
    }
    return RepaintBoundary(child: card);
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
