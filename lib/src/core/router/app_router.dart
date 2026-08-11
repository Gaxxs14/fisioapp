import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/patients/presentation/screens/patient_register_screen.dart';
import '../../features/patients/presentation/screens/patient_detail_screen.dart';
import '../../features/patients/presentation/screens/evaluation_form_screen.dart';
import '../../features/patients/presentation/screens/pdf_preview_screen.dart';
import '../../features/appointments/presentation/screens/calendar_dashboard_screen.dart';
import '../../features/appointments/presentation/screens/appointment_form_screen.dart';
import '../../features/appointments/presentation/screens/waiting_list_screen.dart';
import '../../features/sessions/presentation/screens/session_form_screen.dart';
import '../../features/sessions/presentation/screens/soap_template_manager_screen.dart';
import '../../features/billing/presentation/screens/billing_dashboard_screen.dart';
import '../../features/billing/presentation/screens/payment_form_screen.dart';
import '../../features/billing/presentation/screens/cash_closing_screen.dart';
import '../../features/reports/presentation/screens/reports_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/professional_form_screen.dart';
import '../../features/admin/presentation/screens/work_schedule_form_screen.dart';
import '../../features/patients/presentation/screens/patient_portal_dashboard.dart';
import '../../features/billing/presentation/screens/subscription_dashboard_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/admin/presentation/screens/super_admin_dashboard_screen.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
    ref.listen(localAuthSuccessProvider, (previous, next) => notifyListeners());
  }
}

final routerRefreshProvider = Provider((ref) => RouterRefreshNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.read(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/patients',
        builder: (context, state) => const PatientListScreen(),
      ),
      GoRoute(
        path: '/patients/register',
        builder: (context, state) => const PatientRegisterScreen(),
      ),
      GoRoute(
        path: '/patients/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PatientDetailScreen(patientId: id);
        },
      ),
      GoRoute(
        path: '/patients/evaluation/:id/:isReevaluation',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final isRe = state.pathParameters['isReevaluation'] == 'true';
          return EvaluationFormScreen(patientId: id, isReevaluation: isRe);
        },
      ),
      GoRoute(
        path: '/patients/pdf/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PdfPreviewScreen(patientId: id);
        },
      ),
      GoRoute(
        path: '/appointments',
        builder: (context, state) => const CalendarDashboardScreen(),
      ),
      GoRoute(
        path: '/appointments/book',
        builder: (context, state) {
          final patientId = state.uri.queryParameters['patientId'];
          final patientName = state.uri.queryParameters['patientName'];
          final waitingListEntryId = state.uri.queryParameters['waitingListEntryId'];
          return AppointmentFormScreen(
            patientId: patientId,
            patientName: patientName,
            waitingListEntryId: waitingListEntryId,
          );
        },
      ),
      GoRoute(
        path: '/appointments/waiting-list',
        builder: (context, state) => const WaitingListScreen(),
      ),
      GoRoute(
        path: '/patients/detail/:id/session/new',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final appointmentId = state.uri.queryParameters['appointmentId'];
          return SessionFormScreen(patientId: id, appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/patients/detail/:id/session/edit/:sessionId',
        builder: (context, state) {
          final patientId = state.pathParameters['id']!;
          final sessionId = state.pathParameters['sessionId']!;
          return SessionFormScreen(patientId: patientId, sessionId: sessionId);
        },
      ),
      // ── FASE 12: Gestión de plantillas SOAP ──────────────────────
      GoRoute(
        path: '/sessions/templates',
        builder: (context, state) => const SoapTemplateManagerScreen(),
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) => const BillingDashboardScreen(),
      ),
      GoRoute(
        path: '/billing/pay',
        builder: (context, state) {
          final patientId = state.uri.queryParameters['patientId'] ?? '';
          final patientName = state.uri.queryParameters['patientName'] ?? '';
          final amountStr = state.uri.queryParameters['amount'] ?? '40.0';
          final amount = double.tryParse(amountStr) ?? 40.0;
          return PaymentFormScreen(
            patientId: patientId,
            patientName: patientName,
            defaultAmount: amount,
          );
        },
      ),
      GoRoute(
        path: '/billing/closing',
        builder: (context, state) {
          final expected = state.extra as double? ?? 0.0;
          return CashClosingScreen(expectedAmount: expected);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/staff/schedule',
        builder: (context, state) {
          final user = state.extra as AppUser;
          return WorkScheduleFormScreen(staffUser: user);
        },
      ),
      GoRoute(
        path: '/admin/staff/new',
        builder: (context, state) => const ProfessionalFormScreen(),
      ),
      // ── FASE 8: Portal del Paciente ───────────────────────────────
      GoRoute(
        path: '/patient/portal',
        builder: (context, state) => const PatientPortalDashboard(),
      ),
      // ── FASE 9: Suscripción SaaS ──────────────────────────────────
      GoRoute(
        path: '/clinic/subscription',
        builder: (context, state) => const SubscriptionDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
    ],
    redirect: (context, state) {
      // 1. Obtener el estado actual del usuario
      final user = ref.read(authStateProvider).value;
      final localAuth = ref.read(localAuthSuccessProvider);

      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isRecovering = state.matchedLocation == '/forgot-password';
      // El portal del paciente no usa Firebase Auth; se autentica por Firestore
      final isPatientPortal = state.matchedLocation.startsWith('/patient/');

      // 2. Si no ha iniciado sesión
      if (user == null) {
        // Permitir quedarse en login, registro, recuperación o portal de paciente
        if (isLoggingIn || isRegistering || isRecovering || isPatientPortal) return null;
        return '/login';
      }

      // Validar si requiere autenticación local (huella digital o password)
      if (!localAuth) {
        if (isLoggingIn || isPatientPortal) return null;
        return '/login';
      }

      // 3. Si tiene sesión activa, verificar si la contraseña está vencida (30 días)
      if (user.isPasswordExpired) {
        if (state.matchedLocation == '/change-password') return null;
        return '/change-password';
      }

      // 4. Si tiene sesión y contraseña al día, y está en páginas públicas, ir al Home/SuperAdmin
      if (isLoggingIn || isRegistering || isRecovering) {
        if (user.role == UserRole.superadmin) {
          return '/super-admin';
        }
        return '/home';
      }

      // 5. Redireccionar según el rol superadmin
      if (user.role == UserRole.superadmin) {
        if (state.matchedLocation == '/super-admin' || state.matchedLocation == '/change-password') return null;
        return '/super-admin';
      }

      if (state.matchedLocation == '/super-admin' && user.role != UserRole.superadmin) {
        return '/home';
      }

      // No redirigir en las demás rutas protegidas
      return null;
    },
  );
});
