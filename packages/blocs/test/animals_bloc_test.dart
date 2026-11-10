import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fake_shelter_repository.dart';

void main() {
  Animal animal(String id, AnimalStatus status) => Animal(
    id: AnimalId(id),
    name: AnimalName.parse('Rex $id').valueOrNull!,
    species: Species.dog,
    birthDate: DateTime(2022, 5, 10),
    description: 'Miran pas.',
    enclosureId: const EnclosureId('e-1'),
    status: status,
    receivedAt: DateTime(2026, 8, 1),
  );

  final ready = animal('a-1', ReadyForAdoption(since: DateTime(2026, 9, 1)));
  final resident = animal('a-2', const PermanentResident(reason: 'Starost'));

  /// The use cases' clock. In UTC, because [FixedClock] returns UTC and a local DateTime is never == a UTC one.
  final now = DateTime.utc(2026, 11, 2, 10);

  late FakeShelterRepository repository;

  /// Builds the bloc over [repo] with every use case it needs; a new animal gets the id `a-new`.
  AnimalsBloc blocWith(FakeShelterRepository repo, {AnimalsFilter initialFilter = AnimalsFilter.all}) {
    repository = repo;
    final clock = FixedClock(now);
    return AnimalsBloc(
      getAnimals: GetAnimals(animals: repo),
      intakeAnimal: IntakeAnimal(animals: repo, clock: clock, newId: () => 'a-new'),
      startQuarantine: StartQuarantine(animals: repo, clock: clock),
      endQuarantine: EndQuarantine(animals: repo, clock: clock),
      initialFilter: initialFilter,
    );
  }

  blocTest<AnimalsBloc, AnimalsState>(
    'loads animals',
    build: () => blocWith(FakeShelterRepository(animals: [ready, resident])),
    act: (bloc) => bloc.add(const AnimalsRequested()),
    expect: () => [
      const AnimalsLoading(),
      AnimalsLoaded(animals: [ready, resident], filter: AnimalsFilter.all),
    ],
  );

  blocTest<AnimalsBloc, AnimalsState>(
    'fails, then retries',
    build: () => blocWith(FakeShelterRepository(animals: [ready])..failNextRequest()),
    act: (bloc) async {
      bloc.add(const AnimalsRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AnimalsRetried());
    },
    expect: () => [
      const AnimalsLoading(),
      isA<AnimalsFailure>(),
      const AnimalsLoading(),
      AnimalsLoaded(animals: [ready], filter: AnimalsFilter.all),
    ],
  );

  blocTest<AnimalsBloc, AnimalsState>(
    'filters, shows empty, keeps selection',
    build: () => blocWith(FakeShelterRepository(animals: [ready, resident])),
    act: (bloc) async {
      bloc.add(const AnimalsRequested());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(AnimalSelected(ready.id))
        ..add(const AnimalsFilterChanged(AnimalsFilter.readyForAdoption))
        ..add(const AnimalsFilterChanged(AnimalsFilter.adopted));
    },
    skip: 2,
    expect: () => [
      AnimalsLoaded(animals: [ready, resident], filter: AnimalsFilter.all, selectedId: ready.id),
      AnimalsLoaded(animals: [ready], filter: AnimalsFilter.readyForAdoption, selectedId: ready.id),
      const AnimalsEmpty(AnimalsFilter.adopted),
    ],
  );

  blocTest<AnimalsBloc, AnimalsState>(
    'refresh reloads without showing the spinner',
    build: () => blocWith(FakeShelterRepository(animals: [ready])),
    act: (bloc) async {
      bloc.add(const AnimalsRequested());
      await Future<void>.delayed(Duration.zero);
      await repository.saveAnimal(ready.copyWith(status: resident.status));
      bloc.add(const AnimalsRefreshed());
    },
    expect: () => [
      const AnimalsLoading(),
      AnimalsLoaded(animals: [ready], filter: AnimalsFilter.all),
      AnimalsLoaded(
        animals: [ready.copyWith(status: resident.status)],
        filter: AnimalsFilter.all,
      ),
    ],
  );

  blocTest<AnimalsBloc, AnimalsState>(
    'a failed refresh keeps the current list',
    build: () => blocWith(FakeShelterRepository(animals: [ready])),
    act: (bloc) async {
      bloc.add(const AnimalsRequested());
      await Future<void>.delayed(Duration.zero);
      repository.failNextRequest();
      bloc.add(const AnimalsRefreshed());
    },
    expect: () => [
      const AnimalsLoading(),
      AnimalsLoaded(animals: [ready], filter: AnimalsFilter.all),
    ],
  );

  group('intake', () {
    const coordinator = User(id: UserId('u-coord'), name: 'koordinator', role: Role.coordinator);
    const vet = User(id: UserId('u-vet'), name: 'veterinar', role: Role.veterinarian);

    AnimalIntakeSubmitted intake({User by = coordinator, String name = 'Mrki'}) => AnimalIntakeSubmitted(
      by: by,
      name: name,
      species: Species.dog,
      birthDate: DateTime(2025, 5, 1),
      description: 'Pronađen kraj puta.',
      enclosureId: const EnclosureId('e-1'),
    );

    final mrki = Animal(
      id: const AnimalId('a-new'),
      name: AnimalName.parse('Mrki').valueOrNull!,
      species: Species.dog,
      birthDate: DateTime(2025, 5, 1),
      description: 'Pronađen kraj puta.',
      enclosureId: const EnclosureId('e-1'),
      status: Received(receivedBy: coordinator.id, at: now),
      receivedAt: now,
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'saves the new animal as Received, shows every animal and reports it',
      build: () => blocWith(FakeShelterRepository(animals: [ready]), initialFilter: AnimalsFilter.readyForAdoption),
      act: (bloc) async {
        bloc.add(const AnimalsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(intake());
      },
      skip: 2,
      expect: () => [
        AnimalsLoaded(animals: [ready, mrki], filter: AnimalsFilter.all, notice: AnimalSaved(mrki)),
      ],
      verify: (_) async => expect(await repository.animals(), [ready, mrki]),
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'a name that breaks P1 is refused and nothing is saved',
      build: () => blocWith(FakeShelterRepository(animals: [ready])),
      act: (bloc) async {
        bloc.add(const AnimalsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(intake(name: 'M'));
      },
      skip: 2,
      expect: () => [
        AnimalsLoaded(animals: [ready], filter: AnimalsFilter.all, notice: const AnimalRefused(NameTooShort())),
      ],
      verify: (_) async => expect(await repository.animals(), [ready]),
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'only the coordinator may take in an animal',
      build: () => blocWith(FakeShelterRepository(animals: [ready])),
      act: (bloc) async {
        bloc.add(const AnimalsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(intake(by: vet));
      },
      skip: 2,
      expect: () => [
        AnimalsLoaded(animals: [ready], filter: AnimalsFilter.all, notice: const AnimalRefused(NotAllowed())),
      ],
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'acknowledging the notice clears it',
      build: () => blocWith(FakeShelterRepository(animals: [ready])),
      act: (bloc) async {
        bloc.add(const AnimalsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(intake(name: 'M'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AnimalsNoticeAcknowledged());
      },
      skip: 3,
      expect: () => [
        AnimalsLoaded(animals: [ready], filter: AnimalsFilter.all),
      ],
    );

    test('enclosures lists every enclosure in use once, sorted', () async {
      final other = resident.copyWith(enclosureId: const EnclosureId('a-0'));
      final bloc = blocWith(FakeShelterRepository(animals: [ready, other, ready]))..add(const AnimalsRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.enclosures, const [EnclosureId('a-0'), EnclosureId('e-1')]);
      await bloc.close();
    });
  });

  group('quarantine', () {
    const coordinator = User(id: UserId('u-coord'), name: 'koordinator', role: Role.coordinator);
    const vet = User(id: UserId('u-vet'), name: 'veterinar', role: Role.veterinarian);
    final until = DateTime.utc(2026, 11, 16);
    final received = animal('a-3', Received(receivedBy: coordinator.id, at: DateTime(2026, 11, 1)));
    final quarantined = animal('a-4', InQuarantine(since: DateTime(2026, 10, 20), until: DateTime(2026, 11, 3)));

    Future<void> loaded(AnimalsBloc bloc) async {
      bloc.add(const AnimalsRequested());
      await Future<void>.delayed(Duration.zero);
    }

    blocTest<AnimalsBloc, AnimalsState>(
      'starting it moves a received animal into quarantine until the chosen day',
      build: () => blocWith(FakeShelterRepository(animals: [received])),
      act: (bloc) async {
        await loaded(bloc);
        bloc.add(QuarantineStarted(animalId: received.id, by: coordinator, until: until));
      },
      skip: 2,
      expect: () {
        final changed = received.copyWith(
          status: InQuarantine(since: now, until: until),
        );
        return [
          AnimalsLoaded(animals: [changed], filter: AnimalsFilter.all, notice: AnimalSaved(changed)),
        ];
      },
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'an animal that is already ready cannot go into quarantine',
      build: () => blocWith(FakeShelterRepository(animals: [ready])),
      act: (bloc) async {
        await loaded(bloc);
        bloc.add(QuarantineStarted(animalId: ready.id, by: coordinator, until: until));
      },
      skip: 2,
      expect: () => [
        AnimalsLoaded(
          animals: [ready],
          filter: AnimalsFilter.all,
          notice: AnimalRefused(
            InvalidTransition(
              from: ready.status,
              to: InQuarantine(since: now, until: until),
            ),
          ),
        ),
      ],
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'the veterinarian ends it and the animal becomes ready for adoption',
      build: () => blocWith(FakeShelterRepository(animals: [quarantined])),
      act: (bloc) async {
        await loaded(bloc);
        bloc.add(QuarantineEnded(animalId: quarantined.id, by: vet));
      },
      skip: 2,
      expect: () {
        final changed = quarantined.copyWith(status: ReadyForAdoption(since: now));
        return [
          AnimalsLoaded(animals: [changed], filter: AnimalsFilter.all, notice: AnimalSaved(changed)),
        ];
      },
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'the veterinarian may not start a quarantine',
      build: () => blocWith(FakeShelterRepository(animals: [received])),
      act: (bloc) async {
        await loaded(bloc);
        bloc.add(QuarantineStarted(animalId: received.id, by: vet, until: until));
      },
      skip: 2,
      expect: () => [
        AnimalsLoaded(animals: [received], filter: AnimalsFilter.all, notice: const AnimalRefused(NotAllowed())),
      ],
    );

    blocTest<AnimalsBloc, AnimalsState>(
      'an animal changed by someone else in the meantime is refused, not overwritten',
      build: () => blocWith(FakeShelterRepository(animals: [quarantined])),
      act: (bloc) async {
        await loaded(bloc);
        // Another staff member ends the quarantine first, so the bloc's own end sees a different status.
        await repository.saveAnimal(quarantined.copyWith(status: ReadyForAdoption(since: now)));
        bloc.add(QuarantineEnded(animalId: quarantined.id, by: vet));
      },
      skip: 2,
      expect: () => [isA<AnimalsLoaded>().having((state) => state.notice, 'notice', isA<AnimalRefused>())],
    );
  });
}
