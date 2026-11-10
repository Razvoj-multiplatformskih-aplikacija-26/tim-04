import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/animal_repository.dart';

final class EndQuarantine {
  const EndQuarantine({required this.animals, required this.clock});

  final AnimalRepository animals;
  final Clock clock;

  Future<Result<Animal>> call({required AnimalId id, required User by}) async {
    final animal = await animals.find(id);
    if (animal == null) return const Failure(NotFound());
    switch (endQuarantine(animal: animal, by: by, now: clock.now())) {
      case Failure(:final error):
        return Failure(error);
      case Success(value: final changed):
        return animals.save(changed, from: animal.status);
    }
  }
}
