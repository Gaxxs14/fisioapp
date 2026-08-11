import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Proveedor de la configuración de idioma ('es' o 'en')
final localeProvider = NotifierProvider<LocaleNotifier, String>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<String> {
  @override
  String build() {
    _loadLocale();
    return 'es';
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale');
    if (savedLocale != null) {
      state = savedLocale;
    }
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
  }
}

// Proveedor para acceder de forma reactiva a las traducciones
final l10nProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});

class AppLocalizations {
  final String locale;
  AppLocalizations(this.locale);

  // Auth Screen Localizations
  String get loginTitle => locale == 'es' ? 'Iniciar Sesión' : 'Log In';
  String get loginSubtitle => locale == 'es' ? 'Gestión Clínica Profesional' : 'Professional Clinic Management';
  String get email => locale == 'es' ? 'Correo Electrónico' : 'Email Address';
  String get password => locale == 'es' ? 'Contraseña' : 'Password';
  String get forgotPasswordBtn => locale == 'es' ? '¿Olvidaste tu contraseña?' : 'Forgot your password?';
  String get loginBtn => locale == 'es' ? 'Iniciar Sesión' : 'Log In';
  String get biometricsBtn => locale == 'es' ? 'Acceder con Huella Digital' : 'Log in with Fingerprint';
  String get selectClinic => locale == 'es' ? 'Seleccionar Clínica' : 'Select Clinic';
  String get chooseClinicValidator => locale == 'es' ? 'Elige una clínica' : 'Choose a clinic';
  String get noClinicWarn => locale == 'es' ? 'No hay clínicas registradas. Regístrate aquí.' : 'No clinics registered. Register here.';
  String get emailValidator => locale == 'es' ? 'El correo es obligatorio' : 'Email is required';
  String get emailInvalidValidator => locale == 'es' ? 'Introduce un correo válido' : 'Enter a valid email';
  String get passwordValidator => locale == 'es' ? 'La contraseña es obligatoria' : 'Password is required';
  String get passwordLengthValidator => locale == 'es' ? 'Mínimo 6 caracteres' : 'Minimum 6 characters';
  String get registerHeader => locale == 'es' ? 'Registrar tu Clínica' : 'Register your Clinic';
  String get registerBannerTitle => locale == 'es' ? 'Prueba Gratis de 14 Días' : '14-Day Free Trial';
  String get registerBannerDesc => locale == 'es' ? 'Acceso ilimitado a todas las funcionalidades del plan Profesional. Sin ingresar tarjeta.' : 'Unlimited access to all Professional plan features. No credit card required.';
  String get clinicNameLabel => locale == 'es' ? 'Nombre de la Clínica' : 'Clinic Name';
  String get clinicNameValidator => locale == 'es' ? 'Introduce el nombre de la clínica' : 'Enter clinic name';
  String get adminNameLabel => locale == 'es' ? 'Nombre Completo del Administrador' : 'Administrator Full Name';
  String get adminNameValidator => locale == 'es' ? 'Introduce tu nombre completo' : 'Enter your full name';
  String get registerEmailLabel => locale == 'es' ? 'Correo de Registro' : 'Registration Email';
  String get securityHeader => locale == 'es' ? 'Seguridad de la Cuenta' : 'Account Security';
  String get securitySub => locale == 'es' ? 'Se utilizará para restablecer tu contraseña en caso de olvido.' : 'Used to reset your password if forgotten.';
  String get securityQuestionLabel => locale == 'es' ? 'Pregunta de Seguridad' : 'Security Question';
  String get securityQuestionValidator => locale == 'es' ? 'Selecciona una pregunta' : 'Select a question';
  String get securityAnswerLabel => locale == 'es' ? 'Respuesta de Seguridad' : 'Security Answer';
  String get securityAnswerValidator => locale == 'es' ? 'Introduce tu respuesta de seguridad' : 'Enter your security answer';
  String get registerBtn => locale == 'es' ? 'Comenzar Prueba Gratis' : 'Start Free Trial';
  String get hasAccount => locale == 'es' ? '¿Ya tienes una cuenta?' : 'Already have an account?';
  String get backToLogin => locale == 'es' ? 'Inicia sesión' : 'Log in';

  // Dashboard strings
  String get homeTitle => locale == 'es' ? 'FisioApp Dashboard' : 'FisioApp Dashboard';
  String get welcomeMsg => locale == 'es' ? '¡Hola' : 'Hello';
  String get quickActions => locale == 'es' ? 'Acciones Rápidas' : 'Quick Actions';
  String get patientsMenu => locale == 'es' ? 'Pacientes' : 'Patients';
  String get calendarMenu => locale == 'es' ? 'Agenda' : 'Calendar';
  String get historyMenu => locale == 'es' ? 'Historial Clínico' : 'Clinical History';
  String get billingMenu => locale == 'es' ? 'Cobranza' : 'Billing';
  String get logOutTooltip => locale == 'es' ? 'Cerrar Sesión' : 'Log Out';
  String get profileTooltip => locale == 'es' ? 'Ver Perfil' : 'View Profile';

