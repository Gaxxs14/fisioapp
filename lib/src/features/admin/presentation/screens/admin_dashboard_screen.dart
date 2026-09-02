import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/clinic_absence.dart';
import '../../domain/entities/room_model.dart';
import '../providers/admin_provider.dart';
import '../../../patients/presentation/providers/notification_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Administración',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Mensajería Masiva',
            onPressed: () => _showMassMessageModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.credit_card_outlined),
            tooltip: 'Suscripción SaaS',
            onPressed: () => context.push('/clinic/subscription'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: false,
          tabs: const [
            Tab(text: 'Personal', icon: Icon(Icons.people_outline_rounded, size: 18)),
            Tab(text: 'Ausencias', icon: Icon(Icons.free_breakfast_outlined, size: 18)),
            Tab(text: 'Salas', icon: Icon(Icons.meeting_room_outlined, size: 18)),
            Tab(text: 'Métricas', icon: Icon(Icons.bar_chart_outlined, size: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStaffTab(context, isDark),
            _buildAbsencesTab(context, isDark),
            _buildRoomsTab(context, isDark),
            _buildMetricsTab(context, isDark),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: GESTIÓN DE PERSONAL ─────────────────────────────────────
  Widget _buildStaffTab(BuildContext context, bool isDark) {
    final professionalsAsync = ref.watch(professionalsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        label: Text('Registrar Personal', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        onPressed: () => context.push('/admin/staff/new'),
      ),
      body: professionalsAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return _buildEmptyState(Icons.people_alt_outlined, 'No se registran fisioterapeutas o recepcionistas.');
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: staffList.length,
            itemBuilder: (context, idx) {
              final staff = staffList[idx];
              final initials = staff.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${staff.role.displayName} • ${staff.specialty ?? "General"}',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          if (staff.workDays != null && staff.workDays!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Horario: ${staff.workDays!.length} días (${staff.workHoursStart ?? "08:00"} - ${staff.workHoursEnd ?? "17:00"})',
                              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Botón configurar horario semanal
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryColor, size: 20),
                      tooltip: 'Configurar Horario',
                      onPressed: () => context.push('/admin/staff/schedule', extra: staff),
                    ),
                    Switch(
                      value: staff.isActive,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        ref.read(adminControllerProvider.notifier).toggleProfessionalStatus(
                              uid: staff.uid,
                              isActive: val,
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'Eliminar Personal',
                      onPressed: () => _confirmDeleteStaff(context, staff),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (idx * 50).ms);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar personal: $e')),
      ),
    );
  }

  // ── TAB 2: GESTIÓN DE AUSENCIAS ────────────────────────────────────
  Widget _buildAbsencesTab(BuildContext context, bool isDark) {
    final absencesAsync = ref.watch(absencesStreamProvider);
    final professionalsAsync = ref.watch(professionalsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        label: Text('Registrar Ausencia', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.free_breakfast_outlined, color: Colors.white),
        onPressed: () {
          professionalsAsync.whenData((staffList) {
            if (staffList.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registra personal primero')),
              );
            } else {
              _showAddAbsenceBottomSheet(context, staffList);
            }
          });
        },
      ),
      body: absencesAsync.when(
        data: (absences) {
          if (absences.isEmpty) {
            return _buildEmptyState(Icons.free_breakfast_outlined, 'No hay ausencias o vacaciones registradas.');
          }

          // Ordenar ausencias por fecha de inicio descendente
          final sorted = List<ClinicAbsence>.from(absences)
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: sorted.length,
            itemBuilder: (context, idx) {
              final ab = sorted[idx];
              final startStr = DateFormat('dd/MM/yyyy').format(ab.startDate);
              final endStr = DateFormat('dd/MM/yyyy').format(ab.endDate);

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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (ab.reason == 'vacaciones' ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ab.reason == 'vacaciones' ? Icons.beach_access : Icons.personal_injury,
                        color: ab.reason == 'vacaciones' ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ab.userName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Motivo: ${ab.reason.toUpperCase()} · $startStr al $endStr',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          if (ab.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ab.notes,
                              style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade400),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _confirmDeleteAbsence(context, ab),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (idx * 50).ms);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ── TAB 3: SALAS Y CONSULTORIOS ────────────────────────────────────
  Widget _buildRoomsTab(BuildContext context, bool isDark) {
    final roomsAsync = ref.watch(roomsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        label: Text('Agregar Sala', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () => _showAddRoomBottomSheet(context),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return _buildEmptyState(Icons.meeting_room_outlined, 'Aún no has registrado ninguna sala.');
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            itemBuilder: (context, idx) {
              final room = rooms[idx];
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
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(int.parse(room.colorHex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        room.name,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _confirmDeleteRoom(context, room),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (idx * 50).ms);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar consultorios: $e')),
      ),
    );
  }

  // ── TAB 4: MÉTRICAS Y RENDIMIENTO ──────────────────────────────────
  Widget _buildMetricsTab(BuildContext context, bool isDark) {
    final sessionsAsync = ref.watch(adminClinicSessionsProvider);
    final professionalsAsync = ref.watch(professionalsStreamProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rendimiento por Profesional (Este Mes)',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          professionalsAsync.when(
            data: (professionals) {
              final therapists = professionals.where((u) => u.role == UserRole.physio || u.role == UserRole.admin).toList();
              
              return sessionsAsync.when(
                data: (sessions) {
                  final now = DateTime.now();
                  final currentMonthSessions = sessions.where((s) => s.date.month == now.month && s.date.year == now.year).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: therapists.length,
                    itemBuilder: (context, idx) {
                      final therapist = therapists[idx];
                      final tSessions = currentMonthSessions.where((s) => s.therapistId == therapist.uid).toList();
                      final totalMinutes = tSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
                      
                      // Agrupar técnicas
                      final Map<String, int> techniqueCounts = {};
                      for (var s in tSessions) {
                        for (var t in s.techniques) {
                          techniqueCounts[t] = (techniqueCounts[t] ?? 0) + 1;
                        }
                      }
                      final topTechniques = techniqueCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  therapist.name,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${tSessions.length} sesiones',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tiempo total clínico:',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                                ),
                                Text(
                                  '${totalMinutes ~/ 60}h ${totalMinutes % 60}min',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (topTechniques.isNotEmpty) ...[
                              const Divider(height: 20),
                              Text(
                                'Técnicas más aplicadas:',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: topTechniques.take(3).map((e) {
                                  return Chip(
                                    label: Text('${e.key} (${e.value})', style: GoogleFonts.inter(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS AUXILIARES ─────────────────────────────────────────────
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStaff(BuildContext context, AppUser staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text('Eliminar Personal', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${staff.name}" (${staff.role.displayName}) de tu clínica?\n\nEsta acción revocará su acceso al sistema y eliminará su registro de profesional.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminControllerProvider.notifier).deleteStaffUser(uid: staff.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Se ha eliminado a ${staff.name} de la clínica.', style: GoogleFonts.inter()),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAbsence(BuildContext context, ClinicAbsence ab) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar Ausencia', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar el registro de ausencia para ${ab.userName}? El terapeuta volverá a figurar disponible para citas.',
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
              ref.read(adminControllerProvider.notifier).deleteAbsence(absenceId: ab.id);
            },
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, RoomModel room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar Sala', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar la sala "${room.name}"?',
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
              ref.read(adminControllerProvider.notifier).deleteRoom(roomId: room.id);
            },
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAbsenceBottomSheet(BuildContext context, List<AppUser> staffList) {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();
    AppUser? selectedUser = staffList.isNotEmpty ? staffList.first : null;
    String selectedReason = 'vacaciones';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDates() async {
              final pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: DateTimeRange(start: startDate, end: endDate),
              );
              if (pickedRange != null) {
                setModalState(() {
                  startDate = pickedRange.start;
                  endDate = pickedRange.end;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Registrar Ausencia / Licencia', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    // Seleccionar terapeuta
                    DropdownButtonFormField<AppUser>(
                      initialValue: selectedUser,
                      decoration: const InputDecoration(labelText: 'Profesional'),
                      items: staffList.map((u) {
                        return DropdownMenuItem<AppUser>(
                          value: u,
                          child: Text(u.name, style: GoogleFonts.inter(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedUser = val),
                    ),
                    const SizedBox(height: 16),
                    // Seleccionar motivo
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                      items: const [
                        DropdownMenuItem(value: 'vacaciones', child: Text('Vacaciones')),
                        DropdownMenuItem(value: 'enfermedad', child: Text('Enfermedad / Licencia Médica')),
                        DropdownMenuItem(value: 'personal', child: Text('Motivos Personales')),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      onChanged: (val) => setModalState(() => selectedReason = val ?? 'otro'),
                    ),
                    const SizedBox(height: 16),
                    // Rango de fechas
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Rango: ${DateFormat('dd/MM/yyyy').format(startDate)} al ${DateFormat('dd/MM/yyyy').format(endDate)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                      onTap: pickDates,
                    ),
                    const SizedBox(height: 12),
                    // Notas adicionales
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notas / Observaciones'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        if (selectedUser == null) return;
                        await ref.read(adminControllerProvider.notifier).addAbsence(
                              userId: selectedUser!.uid,
                              userName: selectedUser!.name,
                              startDate: startDate,
                              endDate: endDate,
                              reason: selectedReason,
                              notes: notesController.text.trim(),
                            );
                        if (context.mounted) context.pop();
                      },
                      child: Text('Registrar Ausencia', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddRoomBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String selectedColor = '#0F766E';

    final List<String> roomColors = [
      '#0F766E', // Teal
      '#0EA5E9', // Sky blue
      '#6366F1', // Indigo
      '#8B5CF6', // Violet
      '#EC4899', // Pink
      '#F43F5E', // Rose
      '#EAB308', // Yellow
      '#F97316', // Orange
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Agregar Nuevo Consultorio / Sala', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre o Número de la Sala'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Color en Agenda',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: roomColors.length,
                        itemBuilder: (context, idx) {
                          final colorHex = roomColors[idx];
                          final isSelected = selectedColor == colorHex;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = colorHex),
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        await ref.read(adminControllerProvider.notifier).addRoom(
                              name: nameController.text.trim(),
                              colorHex: selectedColor,
                            );
                        if (context.mounted) context.pop();
                      },
                      child: Text('Guardar Consultorio', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMassMessageModal(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Enviar Comunicado Masivo',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Este mensaje será enviado inmediatamente a la bandeja de entrada de TODOS los pacientes de la clínica.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título del Comunicado',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Escribe un título' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Cuerpo del Mensaje',
                      prefixIcon: Icon(Icons.message_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Escribe el mensaje' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      'Enviar Comunicado',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      
                      // Enviar masivamente
                      await ref.read(notificationControllerProvider.notifier).sendMassAnnouncement(
                        title: titleController.text.trim(),
                        body: bodyController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('Comunicado masivo enviado con éxito', style: GoogleFonts.inter()),
                              ],
                            ),
                            backgroundColor: AppTheme.accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
