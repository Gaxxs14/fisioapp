import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateClinicStatus(String clinicId, bool isActive, String paymentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('clinics').doc(clinicId).update({
        'isActive': isActive,
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive ? 'Licencia de clínica activada con éxito' : 'Licencia de clínica suspendida',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: isActive ? const Color(0xFF0F766E) : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Super Administrador',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0EA5A0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('clinics').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar clínicas: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            
            // Filter clinics by search query
            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] as String? ?? '').toLowerCase();
              return name.contains(_searchQuery.toLowerCase());
            }).toList();

            // Calculate stats
            int total = docs.length;
            int active = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isActive'] == true;
            }).length;
            int pending = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['paymentStatus'] == 'pending';
            }).length;

            return Column(
              children: [
                // Search bar and statistics cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Stats metrics row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Registradas', total.toString(), Icons.business_rounded, Colors.blue, isDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Pendientes', pending.toString(), Icons.hourglass_empty_rounded, Colors.orange, isDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Activas', active.toString(), Icons.check_circle_rounded, Colors.green, isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Input field
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar clínica...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                // Clinic list builder
                Expanded(
                  child: filteredDocs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'No hay clínicas registradas aún' : 'No se encontraron resultados',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? 'Sin nombre';
                            final paymentMethod = data['paymentMethod'] ?? 'N/A';
                            final reference = data['paymentReference'] ?? 'N/A';
                            final paymentStatus = data['paymentStatus'] ?? 'pending';
                            final plan = data['plan'] ?? 'Platino';
                            final billingCycle = data['billingCycle'] ?? 'Mensual';
                            final isActive = data['isActive'] ?? false;
                            final ownerName = data['ownerName'] ?? 'Propietario';
                            final ownerEmail = data['ownerEmail'] ?? '';
                            final ownerPhone = data['ownerPhone'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: ExpansionTile(
                                  backgroundColor: Colors.transparent,
                                  collapsedBackgroundColor: Colors.transparent,
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isActive ? const Color(0xFF0F766E) : Colors.orange.shade800,
                                    child: Text(
                                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.grey.shade900,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isActive ? 'ACTIVO' : 'SUSPENDIDO',
                                          style: GoogleFonts.inter(
                                            color: isActive ? Colors.green.shade600 : Colors.red.shade600,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$plan ($billingCycle)',
                                          style: GoogleFonts.inter(
                                            color: Colors.blue.shade600,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: CrossFadeState(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Divider(),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Propietario', ownerName),
                                            _buildDetailRow('Email', ownerEmail),
                                            _buildDetailRow('Teléfono', ownerPhone),
                                            _buildDetailRow('Método de pago', paymentMethod),
                                            _buildDetailRow('Referencia', reference),
                                            _buildDetailRow('Estado pago', paymentStatus.toUpperCase(), color: paymentStatus == 'approved' ? Colors.green : Colors.orange),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (paymentStatus == 'pending')
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green.shade700,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    ),
                                                    icon: const Icon(Icons.check_rounded, size: 18),
                                                    label: Text('Aprobar Pago', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                                    onPressed: () => _updateClinicStatus(doc.id, true, 'approved'),
                                                  ),
                                                if (paymentStatus == 'approved' && isActive)
                                                  OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.red.shade700,
                                                      side: BorderSide(color: Colors.red.shade700),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    ),
                                                    icon: const Icon(Icons.block_rounded, size: 18),
                                                    label: Text('Suspender', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                                    onPressed: () => _updateClinicStatus(doc.id, false, 'suspended'),
                                                  ),
                                                if (!isActive && paymentStatus != 'pending')
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF0F766E),
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    ),
                                                    icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                                                    label: Text('Activar Licencia', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                                    onPressed: () => _updateClinicStatus(doc.id, true, 'approved'),
                                                  ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class CrossFadeState extends StatelessWidget {
  final Widget child;
  const CrossFadeState({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
