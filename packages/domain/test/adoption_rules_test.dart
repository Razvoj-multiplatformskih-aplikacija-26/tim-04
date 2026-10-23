import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('P3 · submitRequest', () {
    Result<AdoptionRequest> submit({User user = ana, Animal? animal, List<AdoptionRequest> myRequests = const []}) {
      return submitRequest(
        id: const AdoptionRequestId('r-new'),
        user: user,
        animal: animal ?? rex,
        myRequests: myRequests,
        motivation: motivation,
        now: now,
      );
    }

    test('creates a pending request for an adoptable animal', () {
      final expected = AdoptionRequest(
        id: const AdoptionRequestId('r-new'),
        animalId: rex.id,
        applicantId: ana.id,
        motivation: motivation,
        createdAt: now,
      );

      expect(submit(), Success(expected));
    });

    test('rejects staff members', () {
      expect(submit(user: coordinator), const Failure<AdoptionRequest>(NotAllowed()));
      expect(submit(user: vet), const Failure<AdoptionRequest>(NotAllowed()));
    });

    test('rejects an animal that is not ready for adoption', () {
      expect(submit(animal: rexInQuarantine), const Failure<AdoptionRequest>(AnimalNotAdoptable()));
    });

    test('rejects a second active request for the same animal', () {
      final pending = requestBy(ana, animalId: rex.id);
      final approved = requestBy(ana, animalId: rex.id, status: AdoptionRequestStatus.approved);

      expect(submit(myRequests: [pending]), const Failure<AdoptionRequest>(DuplicateRequest()));
      expect(submit(myRequests: [approved]), const Failure<AdoptionRequest>(DuplicateRequest()));
    });

    test('allows a new request for the same animal after the old one was withdrawn', () {
      final withdrawn = requestBy(ana, animalId: rex.id, status: AdoptionRequestStatus.withdrawn);

      expect(submit(myRequests: [withdrawn]).isSuccess, isTrue);
    });

    test('rejects more than maxActiveRequests active requests', () {
      final active = List.generate(
        maxActiveRequests,
        (i) => requestBy(ana, id: 'r-$i', animalId: AnimalId('a-other-$i')),
      );

      expect(submit(myRequests: active), const Failure<AdoptionRequest>(TooManyActiveRequests()));
    });

    test('does not count withdrawn and rejected requests as active', () {
      final inactive = [
        requestBy(ana, id: 'r-1', animalId: const AnimalId('a-1'), status: AdoptionRequestStatus.withdrawn),
        requestBy(ana, id: 'r-2', animalId: const AnimalId('a-2'), status: AdoptionRequestStatus.rejected),
        requestBy(ana, id: 'r-3', animalId: const AnimalId('a-3'), status: AdoptionRequestStatus.rejected),
      ];

      expect(submit(myRequests: inactive).isSuccess, isTrue);
    });

    test('checks permission first, then the animal, then duplicates, then the limit', () {
      final duplicate = requestBy(ana, animalId: rex.id);
      final others = List.generate(
        maxActiveRequests,
        (i) => requestBy(ana, id: 'r-$i', animalId: AnimalId('a-other-$i')),
      );

      expect(submit(user: coordinator, animal: rexInQuarantine), const Failure<AdoptionRequest>(NotAllowed()));
      expect(
        submit(animal: rexInQuarantine, myRequests: [duplicate]),
        const Failure<AdoptionRequest>(AnimalNotAdoptable()),
      );
      expect(submit(myRequests: [duplicate, ...others]), const Failure<AdoptionRequest>(DuplicateRequest()));
    });
  });
}
