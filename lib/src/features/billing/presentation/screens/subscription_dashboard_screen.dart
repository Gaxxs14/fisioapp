import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/subscription_provider.dart';
import '../../domain/entities/subscription_model.dart';

class SubscriptionDashboardScreen extends ConsumerWidget {
  const SubscriptionDashboardScreen({super.key});

  Future<void> _downloadInvoicePdf(Map<String, dynamic> invoice) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FisioApp SaaS - Factura de Suscripción', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                pw.SizedBox(height: 8),
                pw.Text('ID Transacción: ${invoice['id'] ?? ''}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#0F766E')),
                pw.SizedBox(height: 24),
                pw.Text('Detalles del Pago', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Concepto: Plan Suscripción ${invoice['planName'] ?? ''}'),
                pw.Text('Monto Cobrado: \$${(invoice['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} USD'),
                pw.Text('Fecha de Emisión: ${invoice['date'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(invoice['date'])) : ''}'),
                pw.Text('Método de Cobro: Tarjeta finalizada en ${invoice['cardNumber'] ?? ''}'),
                pw.SizedBox(height: 32),
                pw.Divider(),
                pw.Text('Gracias por confiar en FisioApp para la gestión de tu clínica.', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Factura_FisioApp_${invoice['id']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionStreamProvider);
    final invoicesAsync = ref.watch(invoicesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<SubscriptionUiState>(subscriptionControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('Suscripción y Cuenta', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: subscriptionAsync.when(
          data: (subscription) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              children: [
                // 1. Plan Actual Card
                _buildPlanActualCard(context, ref, subscription, isDark),
                const SizedBox(height: 24),

                // 2. Planes Selector
                Text('Elige el Plan para tu Clínica', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildPlanOption(
                  context,
                  ref,
                  subscription: subscription,
                  name: 'Básico',
                  price: 29.0,
                  features: ['Hasta 2 Fisioterapeutas', 'Expedientes ilimitados', 'Reportes diarios'],
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildPlanOption(
                  context,
                  ref,
                  subscription: subscription,
                  name: 'Profesional',
                  price: 59.0,
                  features: ['Hasta 6 Fisioterapeutas', 'Calendario avanzado', 'Portal de Pacientes', 'Reportes PDF'],
                  isDark: isDark,
                  isPopular: true,
                ),
                const SizedBox(height: 12),
                _buildPlanOption(
                  context,
                  ref,
                  subscription: subscription,
                  name: 'Enterprise',
                  price: 99.0,
                  features: ['Fisioterapeutas ilimitados', 'Soporte prioritario 24/7', 'Copias de seguridad automáticas'],
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // 3. Historial de Facturas
                Text('Historial de Facturación', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                invoicesAsync.when(
                  data: (invoices) {
                    if (invoices.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No registras facturas de pago aún.')));
                    }
                    return Column(
                      children: invoices.map((inv) => _buildInvoiceTile(inv, isDark)).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error al cargar facturas: $e'),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error al cargar suscripción: $e')),
        ),
      ),
    );
  }

  // ── TARJETA PLAN ACTUAL ───────────────────────────────────────────
  Widget _buildPlanActualCard(BuildContext context, WidgetRef ref, SubscriptionModel sub, bool isDark) {
    final isTrial = sub.status == 'trialing';
    final isCancelled = sub.status == 'cancelled';
    final remainingDays = sub.trialEndsAt.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F766E), const Color(0xFF0EA5A0)]
              : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan Actual: ${sub.planName}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTrial ? 'Prueba Gratis' : (isCancelled ? 'Cancelado' : 'Activo'),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isTrial) ...[
            Text(
              'Quedan $remainingDays días de tu prueba gratuita.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ] else if (isCancelled) ...[
            Text(
              'Tu plan expira el ${DateFormat('dd/MM/yyyy').format(sub.currentPeriodEnd)}.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ] else ...[
            Text(
              'Próxima renovación: ${DateFormat('dd/MM/yyyy').format(sub.currentPeriodEnd)} por \$${sub.price.toStringAsFixed(2)} USD.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ref.read(subscriptionControllerProvider.notifier).cancelSubscription();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              child: Text('Cancelar Suscripción', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // ── OPCIÓN DE PLAN ────────────────────────────────────────────────
  Widget _buildPlanOption(
    BuildContext context,
    WidgetRef ref, {
    required SubscriptionModel subscription,
    required String name,
    required double price,
    required List<String> features,
    required bool isDark,
    bool isPopular = false,
  }) {
    final isCurrent = subscription.planName == name;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(10)),
                  child: Text('Recomendado', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$$price USD / mes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
          const SizedBox(height: 12),
          Column(
            children: features.map((f) => Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryColor, size: 14),
                const SizedBox(width: 8),
                Text(f, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
              ],
            )).toList(),
          ),
          const SizedBox(height: 16),
          if (isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text('Tu plan actual', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            )
          else
            ElevatedButton(
              onPressed: () => _showPaymentForm(context, ref, name, price),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              child: Text('Adquirir Plan', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ── HISTORIAL FACTURA TILE ────────────────────────────────────────
  Widget _buildInvoiceTile(Map<String, dynamic> invoice, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan: ${invoice['planName'] ?? ''}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${invoice['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['date'])) : ''} • ${invoice['cardNumber'] ?? ''}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text('\$${(invoice['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryColor, size: 20),
            onPressed: () => _downloadInvoicePdf(invoice),
          ),
        ],
      ),
    );
  }

  // ── BOTOM SHEET FORMULARIO TARJETA ───────────────────────────────
  void _showPaymentForm(BuildContext context, WidgetRef ref, String planName, double price) {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final holderController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pasarela de Pago Segura', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Adquiriendo Plan $planName • \$${price.toStringAsFixed(2)} USD', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número de Tarjeta (Luhn Validador)', prefixIcon: Icon(Icons.credit_card)),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: holderController,
                  decoration: const InputDecoration(labelText: 'Nombre del Titular', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: expiryController,
                        decoration: const InputDecoration(labelText: 'Vence (MM/AA)', prefixIcon: Icon(Icons.date_range_outlined)),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: cvvController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CVV', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => v == null || v.length < 3 ? 'Invalido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    Navigator.pop(context); // Cierra bottomsheet
                    
                    // Mostrar loading spinner
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) => const Center(child: CircularProgressIndicator()),
                    );

                    await ref.read(subscriptionControllerProvider.notifier).checkout(
                      planName: planName,
                      price: price,
                      cardNumber: numberController.text.trim(),
                      cardHolder: holderController.text.trim(),
                      expiryDate: expiryController.text.trim(),
                      cvv: cvvController.text.trim(),
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Cierra loading spinner
                      
                      final subState = ref.read(subscriptionControllerProvider);
                      if (subState.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Pago aprobado y Plan $planName activado exitosamente! ✓'),
                            backgroundColor: AppTheme.accentColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Confirmar Pago (\$${price.toStringAsFixed(2)})', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
