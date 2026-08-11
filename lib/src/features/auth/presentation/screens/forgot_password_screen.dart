import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();

  int _currentStep = 1; // Step 1: Email search, Step 2: Question validation
  String? _fetchedQuestion;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestion() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final question = await ref.read(authControllerProvider.notifier).getSecurityQuestion(username);
    
    if (question != null) {
      setState(() {
        _fetchedQuestion = question;
        _currentStep = 2;
      });
    }
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final answer = _answerController.text;
    final newPassword = _newPasswordController.text;

    await ref.read(authControllerProvider.notifier).verifyAndResetPassword(
          username: username,
          securityAnswer: answer,
          newPassword: newPassword,
        );

    final authState = ref.read(authControllerProvider);
    if (authState.success && authState.errorMessage == null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Contraseña Restablecida', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Text(
              'Hemos verificado tu respuesta de seguridad. Por seguridad de Firebase, te hemos enviado un correo oficial para confirmar tu cambio de contraseña. Por favor revisa tu bandeja de entrada.',
              style: GoogleFonts.inter(height: 1.4, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Pop Dialog
                  context.pop(); // Pop ForgotPasswordScreen (returns to Login)
                },
                child: Text('Entendido', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15), width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_reset_outlined,
                        size: 56,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  
                  if (_currentStep == 1) ...[
                    // Paso 1: Ingreso de correo
                    Text(
                      'Paso 1: Identificación',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el nombre de usuario asociado a tu cuenta para buscar tu pregunta de seguridad.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Form(
                        key: _emailFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Nombre de Usuario',
                                hintText: 'Tu usuario de acceso',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre de usuario es obligatorio';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _fetchQuestion,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Buscar Pregunta',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                  ] else ...[
                    // Paso 2: Pregunta de seguridad y restablecimiento
                    Text(
                      'Paso 2: Responder Pregunta',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Responde a la pregunta para poder generar el enlace de cambio de contraseña.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Form(
                        key: _resetFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pregunta de Seguridad:',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 11),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _fetchedQuestion ?? '',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Respuesta
                            TextFormField(
                              controller: _answerController,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Tu Respuesta',
                                prefixIcon: Icon(Icons.check_circle_outline),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Escribe tu respuesta' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Nueva contraseña
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Nueva Contraseña Temporal',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La nueva contraseña es obligatoria';
                                }
                                if (value.length < 6) {
                                  return 'Debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _submitReset,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Restablecer Contraseña',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _currentStep = 1;
                                  _answerController.clear();
                                  _newPasswordController.clear();
                                });
                              },
                              child: Text('Volver al paso anterior', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 350.ms),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
