import 'package:flutter_test/flutter_test.dart';
import 'package:fisioapp/src/features/tools/data/repositories/orthopedic_tests_repository.dart';
import 'package:fisioapp/src/features/tools/domain/entities/orthopedic_test.dart';
import 'package:fisioapp/src/features/auth/domain/entities/app_user.dart';

void main() {
  group('FisioApp Unit & Clinical Tests', () {
    test('OrthopedicTestsRepository loads all clinical tests', () {
      final tests = OrthopedicTestsRepository.allTests;
      expect(tests.isNotEmpty, true);
      expect(tests.length, greaterThanOrEqualTo(15));
    });

    test('OrthopedicTestsRepository filters by joint region correctly', () {
      final kneeTests = OrthopedicTestsRepository.getByRegion(JointRegion.knee);
      expect(kneeTests.isNotEmpty, true);
      for (final test in kneeTests) {
        expect(test.region, JointRegion.knee);
      }
    });

    test('OrthopedicTestsRepository search works for Lachman', () {
      final results = OrthopedicTestsRepository.search('Lachman');
      expect(results.any((t) => t.name.contains('Lachman')), true);
    });

    test('AppUser UserRole supports student role', () {
      expect(UserRole.student.displayName, 'Estudiante / Pasante');
      
      final map = {
        'uid': 'student_123',
        'email': 'student@fisio.edu',
        'name': 'Pasante Carlos',
        'clinicId': 'clinic_1',
        'role': 'student',
      };

      final user = AppUser.fromMap(map);
      expect(user.role, UserRole.student);
      expect(user.name, 'Pasante Carlos');
    });
  });
}
