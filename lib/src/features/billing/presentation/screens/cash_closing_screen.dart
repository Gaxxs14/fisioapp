import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/billing_provider.dart';

class CashClosingScreen extends ConsumerStatefulWidget {
  final double expectedAmount;

  const CashClosingScreen({super.key, required this.expectedAmount});

  @override
  ConsumerState<CashClosingScreen> createState() => _CashClosingScreenState();
}

class _CashClosingScreenState extends ConsumerState<CashClosingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countedController = TextEditingController();
  final _notesController = TextEditingController();

  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppTheme.primaryColor,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _countedController.dispose();
    _notesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor firma para confirmar el cierre de caja.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final counted = double.tryParse(_countedController.text) ?? 0.0;
    
    // Exportamos la firma como Bytes y la convertimos en Base64 para guardarla
    final signatureBytes = await _signatureController.toPngBytes();
    String signatureBase64 = '';
    if (signatureBytes != null) {
      signatureBase64 = base64Encode(signatureBytes);
    }

    await ref.read(billingControllerProvider.notifier).performClosing(
      expectedAmount: widget.expectedAmount,
      countedAmount: counted,
      notes: _notesController.text.trim(),
      signatureBase64: signatureBase64,
    );

    final state = ref.read(billingControllerProvider);
    if (state.success && state.errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cierre de caja completado y guardado.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Volver a Home o al Dashboard
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(billingControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Arqueo y Cierre de Caja',
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
                // Totales
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimado en Sistema:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${widget.expectedAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const Icon(Icons.calculate_rounded, color: AppTheme.primaryColor, size: 36),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Conteo Real
                Container(
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
                      TextFormField(
                        controller: _countedController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Efectivo Real Contado (\$)',
                          prefixIcon: Icon(Icons.monetization_on_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Escribe la cantidad física en caja' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Observaciones / Diferencias',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Firma Digital
                Text(
                  'Firma del Profesional Responsable',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    child: Signature(
                      controller: _signatureController,
                      height: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: Text('Limpiar Firma', style: GoogleFonts.inter(fontSize: 12)),
                      onPressed: () => _signatureController.clear(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Confirmar
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
                          'Confirmar Cierre de Caja',
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
