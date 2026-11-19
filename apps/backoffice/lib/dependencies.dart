import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_sessions.dart';
import 'data/fake_shelter_repository.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  BackofficeDependencies({
    required AnimalRepository animals,
    required AdoptionRequestRepository requests,
    required SessionRepository sessions,
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
       rejectRequest = RejectRequest(requests: requests, notifier: const NoopNotifier()),
       logIn = LogIn(sessions: sessions),
       restoreSession = RestoreSession(sessions: sessions),
       logOut = LogOut(sessions: sessions),
       sessionExpirations = sessions.expirations;

  factory BackofficeDependencies.server({required Uri baseUri}) {
    final api = ApiClient(baseUri: baseUri);
    var nextId = 0;
    return BackofficeDependencies(
      animals: HttpAnimalRepository(api),
      requests: HttpAdoptionRequestRepository(api),
      sessions: HttpSessionRepository(api),
      clock: const SystemClock(),
      newId: () => 'new-${++nextId}',
      users: seedUsers,
    );
  }

  factory BackofficeDependencies.fake({User? signedIn = coordinator}) {
    final fake = FakeShelterRepository();
    var nextId = 0;

    return BackofficeDependencies(
      animals: fake,
      sessions: FakeSessions(signedIn: signedIn),
      clock: const SystemClock(),
      newId: () => 'new-${++nextId}',
      users: seedUsers,
      fakeRepository: fake,
      requests: FakeAdoptionRequestRepository(fake),
    );
  }

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

  final LogIn logIn;
  final RestoreSession restoreSession;
  final LogOut logOut;
  final Stream<void> sessionExpirations;

  String nameOf(UserId id) => users.where((u) => u.id == id).firstOrNull?.name ?? id.value;
}
