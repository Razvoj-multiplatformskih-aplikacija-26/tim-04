import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fake_shelter_repository.dart';

void main() {
  const ana = User(id: UserId('u-ana'), username: 'ana', role: Role.adopter);
  const marko = User(id: UserId('u-marko'), username: 'marko', role: Role.adopter);
  const jelena = User(id: UserId('u-jelena'), username: 'jelena', role: Role.adopter);
  const coordinator = User(id: UserId('u-coord'), username: 'koordinator', role: Role.coordinator);

  final now = DateTime(2026, 10, 28);
  final motivation = RequestMotivation.parse('Imam dvorište i mnogo slobodnog vremena.').valueOrNull!;

  Animal animal(String id, String name) => Animal(
    id: AnimalId(id),
    name: AnimalName.parse(name).valueOrNull!,
    species: Species.dog,
    birthDate: DateTime(2022, 5, 10),
    description: 'Miran pas.',
    enclosureId: const EnclosureId('e-1'),
    status: ReadyForAdoption(since: DateTime(2026, 9, 1)),
    receivedAt: DateTime(2026, 8, 1),
  );

  final rex = animal('a-1', 'Rex');
  final luna = animal('a-2', 'Luna');
  final bobi = animal('a-3', 'Bobi');

  AdoptionRequest request(
    String id,
    User by,
    Animal animal, {
    AdoptionRequestStatus status = AdoptionRequestStatus.pending,
  }) => AdoptionRequest(
    id: AdoptionRequestId(id),
    animalId: animal.id,
    applicantId: by.id,
    motivation: motivation,
    createdAt: DateTime(2026, 10, 1),
    status: status,
  );

  final anasForRex = request('r-1', ana, rex);
  final markosForRex = request('r-2', marko, rex);
  final anasForLuna = request('r-3', ana, luna);
  final jelenasForRex = request('r-4', jelena, rex);

  late FakeShelterRepository repo;

  AdoptionRequestBloc blocWith(User user, List<AdoptionRequest> requests) {
    repo = FakeShelterRepository(animals: [rex, luna, bobi], requests: requests);
    return AdoptionRequestBloc(repository: repo, user: user, clock: () => now, newId: () => 'r-new');
  }

  group('loading', () {
    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'adopter sees only their own requests',
      build: () => blocWith(ana, [anasForRex, markosForRex, anasForLuna]),
      act: (bloc) => bloc.add(const MyRequestsRequested()),
      expect: () => [
        const RequestsLoading(),
        RequestsLoaded(requests: [anasForRex, anasForLuna]),
      ],
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'coordinator sees every request',
      build: () => blocWith(coordinator, [anasForRex, markosForRex]),
      act: (bloc) => bloc.add(const MyRequestsRequested()),
      expect: () => [
        const RequestsLoading(),
        RequestsLoaded(requests: [anasForRex, markosForRex]),
      ],
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'fails, then loads again',
      build: () {
        final bloc = blocWith(ana, [anasForRex]);
        repo.failNextRequest();
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const MyRequestsRequested());
      },
      expect: () => [
        const RequestsLoading(),
        isA<RequestsFailure>(),
        const RequestsLoading(),
        RequestsLoaded(requests: [anasForRex]),
      ],
    );
  });

  group('submit (P3)', () {
    final anasForLunaNew = AdoptionRequest(
      id: const AdoptionRequestId('r-new'),
      animalId: luna.id,
      applicantId: ana.id,
      motivation: motivation,
      createdAt: now,
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'adds a new pending request',
      build: () => blocWith(ana, [anasForRex]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestSubmitted(luna.id, motivation));
      },
      skip: 2,
      expect: () => [
        RequestsLoaded(requests: [anasForRex], busy: true),
        RequestsLoaded(requests: [anasForRex, anasForLunaNew], notice: RequestSaved(anasForLunaNew)),
      ],
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'refuses a third active request and keeps the list',
      build: () => blocWith(ana, [anasForRex, anasForLuna]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestSubmitted(bobi.id, motivation));
      },
      skip: 2,
      expect: () => [
        RequestsLoaded(requests: [anasForRex, anasForLuna], busy: true),
        RequestsLoaded(requests: [anasForRex, anasForLuna], notice: const RequestRefused(TooManyActiveRequests())),
      ],
      verify: (_) async => expect(await repo.requests(), hasLength(2)),
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'reports the same refusal again after the notice is acknowledged',
      build: () => blocWith(ana, [anasForRex, anasForLuna]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestSubmitted(bobi.id, motivation));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestsNoticeAcknowledged());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestSubmitted(bobi.id, motivation));
      },
      skip: 2,
      expect: () => [
        RequestsLoaded(requests: [anasForRex, anasForLuna], busy: true),
        RequestsLoaded(requests: [anasForRex, anasForLuna], notice: const RequestRefused(TooManyActiveRequests())),
        RequestsLoaded(requests: [anasForRex, anasForLuna]),
        RequestsLoaded(requests: [anasForRex, anasForLuna], busy: true),
        RequestsLoaded(requests: [anasForRex, anasForLuna], notice: const RequestRefused(TooManyActiveRequests())),
      ],
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'keeps the list and reports a failed submission',
      build: () => blocWith(ana, [anasForRex]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        repo.failNextRequest();
        bloc.add(RequestSubmitted(luna.id, motivation));
      },
      skip: 2,
      expect: () => [
        RequestsLoaded(requests: [anasForRex], busy: true),
        isA<RequestsLoaded>()
            .having((state) => state.requests, 'requests', [anasForRex])
            .having((state) => state.notice, 'notice', isA<RequestFailed>()),
      ],
    );
  });

  group('withdraw (P4)', () {
    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'withdraws a pending request',
      build: () => blocWith(ana, [anasForRex]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestWithdrawn(anasForRex.id));
      },
      skip: 2,
      expect: () {
        final withdrawn = anasForRex.copyWith(status: AdoptionRequestStatus.withdrawn);
        return [
          RequestsLoaded(requests: [anasForRex], busy: true),
          RequestsLoaded(requests: [withdrawn], notice: RequestSaved(withdrawn)),
        ];
      },
    );

    final approved = request('r-1', ana, rex, status: AdoptionRequestStatus.approved);

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'cannot withdraw an approved request',
      build: () => blocWith(ana, [approved]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestWithdrawn(approved.id));
      },
      skip: 2,
      expect: () => [
        RequestsLoaded(requests: [approved], busy: true),
        RequestsLoaded(requests: [approved], notice: const RequestRefused(WithdrawNotAllowed())),
      ],
    );
  });

  group('approve (P5)', () {
    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'approves one request, rejects the competing ones and reserves the animal',
      build: () => blocWith(coordinator, [anasForRex, markosForRex, jelenasForRex]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestApproved(anasForRex.id));
      },
      skip: 2,
      expect: () {
        final approved = anasForRex.copyWith(status: AdoptionRequestStatus.approved);
        return [
          RequestsLoaded(requests: [anasForRex, markosForRex, jelenasForRex], busy: true),
          RequestsLoaded(
            requests: [
              approved,
              markosForRex.copyWith(status: AdoptionRequestStatus.rejected),
              jelenasForRex.copyWith(status: AdoptionRequestStatus.rejected),
            ],
            notice: RequestSaved(approved),
          ),
        ];
      },
      verify: (_) async {
        final saved = await repo.animal(rex.id);
        expect(saved.status, Reserved(requestId: anasForRex.id, approvedBy: coordinator.id, at: now));
      },
    );

    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'adopter is not allowed to approve',
      build: () => blocWith(ana, [anasForRex]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestApproved(anasForRex.id));
      },
      skip: 2,
      expect: () => [
        RequestsLoaded(requests: [anasForRex], busy: true),
        RequestsLoaded(requests: [anasForRex], notice: const RequestRefused(NotAllowed())),
      ],
    );
  });

  group('reject (P6)', () {
    blocTest<AdoptionRequestBloc, AdoptionRequestState>(
      'rejects a pending request',
      build: () => blocWith(coordinator, [anasForRex]),
      act: (bloc) async {
        bloc.add(const MyRequestsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(RequestRejected(anasForRex.id));
      },
      skip: 2,
      expect: () {
        final rejected = anasForRex.copyWith(status: AdoptionRequestStatus.rejected);
        return [
          RequestsLoaded(requests: [anasForRex], busy: true),
          RequestsLoaded(requests: [rejected], notice: RequestSaved(rejected)),
        ];
      },
    );
  });
}
