import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Mensaje en segundo plano recibido: ${message.messageId}");
  }
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("Mensaje en primer plano recibido: ${message.notification?.title}");
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("El usuario abrió la app desde la notificación: ${message.notification?.title}");
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error al inicializar PushNotificationService: $e");
      }
    }
  }

  static Future<void> requestPermissions() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error al solicitar permisos FCM: $e");
      }
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print("Error al obtener token FCM: $e");
      }
      return null;
    }
  }

  static Future<void> registerDeviceToken(String patientId) async {
    if (patientId.isEmpty) return;
    try {
      final token = await getDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .update({'fcmToken': token});
        if (kDebugMode) {
          print("Token FCM registrado en Firestore para: $patientId");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al guardar token FCM en Firestore: $e");
      }
    }
  }
}
