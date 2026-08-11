import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../providers/patient_portal_provider.dart';
import '../../domain/entities/home_exercise_model.dart';
import '../providers/notification_provider.dart';
import '../../domain/entities/notification_model.dart';
import '../../../../core/services/push_notification_service.dart';

final fcmRegistrationProvider = Provider.family<void, String>((ref, patientId) {
  if (patientId.isNotEmpty) {
    Future.microtask(() async {
      await PushNotificationService.requestPermissions();
      await PushNotificationService.registerDeviceToken(patientId);
    });
  }
});

class PatientPortalDashboard extends ConsumerWidget {
  const PatientPortalDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(currentPatientIdProvider);
    ref.watch(fcmRegistrationProvider(patientId));
    ref.listen<AsyncValue<List<NotificationModel>>>(patientNotificationsProvider, (previous, next) {
      final oldList = previous?.value;
      final newList = next.value ?? [];

      if (oldList == null) {
        return;
      }

      if (newList.length > oldList.length) {
        final newest = newList.first;
        final age = DateTime.now().difference(newest.timestamp);

        if (age.inSeconds < 10 && !newest.isRead) {
          _showFloatingBanner(context, newest);
        }
      }
    });

    final appointmentsAsync = ref.watch(patientCitasStreamProvider);
    final exercisesAsync = ref.watch(patientExercisesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('Portal del Paciente', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón de Notificaciones con Badge
          Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    tooltip: 'Notificaciones',
                    onPressed: () {
                      _showNotificationsSheet(context, ref);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(currentPatientIdProvider.notifier).set('');
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            // Próxima Cita
            appointmentsAsync.when(
              data: (appointments) {
                final upcoming = appointments.where((a) {
                  return a.dateTime.isAfter(DateTime.now()) && a.status != AppointmentStatus.cancelled;
                }).toList()
                  ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                if (upcoming.isEmpty) {
                  return _buildNoCitaCard(isDark);
                }

                final nextCita = upcoming.first;
                return _buildCitaCard(context, ref, nextCita, isDark);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Módulo de Ejercicios en Casa
            Text(
              'Mis Ejercicios para Hoy',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(child: Text('No tienes rutinas asignadas para hoy.'));
                }
                return Column(
                  children: exercises.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final exercise = entry.value;
                    return _buildExerciseTile(ref, exercise, isDark).animate().fadeIn(delay: (idx * 50).ms);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error al cargar ejercicios: $e'),
            ),
            const SizedBox(height: 24),

            // Módulo de Evolución
            _buildEvolucionCard(isDark),
            const SizedBox(height: 24),

            // Módulo de Contacto
            _buildContactoCard(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── TARJETA CITA ──────────────────────────────────────────────────
  Widget _buildCitaCard(BuildContext context, WidgetRef ref, Appointment cita, bool isDark) {
    final timeStr = DateFormat("EEEE d 'de' MMMM • HH:mm", 'es').format(cita.dateTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Próxima Cita', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Fisioterapeuta: ${cita.physioName}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if (cita.roomName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Consultorio: ${cita.roomName}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (cita.status == AppointmentStatus.pending) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(patientPortalControllerProvider.notifier).updateAppointmentStatus(
                            cita.id,
                            cita.clinicId,
                            AppointmentStatus.cancelled,
                          );
                    },
                    child: Text('Cancelar Cita', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.errorColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(patientPortalControllerProvider.notifier).updateAppointmentStatus(
                            cita.id,
                            cita.clinicId,
                            AppointmentStatus.confirmed,
                          );
                    },
                    child: Text('Confirmar', style: GoogleFonts.inter(fontSize: 12)),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Cita Confirmada ✓',
                      style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoCitaCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_outlined, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sin próximas citas agendadas', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Comunícate con la recepción para reservar.', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TILE DE EJERCICIOS ────────────────────────────────────────────
  Widget _buildExerciseTile(WidgetRef ref, HomeExerciseModel exercise, bool isDark) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: exercise.isCompleted,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) {
              ref.read(patientPortalControllerProvider.notifier).toggleExerciseCompletion(exercise.id, val ?? false);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: exercise.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.instructions,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.repetitions,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          if (exercise.videoUrl != null)
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 28),
              onPressed: () {
                // Simulación de reproducción del video explicativo
              },
            ),
        ],
      ),
    );
  }

  // ── TARJETA EVOLUCION ─────────────────────────────────────────────
  Widget _buildEvolucionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolución de Dolor (EVA)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Historial de tu progreso clínico en la escala de dolor', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: Size.infinite,
              painter: _PainChartPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTACTO CLINICA ──────────────────────────────────────────────
  Widget _buildContactoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contacto con la Clínica', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  label: Text('Llamar', style: GoogleFonts.inter(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                  label: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER GRÁFICO ──────────────────────────────────────────
class _PainChartPainter extends CustomPainter {
  final bool isDark;
  _PainChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.primaryColor.withValues(alpha: 0.25), AppTheme.primaryColor.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200
      ..strokeWidth = 1;

    final dotPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    // Pintar líneas horizontales guía
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * 0.8), // Sesión 1: dolor 8
      Offset(size.width * 0.25, size.height * 0.7), // Sesión 2: dolor 7
      Offset(size.width * 0.5, size.height * 0.4), // Sesión 3: dolor 4
      Offset(size.width * 0.75, size.height * 0.3), // Sesión 4: dolor 3
      Offset(size.width, size.height * 0.15), // Sesión 5: dolor 1.5
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (var pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
  // Al abrir, marcamos todas como leídas en Firestore
  ref.read(notificationControllerProvider.notifier).markAllAsRead();

  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.7,
        child: Consumer(
          builder: (context, ref, _) {
            final notificationsAsync = ref.watch(patientNotificationsProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Centro de Notificaciones',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: notificationsAsync.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No tienes notificaciones aún.',
                                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          
                          IconData icon = Icons.info_outline_rounded;
                          Color color = Colors.blue;

                          if (notif.type == 'announcement') {
                            icon = Icons.campaign_outlined;
                            color = Colors.orange;
                          } else if (notif.type == 'appointment') {
                            icon = Icons.event_available_outlined;
                            color = Colors.teal;
                          } else if (notif.type == 'exercise') {
                            icon = Icons.fitness_center_outlined;
                            color = Colors.purple;
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: GoogleFonts.inter(
                                        fontSize: 12, 
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, 
                                        height: 1.4
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(notif.timestamp),
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

void _showFloatingBanner(BuildContext context, NotificationModel notif) {
  final overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notif.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notif.body,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
      );
    },
  );

  overlayState.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 4), () {
    overlayEntry.remove();
  });
}
