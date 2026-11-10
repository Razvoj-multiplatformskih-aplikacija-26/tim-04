import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

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
}
