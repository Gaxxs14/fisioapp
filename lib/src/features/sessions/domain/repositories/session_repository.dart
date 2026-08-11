import '../entities/session.dart';
import '../entities/soap_template.dart';

abstract class SessionRepository {
  Future<void> saveSession(Session session);
  Future<Session?> getSessionById(String sessionId);
  Stream<List<Session>> watchSessions(String clinicId, String patientId);
  Future<void> deleteSession(String sessionId);

  Future<void> saveSoapTemplate(SoapTemplate template);
  Stream<List<SoapTemplate>> watchSoapTemplates(String clinicId);
  Future<void> deleteSoapTemplate(String templateId);
}