  // Profile Screen
  String get profileTitle => locale == 'es' ? 'Perfil de Usuario' : 'User Profile';
  String get nameLabel => locale == 'es' ? 'Nombre' : 'Name';
  String get specialtyLabel => locale == 'es' ? 'Especialidad' : 'Specialty';
  String get scheduleLabel => locale == 'es' ? 'Horario de Trabajo' : 'Work Schedule';
  String get saveProfileBtn => locale == 'es' ? 'Guardar Perfil' : 'Save Profile';
  String get biometricEnable => locale == 'es' ? 'Habilitar Acceso con Huella Digital' : 'Enable Fingerprint Access';
  String get biometricDisabled => locale == 'es' ? 'Tu dispositivo no soporta biometría.' : 'Your device does not support biometrics.';
  String get languageLabel => locale == 'es' ? 'Idioma / Language' : 'Language / Idioma';
  String get spanish => locale == 'es' ? 'Español' : 'Spanish';
  String get english => locale == 'es' ? 'Inglés' : 'English';
  String get successSave => locale == 'es' ? 'Perfil guardado con éxito' : 'Profile saved successfully';

  // Calendar and appointments strings
  String get calendarTitle => locale == 'es' ? 'Agenda y Citas' : 'Calendar & Appointments';
  String get apptDetails => locale == 'es' ? 'Detalle de la Cita' : 'Appointment Details';
  String get blockDetails => locale == 'es' ? 'Horario Bloqueado' : 'Time Block';
  String get patientField => locale == 'es' ? 'Paciente' : 'Patient';
  String get physioField => locale == 'es' ? 'Fisioterapeuta' : 'Physiotherapist';
  String get roomField => locale == 'es' ? 'Consultorio' : 'Room/Office';
  String get timeField => locale == 'es' ? 'Horario' : 'Time';
  String get statusField => locale == 'es' ? 'Estado actual' : 'Current Status';
  String get blockReasonField => locale == 'es' ? 'Motivo del bloqueo' : 'Block Reason';
  String get changeStatusLabel => locale == 'es' ? 'Cambiar Estado:' : 'Change Status:';
  String get reminderBtn => locale == 'es' ? 'Recordatorio' : 'Reminder';
  String get deleteBtn => locale == 'es' ? 'Eliminar' : 'Delete';
  String get reminderSent => locale == 'es' ? 'Recordatorio enviado por WhatsApp al paciente.' : 'Reminder sent to patient via WhatsApp.';
  String get filterPhysio => locale == 'es' ? 'Profesional' : 'Therapist';
  String get filterRoom => locale == 'es' ? 'Consultorio' : 'Room';
  String get filterAll => locale == 'es' ? 'Todos' : 'All';
  String get noAppts => locale == 'es' ? 'No hay citas programadas para este día.' : 'No appointments scheduled for this day.';
  String get durationText => locale == 'es' ? 'minutos' : 'minutes';
  String get waitlistTitle => locale == 'es' ? 'Lista de Espera' : 'Waiting List';
  String get bookApptTitle => locale == 'es' ? 'Agendar Nueva Cita' : 'Book New Appointment';
  String get blockApptTitle => locale == 'es' ? 'Bloquear Horario' : 'Block Time Schedule';
  String get apptTypeMedical => locale == 'es' ? 'Cita Médica' : 'Medical Appointment';
  String get apptTypeBlock => locale == 'es' ? 'Bloquear Horario' : 'Block Schedule';
  String get blockReasonHint => locale == 'es' ? 'Vacaciones, reunión de equipo, mantenimiento...' : 'Vacation, team meeting, maintenance...';
  String get blockReasonRequired => locale == 'es' ? 'Por favor ingresa el motivo del bloqueo' : 'Please enter block reason';
  String get optionalField => locale == 'es' ? '(Opcional)' : '(Optional)';
  String get durationBlockLabel => locale == 'es' ? 'Duración del bloque:' : 'Block duration:';
  String get repeatApptLabel => locale == 'es' ? 'Repetir cita (Recurrente)' : 'Repeat appointment (Recurring)';
  String get repeatApptSub => locale == 'es' ? 'Crea automáticamente bloques en las próximas semanas' : 'Automatically creates blocks for future weeks';
  String get repeatWeekly => locale == 'es' ? 'Cada Semana' : 'Every Week';
  String get repeatBiweekly => locale == 'es' ? 'Cada 2 Semanas' : 'Every 2 Weeks';
  String get saveBtn => locale == 'es' ? 'Confirmar y Guardar' : 'Confirm & Save';
  String get savedSuccess => locale == 'es' ? 'Guardado exitosamente.' : 'Saved successfully.';

