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

    test('finds an animal by id, and null for an unknown id', () async {
      expect(await repo.find(luna.id), luna);
      expect(await repo.find(const AnimalId('a-missing')), isNull);
    });

    test('filters requests by applicant and by animal', () async {
      expect(await repo.requests(), [anasForRex, markosForRex, anasForLuna]);
      expect(await repo.requests(applicant: ana), [anasForRex, anasForLuna]);
      expect(await repo.requests(animal: rex.id), [anasForRex, markosForRex]);
      expect(await repo.requests(applicant: ana, animal: rex.id), [anasForRex]);
    });

    test('submit adds a new request', () async {
      final markosForLuna = request('r-4', by: marko, animalId: luna.id);

      final result = await FakeAdoptionRequestRepository(repo).submit(markosForLuna);

      expect(result.valueOrNull, markosForLuna);
      expect(await repo.requests(applicant: marko), [markosForRex, markosForLuna]);
    });

    test('save replaces a request that is still in the expected status', () async {
      final withdrawn = anasForRex.copyWith(status: AdoptionRequestStatus.withdrawn);

      final result = await FakeAdoptionRequestRepository(repo).save(withdrawn, from: AdoptionRequestStatus.pending);

      expect(result.valueOrNull, withdrawn);
      expect(await repo.requests(animal: rex.id), [withdrawn, markosForRex]);
    });

    test('save refuses a request whose status changed in the meantime', () async {
      final requests = FakeAdoptionRequestRepository(repo);
      await requests.save(
        anasForRex.copyWith(status: AdoptionRequestStatus.rejected),
        from: AdoptionRequestStatus.pending,
      );

      final result = await requests.save(
        anasForRex.copyWith(status: AdoptionRequestStatus.withdrawn),
        from: AdoptionRequestStatus.pending,
      );

      expect(result.errorOrNull, isA<InvalidRequestTransition>());
    });

    test('create adds an animal', () async {
      final bobi = animal('a-bobi', 'Bobi');

      final result = await repo.create(bobi);

      expect(result.valueOrNull, bobi);
      expect(await repo.animals(), [rex, luna, bobi]);
    });

    final reserved = rex.copyWith(
      status: Reserved(requestId: anasForRex.id, approvedBy: const UserId('u-coordinator'), at: DateTime(2026, 10, 22)),
    );

    test('save replaces an animal that is still in the expected status', () async {
      final result = await repo.save(reserved, from: rex.status);

      expect(result.valueOrNull, reserved);
      expect(await repo.animals(), [reserved, luna]);
    });

    test('save refuses an animal whose status changed in the meantime', () async {
      await repo.save(reserved, from: rex.status);

      final result = await repo.save(
        rex.copyWith(status: const PermanentResident(reason: 'Starost')),
        from: rex.status,
      );

      expect(result.errorOrNull, isA<InvalidTransition>());
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
