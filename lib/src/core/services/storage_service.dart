import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // Sube un archivo desde el almacenamiento local
  Future<String> uploadFile({
    required String path,
    required String filePath,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('404') || errStr.contains('object-not-found') || errStr.contains('-13010') || errStr.contains('Not Found')) {
        try {
          final fallbackStorage = FirebaseStorage.instanceFor(bucket: 'gs://fisioapp-df863.appspot.com');
          final ref = fallbackStorage.ref().child(path);
          final uploadTask = ref.putFile(File(filePath));
          final snapshot = await uploadTask;
          _storage = fallbackStorage; // Guardar el bucket correcto para futuras operaciones
          return await snapshot.ref.getDownloadURL();
        } catch (fallbackError) {
          throw Exception('Error al subir archivo a Storage (principal y fallback fallaron): $fallbackError');
        }
      }
      throw Exception('Error al subir archivo a Storage: $e');
    }
  }

  // Sube bytes crudos (útil para la firma en PNG o imágenes manipuladas en memoria)
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String contentType = 'image/png',
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('404') || errStr.contains('object-not-found') || errStr.contains('-13010') || errStr.contains('Not Found')) {
        try {
          final fallbackStorage = FirebaseStorage.instanceFor(bucket: 'gs://fisioapp-df863.appspot.com');
          final ref = fallbackStorage.ref().child(path);
          final metadata = SettableMetadata(contentType: contentType);
          final uploadTask = ref.putData(bytes, metadata);
          final snapshot = await uploadTask;
          _storage = fallbackStorage; // Guardar el bucket correcto para futuras operaciones
          return await snapshot.ref.getDownloadURL();
        } catch (fallbackError) {
          throw Exception('Error al subir bytes a Storage (principal y fallback fallaron): $fallbackError');
        }
      }
      throw Exception('Error al subir bytes a Storage: $e');
    }
  }

  // Elimina un archivo en Storage dada su ruta
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('404') || errStr.contains('object-not-found') || errStr.contains('-13010') || errStr.contains('Not Found')) {
        try {
          final fallbackStorage = FirebaseStorage.instanceFor(bucket: 'gs://fisioapp-df863.appspot.com');
          final ref = fallbackStorage.ref().child(path);
          await ref.delete();
          _storage = fallbackStorage;
          return;
        } catch (_) {}
      }
      throw Exception('Error al eliminar archivo en Storage: $e');
    }
  }
}
