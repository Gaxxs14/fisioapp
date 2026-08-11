import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/billing_provider.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../domain/entities/pack_model.dart';
import '../../domain/entities/transaction_model.dart';

class BillingDashboardScreen extends ConsumerStatefulWidget {
  const BillingDashboardScreen({super.key});

  @override
  ConsumerState<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends ConsumerState<BillingDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Módulo de Cobranza',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Cobros Diario', icon: Icon(Icons.attach_money_rounded, size: 20)),
            Tab(text: 'Catálogo', icon: Icon(Icons.menu_book_rounded, size: 20)),
            Tab(text: 'Vender Bonos', icon: Icon(Icons.card_membership_rounded, size: 20)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDailyTab(context, isDark),
            _buildCatalogTab(context, isDark),
            _buildBonoSalesTab(context, isDark),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: COBROS DIARIO ───────────────────────────────────────────
  Widget _buildDailyTab(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final transactionsAsync = ref.watch(transactionsStreamProvider(todayDate));

    return transactionsAsync.when(
      data: (transactions) {
        double cashTotal = 0;
        double cardTotal = 0;
        double transferTotal = 0;
        double pendingTotal = 0;

        for (var tx in transactions) {
          if (tx.paymentMethod == 'cash') cashTotal += tx.amount;
          if (tx.paymentMethod == 'card') cardTotal += tx.amount;
          if (tx.paymentMethod == 'transfer') transferTotal += tx.amount;
          if (tx.paymentMethod == 'pending') pendingTotal += tx.amount;
        }

        final grandTotal = cashTotal + cardTotal + transferTotal;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            // KPI Cards de Sumario Diario
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Efectivo',
                    amount: cashTotal,
                    color: Colors.green,
                    icon: Icons.money_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Tarjetas',
                    amount: cardTotal,
                    color: Colors.blue,
                    icon: Icons.credit_card_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Transferencias',
                    amount: transferTotal,
                    color: Colors.purple,
                    icon: Icons.account_balance_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Pendiente',
                    amount: pendingTotal,
                    color: Colors.orange,
                    icon: Icons.hourglass_bottom_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card Gran Total Cobrado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF14B8A6)],
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
                children: [
                  Text(
                    'TOTAL RECAUDADO HOY',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${grandTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(
                      'Realizar Cierre de Caja',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.push('/billing/closing', extra: grandTotal),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 28),

            // Listado de transacciones
            Text(
              'Transacciones del Día',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              _buildEmptyState(
                icon: Icons.receipt_long_rounded,
                message: 'Aún no se registran cobros en el día de hoy.',
              )
            else
              ...transactions.map((tx) => _buildTransactionCard(tx, isDark)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar transacciones: $e', style: GoogleFonts.inter())),
    );
  }

  // ── TAB 2: CATALOGO DE SERVICIOS ────────────────────────────────────
  Widget _buildCatalogTab(BuildContext context, bool isDark) {
    final servicesAsync = ref.watch(servicesStreamProvider);

    return servicesAsync.when(
      data: (services) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryColor,
            label: Text('Agregar Servicio', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddServiceBottomSheet(context),
          ),
          body: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: services.length,
            itemBuilder: (context, idx) {
              final service = services[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(int.parse(service.colorHex.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${service.durationMinutes} min',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${service.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (idx * 50).ms);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar catálogo: $e')),
    );
  }

  // ── TAB 3: VENTA DE BONOS ───────────────────────────────────────────
  Widget _buildBonoSalesTab(BuildContext context, bool isDark) {
    final packsAsync = ref.watch(packsStreamProvider);

    return packsAsync.when(
      data: (packs) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryColor,
            label: Text('Agregar Bono', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add_moderator_rounded),
            onPressed: () => _showAddPackBottomSheet(context),
          ),
          body: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: packs.length,
            itemBuilder: (context, idx) {
              final pack = packs[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pack.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${pack.totalSessions} Sesiones',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Validez: ${pack.expirationMonths} meses',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        Text(
                          '\$${pack.price.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: Text('Vender a Paciente', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _sellBonoDialog(context, pack),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (idx * 50).ms);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar paquetes: $e')),
    );
  }

  // ── WIDGETS AUXILIARES ─────────────────────────────────────────────
  Widget _buildKpiCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, bool isDark) {
    IconData icon = Icons.money_rounded;
    Color iconColor = Colors.green;

    if (tx.paymentMethod == 'card') {
      icon = Icons.credit_card_rounded;
      iconColor = Colors.blue;
    } else if (tx.paymentMethod == 'transfer') {
      icon = Icons.account_balance_rounded;
      iconColor = Colors.purple;
    } else if (tx.paymentMethod == 'pending') {
      icon = Icons.hourglass_bottom_rounded;
      iconColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.concept,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.patientName,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '\$${tx.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(icon, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }

  // ── DIÁLOGOS Y BOTTOMSHEETS ────────────────────────────────────────
  void _showAddServiceBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '45');
    final priceController = TextEditingController();
    String selectedColor = '#0F766E';

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
                Text('Agregar Nuevo Servicio', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre del Servicio'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Duración (min)'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio (\$)'),
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await ref.read(billingControllerProvider.notifier).addService(
                      name: nameController.text.trim(),
                      durationMinutes: int.parse(durationController.text),
                      price: double.parse(priceController.text),
                      colorHex: selectedColor,
                    );
                    if (context.mounted) context.pop();
                  },
                  child: Text('Guardar Servicio', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPackBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final sessionsController = TextEditingController(text: '10');
    final priceController = TextEditingController();
    final expirationController = TextEditingController(text: '12');

    final servicesAsync = ref.watch(servicesStreamProvider);
    String? selectedServiceId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Agregar Nuevo Paquete/Bono', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre del Bono (ej: Bono 10 de Fisio)'),
                      validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    servicesAsync.when(
                      data: (services) {
                        if (services.isNotEmpty && selectedServiceId == null) {
                          selectedServiceId = services.first.id;
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: selectedServiceId,
                          decoration: const InputDecoration(labelText: 'Servicio Vinculado'),
                          items: services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (val) => setModalState(() => selectedServiceId = val),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Error al cargar servicios: $e'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: sessionsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Cant. Sesiones'),
                            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Precio (\$)'),
                            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expirationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Meses de Vencimiento'),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate() || selectedServiceId == null) return;
                        await ref.read(billingControllerProvider.notifier).addPack(
                          name: nameController.text.trim(),
                          serviceId: selectedServiceId!,
                          totalSessions: int.parse(sessionsController.text),
                          price: double.parse(priceController.text),
                          expirationMonths: int.parse(expirationController.text),
                        );
                        if (context.mounted) context.pop();
                      },
                      child: Text('Guardar Paquete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sellBonoDialog(BuildContext context, PackModel pack) {
    String? selectedPatientId;
    String? selectedPatientName;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Vender Bono', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Consumer(
            builder: (context, ref, child) {
              final patientsAsync = ref.watch(patientsStreamProvider);
              return patientsAsync.when(
                data: (patients) {
                  if (patients.isEmpty) {
                    return Text(
                      'No hay pacientes registrados en esta clínica para vender el bono.',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Selecciona el paciente al que deseas asignar el paquete "${pack.name}":',
                        style: GoogleFonts.inter(fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Paciente',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: patients.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (DNI: ${p.dni})', style: GoogleFonts.inter(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          selectedPatientId = val;
                          final match = patients.firstWhere((element) => element.id == val);
                          selectedPatientName = match.name;
                        },
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => Text('Error al cargar pacientes: $e', style: GoogleFonts.inter(fontSize: 12)),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancelar', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPatientId == null || selectedPatientName == null) return;

                await ref.read(billingControllerProvider.notifier).sellBonoToPatient(
                  patientId: selectedPatientId!,
                  patientName: selectedPatientName!,
                  pack: pack,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bono vendido a $selectedPatientName con éxito.', style: GoogleFonts.inter()),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              },
              child: Text('Confirmar Venta', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
