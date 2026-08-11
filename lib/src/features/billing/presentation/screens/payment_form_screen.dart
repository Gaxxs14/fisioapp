import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/billing_provider.dart';
import '../../domain/entities/patient_bono.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;
  final double defaultAmount;

  const PaymentFormScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.defaultAmount,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _conceptController;
  late TextEditingController _amountController;
  final _referenceController = TextEditingController();

  String _selectedMethod = 'cash'; // cash, card, transfer, pending, bono
  PatientBono? _selectedBono;

  @override
  void initState() {
    super.initState();
    _conceptController = TextEditingController(text: 'Sesión de Fisioterapia - ${widget.patientName}');
    _amountController = TextEditingController(text: widget.defaultAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMethod == 'bono' && _selectedBono == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona un bono activo.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    await ref.read(billingControllerProvider.notifier).registerPayment(
      patientId: widget.patientId,
      patientName: widget.patientName,
      concept: _conceptController.text.trim(),
      amount: _selectedMethod == 'bono' ? 0.0 : amount, // El consumo por bono vale 0.0 contablemente directo
      paymentMethod: _selectedMethod,
      referenceCode: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      useBonoId: _selectedBono?.id,
    );

    final state = ref.read(billingControllerProvider);
    if (state.success && state.errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago registrado correctamente.', style: GoogleFonts.inter()),
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
    final uiState = ref.watch(billingControllerProvider);
    final bonosAsync = ref.watch(patientBonosStreamProvider(widget.patientId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Registrar Cobro',
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
                // Info del paciente
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paciente a Cobrar:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 2),
                          Text(widget.patientName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Formulario
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
                      // Concepto
                      TextFormField(
                        controller: _conceptController,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Concepto del Cobro'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),

                      // Monto
                      if (_selectedMethod != 'bono') ...[
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Monto a Cobrar (\$)'),
                          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Métodos de Pago
                      Text(
                        'Método de Pago',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMethodChip('Efectivo', 'cash', Icons.money_rounded),
                          _buildMethodChip('Tarjeta', 'card', Icons.credit_card_rounded),
                          _buildMethodChip('Transferencia', 'transfer', Icons.account_balance_rounded),
                          _buildMethodChip('Pendiente', 'pending', Icons.hourglass_bottom_rounded),
                          _buildMethodChip('Usar Bono', 'bono', Icons.card_membership_rounded),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Selección de Bono (Si aplica)
                      if (_selectedMethod == 'bono') ...[
                        Text(
                          'Selecciona Bono Activo:',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        bonosAsync.when(
                          data: (bonos) {
                            final activeBonos = bonos.where((b) => b.remainingSessions > 0).toList();
                            if (activeBonos.isEmpty) {
                              return Text(
                                'El paciente no posee ningún bono con sesiones disponibles.',
                                style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                              );
                            }
                            return Column(
                              children: activeBonos.map((bono) {
                                final isSelected = _selectedBono?.id == bono.id;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      '${bono.serviceName} (${bono.remainingSessions}/${bono.purchasedSessions} ses.)',
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedBono = selected ? bono : null;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Text('Error al consultar bonos: $e'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Código de Referencia
                      if (_selectedMethod == 'card' || _selectedMethod == 'transfer') ...[
                        TextFormField(
                          controller: _referenceController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(labelText: 'Código / Núm. Referencia (Opcional)'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Guardar
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
                          'Confirmar y Registrar Pago',
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

  Widget _buildMethodChip(String label, String value, IconData icon) {
    final isSelected = _selectedMethod == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? AppTheme.primaryColor : Colors.grey),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMethod = value;
            if (value != 'bono') {
              _selectedBono = null;
            }
          });
        }
      },
    );
  }
}
