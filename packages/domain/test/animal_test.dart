import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final receivedAt = DateTime(2026, 9, 1);

  Animal animal({AnimalStatus? status}) => Animal(
    id: const AnimalId('a-1'),
    name: AnimalName.parse('Žućko').valueOrNull!,
    species: Species.dog,
    birthDate: DateTime(2024, 5, 15),
    description: 'Mirne naravi, voli decu.',
    enclosureId: const EnclosureId('b-3'),
    status: status ?? ReadyForAdoption(since: receivedAt),
    receivedAt: receivedAt,
  );

  group('Animal', () {
    test('is adoptable only when ready for adoption', () {
      expect(animal().isAdoptable, isTrue);
      expect(animal(status: const PermanentResident(reason: 'Starost')).isAdoptable, isFalse);
    });

    test('counts age in whole months', () {
      expect(animal().ageInMonths(DateTime(2026, 5, 15)), 24);
      expect(animal().ageInMonths(DateTime(2026, 5, 14)), 23);
    });

    test('copyWith changes only the given fields', () {
      final reserved = Reserved(
        requestId: const AdoptionRequestId('r-1'),
        approvedBy: const UserId('u-coordinator'),
        at: receivedAt,
      );
      final changed = animal().copyWith(status: reserved);

      expect(changed.status, reserved);
      expect(changed.name, animal().name);
      expect(changed, isNot(animal()));
      expect(animal().copyWith(), animal());
    });
  });
}