  // Waiting list strings
  String get waitlistEmpty => locale == 'es' ? 'La lista de espera está vacía.' : 'The waiting list is empty.';
  String get searchPatient => locale == 'es' ? 'Buscar paciente...' : 'Search patient...';
  String get prefPhysio => locale == 'es' ? 'Preferencia:' : 'Preference:';
  String get prefRoom => locale == 'es' ? 'Sala:' : 'Room:';
  String get anyPhysio => locale == 'es' ? 'Cualquier Fisioterapeuta' : 'Any Physiotherapist';
  String get anyRoom => locale == 'es' ? 'Cualquier Consultorio' : 'Any Room';
  String get addWaitlistTitle => locale == 'es' ? 'Agregar a Lista de Espera' : 'Add to Waiting List';
  String get notesField => locale == 'es' ? 'Notas / Urgencia / Observaciones' : 'Notes / Urgency / Observations';
  String get notesHint => locale == 'es' ? 'Ej: Prefiere horarios por la tarde' : 'E.g., Prefers afternoon slots';
  String get addBtn => locale == 'es' ? 'Agregar a Lista' : 'Add to List';

  // Sessions and SOAP notes strings
  String get sessionsTab => locale == 'es' ? 'Sesiones' : 'Sessions';
  String get newSessionBtn => locale == 'es' ? 'Nueva Sesión' : 'New Session';
  String get noSessions => locale == 'es' ? 'No hay sesiones clínicas registradas para este paciente.' : 'No clinical sessions registered for this patient.';
  String get sessionDate => locale == 'es' ? 'Fecha de la sesión' : 'Session Date';
  String get subjectiveLabel => locale == 'es' ? 'S - Subjetivo (Sintomatología, dolor, reporte del paciente)' : 'S - Subjective (Symptomatology, pain, patient report)';
  String get objectiveLabel => locale == 'es' ? 'O - Objetivo (Rangos, palpación, tests físicos, postura)' : 'O - Objective (Ranges, palpation, physical tests, posture)';
  String get assessmentLabel => locale == 'es' ? 'A - Evaluación (Diagnóstico fisioterapéutico y progreso)' : 'A - Assessment (Physiotherapeutic diagnosis and progress)';
  String get planLabel => locale == 'es' ? 'P - Plan (Tratamiento, ejercicios a casa, pauta futura)' : 'P - Plan (Treatment, home exercises, future schedule)';
  String get painLevelPreLabel => locale == 'es' ? 'Nivel de dolor Inicial (Pre-sesión):' : 'Initial pain level (Pre-session):';
  String get painLevelPostLabel => locale == 'es' ? 'Nivel de dolor Final (Post-sesión):' : 'Final pain level (Post-session):';
  String get durationRealLabel => locale == 'es' ? 'Duración real de la sesión (minutos):' : 'Real session duration (minutes):';
  String get techniquesAppliedLabel => locale == 'es' ? 'Técnicas Aplicadas' : 'Applied Techniques';
  String get internalNotesLabel => locale == 'es' ? 'Observaciones Internas (Privadas)' : 'Internal Observations (Private)';
  String get photoEvolutionLabel => locale == 'es' ? 'Fotos de evolución clínica' : 'Clinical evolution photos';
  String get addPhotoBtn => locale == 'es' ? 'Capturar Foto' : 'Capture Photo';
  String get saveAsTemplateLabel => locale == 'es' ? 'Guardar SOAP como plantilla de patología' : 'Save SOAP as pathology template';
  String get templateNameLabel => locale == 'es' ? 'Nombre de la patología' : 'Pathology name';
  String get selectTemplateLabel => locale == 'es' ? 'Cargar plantilla de patología' : 'Load pathology template';
  String get defaultTemplateChoice => locale == 'es' ? 'Ninguna (Escribir en blanco)' : 'None (Write from blank)';
  String get startSessionAction => locale == 'es' ? 'Iniciar Sesión Clínica' : 'Start Clinical Session';
  String get viewSessionTitle => locale == 'es' ? 'Detalle de Sesión' : 'Session Detail';
  String get sessionSavedSuccess => locale == 'es' ? 'Sesión clínica guardada con éxito.' : 'Clinical session saved successfully.';
  String get sessionTitle => locale == 'es' ? 'Sesión Clínica' : 'Clinical Session';
}

