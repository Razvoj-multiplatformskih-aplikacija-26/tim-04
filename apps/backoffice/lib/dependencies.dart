import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'data/fake_shelter_repository.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  const BackofficeDependencies({
    required this.repository,
    required this.user,
    required this.clock,
    required this.newId,
    this.fakeRepository,
  });

  factory BackofficeDependencies.fake() {
    final fake = FakeShelterRepository();
    var nextId = 0;
    return BackofficeDependencies(
      repository: fake,
      user: coordinator,
      clock: DateTime.now,
      newId: () => 'r-new-${++nextId}',
      fakeRepository: fake,
    );
  }

  final ShelterRepository repository;
  final User user;
  final DateTime Function() clock;
  final String Function() newId;
  final FakeShelterRepository? fakeRepository;
}
