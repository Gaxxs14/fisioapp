import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_error_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/app_user.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  
  TimeOfDay? _workHoursStart;
  TimeOfDay? _workHoursEnd;
  
  List<String> _selectedDays = [];
  bool _biometricsSupported = false;
  bool _biometricsEnabled = false;
  bool _isLoading = false;
  
  final BiometricService _biometricService = BiometricService();
  final StorageService _storageService = StorageService();
  
  final List<String> _weekDaysKeys = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkBiometrics();
  }

  Future<void> _selectAndUploadPhoto(AppUser user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final storagePath = 'clinics/${user.clinicId}/users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final photoUrl = await _storageService.uploadFile(
          path: storagePath,
          filePath: pickedFile.path,
        );

        final updatedUser = user.copyWith(photoUrl: photoUrl);
        await ref.read(authControllerProvider.notifier).updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada correctamente.'),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir la foto: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _loadUserData() {
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _specialtyController.text = user.specialty ?? '';
      _selectedDays = user.workDays ?? [];
      
      if (user.workHoursStart != null) {
        final parts = user.workHoursStart!.split(':');
        _workHoursStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _workHoursStart = const TimeOfDay(hour: 9, minute: 0);
      }
      
      if (user.workHoursEnd != null) {
        final parts = user.workHoursEnd!.split(':');
        _workHoursEnd = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        _workHoursEnd = const TimeOfDay(hour: 18, minute: 0);
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final supported = await _biometricService.isDeviceSupported() && 
                         await _biometricService.hasEnrolledBiometrics();
    final enabled = await _biometricService.isBiometricsEnabledInApp();
    setState(() {
      _biometricsSupported = supported;
      _biometricsEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workHoursStart ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && picked != _workHoursStart) {
      setState(() {
        _workHoursStart = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workHoursEnd ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null && picked != _workHoursEnd) {
      setState(() {
        _workHoursEnd = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDayLabel(String key, String locale) {
    if (locale == 'es') {
      switch (key) {
        case 'Monday': return 'Lun';
        case 'Tuesday': return 'Mar';
        case 'Wednesday': return 'Mié';
        case 'Thursday': return 'Jue';
        case 'Friday': return 'Vie';
        case 'Saturday': return 'Sáb';
        case 'Sunday': return 'Dom';
        default: return key;
      }
    } else {
      return key.substring(0, 3);
    }
  }

  Future<void> _save(AppLocalizations l10n, String currentLocale) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = ref.read(authControllerProvider).user;
    
    if (user != null) {
      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        specialty: user.role == UserRole.physio ? _specialtyController.text.trim() : null,
        workDays: _selectedDays,
        workHoursStart: _workHoursStart != null ? _formatTimeOfDay(_workHoursStart!) : null,
        workHoursEnd: _workHoursEnd != null ? _formatTimeOfDay(_workHoursEnd!) : null,
      );

      try {
        await ref.read(authControllerProvider.notifier).updateUserProfile(updatedUser);
        await _biometricService.setBiometricsEnabled(_biometricsEnabled);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.successSave, style: GoogleFonts.inter()),
                ],
              ),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final friendlyError = FirebaseErrorFormatter.format(e, currentLocale);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyError, style: GoogleFonts.inter()),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeProvider);
    final appThemeMode = ref.watch(themeProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle, style: GoogleFonts.inter())),
        body: Center(child: Text('Session expired.', style: GoogleFonts.inter())),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── PREMIUM APP BAR WITH HERO HEADER ────────────────────────
          SliverAppBar(
            expandedHeight: 220,
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
                  padding: const EdgeInsets.only(top: 80, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () => _selectAndUploadPhoto(user),
                          child: Stack(
                            children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null || user.photoUrl!.isEmpty
                                    ? const Icon(Icons.person, size: 46, color: Colors.white)
                                    : null,
                              ),
                            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── PROFILE OPTIONS ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 🎨 SECCIÓN: APARIENCIA (THEME SELECTOR)
                          _buildSectionHeader(
                            icon: Icons.palette_outlined,
                            title: currentLocale == 'es' ? 'Apariencia y Tema' : 'Theme & Appearance',
                          ),
                          const SizedBox(height: 12),
                          _buildThemeSelector(context, ref, appThemeMode, isDark),
                          const SizedBox(height: 24),

                          // 👤 SECCIÓN: INFORMACIÓN PERSONAL
                          _buildSectionHeader(
                            icon: Icons.person_outline,
                            title: currentLocale == 'es' ? 'Información Personal' : 'Personal Info',
                          ),
                          const SizedBox(height: 12),
                          _buildCardWrapper(
                            isDark: isDark,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.nameLabel,
                                    prefixIcon: const Icon(Icons.badge_outlined),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty 
                                      ? (currentLocale == 'es' ? 'Escribe tu nombre' : 'Enter your name') 
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: user.email,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                                  ),
                                ),
                                if (user.role == UserRole.physio) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _specialtyController,
                                    decoration: InputDecoration(
                                      labelText: l10n.specialtyLabel,
                                      prefixIcon: const Icon(Icons.psychology_outlined),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 📅 SECCIÓN: HORARIOS Y DÍAS LABORALES
                          if (user.role == UserRole.physio || user.role == UserRole.admin) ...[
                            _buildSectionHeader(
                              icon: Icons.calendar_month_outlined,
                              title: l10n.scheduleLabel,
                            ),
                            const SizedBox(height: 12),
                            _buildCardWrapper(
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentLocale == 'es' ? 'Días Laborales' : 'Work Days',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _weekDaysKeys.map((dayKey) {
                                      final isSelected = _selectedDays.contains(dayKey);
                                      return ChoiceChip(
                                        label: Text(
                                          _getDayLabel(dayKey, currentLocale),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected 
                                                ? AppTheme.primaryColor 
                                                : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                        checkmarkColor: AppTheme.primaryColor,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedDays.add(dayKey);
                                            } else {
                                              _selectedDays.remove(dayKey);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    currentLocale == 'es' ? 'Horario' : 'Work Hours',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _selectStartTime(context),
                                          borderRadius: BorderRadius.circular(12),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: currentLocale == 'es' ? 'Entrada' : 'In',
                                              prefixIcon: const Icon(Icons.access_time),
                                            ),
                                            child: Text(
                                              _workHoursStart != null ? _workHoursStart!.format(context) : '09:00 AM',
                                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _selectEndTime(context),
                                          borderRadius: BorderRadius.circular(12),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: currentLocale == 'es' ? 'Salida' : 'Out',
                                              prefixIcon: const Icon(Icons.access_time_filled_outlined),
                                            ),
                                            child: Text(
                                              _workHoursEnd != null ? _workHoursEnd!.format(context) : '06:00 PM',
                                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 🌐 SECCIÓN: IDIOMA
                          _buildSectionHeader(
                            icon: Icons.language_outlined,
                            title: l10n.languageLabel,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: currentLocale,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.translate_outlined),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              DropdownMenuItem(value: 'es', child: Text(l10n.spanish, style: GoogleFonts.inter())),
                              DropdownMenuItem(value: 'en', child: Text(l10n.english, style: GoogleFonts.inter())),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(localeProvider.notifier).setLocale(val);
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // 🔐 SECCIÓN: BIOMETRÍA & SEGURIDAD
                          if (_biometricsSupported) ...[
                            _buildSectionHeader(
                              icon: Icons.fingerprint_outlined,
                              title: currentLocale == 'es' ? 'Seguridad Biométrica' : 'Biometric Security',
                            ),
                            const SizedBox(height: 12),
                            _buildCardWrapper(
                              isDark: isDark,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  l10n.biometricEnable,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  currentLocale == 'es' 
                                      ? 'Usa tu huella dactilar para acceder rápidamente.' 
                                      : 'Use fingerprint scanner to access quickly.',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                                ),
                                value: _biometricsEnabled,
                                activeThumbColor: AppTheme.primaryColor,
                                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                onChanged: (bool value) {
                                  setState(() => _biometricsEnabled = value);
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // ── BOTÓN GUARDAR CAMBIOS ────────────────────
                          ElevatedButton(
                            onPressed: () => _save(l10n, currentLocale),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              l10n.saveProfileBtn,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS AUXILIARES DE DISEÑO ───────────────────────────────────

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildCardWrapper({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentMode, bool isDark) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return _buildCardWrapper(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageCode == 'es' ? 'Selecciona el tema de la aplicación:' : 'Select application theme:',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / 3 - 6;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ThemeOptionButton(
                    width: width,
                    icon: Icons.wb_sunny_outlined,
                    label: languageCode == 'es' ? 'Claro' : 'Light',
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                    isDark: isDark,
                  ),
                  _ThemeOptionButton(
                    width: width,
                    icon: Icons.settings_brightness_outlined,
                    label: languageCode == 'es' ? 'Auto' : 'System',
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                    isDark: isDark,
                  ),
                  _ThemeOptionButton(
                    width: width,
                    icon: Icons.nights_stay_outlined,
                    label: languageCode == 'es' ? 'Oscuro' : 'Dark',
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeOptionButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: 250.ms,
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withValues(alpha: 0.15) 
              : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.grey.shade600), 
              size: 20
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
