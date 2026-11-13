import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_shelter_repository.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  BackofficeDependencies({
    required AnimalRepository animals,
    required AdoptionRequestRepository requests,
    required this.user,
    required this.clock,
    required this.newId,
    this.users = const [],
    this.fakeRepository,
  }) : getAnimals = GetAnimals(animals: animals),
       intakeAnimal = IntakeAnimal(animals: animals, clock: clock, newId: () => 'a-${newId()}'),
       startQuarantine = StartQuarantine(animals: animals, clock: clock),
       endQuarantine = EndQuarantine(animals: animals, clock: clock),
       getRequests = GetRequests(requests: requests),
       submitRequest = SubmitRequest(requests: requests, animals: animals, clock: clock, newId: newId),
       withdrawRequest = WithdrawRequest(requests: requests, clock: clock),
       approveRequest = ApproveRequest(
         requests: requests,
         animals: animals,
         clock: clock,
         notifier: const NoopNotifier(),
       ),
       rejectRequest = RejectRequest(requests: requests, notifier: const NoopNotifier());

  factory BackofficeDependencies.fake() {
    final fake = FakeShelterRepository();
    var nextId = 0;

    return BackofficeDependencies(
      animals: fake,
      user: coordinator,
      clock: const SystemClock(),
      newId: () => 'new-${++nextId}',
      users: seedUsers,
      fakeRepository: fake,
      requests: FakeAdoptionRequestRepository(fake),
    );
  }

  final User user;
  final Clock clock;
  final String Function() newId;

  final GetAnimals getAnimals;
  final IntakeAnimal intakeAnimal;
  final StartQuarantine startQuarantine;
  final EndQuarantine endQuarantine;

  final List<User> users;
  final FakeShelterRepository? fakeRepository;

  final GetRequests getRequests;
  final SubmitRequest submitRequest;
  final WithdrawRequest withdrawRequest;
  final ApproveRequest approveRequest;
  final RejectRequest rejectRequest;

  String nameOf(UserId id) => users.where((u) => u.id == id).firstOrNull?.name ?? id.value;
}
