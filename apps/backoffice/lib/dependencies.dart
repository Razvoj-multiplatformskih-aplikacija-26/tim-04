import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_shelter_repository.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  BackofficeDependencies({
    required this.repository,
    required AnimalRepository animals,
    required this.user,
    required this.clock,
    required this.newId,
    this.users = const [],
    this.fakeRepository,
  }) : getAnimals = GetAnimals(animals: animals),
       intakeAnimal = IntakeAnimal(animals: animals, clock: clock, newId: () => 'a-${newId()}'),
       startQuarantine = StartQuarantine(animals: animals, clock: clock),
       endQuarantine = EndQuarantine(animals: animals, clock: clock);

  factory BackofficeDependencies.fake() {
    final fake = FakeShelterRepository();
    var nextId = 0;
    return BackofficeDependencies(
      repository: fake,
      animals: fake,
      user: coordinator,
      clock: const SystemClock(),
      newId: () => 'new-${++nextId}',
      users: seedUsers,
      fakeRepository: fake,
    );
  }

  final ShelterRepository repository;
  final User user;
  final Clock clock;
  final String Function() newId;

  final GetAnimals getAnimals;
  final IntakeAnimal intakeAnimal;
  final StartQuarantine startQuarantine;
  final EndQuarantine endQuarantine;

  final List<User> users;
  final FakeShelterRepository? fakeRepository;

  String nameOf(UserId id) => users.where((u) => u.id == id).firstOrNull?.name ?? id.value;
}
