import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorFormatter {
  static String format(dynamic error, String locale) {
    String code = '';
    String defaultMessage = '';

    if (error is FirebaseAuthException) {
      code = error.code;
      defaultMessage = error.message ?? error.toString();
    } else if (error is FirebaseException) {
      code = error.code;
      defaultMessage = error.message ?? error.toString();
    } else {
      final errString = error.toString().toLowerCase();
      if (errString.contains('invalid-credential') || 
          errString.contains('wrong-password') || 
          errString.contains('user-not-found')) {
        code = 'invalid-credential';
      } else if (errString.contains('email-already-in-use')) {
        code = 'email-already-in-use';
      } else if (errString.contains('network-request-failed')) {
        code = 'network-request-failed';
      } else if (errString.contains('permission-denied')) {
        code = 'permission-denied';
      } else {
        return error.toString().replaceAll('Exception: ', '');
      }
    }

    if (locale == 'es') {
      switch (code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'El correo electrónico o la contraseña ingresados no coinciden con nuestros registros. Por favor, verifica tus datos.';
        case 'email-already-in-use':
          return 'Este correo electrónico ya está registrado en otra cuenta. Intenta iniciar sesión o usa otro correo.';
        case 'invalid-email':
          return 'El formato del correo electrónico no es válido. Verifica que esté escrito correctamente.';
        case 'weak-password':
          return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
        case 'operation-not-allowed':
          return 'Este método de inicio de sesión no está habilitado. Contacta al administrador.';
        case 'user-disabled':
          return 'Esta cuenta de usuario ha sido desactivada por el administrador.';
        case 'network-request-failed':
          return 'No se pudo establecer conexión con los servicios. Revisa tu conexión a internet e inténtalo de nuevo.';
        case 'permission-denied':
          return 'No tienes permisos suficientes para realizar esta acción. Verifica la configuración de tu base de datos o rol.';
        case 'unavailable':
          return 'El servicio de base de datos no está disponible en este momento. Inténtalo más tarde.';
        default:
          return defaultMessage.replaceAll('Exception: ', '');
      }
    } else {
      // English translations
      switch (code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'The email address or password entered does not match our records. Please verify your credentials.';
        case 'email-already-in-use':
          return 'This email address is already registered to another account. Try logging in or use another email.';
        case 'invalid-email':
          return 'The email address format is invalid. Please check for spelling mistakes.';
        case 'weak-password':
          return 'The password is too weak. It must be at least 6 characters long.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'user-disabled':
          return 'This user account has been disabled by the administrator.';
        case 'network-request-failed':
          return 'Could not establish connection with services. Please check your internet connection and try again.';
        case 'permission-denied':
          return 'You do not have permission to perform this action. Check your database rules or user role.';
        case 'unavailable':
          return 'The database service is temporarily unavailable. Please try again later.';
        default:
          return defaultMessage.replaceAll('Exception: ', '');
      }
    }
  }
}
