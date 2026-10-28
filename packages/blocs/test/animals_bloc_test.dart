import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

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

  blocTest<AnimalsBloc, AnimalsState>(
    'loads animals',
    build: () => AnimalsBloc(repository: FakeShelterRepository(animals: [ready, resident])),
    act: (bloc) => bloc.add(const AnimalsRequested()),
    expect: () => [
      const AnimalsLoading(),
      AnimalsLoaded(animals: [ready, resident], filter: AnimalsFilter.all),
    ],
  );

  blocTest<AnimalsBloc, AnimalsState>(
    'fails, then retries',
    build: () => AnimalsBloc(repository: FakeShelterRepository(animals: [ready])..failNextRequest()),
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
    build: () => AnimalsBloc(repository: FakeShelterRepository(animals: [ready, resident])),
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
}
