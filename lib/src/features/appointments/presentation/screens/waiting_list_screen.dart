import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_error_formatter.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../providers/appointment_provider.dart';

class WaitingListScreen extends ConsumerStatefulWidget {
  const WaitingListScreen({super.key});

  @override
  ConsumerState<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends ConsumerState<WaitingListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddWaitingListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const AddWaitingListBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final waitingListAsync = ref.watch(waitingListStreamProvider);
    final therapistsAsync = ref.watch(therapistsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final uiState = ref.watch(appointmentControllerProvider);
    final l10n = ref.watch(l10nProvider);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AppointmentUiState>(appointmentControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        final friendlyError = FirebaseErrorFormatter.format(next.errorMessage!, locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(friendlyError, style: GoogleFonts.inter())),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(appointmentControllerProvider.notifier).clearError();
      }
    });

    final therapists = therapistsAsync.value ?? [];
    final rooms = roomsAsync.value ?? [];

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
          onPressed: _showAddWaitingListDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── PREMIUM SLIVER APP BAR WITH SEARCH INTEGRATION ──────────
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
                        l10n.waitlistTitle,
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
                            hintText: l10n.searchPatient,
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
                              _searchQuery = value.toLowerCase();
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

          // ── LISTADO DE ESPERA ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: uiState.isLoading
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : waitingListAsync.when(
                    data: (entries) {
                      final filtered = entries.where((e) {
                        return e.patientName.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(l10n, isDark),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = filtered[index];

                            final physioName = entry.preferredPhysioId != null
                                ? therapists.firstWhere(
                                    (t) => t['uid'] == entry.preferredPhysioId,
                                    orElse: () => {'name': 'No encontrado'},
                                  )['name'] as String
                                : l10n.anyPhysio;

                            final roomName = entry.preferredRoomId != null
                                ? rooms.firstWhere(
                                    (r) => r['id'] == entry.preferredRoomId,
                                    orElse: () => {'name': 'No encontrado'},
                                  )['name'] as String
                                : l10n.anyRoom;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
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
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.patientName,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(entry.createdAt),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    
                                    _buildDetailRow(Icons.medical_services_outlined, '${l10n.prefPhysio} ', physioName),
                                    _buildDetailRow(Icons.business_outlined, '${l10n.prefRoom} ', roomName),
                                    
                                    if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark 
                                              ? Colors.white.withValues(alpha: 0.03) 
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isDark 
                                                ? Colors.white.withValues(alpha: 0.06) 
                                                : Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          entry.notes!,
                                          style: GoogleFonts.inter(
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            ref.read(appointmentControllerProvider.notifier)
                                                .removePatientFromWaitingList(entry.id);
                                          },
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                          label: Text(l10n.deleteBtn, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.errorColor,
                                            side: const BorderSide(color: AppTheme.errorColor),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            context.push(
                                              '/appointments/book'
                                              '?patientId=${entry.patientId}'
                                              '&patientName=${Uri.encodeComponent(entry.patientName)}'
                                              '&waitingListEntryId=${entry.id}'
                                            );
                                          },
                                          icon: const Icon(Icons.calendar_month_outlined, size: 16),
                                          label: Text(
                                            locale == 'es' ? 'Agendar Cita' : 'Schedule Appt',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                          },
                          childCount: filtered.length,
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Error: $err', style: GoogleFonts.inter())),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_empty_rounded, size: 52, color: isDark ? const Color(0xFF14B8A6) : AppTheme.primaryColor),
          ),
          const SizedBox(height: 18),
          Text(
            _searchQuery.isEmpty ? l10n.waitlistEmpty : 'Sin resultados',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (_searchQuery.isNotEmpty)
            Text(
              'No hay registros para la búsqueda actual.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// ADD TO WAITING LIST BOTTOM SHEET
// ────────────────────────────────────────────────────────────────────────────
class AddWaitingListBottomSheet extends ConsumerStatefulWidget {
  const AddWaitingListBottomSheet({super.key});

  @override
  ConsumerState<AddWaitingListBottomSheet> createState() => _AddWaitingListBottomSheetState();
}

class _AddWaitingListBottomSheetState extends ConsumerState<AddWaitingListBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _preferredPhysioId;
  String? _preferredRoomId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(localeProvider) == 'es' ? 'Por favor selecciona un paciente.' : 'Please select a patient.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    ref.read(appointmentControllerProvider.notifier).addPatientToWaitingList(
          patientId: _selectedPatientId!,
          patientName: _selectedPatientName!,
          preferredPhysioId: _preferredPhysioId,
          preferredRoomId: _preferredRoomId,
          notes: _notesController.text,
        ).then((_) {
          navigator.pop();
        });
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final therapistsAsync = ref.watch(therapistsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final l10n = ref.watch(l10nProvider);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF131B2E) : Colors.white,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.addWaitlistTitle,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Selector de Paciente
            patientsAsync.when(
              data: (patients) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: l10n.patientField,
                    prefixIcon: const Icon(Icons.person_outline),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: patients.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text('${p.name} (${p.dni})', style: GoogleFonts.inter(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPatientId = val;
                        _selectedPatientName = patients.firstWhere((p) => p.id == val).name;
                      });
                    }
                  },
                  validator: (val) => val == null ? (locale == 'es' ? 'Selecciona un paciente' : 'Select a patient') : null,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
            ),
            const SizedBox(height: 16),

            // Selector de Fisioterapeuta Preferido
            therapistsAsync.when(
              data: (therapists) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: locale == 'es' ? 'Fisioterapeuta Preferido (Opcional)' : 'Preferred Therapist (Optional)',
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l10n.anyPhysio, style: GoogleFonts.inter(fontSize: 13))),
                    ...therapists.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['uid'] as String,
                        child: Text(t['name'] as String, style: GoogleFonts.inter(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _preferredPhysioId = val),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
            ),
            const SizedBox(height: 16),

            // Selector de Sala Preferida
            roomsAsync.when(
              data: (rooms) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: locale == 'es' ? 'Consultorio Preferido (Opcional)' : 'Preferred Office (Optional)',
                    prefixIcon: const Icon(Icons.business_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l10n.anyRoom, style: GoogleFonts.inter(fontSize: 13))),
                    ...rooms.map((r) {
                      return DropdownMenuItem<String>(
                        value: r['id'] as String,
                        child: Text(r['name'] as String, style: GoogleFonts.inter(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _preferredRoomId = val),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notesField,
                prefixIcon: const Icon(Icons.notes_rounded),
                hintText: l10n.notesHint,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => _submit(l10n),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.addBtn, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
