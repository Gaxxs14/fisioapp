import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Map<String, AppUser> _cachedUsers = {};

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH STATE STREAM
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return await _getUserFromFirestore(fbUser.uid);
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return await _getUserFromFirestore(fbUser.uid);
  }

  Future<AppUser?> _getUserFromFirestore(String uid) async {
    if (_cachedUsers.containsKey(uid)) {
      return _cachedUsers[uid];
    }
    try {
      var doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
      
      // Delay and retry to handle race conditions where Auth stream fires before Firestore document write finishes
      await Future.delayed(const Duration(milliseconds: 1000));
      doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      // Ignorar errores de red silenciosamente
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN CON NOMBRE DE USUARIO
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<AppUser> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // 1. Buscar el usuario por nombre de usuario o correo en Firestore
      final cleanInput = username.trim().toLowerCase();
      var querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: cleanInput)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: cleanInput)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        if (username.trim().toLowerCase() == 'superadmin' && password == 'admin1234') {
          // Crear dinámicamente el documento del superadmin si no existe
          final now = DateTime.now();
          final tempDoc = {
            'uid': 'superadmin',
            'username': 'superadmin',
            'role': 'superadmin',
            'tempPassword': 'admin1234',
            'email': 'superadmin@fisioapp.com',
            'pendingAuth': true,
            'createdAt': now.toIso8601String(),
            'lastPasswordChange': now.toIso8601String(),
            'isActive': true,
            'clinicId': '',
          };
          await _firestore.collection('users').doc('superadmin').set(tempDoc);
          
          // Volver a consultar
          querySnapshot = await _firestore
              .collection('users')
              .where('username', isEqualTo: 'superadmin')
              .limit(1)
              .get();
        } else {
          throw Exception('Usuario o contraseña incorrectos.');
        }
      }

      final userData = querySnapshot.docs.first.data();
      final email = userData['email'] as String?;
      final clinicId = userData['clinicId'] as String?;
      final roleStr = userData['role'] as String?;
      final isSuperAdmin = roleStr == 'superadmin';

      if (email == null || (clinicId == null && !isSuperAdmin)) {
        throw Exception('Error en la configuración del usuario.');
      }

      // Validar el estado de la clínica antes de proceder (Bypass temporal para modo gratis)
      /*
      if (clinicId != null && clinicId.isNotEmpty) {
        final initialClinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
        if (initialClinicDoc.exists) {
          final initialClinicData = initialClinicDoc.data()!;
          // Se desactivan temporalmente las excepciones de pago y activación
          final isClinicActive = initialClinicData['isActive'] as bool? ?? true;
          final paymentStatus = initialClinicData['paymentStatus'] as String?;
          if (paymentStatus == 'pending_verification') {
            throw Exception('El pago de tu clínica está en proceso de verificación. Te notificaremos por correo electrónico una vez que tu cuenta esté activa.');
          }
          if (!isClinicActive) {
            throw Exception('Tu clínica se encuentra inactiva. Por favor, comunícate con soporte.');
          }
        }
      }
      */

      // Caso de Primera Autenticación (el admin lo creó en Firestore pero falta en Firebase Auth)
      if (userData['pendingAuth'] == true) {
        final tempPassword = userData['tempPassword'] as String?;
        if (tempPassword != password) {
          throw Exception('Usuario o contraseña incorrectos.');
        }

        // 1. Crear el usuario en Firebase Auth con email y password
        fb_auth.UserCredential userCredential;
        try {
          userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on fb_auth.FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            userCredential = await _firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        }

        final fbUser = userCredential.user;
        if (fbUser == null) {
          throw Exception('El registro falló.');
        }

        // 2. Migrar el documento de Firestore de docId (ID temporal) a fbUser.uid
        final now = DateTime.now();
        final appUser = AppUser(
          uid: fbUser.uid,
          email: email,
          name: userData['name'] ?? 'Super Admin',
          username: username.trim().toLowerCase(),
          clinicId: clinicId ?? '',
          role: UserRole.values.firstWhere(
            (r) => r.name == userData['role'],
            orElse: () => UserRole.physio,
          ),
          specialty: userData['specialty'] as String?,
          workDays: (userData['workDays'] as List?)?.map((e) => e.toString()).toList(),
          workHoursStart: userData['workHoursStart'] as String?,
          workHoursEnd: userData['workHoursEnd'] as String?,
          lastPasswordChange: now,
          createdAt: now,
          isActive: true,
        );

        // Guardar en el caché temporal para evitar la condición de carrera
        _cachedUsers[fbUser.uid] = appUser;

        // Guardar el nuevo documento con el UID correcto
        await _firestore.collection('users').doc(fbUser.uid).set(appUser.toMap());

        // Eliminar el documento temporal (solo si era temporal)
        if (querySnapshot.docs.first.id != fbUser.uid) {
          await _firestore.collection('users').doc(querySnapshot.docs.first.id).delete();
        }

        // Limpiar el caché
        _cachedUsers.remove(fbUser.uid);

        return appUser;
      }

      // 2. Autenticar en Firebase Auth con el email recuperado
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('El inicio de sesión falló.');
      }

      // 3. Recuperar el usuario completo de Firestore
      final appUser = await _getUserFromFirestore(fbUser.uid);
      if (appUser == null) {
        await signOut();
        throw Exception('No se encontró el perfil de usuario en el sistema.');
      }

      if (!appUser.isActive && appUser.role != UserRole.admin && appUser.role != UserRole.superadmin) {
        await signOut();
        throw Exception('Tu usuario ha sido desactivado por el administrador.');
      }

      // 4. Validar si la licencia de la clínica está activa (Desactivado temporalmente para pruebas gratis)
      /*
      if (clinicId != null && clinicId.isNotEmpty) {
        final clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
        if (clinicDoc.exists) {
          final clinicData = clinicDoc.data()!;
          final trialEndDateStr = clinicData['trialEndDate'] as String?;
          final isSubscriptionActive = clinicData['isSubscriptionActive'] ?? false;

          if (trialEndDateStr != null) {
            final trialEndDate = DateTime.parse(trialEndDateStr);
            if (DateTime.now().isAfter(trialEndDate) && !isSubscriptionActive) {
              await signOut();
              throw Exception('La prueba gratuita de 14 días ha expirado. Por favor, actualiza tu suscripción.');
            }
          }
        }
      }
      */

      return appUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception('Usuario o contraseña incorrectos.');
      }
      throw Exception(e.message ?? 'Error en la autenticación.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REGISTRO DE CLÍNICA
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<AppUser> registerClinic({
    required String clinicName,
    required String ownerName,
    required String username,
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    // Validar que el username no esté en uso
    final existingUser = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw Exception('El nombre de usuario "$username" ya está en uso. Elige otro.');
    }

    fb_auth.UserCredential? userCredential;
    try {
      // 1. Crear la clínica en Firestore (Activa y aprobada por defecto para pruebas gratis)
      final clinicRef = _firestore.collection('clinics').doc();
      final DateTime now = DateTime.now();
      final DateTime trialEndDate = now.add(const Duration(days: 365 * 100)); // 100 años

      final clinicData = {
        'id': clinicRef.id,
        'name': clinicName,
        'createdAt': now.toIso8601String(),
        'trialEndDate': trialEndDate.toIso8601String(),
        'isSubscriptionActive': true,
        'paymentStatus': 'approved',
        'isActive': true,
      };

      // 2. Crear usuario en Firebase Auth con el email interno
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) throw Exception('El registro falló.');

      // 3. Crear el modelo AppUser con username
      final appUser = AppUser(
        uid: fbUser.uid,
        email: email,
        name: ownerName,
        username: username.trim().toLowerCase(),
        clinicId: clinicRef.id,
        role: UserRole.admin,
        lastPasswordChange: now,
        createdAt: now,
        securityQuestions: {
          'question': securityQuestion,
          'answer_hashed': securityAnswer.trim().toLowerCase(),
        },
      );

      // 4. Guardar en Firestore de forma secuencial
      await clinicRef.set(clinicData);
      await _firestore.collection('users').doc(fbUser.uid).set(appUser.toMap());

      return appUser;
    } catch (e) {
      // Si falló Firestore pero se creó en Auth, eliminar el usuario de Auth
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CAMBIO DE CONTRASEÑA
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> updatePassword(String newPassword) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('No hay un usuario activo.');

    try {
      await fbUser.updatePassword(newPassword);
      await _firestore.collection('users').doc(fbUser.uid).update({
        'lastPasswordChange': DateTime.now().toIso8601String(),
      });
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Esta acción requiere haber iniciado sesión recientemente. Por favor, vuelve a iniciar sesión.');
      }
      throw Exception(e.message ?? 'Error al actualizar contraseña.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECUPERACIÓN DE CONTRASEÑA POR USERNAME + PREGUNTA DE SEGURIDAD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> verifyAndResetPassword({
    required String username,
    required String securityAnswer,
    required String newPassword,
  }) async {
    // 1. Buscar al usuario por nombre de usuario o correo
    final cleanInput = username.trim().toLowerCase();
    var querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: cleanInput)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanInput)
          .limit(1)
          .get();
    }

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No se encontró ningún usuario con ese nombre de usuario o correo.');
    }

    final doc = querySnapshot.docs.first;
    final userData = doc.data();
    final email = userData['email'] as String?;
    final Map<String, dynamic>? securityQuestions = userData['securityQuestions'];

    if (securityQuestions == null || !securityQuestions.containsKey('answer_hashed')) {
      throw Exception('El usuario no configuró preguntas de seguridad.');
    }

    final savedAnswer = (securityQuestions['answer_hashed'] as String? ?? '').trim().toLowerCase();
    final inputAnswer = securityAnswer.trim().toLowerCase();

    // 2. Validar respuesta de seguridad (insensible a mayúsculas/minúsculas y espacios)
    if (savedAnswer != inputAnswer) {
      throw Exception('La respuesta de seguridad es incorrecta.');
    }

    // 3. Si el usuario aún no ha iniciado sesión por primera vez (pendingAuth de la web)
    if (userData['pendingAuth'] == true) {
      await _firestore.collection('users').doc(doc.id).update({
        'tempPassword': newPassword,
        'lastPasswordChange': DateTime.now().toIso8601String(),
      });
      return;
    }

    // 4. Si ya es usuario activo en Firebase Auth, enviar correo de restablecimiento
    if (email != null) {
      try {
        await _firebaseAuth.sendPasswordResetEmail(email: email);
      } catch (e) {
        debugPrint("Error enviando reset email: $e");
      }
    }

    // 5. Marcar cambio de fecha de contraseña
    await _firestore.collection('users').doc(doc.id).update({
      'lastPasswordChange': DateTime.now()
          .subtract(const Duration(days: 31))
          .toIso8601String(),
    });
  }

  @override
  Future<String> getSecurityQuestion(String username) async {
    final cleanInput = username.trim().toLowerCase();
    var querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: cleanInput)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanInput)
          .limit(1)
          .get();
    }

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No se encontró ningún usuario con ese nombre de usuario o correo.');
    }

    final doc = querySnapshot.docs.first;
    final userData = doc.data();
    final Map<String, dynamic>? securityQuestions = userData['securityQuestions'];

    if (securityQuestions == null || !securityQuestions.containsKey('question')) {
      throw Exception('El usuario no configuró preguntas de seguridad.');
    }

    return securityQuestions['question'] as String;
  }

  @override
  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al actualizar el perfil.');
    }
  }
}
