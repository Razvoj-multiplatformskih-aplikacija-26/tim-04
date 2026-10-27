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

  group('P4 · withdrawRequest', () {
    final pending = requestBy(ana, animalId: rex.id);

    test('withdraws a pending request of the applicant', () {
      final result = withdrawRequest(request: pending, by: ana, now: now);

      expect(result, Success(pending.copyWith(status: AdoptionRequestStatus.withdrawn)));
    });

    test('rejects another adopter', () {
      expect(withdrawRequest(request: pending, by: marko, now: now), const Failure<AdoptionRequest>(NotAllowed()));
    });

    test('rejects staff members, because only the applicant may withdraw', () {
      expect(
        withdrawRequest(request: pending, by: coordinator, now: now),
        const Failure<AdoptionRequest>(NotAllowed()),
      );
    });

    test('rejects a request that is no longer pending', () {
      final approved = pending.copyWith(status: AdoptionRequestStatus.approved);
      final rejected = pending.copyWith(status: AdoptionRequestStatus.rejected);
      final withdrawn = pending.copyWith(status: AdoptionRequestStatus.withdrawn);

      expect(
        withdrawRequest(request: approved, by: ana, now: now),
        const Failure<AdoptionRequest>(WithdrawNotAllowed()),
      );
      expect(
        withdrawRequest(request: rejected, by: ana, now: now),
        const Failure<AdoptionRequest>(WithdrawNotAllowed()),
      );
      expect(
        withdrawRequest(request: withdrawn, by: ana, now: now),
        const Failure<AdoptionRequest>(WithdrawNotAllowed()),
      );
    });

    test('checks the applicant before the status', () {
      final approved = pending.copyWith(status: AdoptionRequestStatus.approved);

      expect(withdrawRequest(request: approved, by: marko, now: now), const Failure<AdoptionRequest>(NotAllowed()));
    });
  });

  group('P5 · approveRequest', () {
    final byAna = requestBy(ana, animalId: rex.id, id: 'r-1');
    final byMarko = requestBy(marko, animalId: rex.id, id: 'r-2');
    final byJelena = requestBy(jelena, animalId: rex.id, id: 'r-3');
    final all = [byAna, byMarko, byJelena];

    Result<ApprovalOutcome> approve({Animal? animal, AdoptionRequest? request, User by = coordinator}) =>
        approveRequest(animal: animal ?? rex, request: request ?? byMarko, allRequestsForAnimal: all, by: by, now: now);

    test('reserves the animal and rejects the other two competing requests', () {
      final outcome = approve().valueOrNull!;

      expect(outcome.animal.status, Reserved(requestId: byMarko.id, approvedBy: coordinator.id, at: now));
      expect(outcome.approved, byMarko.copyWith(status: AdoptionRequestStatus.approved));
      expect(outcome.rejected, [
        byAna.copyWith(status: AdoptionRequestStatus.rejected),
        byJelena.copyWith(status: AdoptionRequestStatus.rejected),
      ]);
    });

    test('leaves requests that are no longer pending out of the rejected list', () {
      final withdrawn = requestBy(jelena, animalId: rex.id, id: 'r-4', status: AdoptionRequestStatus.withdrawn);
      final outcome = approveRequest(
        animal: rex,
        request: byMarko,
        allRequestsForAnimal: [byAna, byMarko, withdrawn],
        by: coordinator,
        now: now,
      ).valueOrNull!;

      expect(outcome.rejected.map((r) => r.id), [byAna.id]);
    });

    test('a senior volunteer can approve as well', () {
      expect(approve(by: senior).isSuccess, isTrue);
    });

    test('rejects adopters, volunteers and vets', () {
      for (final user in [ana, volunteer, vet]) {
        expect(approve(by: user), const Failure<ApprovalOutcome>(NotAllowed()));
      }
    });

    test('rejects a request that is no longer pending', () {
      final withdrawn = byMarko.copyWith(status: AdoptionRequestStatus.withdrawn);

      expect(approve(request: withdrawn), const Failure<ApprovalOutcome>(InvalidRequestTransition()));
    });

    test('rejects an animal that is not ready for adoption', () {
      expect(approve(animal: rexInQuarantine), const Failure<ApprovalOutcome>(AnimalNotAdoptable()));
    });

    test('locks the animal: a second approval for the same animal fails', () {
      final reservedRex = approve().valueOrNull!.animal;

      expect(approve(animal: reservedRex, request: byAna), const Failure<ApprovalOutcome>(AnimalNotAdoptable()));
    });

    test('checks permission, then the request, then the animal', () {
      final withdrawn = byMarko.copyWith(status: AdoptionRequestStatus.withdrawn);

      expect(
        approve(animal: rexInQuarantine, request: withdrawn, by: ana),
        const Failure<ApprovalOutcome>(NotAllowed()),
      );
      expect(
        approve(animal: rexInQuarantine, request: withdrawn),
        const Failure<ApprovalOutcome>(InvalidRequestTransition()),
      );
    });
  });

  group('P6 · rejectRequest', () {
    final pending = requestBy(ana, animalId: rex.id);

    test('a coordinator and a senior volunteer can reject a pending request', () {
      final rejected = Success(pending.copyWith(status: AdoptionRequestStatus.rejected));

      expect(rejectRequest(request: pending, by: coordinator), rejected);
      expect(rejectRequest(request: pending, by: senior), rejected);
    });

    test('rejects adopters, volunteers and vets', () {
      for (final user in [ana, marko, volunteer, vet]) {
        expect(rejectRequest(request: pending, by: user), const Failure<AdoptionRequest>(NotAllowed()));
      }
    });

    test('rejects a request that is no longer pending', () {
      for (final status in [
        AdoptionRequestStatus.approved,
        AdoptionRequestStatus.rejected,
        AdoptionRequestStatus.withdrawn,
      ]) {
        expect(
          rejectRequest(
            request: pending.copyWith(status: status),
            by: coordinator,
          ),
          const Failure<AdoptionRequest>(InvalidRequestTransition()),
        );
      }
    });

    test('checks permission before the status', () {
      final withdrawn = pending.copyWith(status: AdoptionRequestStatus.withdrawn);

      expect(rejectRequest(request: withdrawn, by: ana), const Failure<AdoptionRequest>(NotAllowed()));
    });
  });

  group('competingRequests', () {
    const other = AnimalId('a-other');
    final byJelena = requestBy(jelena, animalId: rex.id, id: 'r-3', createdAt: DateTime(2026, 10, 12));
    final byAna = requestBy(ana, animalId: rex.id, id: 'r-1', createdAt: DateTime(2026, 10, 10));
    final byMarko = requestBy(
      marko,
      animalId: rex.id,
      id: 'r-2',
      createdAt: DateTime(2026, 10, 11),
      status: AdoptionRequestStatus.approved,
    );
    final withdrawn = requestBy(
      marko,
      animalId: rex.id,
      id: 'r-4',
      createdAt: DateTime(2026, 10, 9),
      status: AdoptionRequestStatus.withdrawn,
    );
    final forOtherAnimal = requestBy(ana, animalId: other, id: 'r-5');

    test('returns active requests for the animal, oldest first', () {
      final all = [byJelena, forOtherAnimal, byAna, withdrawn, byMarko];

      expect(competingRequests(rex.id, all), [byAna, byMarko, byJelena]);
    });

    test('returns an empty list when nobody competes for the animal', () {
      expect(competingRequests(other, [byAna, byMarko]), isEmpty);
      expect(competingRequests(rex.id, []), isEmpty);
    });
  });
}
