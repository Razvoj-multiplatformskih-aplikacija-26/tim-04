import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Success carries a value and no error', () {
      const Result<int> result = Success(5);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 5);
      expect(result.errorOrNull, isNull);
    });

    test('Failure carries an error and no value', () {
      const Result<int> result = Failure(NameTooShort());

      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, isA<NameTooShort>());
    });

    test('failures with the same error are equal', () {
      expect(const Failure<int>(MotivationTooShort(12)), const Failure<int>(MotivationTooShort(12)));
      expect(const Failure<int>(MotivationTooShort(12)), isNot(const Failure<int>(MotivationTooShort(15))));
    });
  });

  group('Role', () {
    test('only staff roles are staff', () {
      expect(Role.adopter.isStaff, isFalse);
      expect(Role.volunteer.isStaff, isTrue);
      expect(Role.seniorVolunteer.isStaff, isTrue);
      expect(Role.veterinarian.isStaff, isTrue);
      expect(Role.coordinator.isStaff, isTrue);
    });
  });
}