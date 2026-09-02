import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';
import '../../features/appointments/presentation/providers/appointment_provider.dart';

class MainNavScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(l10nProvider);
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);

    // Contar citas pendientes para hoy
    final now = DateTime.now();
    final todayAppointmentsCount = appointmentsAsync.value?.where((a) {
      return a.dateTime.year == now.year &&
          a.dateTime.month == now.month &&
          a.dateTime.day == now.day;
    }).length ?? 0;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : AppTheme.primaryColor.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBarItem(
                      index: 0,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.grid_view_rounded,
                      activeIcon: Icons.grid_view_rounded,
                      label: l10n.locale == 'es' ? 'Inicio' : 'Home',
                      onTap: () => _onTap(context, 0),
                      isDark: isDark,
                    ),
                    _NavBarItem(
                      index: 1,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.calendar_today_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: l10n.locale == 'es' ? 'Agenda' : 'Calendar',
                      badgeCount: todayAppointmentsCount > 0 ? todayAppointmentsCount : null,
                      onTap: () => _onTap(context, 1),
                      isDark: isDark,
                    ),
                    _NavBarItem(
                      index: 2,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_alt_rounded,
                      label: l10n.locale == 'es' ? 'Pacientes' : 'Patients',
                      onTap: () => _onTap(context, 2),
                      isDark: isDark,
                    ),
                    _NavBarItem(
                      index: 3,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                      label: l10n.locale == 'es' ? 'Finanzas' : 'Billing',
                      onTap: () => _onTap(context, 3),
                      isDark: isDark,
                    ),
                    _NavBarItem(
                      index: 4,
                      currentIndex: navigationShell.currentIndex,
                      icon: Icons.healing_outlined,
                      activeIcon: Icons.healing_rounded,
                      label: l10n.locale == 'es' ? 'Clínica' : 'Tools',
                      onTap: () => _onTap(context, 4),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  final VoidCallback onTap;
  final bool isDark;

  const _NavBarItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 22,
                      color: isSelected
                          ? (isDark ? const Color(0xFF2DD4BF) : AppTheme.primaryColor)
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount! > 9 ? '9+' : '$badgeCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? const Color(0xFF2DD4BF) : AppTheme.primaryColor)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
