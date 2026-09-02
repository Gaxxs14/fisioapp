import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class SupplyItem {
  final String id;
  final String name;
  final String category; // 'Punción', 'Vendaje', 'Electroterapia', 'Ortopedia'
  int quantity;
  final String unit; // 'cajas', 'rollos', 'unidades', 'botes'
  final int minThreshold;

  SupplyItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.minThreshold = 5,
  });

  bool get isLowStock => quantity <= minThreshold;
}

class ClinicalSuppliesScreen extends StatefulWidget {
  const ClinicalSuppliesScreen({super.key});

  @override
  State<ClinicalSuppliesScreen> createState() => _ClinicalSuppliesScreenState();
}

class _ClinicalSuppliesScreenState extends State<ClinicalSuppliesScreen> {
  String _selectedCategory = 'Todos';
  final List<SupplyItem> _items = [
    SupplyItem(id: '1', name: 'Agujas Punción Seca 0.25 x 25mm', category: 'Punción', quantity: 12, unit: 'cajas', minThreshold: 3),
    SupplyItem(id: '2', name: 'Agujas Punción Seca 0.30 x 40mm', category: 'Punción', quantity: 2, unit: 'cajas', minThreshold: 3),
    SupplyItem(id: '3', name: 'Cinta Kinesiotape (Azul / Negro)', category: 'Vendaje', quantity: 8, unit: 'rollos', minThreshold: 4),
    SupplyItem(id: '4', name: 'Electrodos Adhesivos 5x5cm', category: 'Electroterapia', quantity: 4, unit: 'paquetes', minThreshold: 5),
    SupplyItem(id: '5', name: 'Gel Conductor Ultrasonido 5L', category: 'Electroterapia', quantity: 1, unit: 'bidón', minThreshold: 1),
    SupplyItem(id: '6', name: 'Crema de Masaje Miofascial 1kg', category: 'Terapia Manual', quantity: 3, unit: 'botes', minThreshold: 2),
    SupplyItem(id: '7', name: 'Bandas Elásticas Resistentes (Loop)', category: 'Ortopedia', quantity: 15, unit: 'unidades', minThreshold: 5),
    SupplyItem(id: '8', name: 'Pelotas Lacrosse Miofascial', category: 'Ortopedia', quantity: 6, unit: 'unidades', minThreshold: 3),
  ];

  List<SupplyItem> get _filtered {
    if (_selectedCategory == 'Todos') return _items;
    return _items.where((i) => i.category == _selectedCategory).toList();
  }

  void _adjustQty(SupplyItem item, int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      final newQty = item.quantity + delta;
      if (newQty >= 0) {
        item.quantity = newQty;
      }
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final unitCtrl = TextEditingController(text: 'unidades');
    String cat = 'Punción';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nuevo Insumo Clínico', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Insumo / Producto'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unidad (rollos, cajas)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: ['Punción', 'Vendaje', 'Electroterapia', 'Terapia Manual', 'Ortopedia']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => cat = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _items.add(
                      SupplyItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        category: cat,
                        quantity: int.tryParse(qtyCtrl.text) ?? 1,
                        unit: unitCtrl.text.trim(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar Insumo', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;
    final lowStockCount = _items.where((i) => i.isLowStock).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Insumos y Stock Clínico', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0D2137) : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Agregar Insumo',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de alerta de stock bajo
          if (lowStockCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.amberAlert.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.amberAlert.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.amberAlert, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hay $lowStockCount insumos con stock por debajo del mínimo.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Categorías
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Todos', 'Punción', 'Vendaje', 'Electroterapia', 'Terapia Manual', 'Ortopedia'].map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat, style: GoogleFonts.inter(fontSize: 12)),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista de Insumos
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isLowStock
                          ? AppTheme.amberAlert.withValues(alpha: 0.5)
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.isLowStock
                              ? AppTheme.amberAlert.withValues(alpha: isDark ? 0.2 : 0.1)
                              : AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isLowStock ? Icons.inventory_2_outlined : Icons.check_box_outlined,
                          color: item.isLowStock ? AppTheme.amberAlert : AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${item.category} • ',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade500),
                                ),
                                if (item.isLowStock)
                                  Text(
                                    '¡Stock Crítico!',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.amberAlert,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22),
                            color: Colors.grey.shade500,
                            onPressed: () => _adjustQty(item, -1),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22),
                            color: AppTheme.primaryColor,
                            onPressed: () => _adjustQty(item, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 30 * index));
              },
            ),
          ),
        ],
      ),
    );
  }
}
