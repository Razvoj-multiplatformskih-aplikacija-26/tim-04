import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('P1 · AnimalName', () {
    test('accepts names from two to forty characters', () {
      expect(AnimalName.parse('Bo').valueOrNull?.text, 'Bo');
      expect(AnimalName.parse('A' * 40).isSuccess, isTrue);
    });

    test('trims spaces around the name', () {
      expect(AnimalName.parse('  Žućko  ').valueOrNull?.text, 'Žućko');
    });

    test('rejects names shorter than two characters', () {
      expect(AnimalName.parse('A'), const Failure<AnimalName>(NameTooShort()));
      expect(AnimalName.parse('   '), const Failure<AnimalName>(NameTooShort()));
    });

    test('rejects names longer than forty characters', () {
      expect(AnimalName.parse('A' * 41), const Failure<AnimalName>(NameTooLong()));
    });
  });
}
