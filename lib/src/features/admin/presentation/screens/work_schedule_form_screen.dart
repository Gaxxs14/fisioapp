import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/admin_provider.dart';

class WorkScheduleFormScreen extends ConsumerStatefulWidget {
  final AppUser staffUser;

  const WorkScheduleFormScreen({
    super.key,
    required this.staffUser,
  });

  @override
  ConsumerState<WorkScheduleFormScreen> createState() => _WorkScheduleFormScreenState();
}

class _WorkScheduleFormScreenState extends ConsumerState<WorkScheduleFormScreen> {
  final List<String> _weekdays = [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo'
  ];

  final Map<String, String> _weekdayLabels = {
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
    'domingo': 'Domingo',
  };

  late List<String> _selectedDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _selectedDays = List<String>.from(widget.staffUser.workDays ?? []);
    
    // Parse existing work hours or set default (08:00 - 17:00)
    _startTime = _parseTime(widget.staffUser.workHoursStart, const TimeOfDay(hour: 8, minute: 0));
    _endTime = _parseTime(widget.staffUser.workHoursEnd, const TimeOfDay(hour: 17, minute: 0));
  }

  TimeOfDay _parseTime(String? timeStr, TimeOfDay defaultTime) {
    if (timeStr == null || timeStr.isEmpty) return defaultTime;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return defaultTime;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _save() async {
    await ref.read(adminControllerProvider.notifier).updateStaffWorkSchedule(
      uid: widget.staffUser.uid,
      workDays: _selectedDays,
      workHoursStart: _formatTime(_startTime),
      workHoursEnd: _formatTime(_endTime),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Horario actualizado con éxito', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uiState = ref.watch(adminControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'Horario de ${widget.staffUser.name}',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: uiState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Días Laborales',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: _weekdays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _weekdayLabels[day]!,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            value: isSelected,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Horas de Trabajo',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartTime,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Entrada',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _startTime.format(context),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndTime,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Salida',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(
                                  _endTime.format(context),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _save,
                      child: Text(
                        'Guardar Horario',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
