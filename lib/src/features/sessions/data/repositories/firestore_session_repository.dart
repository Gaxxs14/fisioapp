import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/soap_template.dart';
import '../../domain/repositories/session_repository.dart';

class FirestoreSessionRepository implements SessionRepository {
  final FirebaseFirestore _firestore;

  FirestoreSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveSession(Session session) async {
    try {
      final docRef = _firestore.collection('sessions').doc(session.id.isEmpty ? null : session.id);
      final finalSession = session.id.isEmpty ? session.copyWith(id: docRef.id) : session;
      await docRef.set(finalSession.toMap());
    } catch (e) {
      throw Exception('Error al guardar sesión clínica: $e');
    }
  }

  @override
  Future<Session?> getSessionById(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();
      if (!doc.exists) return null;
      return Session.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener sesión: $e');
    }
  }

  @override
  Stream<List<Session>> watchSessions(String clinicId, String patientId) {
    return _firestore
        .collection('sessions')
        .where('clinicId', isEqualTo: clinicId)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) => Session.fromMap(doc.data())).toList();
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return sessions;
    });
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
    } catch (e) {
      throw Exception('Error al eliminar sesión clínica: $e');
    }
  }

  @override
  Future<void> saveSoapTemplate(SoapTemplate template) async {
    try {
      final docRef = _firestore.collection('soap_templates').doc(template.id.isEmpty ? null : template.id);
      final finalTemplate = template.id.isEmpty ? template.copyWith(id: docRef.id) : template;
      await docRef.set(finalTemplate.toMap());
    } catch (e) {
      throw Exception('Error al guardar plantilla SOAP: $e');
    }
  }

  @override
  Stream<List<SoapTemplate>> watchSoapTemplates(String clinicId) {
    // Escucha las plantillas en Firestore. Si está vacía, inicializa las plantillas por defecto.
    return _firestore
        .collection('soap_templates')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        await _initializeDefaultTemplates(clinicId);
        // Volver a hacer consulta simple para devolver los nuevos datos cargados
        final freshDocs = await _firestore
            .collection('soap_templates')
            .where('clinicId', isEqualTo: clinicId)
            .get();
        return freshDocs.docs.map((doc) => SoapTemplate.fromMap(doc.data())).toList();
      }
      return snapshot.docs.map((doc) => SoapTemplate.fromMap(doc.data())).toList();
    });
  }

  @override
  Future<void> deleteSoapTemplate(String templateId) async {
    try {
      await _firestore.collection('soap_templates').doc(templateId).delete();
    } catch (e) {
      throw Exception('Error al eliminar plantilla SOAP: $e');
    }
  }

  Future<void> _initializeDefaultTemplates(String clinicId) async {
    final defaultTemplates = [
      SoapTemplate(
        id: '',
        clinicId: clinicId,
        name: 'Lumbalgia Mecánica',
        pathologyTag: 'lumbar',
        subjective: 'Paciente refiere dolor lumbar bajo de tipo mecánico. Refiere rigidez matutina y dificultad al levantarse.',
        objective: 'Contractura muscular paravertebral bilateral. Limitación en rango de flexión anterior del tronco. EVA: 6/10.',
        assessment: 'Lumbalgia subaguda mecánica. Restricción fascial lumbar posterior.',
        plan: 'Masoterapia descontracturante lumbar. Movilizaciones articulares pasivas. Estiramientos de isquiotibiales y psoas ilíaco.',
        defaultTechniques: ['Masoterapia', 'Kinesioterapia', 'Estiramientos'],
        defaultDurationMinutes: 45,
      ),
      SoapTemplate(
        id: '',
        clinicId: clinicId,
        name: 'Esguince de Tobillo',
        pathologyTag: 'deportivo',
        subjective: 'Paciente refiere dolor e inestabilidad en el tobillo tras inversión forzada. Dificultad para apoyar el pie.',
        objective: 'Inflamación y hematoma en maleolo externo. Dolor al test de cajón anterior. EVA: 5/10.',
        assessment: 'Esguince ligamento colateral externo tobillo grado II. Edema e inestabilidad moderada.',
        plan: 'Electroterapia analgésica. Crioterapia. Drenaje linfático manual. Ejercicios iniciales de propiocepción sin carga.',
        defaultTechniques: ['Kinesioterapia', 'Electroterapia'],
        defaultDurationMinutes: 30,
      ),
      SoapTemplate(
        id: '',
        clinicId: clinicId,
        name: 'Cervicalgia / Cefalea',
        pathologyTag: 'cervical',
        subjective: 'Paciente refiere dolor sordo cervical extendido hacia zona craneal (tensional). Asociado a estrés laboral postural.',
        objective: 'Puntos gatillo activos en trapecios superiores y angular de la escápula. Rotaciones limitadas simétricamente.',
        assessment: 'Cervicalgia postural tensional con contractura refleja escapular.',
        plan: 'Liberación de puntos gatillo. Terapia manual cervical. Ejercicios de reeducación postural global y estiramientos.',
        defaultTechniques: ['Masoterapia', 'Estiramientos'],
        defaultDurationMinutes: 45,
      ),
      SoapTemplate(
        id: '',
        clinicId: clinicId,
        name: 'Tendinitis de Hombro',
        pathologyTag: 'hombro',
        subjective: 'Paciente refiere dolor en hombro dominante al elevar el brazo y durante el sueño. Inicio insidioso hace 3 semanas.',
        objective: 'Arco doloroso de 60°-120° en abducción. Test de Neer y Hawkins positivos. EVA: 5/10 en movimiento.',
        assessment: 'Síndrome de pinzamiento subacromial. Probable tendinitis del supraespinoso.',
        plan: 'Ultrasonido terapéutico. Ejercicios de estabilización escapular. Estiramientos de la cápsula posterior.',
        defaultTechniques: ['Ultrasonido', 'Kinesioterapia', 'Estiramientos'],
        defaultDurationMinutes: 45,
      ),
      SoapTemplate(
        id: '',
        clinicId: clinicId,
        name: 'Gonalgia / Artrosis de Rodilla',
        pathologyTag: 'rodilla',
        subjective: 'Paciente refiere dolor en rodilla al subir escaleras y después de estar sentado por tiempo prolongado. Crepitación.',
        objective: 'Crepitación femoropatelar positiva. Leve derrame articular. EVA: 4/10. Genu varo moderado.',
        assessment: 'Síndrome femoropatelar. Gonartrosis leve-moderada.',
        plan: 'Termoterapia. Fortalecimiento de cuádriceps. Ejercicios de propiocepción. Educación postural.',
        defaultTechniques: ['Termoterapia', 'Kinesioterapia', 'Electroterapia'],
        defaultDurationMinutes: 45,
      ),
    ];

    for (var template in defaultTemplates) {
      await saveSoapTemplate(template);
    }
  }
}
