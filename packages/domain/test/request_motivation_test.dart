import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('P2 · RequestMotivation', () {
    test('accepts motivations from twenty to five hundred characters', () {
      expect(RequestMotivation.parse('A' * 20).isSuccess, isTrue);
      expect(RequestMotivation.parse('A' * 500).isSuccess, isTrue);
    });

    test('trims spaces around the motivation', () {
      expect(RequestMotivation.parse('  Imamo veliko dvorište.  ').valueOrNull?.text, 'Imamo veliko dvorište.');
    });

    test('rejects motivations shorter than twenty characters and reports the length', () {
      expect(RequestMotivation.parse('Volim pse.'), const Failure<RequestMotivation>(MotivationTooShort(10)));
    });

    test('rejects motivations longer than five hundred characters', () {
      expect(RequestMotivation.parse('A' * 501), const Failure<RequestMotivation>(MotivationTooLong()));
    });
  });
}
