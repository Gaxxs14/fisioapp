import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_error_formatter.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../providers/appointment_provider.dart';
import '../../../admin/presentation/providers/admin_provider.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? waitingListEntryId;

  const AppointmentFormScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.waitingListEntryId,
  });

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _blockReasonController = TextEditingController();

  bool _isBlocked = false;
  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedPhysioId;
  String? _selectedPhysioName;
  String? _selectedRoomId;
  String? _selectedRoomName;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 45;
  bool _isRecurring = false;
  String _recurrencePattern = 'weekly';

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedPatientName = widget.patientName;
  }

  @override
  void dispose() {
    _blockReasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBlocked && _selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentLocale == 'es' ? 'Selecciona un paciente' : 'Select a patient', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_selectedPhysioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentLocale == 'es' ? 'Selecciona un fisioterapeuta' : 'Select a physiotherapist', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 1. Validar Ausencias
    final absences = ref.read(absencesStreamProvider).value ?? [];
    final hasAbsence = absences.any((ab) =>
        ab.userId == _selectedPhysioId &&
        ab.status == 'approved' &&
        appointmentDateTime.isAfter(ab.startDate.subtract(const Duration(minutes: 1))) &&
        appointmentDateTime.isBefore(ab.endDate.add(const Duration(days: 1))));
    
    if (hasAbsence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale == 'es' 
                ? 'El fisioterapeuta tiene una ausencia/vacaciones en este rango de fechas.' 
                : 'The physiotherapist is absent or on vacation during this date range.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 2. Validar Días de Trabajo
    final professionals = ref.read(professionalsStreamProvider).value ?? [];
    final physioUser = professionals.where((u) => u.uid == _selectedPhysioId).firstOrNull;
    if (physioUser != null && physioUser.workDays != null && physioUser.workDays!.isNotEmpty) {
      final weekdayMap = {
        DateTime.monday: 'lunes',
        DateTime.tuesday: 'martes',
        DateTime.wednesday: 'miercoles',
        DateTime.thursday: 'jueves',
        DateTime.friday: 'viernes',
        DateTime.saturday: 'sabado',
        DateTime.sunday: 'domingo',
      };
      final dayName = weekdayMap[appointmentDateTime.weekday];
      if (!physioUser.workDays!.contains(dayName)) {
        final dayLabel = dayName != null ? dayName[0].toUpperCase() + dayName.substring(1) : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale == 'es' 
                  ? 'El fisioterapeuta no trabaja los días $dayLabel.' 
                  : 'The physiotherapist does not work on $dayLabel.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }


    ref.read(appointmentControllerProvider.notifier).bookAppointment(
          patientId: _isBlocked ? null : _selectedPatientId,
          patientName: _isBlocked ? null : _selectedPatientName,
          physioId: _selectedPhysioId!,
          physioName: _selectedPhysioName!,
          roomId: _selectedRoomId,
          roomName: _selectedRoomName,
          dateTime: appointmentDateTime,
          durationMinutes: _durationMinutes,
          isBlocked: _isBlocked,
          blockReason: _isBlocked ? _blockReasonController.text : null,
          isRecurring: _isRecurring,
          recurrencePattern: _isRecurring ? _recurrencePattern : null,
        );
  }

  String get currentLocale => ref.read(localeProvider);

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final therapistsAsync = ref.watch(therapistsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final uiState = ref.watch(appointmentControllerProvider);
    final l10n = ref.watch(l10nProvider);
    final locale = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AppointmentUiState>(appointmentControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        final friendlyError = FirebaseErrorFormatter.format(next.errorMessage!, locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(appointmentControllerProvider.notifier).clearError();
      }
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.savedSuccess, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (widget.waitingListEntryId != null) {
          ref.read(appointmentControllerProvider.notifier).removePatientFromWaitingList(widget.waitingListEntryId!);
        }
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          _isBlocked ? l10n.blockApptTitle : l10n.bookApptTitle,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── TIPO DE SLOT (ChoiceChips) ─────────────────
                        _buildCardWrapper(
                          isDark: isDark,
                          child: Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(child: Text(l10n.apptTypeMedical, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
                                  selected: !_isBlocked,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _isBlocked = false);
                                  },
                                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  checkmarkColor: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: Center(child: Text(l10n.apptTypeBlock, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
                                  selected: _isBlocked,
                                  selectedColor: AppTheme.errorColor.withValues(alpha: 0.15),
                                  checkmarkColor: AppTheme.errorColor,
                                  onSelected: (selected) {
                                    if (selected) setState(() => _isBlocked = true);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── ASIGNACIONES PRINCIPALES ─────────────────────
                        _buildSectionHeader(Icons.assignment_ind_outlined, _isBlocked ? 'Detalles de Bloqueo' : 'Paciente y Terapeuta'),
                        const SizedBox(height: 12),
                        _buildCardWrapper(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_isBlocked) ...[
                                patientsAsync.when(
                                  data: (patients) {
                                    final hasSelectedPatient = patients.any((p) => p.id == _selectedPatientId);
                                    final dropdownValue = hasSelectedPatient ? _selectedPatientId : null;

                                    return DropdownButtonFormField<String>(
                                      initialValue: dropdownValue,
                                      decoration: InputDecoration(
                                        labelText: l10n.patientField,
                                        prefixIcon: const Icon(Icons.person_outline),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                      items: patients.map((p) {
                                        return DropdownMenuItem<String>(
                                          value: p.id,
                                          child: Text('${p.name} (${p.dni})', style: GoogleFonts.inter(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedPatientId = val;
                                            _selectedPatientName = patients.firstWhere((p) => p.id == val).name;
                                          });
                                        }
                                      },
                                      validator: (val) => val == null ? (locale == 'es' ? 'Selecciona un paciente' : 'Select a patient') : null,
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _blockReasonController,
                                  decoration: InputDecoration(
                                    labelText: l10n.blockReasonField,
                                    prefixIcon: const Icon(Icons.block_outlined),
                                    hintText: l10n.blockReasonHint,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (val) {
                                    if (_isBlocked && (val == null || val.trim().isEmpty)) {
                                      return l10n.blockReasonRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Dropdown Fisioterapeutas
                              therapistsAsync.when(
                                data: (therapists) {
                                  return DropdownButtonFormField<String>(
                                    initialValue: _selectedPhysioId,
                                    decoration: InputDecoration(
                                      labelText: l10n.physioField,
                                      prefixIcon: const Icon(Icons.medical_services_outlined),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    items: therapists.map((t) {
                                      return DropdownMenuItem<String>(
                                        value: t['uid'] as String,
                                        child: Text(t['name'] as String, style: GoogleFonts.inter(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedPhysioId = val;
                                          _selectedPhysioName = therapists.firstWhere((t) => t['uid'] == val)['name'] as String;
                                        });
                                      }
                                    },
                                    validator: (val) => val == null ? (locale == 'es' ? 'Selecciona un fisioterapeuta' : 'Select a therapist') : null,
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
                              ),
                              const SizedBox(height: 16),

                              // Dropdown Salas
                              roomsAsync.when(
                                data: (rooms) {
                                  return DropdownButtonFormField<String>(
                                    initialValue: _selectedRoomId,
                                    decoration: InputDecoration(
                                      labelText: '${l10n.roomField} ${l10n.optionalField}',
                                      prefixIcon: const Icon(Icons.business_outlined),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(locale == 'es' ? 'Ninguna sala asignada' : 'No office assigned', style: GoogleFonts.inter(fontSize: 13)),
                                      ),
                                      ...rooms.map((r) {
                                        return DropdownMenuItem<String>(
                                          value: r['id'] as String,
                                          child: Text(r['name'] as String, style: GoogleFonts.inter(fontSize: 13)),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedRoomId = val;
                                        _selectedRoomName = val != null
                                            ? rooms.firstWhere((r) => r['id'] == val)['name'] as String
                                            : null;
                                      });
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Text('Error: $err', style: GoogleFonts.inter()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── FECHA Y HORA ─────────────────────────────────
                        _buildSectionHeader(Icons.calendar_today_outlined, 'Fecha y Hora'),
                        const SizedBox(height: 12),
                        _buildCardWrapper(
                          isDark: isDark,
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: locale == 'es' ? 'Día' : 'Day',
                                      prefixIcon: const Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: locale == 'es' ? 'Hora' : 'Hour',
                                      prefixIcon: const Icon(Icons.access_time),
                                    ),
                                    child: Text(
                                      _selectedTime.format(context),
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── DURACIÓN (ChoiceChips) ───────────────────────
                        _buildSectionHeader(Icons.timer_outlined, l10n.durationBlockLabel),
                        const SizedBox(height: 12),
                        _buildCardWrapper(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [15, 30, 45, 60, 90, 120].map((duration) {
                                  final isSelected = _durationMinutes == duration;
                                  return ChoiceChip(
                                    label: Text('$duration min', style: GoogleFonts.inter(fontSize: 12)),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                    checkmarkColor: AppTheme.primaryColor,
                                    onSelected: (selected) {
                                      if (selected) setState(() => _durationMinutes = duration);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── RECURRENCIA ──────────────────────────────────
                        _buildSectionHeader(Icons.replay_outlined, 'Recurrencia'),
                        const SizedBox(height: 12),
                        _buildCardWrapper(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l10n.repeatApptLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text(l10n.repeatApptSub, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                                value: _isRecurring,
                                activeThumbColor: AppTheme.primaryColor,
                                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                onChanged: (val) => setState(() => _isRecurring = val),
                              ),
                              if (_isRecurring) ...[
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: Center(child: Text(l10n.repeatWeekly, style: GoogleFonts.inter(fontSize: 12))),
                                        selected: _recurrencePattern == 'weekly',
                                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                        checkmarkColor: AppTheme.primaryColor,
                                        onSelected: (selected) {
                                          if (selected) setState(() => _recurrencePattern = 'weekly');
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: Center(child: Text(l10n.repeatBiweekly, style: GoogleFonts.inter(fontSize: 12))),
                                        selected: _recurrencePattern == 'biweekly',
                                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                        checkmarkColor: AppTheme.primaryColor,
                                        onSelected: (selected) {
                                          if (selected) setState(() => _recurrencePattern = 'biweekly');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botón agendar
                        ElevatedButton(
                          onPressed: () => _submitForm(l10n),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            l10n.saveBtn,
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
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
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
