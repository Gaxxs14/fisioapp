import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_error_formatter.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/app_user.dart';
import '../../../patients/presentation/providers/patient_portal_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isPatientMode = false;

  final BiometricService _biometricService = BiometricService();
  bool _biometricsAvailable = false;
  Map<String, String>? _savedCredentials;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final isSupported = await _biometricService.isDeviceSupported();
    final hasBiometrics = await _biometricService.hasEnrolledBiometrics();

    if (isSupported && hasBiometrics) {
      final saved = await _biometricService.getSavedCredentials();
      if (mounted) {
        setState(() {
          _biometricsAvailable = true;
          _savedCredentials = saved;

          if (saved != null) {
            _usernameController.text = saved['username'] ?? saved['email'] ?? '';
          }
        });

        // No iniciamos la huella automáticamente, el usuario debe dar tap al botón.
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated && mounted) {
      final firebaseUser = ref.read(authStateProvider).value;
      if (firebaseUser != null) {
        ref.read(localAuthSuccessProvider.notifier).state = true;
      } else if (_savedCredentials != null) {
        final username = _savedCredentials!['username'] ?? _savedCredentials!['email'] ?? '';
        final password = _savedCredentials!['password'] ?? '';
        await ref.read(authControllerProvider.notifier).signIn(
          username: username,
          password: password,
        );
        if (mounted) {
          ref.read(localAuthSuccessProvider.notifier).state = true;
        }
      }
    }
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_isPatientMode) {
      // Login de Paciente
      try {
        final query = await FirebaseFirestore.instance
            .collection('patients')
            .where('email', isEqualTo: username.toLowerCase())
            .get();

        if (query.docs.isEmpty) {
          throw 'No se encontró ningún paciente con ese correo electrónico.';
        }

        final patientDoc = query.docs.first;
        final patientData = patientDoc.data();
        final dni = patientData['dni'] ?? '';

        if (dni != password) {
          throw 'La contraseña (DNI) ingresada es incorrecta.';
        }

        // Credenciales correctas
        if (mounted) {
          ref.read(currentPatientIdProvider.notifier).set(patientDoc.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Bienvenido a tu portal, ${patientData['name']}!'),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.push('/patient/portal');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: GoogleFonts.inter()),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    // Login Profesional habitual
    await ref.read(authControllerProvider.notifier).signIn(
      username: username,
      password: password,
    );

    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.success && authState.errorMessage == null) {
        final deviceSupported = await _biometricService.isDeviceSupported();
        final hasEnrolled = await _biometricService.hasEnrolledBiometrics();

        debugPrint('[BIOMETRICS DEBUG] deviceSupported: $deviceSupported, hasEnrolled: $hasEnrolled');

        if (deviceSupported && hasEnrolled) {
          final prefs = await SharedPreferences.getInstance();
          final hasDecided = prefs.containsKey('biometric_enabled');
          final savedValue = prefs.getBool('biometric_enabled');

          debugPrint('[BIOMETRICS DEBUG] hasDecided: $hasDecided, savedValue: $savedValue');

          if (!hasDecided) {
            if (mounted) {
              await _showBiometricOptInDialog(context, username, password);
            }
          } else {
            final isEnabled = savedValue ?? false;
            if (isEnabled) {
              await _biometricService.saveCredentials(
                email: username, 
                password: password,
                clinicId: '',
                clinicName: '',
              );
            }
            ref.read(localAuthSuccessProvider.notifier).state = true;
          }
        } else {
          // El dispositivo no soporta biometría, acceso directo directo
          ref.read(localAuthSuccessProvider.notifier).state = true;
        }
      }
    }
  }

  Future<void> _showBiometricOptInDialog(
    BuildContext context,
    String username,
    String password,
  ) async {
    final currentLocale = ref.read(localeProvider);
    final isEs = currentLocale == 'es';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 10),
              Text(
                isEs ? '¿Activar huella digital?' : 'Enable Fingerprint?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            isEs
                ? '¿Deseas usar tu huella digital para iniciar sesión de forma más rápida en tus próximos accesos?'
                : 'Would you like to use fingerprint login to access your account faster in the future?',
            style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () async {
                await _biometricService.setBiometricsEnabled(false);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                ref.read(localAuthSuccessProvider.notifier).state = true;
              },
              child: Text(
                isEs ? 'Ahora no' : 'Not now',
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                await _biometricService.setBiometricsEnabled(true);
                await _biometricService.saveCredentials(
                  email: username,
                  password: password,
                  clinicId: '',
                  clinicName: '',
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                ref.read(localAuthSuccessProvider.notifier).state = true;
              },
              child: Text(
                isEs ? 'Activar' : 'Enable',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<AppUser?>>(authStateProvider, (previous, next) async {
      final user = next.value;
      if (user != null) {
        // Si el login es manual (controlador está en carga o éxito), no interferir 
        // y dejar que _submit maneje el diálogo de consentimiento.
        final authController = ref.read(authControllerProvider);
        if (authController.isLoading || authController.success) {
          return;
        }

        final enabledInApp = await _biometricService.isBiometricsEnabledInApp();
        if (!enabledInApp) {
          ref.read(localAuthSuccessProvider.notifier).state = true;
        }
      }
    });

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        final friendlyError = FirebaseErrorFormatter.format(next.errorMessage!, currentLocale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(friendlyError, style: GoogleFonts.inter(fontSize: 13))),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── BACKGROUND ───────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF022C22), const Color(0xFF0F172A)]
                      : [const Color(0xFFE0F7F5), const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Círculos decorativos
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.05 : 0.06),
              ),
            ),
          ),

          // ── SELECTOR DE IDIOMA ───────────────────────────────────────
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200,
                  ),
                ),
                child: DropdownButton<String>(
                  value: currentLocale,
                  underline: const SizedBox(),
                  icon: Icon(Icons.language, size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                  items: [
                    DropdownMenuItem(
                      value: 'es',
                      child: Text(l10n.spanish,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.english,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) ref.read(localeProvider.notifier).setLocale(val);
                  },
                ),
              ),
            ),
          ),

          // ── CONTENIDO PRINCIPAL ──────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo con gradiente
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFF14B8A6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.healing_outlined, size: 56, color: Colors.white),
                      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    ),
                    const SizedBox(height: 20),

                    // Nombre de la app
                    Center(
                      child: Text(
                        'FisioApp',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                          letterSpacing: -1,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 6),

                    Center(
                      child: Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 36),

                    // ── TARJETA DEL FORMULARIO ────────────────────────
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: isDark ? const Color(0xFF131B2E) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Título del formulario
                              Text(
                                currentLocale == 'es'
                                    ? 'Iniciar Sesión'
                                    : 'Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentLocale == 'es'
                                    ? 'Ingresa tu usuario y contraseña'
                                    : 'Enter your username and password',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Selector de Acceso: Fisioterapeutas vs Pacientes
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: Text(
                                        currentLocale == 'es' ? 'Fisioterapeutas' : 'Professionals',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      selected: !_isPatientMode,
                                      onSelected: (selected) {
                                        if (selected) setState(() => _isPatientMode = false);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: Text(
                                        currentLocale == 'es' ? 'Pacientes' : 'Patients',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      selected: _isPatientMode,
                                      onSelected: (selected) {
                                        if (selected) setState(() => _isPatientMode = true);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Campo: Nombre de usuario / Correo Paciente
                              TextFormField(
                                controller: _usernameController,
                                keyboardType: _isPatientMode ? TextInputType.emailAddress : TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: _isPatientMode
                                      ? (currentLocale == 'es' ? 'Correo del Paciente' : 'Patient Email')
                                      : (currentLocale == 'es' ? 'Nombre de Usuario' : 'Username'),
                                  hintText: _isPatientMode
                                      ? 'ej: paciente@correo.com'
                                      : (currentLocale == 'es' ? 'ej: dr.garcia' : 'e.g. dr.garcia'),
                                  prefixIcon: Icon(_isPatientMode ? Icons.email_outlined : Icons.person_outline),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return currentLocale == 'es'
                                        ? 'Ingresa tu nombre de usuario'
                                        : 'Enter your username';
                                  } else if (_isPatientMode && !value.contains('@')) {
                                    return 'Ingresa un correo electrónico válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Campo: Contraseña
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(l10n),
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => value == null || value.isEmpty
                                    ? l10n.passwordValidator
                                    : null,
                              ),
                              const SizedBox(height: 8),

                              // Olvidé mi contraseña
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push('/forgot-password'),
                                  child: Text(
                                    l10n.forgotPasswordBtn,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Botón Iniciar Sesión
                              ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => _submit(l10n),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        l10n.loginBtn,
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                              ),

                              // Botón de Huella Digital
                              if (_biometricsAvailable &&
                                  (_savedCredentials != null || ref.read(authStateProvider).value != null)) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: GestureDetector(
                                    onTap: authState.isLoading
                                        ? null
                                        : _authenticateWithBiometrics,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        border: Border.all(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.fingerprint_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        currentLocale == 'es'
                            ? 'Para registrar tu clínica, visita nuestra web o comunícate con soporte.'
                            : 'To register your clinic, visit our website or contact support.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
