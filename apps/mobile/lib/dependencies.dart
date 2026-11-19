import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_shelter_repository.dart';
import 'data/seed.dart';

final class AppDependencies {
  const AppDependencies({required this.animals, required this.requests, this.user = currentUser, this.fakeRepository});

  factory AppDependencies.server({required Uri baseUri}) {
    final api = ApiClient(baseUri: baseUri, devUser: currentUser.id.value);
    return AppDependencies(animals: HttpAnimalRepository(api), requests: HttpAdoptionRequestRepository(api));
  }

  factory AppDependencies.fake([FakeShelterRepository? repository]) {
    final fake = repository ?? FakeShelterRepository();
    return AppDependencies(animals: fake, requests: FakeAdoptionRequestRepository(fake), fakeRepository: fake);
  }

  final AnimalRepository animals;
  final AdoptionRequestRepository requests;
  final User user;
  final FakeShelterRepository? fakeRepository;
}
