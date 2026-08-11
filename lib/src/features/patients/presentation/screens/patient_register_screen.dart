import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _selectedGender = 'Masculino';

  final List<String> _genders = ['Masculino', 'Femenino', 'Otro'];

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Por favor, selecciona la fecha de nacimiento.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await ref.read(patientControllerProvider.notifier).createPatient(
      name: _nameController.text.trim(),
      dni: _dniController.text.trim(),
      birthDate: _selectedBirthDate!,
      gender: _selectedGender,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      contactPersonName: _emergencyNameController.text.trim(),
      contactPersonPhone: _emergencyPhoneController.text.trim(),
    );

    final state = ref.read(patientControllerProvider);
    if (state.errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Paciente registrado con éxito!',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(patientControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Nuevo Paciente',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── SECCIÓN 1: DATOS PERSONALES ─────────────────────────
                  _buildSectionHeader(Icons.person_outline, 'Datos Personales'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty 
                              ? 'El nombre es obligatorio' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dniController,
                          decoration: const InputDecoration(
                            labelText: 'Documento de Identidad (DNI)',
                            prefixIcon: Icon(Icons.perm_identity),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty 
                              ? 'El DNI es obligatorio' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Fecha de nacimiento
                        InkWell(
                          onTap: () => _selectBirthDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha de Nacimiento',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                            child: Text(
                              _selectedBirthDate != null
                                  ? DateFormat('dd / MM / yyyy').format(_selectedBirthDate!)
                                  : 'Selecciona la fecha',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: _selectedBirthDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Género
                        Text(
                          'Género:',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _genders.map((gender) {
                            final isSelected = _selectedGender == gender;
                            return ChoiceChip(
                              label: Text(
                                gender,
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
                                if (selected) {
                                  setState(() => _selectedGender = gender);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SECCIÓN 2: INFORMACIÓN DE CONTACTO ───────────────────
                  _buildSectionHeader(Icons.contact_mail_outlined, 'Contacto'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Número de Teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty 
                              ? 'El teléfono es obligatorio' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return null; // Opcional
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Introduce un correo válido';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SECCIÓN 3: CONTACTO DE EMERGENCIA ────────────────────
                  _buildSectionHeader(Icons.contact_phone_outlined, 'Contacto de Emergencia'),
                  const SizedBox(height: 12),
                  _buildCardWrapper(
                    isDark: isDark,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emergencyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Contacto',
                            prefixIcon: Icon(Icons.person_pin_outlined),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty 
                              ? 'El nombre del contacto es obligatorio' 
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono del Contacto',
                            prefixIcon: Icon(Icons.phone_iphone_outlined),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty 
                              ? 'El teléfono del contacto es obligatorio' 
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón registrar
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
                            'Registrar Paciente',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}
