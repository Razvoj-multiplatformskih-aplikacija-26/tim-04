import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/animal_repository.dart';

final class IntakeAnimal {
  const IntakeAnimal({required this.animals, required this.clock, required this.newId});

  final AnimalRepository animals;
  final Clock clock;
  final String Function() newId;

  Future<Result<Animal>> call({
    required User by,
    required String name,
    required Species species,
    required DateTime birthDate,
    required String description,
    required EnclosureId enclosureId,
  }) async {
    final result = intakeAnimal(
      id: AnimalId(newId()),
      by: by,
      name: name,
      species: species,
      birthDate: birthDate,
      description: description,
      enclosureId: enclosureId,
      now: clock.now(),
    );
    switch (result) {
      case Failure(:final error):
        return Failure(error);
      case Success(value: final animal):
        return animals.create(animal);
    }
  }
}
