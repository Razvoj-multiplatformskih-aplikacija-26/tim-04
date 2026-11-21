import 'package:api_client/api_client.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_sessions.dart';
import 'data/fake_shelter_repository.dart';
import 'data/seed.dart';

final class AppDependencies {
  AppDependencies({
    required this.animals,
    required this.requests,
    required SessionRepository sessions,
    this.fakeRepository,
  }) : logIn = LogIn(sessions: sessions),
       restoreSession = RestoreSession(sessions: sessions),
       logOut = LogOut(sessions: sessions),
       sessionExpirations = sessions.expirations;

  factory AppDependencies.server({required Uri baseUri, required TokenStore tokens}) {
    final api = ApiClient(baseUri: baseUri, tokens: tokens);
    return AppDependencies(
      animals: HttpAnimalRepository(api),
      requests: HttpAdoptionRequestRepository(api),
      sessions: HttpSessionRepository(api),
    );
  }

  factory AppDependencies.fake({FakeShelterRepository? repository, SessionRepository? sessions}) {
    final fake = repository ?? FakeShelterRepository();
    return AppDependencies(
      animals: fake,
      requests: FakeAdoptionRequestRepository(fake),
      sessions: sessions ?? FakeSessions(signedIn: currentUser),
      fakeRepository: fake,
    );
  }

  final AnimalRepository animals;
  final AdoptionRequestRepository requests;
  final FakeShelterRepository? fakeRepository;
  final LogIn logIn;
  final RestoreSession restoreSession;
  final LogOut logOut;
  final Stream<void> sessionExpirations;
}
