import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/appointment_provider.dart';
import '../../domain/entities/appointment.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../../patients/domain/entities/patient.dart';

class CalendarDashboardScreen extends ConsumerStatefulWidget {
  const CalendarDashboardScreen({super.key});

  @override
  ConsumerState<CalendarDashboardScreen> createState() => _CalendarDashboardScreenState();
}

class _CalendarDashboardScreenState extends ConsumerState<CalendarDashboardScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  String? _filterPhysioId;
  String? _filterRoomId;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Appointment> _getAppointmentsForDay(List<Appointment> appointments, DateTime day) {
    return appointments.where((appointment) {
      final sameDay = isSameDay(appointment.dateTime, day);
      final physioMatches = _filterPhysioId == null || appointment.physioId == _filterPhysioId;
      final roomMatches = _filterRoomId == null || appointment.roomId == _filterRoomId;
      return sameDay && physioMatches && roomMatches;
    }).toList();
  }

  Color _getStatusColor(AppointmentStatus status, {bool isBlocked = false}) {
    if (isBlocked) return Colors.blueGrey;
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.ongoing:
        return Colors.teal;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(AppointmentStatus status, String locale) {
    if (locale == 'es') {
      return status.displayName;
    }
    switch (status) {
      case AppointmentStatus.pending: return 'Pending';
      case AppointmentStatus.confirmed: return 'Confirmed';
      case AppointmentStatus.ongoing: return 'Ongoing';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.cancelled: return 'Cancelled';
      case AppointmentStatus.noShow: return 'No Show';
    }
  }

  void _showAppointmentDetails(Appointment app, AppLocalizations l10n, String currentLocale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header del modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            app.isBlocked ? l10n.blockDetails : l10n.apptDetails,
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
                      
                      if (app.isBlocked) ...[
                        _buildDetailRow(Icons.block_outlined, '${l10n.blockReasonField}:', app.blockReason ?? 'Reunión / Vacaciones'),
                      ] else ...[
                        _buildDetailRow(Icons.person_outline, '${l10n.patientField}:', app.patientName ?? 'Paciente'),
                        _buildDetailRow(Icons.business_outlined, '${l10n.roomField}:', app.roomName ?? (currentLocale == 'es' ? 'Sin consultorio' : 'No office assigned')),
                      ],
                      _buildDetailRow(Icons.medical_services_outlined, '${l10n.physioField}:', app.physioName),
                      _buildDetailRow(
                        Icons.access_time_outlined,
                        '${l10n.timeField}:',
                        '${DateFormat('dd/MM/yyyy HH:mm').format(app.dateTime)} (${app.durationMinutes} ${l10n.durationText})',
                      ),
                      _buildDetailRow(Icons.info_outline, '${l10n.statusField}:', _getStatusDisplayName(app.status, currentLocale)),
                      
                      const SizedBox(height: 24),
                      
                      // Acciones de estado
                      if (!app.isBlocked) ...[
                        Text(
                          l10n.changeStatusLabel,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: AppointmentStatus.values.map((status) {
                              if (status == app.status) return const SizedBox.shrink();
                              final stColor = _getStatusColor(status);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(
                                    _getStatusDisplayName(status, currentLocale),
                                    style: GoogleFonts.inter(color: stColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  backgroundColor: stColor.withValues(alpha: 0.12),
                                  side: BorderSide(color: stColor.withValues(alpha: 0.2)),
                                  onPressed: () {
                                    ref.read(appointmentControllerProvider.notifier).updateAppointmentStatus(app, status);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.play_circle_fill, size: 20),
                            label: Text(l10n.startSessionAction, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/patients/detail/${app.patientId ?? ''}/session/new?appointmentId=${app.id}');
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.notifications_active_outlined, size: 18),
                              label: Text(l10n.reminderBtn, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              onPressed: () async {
                                final patients = ref.read(patientsStreamProvider).value ?? [];
                                final patient = patients.cast<Patient?>().firstWhere(
                                  (p) => p?.id == app.patientId,
                                  orElse: () => null,
                                );

                                if (patient == null || patient.phone.trim().isEmpty) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          currentLocale == 'es' 
                                              ? 'El paciente no tiene un número telefónico registrado.' 
                                              : 'The patient does not have a registered phone number.',
                                          style: GoogleFonts.inter(),
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final phoneDigits = patient.phone.replaceAll(RegExp(r'\D'), '');
                                final dateStr = DateFormat('dd/MM/yyyy').format(app.dateTime);
                                final timeStr = DateFormat('HH:mm').format(app.dateTime);
                                final message = currentLocale == 'es'
                                    ? 'Hola ${app.patientName}, te recordamos tu cita de fisioterapia el día $dateStr a las $timeStr con el FT. ${app.physioName}. ¡Te esperamos!'
                                    : 'Hello ${app.patientName}, this is a reminder for your physical therapy appointment on $dateStr at $timeStr with PT. ${app.physioName}. We look forward to seeing you!';

                                final whatsappUrl = Uri.parse('https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message)}');

                                Navigator.pop(context);
                                
                                try {
                                  final launched = await launchUrl(
                                    whatsappUrl,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!launched) {
                                    throw 'Could not launch URL';
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          currentLocale == 'es' 
                                              ? 'No se pudo abrir la aplicación de WhatsApp. Verifica si está instalada.' 
                                              : 'Could not open WhatsApp application. Check if it is installed.',
                                          style: GoogleFonts.inter(),
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(l10n.deleteBtn, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              onPressed: () {
                                ref.read(appointmentControllerProvider.notifier).cancelAppointment(app.id);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);
    final therapistsAsync = ref.watch(therapistsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeProvider);
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
          onPressed: () => context.push('/appointments/book'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_task_outlined, color: Colors.white, size: 24),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── PREMIUM SLIVER APP BAR ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D2137) : AppTheme.primaryColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.assignment_ind_outlined),
                tooltip: l10n.waitlistTitle,
                onPressed: () => context.push('/appointments/waiting-list'),
              ),
              const SizedBox(width: 8),
            ],
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
                        l10n.calendarTitle,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FILTROS DE AGENDA (MEDICOS Y SALAS) ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: therapistsAsync.when(
                      data: (therapists) {
                        return DropdownButtonFormField<String>(
                          initialValue: _filterPhysioId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.filterPhysio,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem<String>(value: null, child: Text(l10n.filterAll, style: GoogleFonts.inter(fontSize: 12))),
                            ...therapists.map((t) => DropdownMenuItem<String>(value: t['uid'], child: Text(t['name'], style: GoogleFonts.inter(fontSize: 12)))),
                          ],
                          onChanged: (value) => setState(() => _filterPhysioId = value),
                        );
                      },
                      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                      error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: roomsAsync.when(
                      data: (rooms) {
                        return DropdownButtonFormField<String>(
                          initialValue: _filterRoomId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.filterRoom,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem<String>(value: null, child: Text(l10n.filterAll, style: GoogleFonts.inter(fontSize: 12))),
                            ...rooms.map((r) => DropdownMenuItem<String>(value: r['id'], child: Text(r['name'], style: GoogleFonts.inter(fontSize: 12)))),
                          ],
                          onChanged: (value) => setState(() => _filterRoomId = value),
                        );
                      },
                      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                      error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TABLE CALENDAR PREMIUM CARD ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                locale: currentLocale,
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final list = appointmentsAsync.value ?? [];
                  return _getAppointmentsForDay(list, day)
                      .where((a) => a.status != AppointmentStatus.cancelled)
                      .toList();
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                  todayTextStyle: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  selectedTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  defaultTextStyle: GoogleFonts.inter(),
                  weekendTextStyle: GoogleFonts.inter(color: Colors.red.shade400),
                  markerSize: 5.0,
                  markersMaxCount: 3,
                  markerDecoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  formatButtonDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),

          // ── LISTADO DE CITAS DEL DÍA ─────────────────────────────────
          appointmentsAsync.when(
            data: (appointments) {
              final dayAppointments = _getAppointmentsForDay(appointments, _selectedDay ?? DateTime.now());
              dayAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

              if (dayAppointments.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(l10n, isDark),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final app = dayAppointments[index];
                      final stColor = _getStatusColor(app.status, isBlocked: app.isBlocked);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAppointmentDetails(app, l10n, currentLocale),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  // Barra vertical de estado
                                  Container(
                                    width: 4,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: stColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (app.isBlocked) ...[
                                              const Icon(Icons.lock_outline, size: 14, color: Colors.blueGrey),
                                              const SizedBox(width: 6),
                                            ],
                                            Expanded(
                                              child: Text(
                                                app.isBlocked 
                                                    ? (app.blockReason ?? l10n.blockDetails) 
                                                    : (app.patientName ?? l10n.patientField),
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: app.isBlocked ? (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700) : null,
                                                  decoration: app.status == AppointmentStatus.cancelled
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fisio: ${app.physioName} • ${app.roomName ?? (currentLocale == 'es' ? "Sin sala" : "No Room")}',
                                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat('HH:mm').format(app.dateTime),
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primaryColor),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${app.durationMinutes} min',
                                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.1, end: 0);
                    },
                    childCount: dayAppointments.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Shimmer.fromColors(
                  baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
                  highlightColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(3, (index) => Container(
                        height: 72,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      )),
                    ),
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $err', style: GoogleFonts.inter())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
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
                Icons.calendar_today_outlined,
                size: 52,
                color: isDark ? const Color(0xFF14B8A6) : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.noAppts,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'es' 
                  ? 'No hay eventos agendados para este día.' 
                  : 'No scheduled events for this day.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
