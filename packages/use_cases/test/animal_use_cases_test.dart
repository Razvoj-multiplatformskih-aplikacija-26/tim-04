import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'in_memory_animals.dart';

const coordinator = User(id: UserId('u-coordinator'), name: 'Dragana Ilić', role: Role.coordinator);
const volunteer = User(id: UserId('u-volunteer'), name: 'Jovan Marić', role: Role.volunteer);
const vet = User(id: UserId('u-vet'), name: 'dr Ivana Lazić', role: Role.veterinarian);

final clock = FixedClock(DateTime.utc(2026, 11, 10, 9));

final rex = Animal(
  id: const AnimalId('a-rex'),
  name: AnimalName.parse('Rex').valueOrNull!,
  species: Species.dog,
  birthDate: DateTime.utc(2022, 5, 10),
  description: 'Miran i druželjubiv pas.',
  enclosureId: const EnclosureId('e-1'),
  status: InQuarantine(since: DateTime.utc(2026, 11, 1), until: DateTime.utc(2026, 11, 20)),
  receivedAt: DateTime.utc(2026, 11, 1),
);

void main() {
  group('IntakeAnimal', () {
    Future<Result<Animal>> intake(InMemoryAnimals animals, {required User by}) =>
        IntakeAnimal(animals: animals, clock: clock, newId: () => 'a-new')(
          by: by,
          name: 'Mrki',
          species: Species.dog,
          birthDate: DateTime.utc(2024, 3, 1),
          description: 'Pronađen pored puta.',
          enclosureId: const EnclosureId('e-1'),
        );

    test('creates a received animal with the id from newId and the time from the clock', () async {
      final animals = InMemoryAnimals();

      final animal = (await intake(animals, by: coordinator)).valueOrNull!;

      expect(animal.id, const AnimalId('a-new'));
      expect(animal.status, Received(receivedBy: coordinator.id, at: clock.now()));
      expect(animal.receivedAt, clock.now());
      expect(animals.stored, [animal]);
    });

    test('by a volunteer is not allowed and saves nothing', () async {
      final animals = InMemoryAnimals();

      final result = await intake(animals, by: volunteer);

      expect(result.errorOrNull, isA<NotAllowed>());
      expect(animals.stored, isEmpty);
    });
  });

  test('StartQuarantine for an animal that does not exist is not found', () async {
    final startQuarantine = StartQuarantine(animals: InMemoryAnimals([rex]), clock: clock);

    final result = await startQuarantine(
      id: const AnimalId('a-missing'),
      by: coordinator,
      until: DateTime.utc(2026, 11, 30),
    );

    expect(result.errorOrNull, isA<NotFound>());
  });

  test('EndQuarantine after someone else changed the animal is an invalid transition', () async {
    final animals = InMemoryAnimals([rex]);
    final changedMeanwhile = rex.copyWith(status: ReadyForAdoption(since: DateTime.utc(2026, 11, 9)));
    animals.afterFind = () => animals.replace(changedMeanwhile);
    final endQuarantine = EndQuarantine(animals: animals, clock: clock);

    final result = await endQuarantine(id: rex.id, by: vet);

    expect(result.errorOrNull, isA<InvalidTransition>());
    expect(animals.stored, [changedMeanwhile]);
  });
}
