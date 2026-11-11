import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'in_memory_animals.dart';
import 'in_memory_requests.dart';

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana', role: Role.adopter);
  const marko = User(id: UserId('u-marko'), name: 'Marko', role: Role.adopter);
  const coordinator = User(id: UserId('u-coordinator'), name: 'Koordinator', role: Role.coordinator);
  final clock = FixedClock(DateTime.utc(2026, 11, 10, 9));
  final motivation = RequestMotivation.parse('Imamo veliko dvorište i mnogo slobodnog vremena.').valueOrNull!;

  AdoptionRequest request(String id, User by, {AdoptionRequestStatus status = AdoptionRequestStatus.pending}) =>
      AdoptionRequest(
        id: AdoptionRequestId(id),
        animalId: const AnimalId('a-rex'),
        applicantId: by.id,
        motivation: motivation,
        createdAt: DateTime.utc(2026, 11, 1),
        status: status,
      );

  final anas = request('r-ana', ana);
  final markos = request('r-marko', marko);

  group('GetRequests', () {
    test('an adopter gets only their own requests', () async {
      final getRequests = GetRequests(requests: InMemoryRequests([anas, markos]));

      expect(await getRequests(ana), [anas]);
    });

    test('staff get every request', () async {
      final getRequests = GetRequests(requests: InMemoryRequests([anas, markos]));

      expect(await getRequests(coordinator), [anas, markos]);
    });
  });

  group('WithdrawRequest', () {
    test('the applicant withdraws their pending request', () async {
      final requests = InMemoryRequests([anas]);
      final withdraw = WithdrawRequest(requests: requests, clock: clock);

      final result = await withdraw(id: anas.id, by: ana);

      expect(result, Success(anas.copyWith(status: AdoptionRequestStatus.withdrawn)));
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.withdrawn);
    });

    test('a request of another adopter is not found', () async {
      final requests = InMemoryRequests([anas]);
      final withdraw = WithdrawRequest(requests: requests, clock: clock);

      expect(await withdraw(id: anas.id, by: marko), const Failure<AdoptionRequest>(NotFound()));
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.pending);
    });

    test('a request that does not exist is not found', () async {
      final withdraw = WithdrawRequest(requests: InMemoryRequests([]), clock: clock);

      expect(await withdraw(id: anas.id, by: ana), const Failure<AdoptionRequest>(NotFound()));
    });

    test('an approved request cannot be withdrawn', () async {
      final approved = request('r-ana', ana, status: AdoptionRequestStatus.approved);
      final withdraw = WithdrawRequest(requests: InMemoryRequests([approved]), clock: clock);

      expect(await withdraw(id: approved.id, by: ana), const Failure<AdoptionRequest>(WithdrawNotAllowed()));
    });

    test('when the request is approved meanwhile, the reason comes from the fresh state', () async {
      final requests = RequestsChangedMeanwhile([anas], changeTo: AdoptionRequestStatus.approved);
      final withdraw = WithdrawRequest(requests: requests, clock: clock);

      expect(await withdraw(id: anas.id, by: ana), const Failure<AdoptionRequest>(WithdrawNotAllowed()));
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.approved);
    });
  });

  group('RejectRequest', () {
    test('the coordinator rejects a pending request', () async {
      final requests = InMemoryRequests([anas]);
      final reject = RejectRequest(requests: requests);

      expect(
        await reject(id: anas.id, by: coordinator),
        Success(anas.copyWith(status: AdoptionRequestStatus.rejected)),
      );
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.rejected);
    });

    test('an adopter may not reject', () async {
      final reject = RejectRequest(requests: InMemoryRequests([anas]));

      expect(await reject(id: anas.id, by: ana), const Failure<AdoptionRequest>(NotAllowed()));
    });

    test('when someone else decides first, the late call is told the request is no longer pending', () async {
      final requests = RequestsChangedMeanwhile([anas], changeTo: AdoptionRequestStatus.approved);
      final reject = RejectRequest(requests: requests);

      expect(await reject(id: anas.id, by: coordinator), const Failure<AdoptionRequest>(InvalidRequestTransition()));
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.approved);
    });
  });

  Animal animal(String id, AnimalStatus status) => Animal(
    id: AnimalId(id),
    name: AnimalName.parse('Rex').valueOrNull!,
    species: Species.dog,
    birthDate: DateTime.utc(2022, 5, 10),
    description: 'Miran pas.',
    enclosureId: const EnclosureId('B-1'),
    status: status,
    receivedAt: DateTime.utc(2026, 8, 1),
  );

  final rex = animal('a-rex', ReadyForAdoption(since: DateTime.utc(2026, 9, 1)));

  group('SubmitRequest', () {
    SubmitRequest submitWith(InMemoryRequests requests, List<Animal> animals) =>
        SubmitRequest(requests: requests, animals: InMemoryAnimals(animals), clock: clock, newId: () => 'r-new');

    test('an adopter sends a request that is saved with the time from the clock', () async {
      final requests = InMemoryRequests([]);
      final submit = submitWith(requests, [rex]);

      final result = await submit(animalId: rex.id, motivation: motivation, by: ana);

      final expected = AdoptionRequest(
        id: const AdoptionRequestId('r-new'),
        animalId: rex.id,
        applicantId: ana.id,
        motivation: motivation,
        createdAt: clock.now(),
      );
      expect(result, Success(expected));
      expect(requests.stored(expected.id), expected);
    });

    test('an animal that does not exist is not found', () async {
      final submit = submitWith(InMemoryRequests([]), []);

      expect(
        await submit(animalId: rex.id, motivation: motivation, by: ana),
        const Failure<AdoptionRequest>(NotFound()),
      );
    });

    test('P3: a third active request is refused', () async {
      final luna = animal('a-luna', ReadyForAdoption(since: DateTime.utc(2026, 9, 1)));
      final bobi = animal('a-bobi', ReadyForAdoption(since: DateTime.utc(2026, 9, 1)));
      final requests = InMemoryRequests([
        AdoptionRequest(
          id: const AdoptionRequestId('r-1'),
          animalId: luna.id,
          applicantId: ana.id,
          motivation: motivation,
          createdAt: DateTime.utc(2026, 11, 1),
        ),
        AdoptionRequest(
          id: const AdoptionRequestId('r-2'),
          animalId: bobi.id,
          applicantId: ana.id,
          motivation: motivation,
          createdAt: DateTime.utc(2026, 11, 2),
          status: AdoptionRequestStatus.approved,
        ),
      ]);
      final submit = submitWith(requests, [rex, luna, bobi]);

      expect(
        await submit(animalId: rex.id, motivation: motivation, by: ana),
        const Failure<AdoptionRequest>(TooManyActiveRequests(max: 2)),
      );
      expect(await requests.requests(applicant: ana.id), hasLength(2));
    });

    test('an animal that is not ready for adoption is refused', () async {
      final quarantined = animal(
        'a-rex',
        InQuarantine(since: DateTime.utc(2026, 11, 1), until: DateTime.utc(2026, 11, 15)),
      );
      final submit = submitWith(InMemoryRequests([]), [quarantined]);

      expect(
        await submit(animalId: quarantined.id, motivation: motivation, by: ana),
        const Failure<AdoptionRequest>(AnimalNotAdoptable()),
      );
    });
  });

  group('ApproveRequest', () {
    const jelena = User(id: UserId('u-jelena'), name: 'Jelena', role: Role.adopter);
    final jelenas = request('r-jelena', jelena);

    test('P5: approving one request reserves the animal and rejects the other pending requests', () async {
      final requests = InMemoryRequests([anas, markos, jelenas]);
      final approve = ApproveRequest(requests: requests, animals: InMemoryAnimals([rex]), clock: clock);

      final result = await approve(id: markos.id, by: coordinator);

      expect(
        result.valueOrNull?.animal.status,
        Reserved(requestId: markos.id, approvedBy: coordinator.id, at: clock.now()),
      );
      expect(requests.stored(markos.id).status, AdoptionRequestStatus.approved);
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.rejected);
      expect(requests.stored(jelenas.id).status, AdoptionRequestStatus.rejected);
    });

    test('an adopter may not approve', () async {
      final requests = InMemoryRequests([anas, markos]);
      final approve = ApproveRequest(requests: requests, animals: InMemoryAnimals([rex]), clock: clock);

      expect(await approve(id: anas.id, by: ana), const Failure<ApprovalOutcome>(NotAllowed()));
      expect(requests.stored(anas.id).status, AdoptionRequestStatus.pending);
    });

    test('approving the same request again is refused because it is no longer pending', () async {
      final requests = InMemoryRequests([anas, markos]);
      final approve = ApproveRequest(requests: requests, animals: InMemoryAnimals([rex]), clock: clock);

      await approve(id: anas.id, by: coordinator);

      expect(await approve(id: anas.id, by: coordinator), const Failure<ApprovalOutcome>(InvalidRequestTransition()));
    });
  });
}
