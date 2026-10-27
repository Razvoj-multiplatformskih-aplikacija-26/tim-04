import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fake_shelter_repository.dart';

void main() {
  const ana = UserId('u-ana');
  const marko = UserId('u-marko');

  final motivation = RequestMotivation.parse('Imamo veliko dvorište i mnogo slobodnog vremena.').valueOrNull!;

  Animal animal(String id, String name) {
    return Animal(
      id: AnimalId(id),
      name: AnimalName.parse(name).valueOrNull!,
      species: Species.dog,
      birthDate: DateTime(2022, 5, 10),
      description: 'Miran i druželjubiv pas.',
      enclosureId: const EnclosureId('e-1'),
      status: ReadyForAdoption(since: DateTime(2026, 9, 1)),
      receivedAt: DateTime(2026, 8, 1),
    );
  }

  AdoptionRequest request(String id, {required UserId by, required AnimalId animalId}) {
    return AdoptionRequest(
      id: AdoptionRequestId(id),
      animalId: animalId,
      applicantId: by,
      motivation: motivation,
      createdAt: DateTime(2026, 10, 10),
    );
  }

  final rex = animal('a-rex', 'Rex');
  final luna = animal('a-luna', 'Luna');
  final anasForRex = request('r-1', by: ana, animalId: rex.id);
  final markosForRex = request('r-2', by: marko, animalId: rex.id);
  final anasForLuna = request('r-3', by: ana, animalId: luna.id);

  late FakeShelterRepository repo;

  setUp(() {
    repo = FakeShelterRepository(animals: [rex, luna], requests: [anasForRex, markosForRex, anasForLuna]);
  });

  group('FakeShelterRepository', () {
    test('returns the animals it was created with', () async {
      expect(await repo.animals(), [rex, luna]);
    });

    test('finds an animal by id', () async {
      expect(await repo.animal(luna.id), luna);
    });

    test('filters requests by applicant and by animal', () async {
      expect(await repo.requests(), [anasForRex, markosForRex, anasForLuna]);
      expect(await repo.requests(applicant: ana), [anasForRex, anasForLuna]);
      expect(await repo.requests(animal: rex.id), [anasForRex, markosForRex]);
      expect(await repo.requests(applicant: ana, animal: rex.id), [anasForRex]);
    });

    test('saveRequest adds a request with a new id', () async {
      final markosForLuna = request('r-4', by: marko, animalId: luna.id);

      await repo.saveRequest(markosForLuna);

      expect(await repo.requests(applicant: marko), [markosForRex, markosForLuna]);
    });

    test('saveRequest replaces a request with the same id', () async {
      final withdrawn = anasForRex.copyWith(status: AdoptionRequestStatus.withdrawn);

      await repo.saveRequest(withdrawn);

      expect(await repo.requests(animal: rex.id), [withdrawn, markosForRex]);
    });

    test('saveAnimal replaces an animal with the same id', () async {
      final reserved = rex.copyWith(
        status: Reserved(
          requestId: anasForRex.id,
          approvedBy: const UserId('u-coordinator'),
          at: DateTime(2026, 10, 22),
        ),
      );

      await repo.saveAnimal(reserved);

      expect(await repo.animals(), [reserved, luna]);
    });

    test('does not let the caller change its lists', () async {
      final animals = await repo.animals();
      animals.clear();

      expect(await repo.animals(), [rex, luna]);
    });

    test('fails only the next request after failNextRequest', () async {
      repo.failNextRequest();

      await expectLater(repo.animals(), throwsException);
      expect(await repo.animals(), [rex, luna]);
    });
  });
}
