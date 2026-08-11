import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/admin_provider.dart';

class ProfessionalFormScreen extends ConsumerStatefulWidget {
  const ProfessionalFormScreen({super.key});

  @override
  ConsumerState<ProfessionalFormScreen> createState() => _ProfessionalFormScreenState();
}

class _ProfessionalFormScreenState extends ConsumerState<ProfessionalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.physio;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(adminControllerProvider.notifier).addStaffUser(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
          email: _emailController.text.trim(),
          specialty: _selectedRole == UserRole.receptionist ? 'Recepción' : _specialtyController.text.trim(),
          role: _selectedRole,
          password: _passwordController.text,
        );

    final state = ref.read(adminControllerProvider);
    if (state.success && state.errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta de personal registrada exitosamente.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(adminControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AdminUiState>(adminControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(adminControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Registrar Personal',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjeta Principal del Formulario
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
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre completo
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Usuario',
                          hintText: 'ej: lic.ortiz',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Rol
                      Text(
                        'Rol de Personal',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text('Fisioterapeuta', style: GoogleFonts.inter(fontSize: 12)),
                            selected: _selectedRole == UserRole.physio,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRole = UserRole.physio);
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Text('Recepcionista', style: GoogleFonts.inter(fontSize: 12)),
                            selected: _selectedRole == UserRole.receptionist,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRole = UserRole.receptionist);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Especialidad (solo si es Fisioterapeuta)
                      if (_selectedRole == UserRole.physio) ...[
                        TextFormField(
                          controller: _specialtyController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Especialidad Fisioterapéutica',
                            prefixIcon: Icon(Icons.healing_outlined),
                          ),
                          validator: (v) => _selectedRole == UserRole.physio && (v == null || v.isEmpty)
                              ? 'Campo obligatorio para terapeutas'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Contraseña Temporal
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Contraseña Temporal',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Guardar
                ElevatedButton(
                  onPressed: uiState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: uiState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Registrar Personal',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
