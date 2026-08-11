import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../../appointments/presentation/providers/appointment_provider.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../auth/domain/entities/app_user.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeProvider);

    final patientsAsync = ref.watch(patientsStreamProvider);
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);
    final waitingListAsync = ref.watch(waitingListStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── PREMIUM APP BAR ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D2137) : AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(context, user, l10n, isDark, size),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                ),
                tooltip: l10n.profileTooltip,
                onPressed: () => context.push('/profile'),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_outlined, color: Colors.white, size: 20),
                ),
                tooltip: l10n.logOutTooltip,
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ── REAL-TIME STATS ──────────────────────────────────
                  _buildStatsRow(l10n, patientsAsync, appointmentsAsync, waitingListAsync, isDark, currentLocale),

                  const SizedBox(height: 28),

                  // ── TODAY'S AGENDA ───────────────────────────────────
                  _buildSectionTitle(
                    context,
                    currentLocale == 'es' ? 'Agenda de Hoy' : "Today's Schedule",
                    currentLocale == 'es' ? 'Ver todo' : 'View all',
                    () => context.push('/appointments'),
                    delay: 150,
                  ),
                  const SizedBox(height: 12),
                  _buildTodayAgenda(context, l10n, currentLocale, appointmentsAsync, isDark),

                  // ── QUICK ACTIONS ────────────────────────────────────
                  _buildSectionTitle(
                    context,
                    l10n.quickActions,
                    '',
                    null,
                    delay: 200,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActionsGrid(context, l10n, isDark, user),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO HEADER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, dynamic user, AppLocalizations l10n, bool isDark, Size size) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;
    if (hour < 12) {
      greeting = l10n.locale == 'es' ? 'Buenos días' : 'Good morning';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 18) {
      greeting = l10n.locale == 'es' ? 'Buenas tardes' : 'Good afternoon';
      greetingIcon = Icons.wb_cloudy_outlined;
    } else {
      greeting = l10n.locale == 'es' ? 'Buenas noches' : 'Good evening';
      greetingIcon = Icons.nights_stay_outlined;
    }

    final dateStr = DateFormat(l10n.locale == 'es' ? "EEEE, d 'de' MMMM" : 'EEEE, MMMM d', l10n.locale).format(now);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D2137), const Color(0xFF0A3D5C)]
              : [const Color(0xFF0F766E), const Color(0xFF0EA5A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(greetingIcon, color: Colors.white.withValues(alpha: 0.8), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.name ?? 'Terapeuta'} 👋',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        user?.role?.displayName ?? 'Fisioterapeuta',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today_outlined, color: Colors.white.withValues(alpha: 0.7), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATS ROW
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(
    AppLocalizations l10n,
    AsyncValue<List<dynamic>> patientsAsync,
    AsyncValue<List<Appointment>> appointmentsAsync,
    AsyncValue<List<dynamic>> waitingListAsync,
    bool isDark,
    String locale,
  ) {
    final patientsCount = patientsAsync.value?.length ?? 0;
    final todayCount = appointmentsAsync.value?.where((a) {
          return _isToday(a.dateTime) && !a.isBlocked && a.status != AppointmentStatus.cancelled;
        }).length ??
        0;
    final waitlistCount = waitingListAsync.value?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: _StatCard(
              title: locale == 'es' ? 'Citas Hoy' : 'Today',
              value: todayCount.toString(),
              icon: Icons.event_available_outlined,
              gradient: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
              delay: 50,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RepaintBoundary(
            child: _StatCard(
              title: locale == 'es' ? 'Pacientes' : 'Patients',
              value: patientsCount.toString(),
              icon: Icons.people_alt_outlined,
              gradient: [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)],
              delay: 100,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RepaintBoundary(
            child: _StatCard(
              title: locale == 'es' ? 'En Espera' : 'Waitlist',
              value: waitlistCount.toString(),
              icon: Icons.hourglass_bottom_outlined,
              gradient: [const Color(0xFFD97706), const Color(0xFFFBBF24)],
              delay: 150,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SECTION TITLE
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String actionLabel,
    VoidCallback? onAction, {
    int delay = 0,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        if (actionLabel.isNotEmpty && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: -0.05, end: 0);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TODAY'S AGENDA
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTodayAgenda(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    AsyncValue<List<Appointment>> appointmentsAsync,
    bool isDark,
  ) {
    return appointmentsAsync.when(
      data: (appointments) {
        final today = appointments.where((a) {
          return _isToday(a.dateTime) && !a.isBlocked && a.status != AppointmentStatus.cancelled;
        }).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        final preview = today.take(3).toList();

        if (preview.isEmpty) {
          return _buildEmptyAgenda(locale, isDark);
        }

        return Column(
          children: preview.asMap().entries.map((entry) {
            final i = entry.key;
            final app = entry.value;
            return _AppointmentTile(
              appointment: app,
              isDark: isDark,
              delay: 170 + (i * 60),
              onTap: () => context.push('/patients/detail/${app.patientId}'),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      // ignore: avoid_unused_parameters
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyAgenda(String locale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              locale == 'es'
                  ? '¡Sin citas pendientes hoy! Disfruta tu día 🎉'
                  : 'No appointments scheduled today! Enjoy your day 🎉',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 170.ms);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS GRID
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionsGrid(BuildContext context, AppLocalizations l10n, bool isDark, AppUser? user) {
    final actions = [
      _QuickAction(
        title: l10n.patientsMenu,
        subtitle: l10n.locale == 'es' ? 'Gestionar expedientes' : 'Manage records',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF1D4ED8),
        bgColor: const Color(0xFFEFF6FF),
        bgColorDark: const Color(0xFF172554),
        route: '/patients',
        delay: 220,
      ),
      _QuickAction(
        title: l10n.calendarMenu,
        subtitle: l10n.locale == 'es' ? 'Ver y agendar citas' : 'View & book',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        bgColorDark: const Color(0xFF451A03),
        route: '/appointments',
        delay: 270,
      ),
      _QuickAction(
        title: l10n.billingMenu,
        subtitle: l10n.locale == 'es' ? 'Facturación y Cajas' : 'Invoices & Cash',
        icon: Icons.point_of_sale_outlined,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
        bgColorDark: const Color(0xFF064E3B),
        route: '/billing',
        delay: 320,
      ),
      _QuickAction(
        title: l10n.locale == 'es' ? 'Reportes' : 'Analytics',
        subtitle: l10n.locale == 'es' ? 'Métricas y balances' : 'Balances & charts',
        icon: Icons.analytics_outlined,
        color: const Color(0xFFEC4899),
        bgColor: const Color(0xFFFDF2F8),
        bgColorDark: const Color(0xFF500724),
        route: '/reports',
        delay: 370,
      ),
      if (user?.role == UserRole.admin)
        _QuickAction(
          title: l10n.locale == 'es' ? 'Administración' : 'Settings',
          subtitle: l10n.locale == 'es' ? 'Ajustes y personal' : 'Staff & configs',
          icon: Icons.settings_applications_outlined,
          color: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          bgColorDark: const Color(0xFF2E1065),
          route: '/admin',
          delay: 420,
        ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8), // Padding para evitar que las sombras de las tarjetas salgan cortadas
      children: actions.map((action) => RepaintBoundary(
        child: _QuickActionCard(action: action, isDark: isDark, context: context),
      )).toList(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STAT CARD WIDGET
// ────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int delay;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.delay,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 250.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic, duration: 250.ms);
  }
}



// ────────────────────────────────────────────────────────────────────────────
// APPOINTMENT TILE
// ────────────────────────────────────────────────────────────────────────────
class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool isDark;
  final int delay;
  final VoidCallback onTap;

  const _AppointmentTile({
    required this.appointment,
    required this.isDark,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Time column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(appointment.dateTime),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${appointment.durationMinutes}m',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Divider
                Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName ?? 'Paciente',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.roomName ?? 'Sin consultorio',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(appointment.status),
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 250.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic, duration: 250.ms);
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.pending:
        return Colors.orange;
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

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.ongoing:
        return 'En Curso';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.noShow:
        return 'No asistió';
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// QUICK ACTION MODEL
// ────────────────────────────────────────────────────────────────────────────
class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color bgColorDark;
  final String? route;
  final int delay;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.bgColorDark,
    required this.route,
    required this.delay,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// QUICK ACTION CARD
// ────────────────────────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  final bool isDark;
  final BuildContext context;

  const _QuickActionCard({
    required this.action,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext outerContext) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (action.route != null) {
              context.push(action.route!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.mounted
                        ? (action.subtitle.contains('pronto') || action.subtitle.contains('soon')
                            ? '${action.title}: Módulo disponible próximamente.'
                            : action.title)
                        : action.title,
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: action.color,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? action.bgColorDark : action.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 26),
                ),
                const Spacer(),
                Text(
                  action.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: action.delay > 300 ? 300 : action.delay),
      duration: 280.ms,
    ).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic, duration: 280.ms);
  }
}
