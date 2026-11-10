import 'package:domain/domain.dart';

import 'ports/animal_repository.dart';

final class GetAnimals {
  const GetAnimals({required this.animals});

  final AnimalRepository animals;

  Future<List<Animal>> call() => animals.animals();
}
