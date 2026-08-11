import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _savedClinicIdKey = 'saved_clinic_id';
  static const String _savedClinicNameKey = 'saved_clinic_name';

  // Verifica si el dispositivo soporta biometría
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  // Verifica si el usuario tiene huellas/rostro registrados
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Comprueba si el usuario activó la huella en los ajustes de la app
  Future<bool> isBiometricsEnabledInApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Activa o desactiva la huella en los ajustes de la app
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (!enabled) {
      // Limpiar credenciales almacenadas de forma segura si se desactiva
      await _secureStorage.delete(key: _savedEmailKey);
      await _secureStorage.delete(key: _savedPasswordKey);
      await _secureStorage.delete(key: _savedClinicIdKey);
      await _secureStorage.delete(key: _savedClinicNameKey);
    }
  }

  // Guarda credenciales de forma segura al iniciar sesión exitosamente
  Future<void> saveCredentials({
    required String email,
    required String password,
    required String clinicId,
    required String clinicName,
  }) async {
    await _secureStorage.write(key: _savedEmailKey, value: email);
    await _secureStorage.write(key: _savedPasswordKey, value: password);
    await _secureStorage.write(key: _savedClinicIdKey, value: clinicId);
    await _secureStorage.write(key: _savedClinicNameKey, value: clinicName);
  }

  // Retorna las credenciales almacenadas para el login automático
  Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _secureStorage.read(key: _savedEmailKey);
    final password = await _secureStorage.read(key: _savedPasswordKey);
    final clinicId = await _secureStorage.read(key: _savedClinicIdKey);
    final clinicName = await _secureStorage.read(key: _savedClinicNameKey);

    if (email != null && password != null && clinicId != null) {
      return {
        'email': email,
        'password': password,
        'clinicId': clinicId,
        'clinicName': clinicName ?? '',
      };
    }
    return null;
  }

  // Lanza el diálogo de huella digital
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Escanea tu huella digital para iniciar sesión en la clínica',
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
