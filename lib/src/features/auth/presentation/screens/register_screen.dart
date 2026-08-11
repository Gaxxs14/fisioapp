import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_error_formatter.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _clinicNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  String? _selectedQuestion;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final List<String> _securityQuestionsEs = [
    '¿Cuál era el nombre de tu primera mascota?',
    '¿En qué ciudad naciste?',
    '¿Cuál fue el nombre de tu primera escuela?',
    '¿Cuál es el segundo nombre de tu madre?',
    '¿Cuál es tu color favorito?',
  ];

  final List<String> _securityQuestionsEn = [
    'What was the name of your first pet?',
    'In what city were you born?',
    'What was the name of your first school?',
    'What is your mother\'s middle name?',
    'What is your favorite color?',
  ];

  @override
  void dispose() {
    _clinicNameController.dispose();
    _ownerNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).registerClinic(
      clinicName: _clinicNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      username: _usernameController.text.trim().toLowerCase(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      securityQuestion: _selectedQuestion!,
      securityAnswer: _securityAnswerController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeProvider);

    final questions =
        currentLocale == 'es' ? _securityQuestionsEs : _securityQuestionsEn;
    _selectedQuestion ??= questions.first;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.primaryColor, size: 52),
                ),
                const SizedBox(height: 20),
                Text(
                  currentLocale == 'es' ? '¡Clínica Creada!' : 'Clinic Created!',
                  style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Mostrar las credenciales de acceso al usuario
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLocale == 'es'
                            ? '🔑 Tus credenciales de acceso:'
                            : '🔑 Your login credentials:',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '${currentLocale == 'es' ? 'Usuario' : 'Username'}: ',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _usernameController.text.trim().toLowerCase(),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentLocale == 'es'
                      ? 'Guarda tu usuario. Lo necesitarás para iniciar sesión cada vez.'
                      : 'Save your username. You\'ll need it to sign in every time.',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(authControllerProvider.notifier).clearSuccess();
                      context.go('/login');
                    },
                    child: Text(
                      currentLocale == 'es'
                          ? 'Ir al Inicio de Sesión'
                          : 'Go to Login',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (next.errorMessage != null) {
        final friendlyError =
            FirebaseErrorFormatter.format(next.errorMessage!, currentLocale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(friendlyError,
                        style: GoogleFonts.inter(fontSize: 13))),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerHeader,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner de prueba gratis
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.08),
                      AppTheme.primaryColor.withValues(alpha: 0.03),
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_outlined,
                            color: AppTheme.primaryColor, size: 28),
                      ).animate().scale(
                          duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.registerBannerTitle,
                              style: GoogleFonts.inter(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.registerBannerDesc,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── SECCIÓN: INFORMACIÓN DE LA CLÍNICA ──────────
                      _SectionHeader(
                        icon: Icons.business_outlined,
                        title: currentLocale == 'es'
                            ? 'Información de la Clínica'
                            : 'Clinic Information',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _clinicNameController,
                        decoration: InputDecoration(
                          labelText: l10n.clinicNameLabel,
                          prefixIcon: const Icon(Icons.business_outlined),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? l10n.clinicNameValidator
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _ownerNameController,
                        decoration: InputDecoration(
                          labelText: l10n.adminNameLabel,
                          prefixIcon: const Icon(Icons.person_outline),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? l10n.adminNameValidator
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // ── SECCIÓN: CREDENCIALES DE ACCESO ─────────────
                      _SectionHeader(
                        icon: Icons.key_outlined,
                        title: currentLocale == 'es'
                            ? 'Credenciales de Acceso'
                            : 'Login Credentials',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentLocale == 'es'
                                    ? 'Con estas credenciales iniciarás sesión. El correo electrónico es solo para recuperar tu contraseña.'
                                    : 'Use these credentials to sign in. The email is only for password recovery.',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Nombre de usuario
                      TextFormField(
                        controller: _usernameController,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: currentLocale == 'es'
                              ? 'Nombre de Usuario'
                              : 'Username',
                          hintText: currentLocale == 'es'
                              ? 'ej: dr.garcia (sin espacios)'
                              : 'e.g. dr.garcia (no spaces)',
                          prefixIcon: const Icon(Icons.alternate_email),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return currentLocale == 'es'
                                ? 'El nombre de usuario es obligatorio'
                                : 'Username is required';
                          }
                          if (v.trim().contains(' ')) {
                            return currentLocale == 'es'
                                ? 'El usuario no puede tener espacios'
                                : 'Username cannot have spaces';
                          }
                          if (v.trim().length < 3) {
                            return currentLocale == 'es'
                                ? 'Mínimo 3 caracteres'
                                : 'Minimum 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Correo (solo para recuperación)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: currentLocale == 'es'
                              ? 'Correo de Recuperación'
                              : 'Recovery Email',
                          hintText: currentLocale == 'es'
                              ? 'Para recuperar tu contraseña'
                              : 'For password recovery only',
                          prefixIcon: const Icon(Icons.email_outlined),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.emailValidator;
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v)) {
                            return l10n.emailInvalidValidator;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.passwordValidator;
                          if (v.length < 6) return l10n.passwordLengthValidator;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Confirmar contraseña
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: currentLocale == 'es'
                              ? 'Confirmar Contraseña'
                              : 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return currentLocale == 'es'
                                ? 'Confirma tu contraseña'
                                : 'Confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return currentLocale == 'es'
                                ? 'Las contraseñas no coinciden'
                                : 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── SECCIÓN: SEGURIDAD DE LA CUENTA ─────────────
                      _SectionHeader(
                        icon: Icons.security_outlined,
                        title: l10n.securityHeader,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.securitySub,
                        style: GoogleFonts.inter(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedQuestion,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.securityQuestionLabel,
                          prefixIcon: const Icon(Icons.quiz_outlined),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        items: questions.map((q) {
                          return DropdownMenuItem<String>(
                            value: q,
                            child: Text(q,
                                style: GoogleFonts.inter(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedQuestion = v),
                        validator: (v) =>
                            v == null ? l10n.securityQuestionValidator : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _securityAnswerController,
                        decoration: InputDecoration(
                          labelText: l10n.securityAnswerLabel,
                          prefixIcon: const Icon(Icons.check_circle_outline),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? l10n.securityAnswerValidator
                            : null,
                      ),
                      const SizedBox(height: 32),

                      // Botón de Registro
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                l10n.registerBtn,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.hasAccount,
                        style: GoogleFonts.inter(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 13)),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.backToLogin,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para encabezados de sección
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
