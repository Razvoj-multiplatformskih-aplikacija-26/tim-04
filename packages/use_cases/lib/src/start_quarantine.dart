import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/animal_repository.dart';

final class StartQuarantine {
  const StartQuarantine({required this.animals, required this.clock});

  final AnimalRepository animals;
  final Clock clock;

  Future<Result<Animal>> call({required AnimalId id, required User by, required DateTime until}) async {
    final animal = await animals.find(id);
    if (animal == null) return const Failure(NotFound());
    switch (startQuarantine(animal: animal, by: by, now: clock.now(), until: until)) {
      case Failure(:final error):
        return Failure(error);
      case Success(value: final changed):
        return animals.save(changed, from: animal.status);
    }
  }
}
