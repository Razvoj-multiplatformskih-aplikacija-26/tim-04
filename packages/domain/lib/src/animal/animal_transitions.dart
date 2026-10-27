import '../adoption/access_policy.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import '../user.dart';
import 'animal.dart';
import 'animal_name.dart';
import 'animal_status.dart';

Result<Animal> startQuarantine({
  required Animal animal,
  required User by,
  required DateTime now,
  required DateTime until,
}) {
  if (!AccessPolicy.canChangeAnimalStatus(by)) return const Failure(NotAllowed());
  final quarantine = InQuarantine(since: now, until: until);
  if (!canTransition(animal.status, quarantine)) return Failure(InvalidTransition(from: animal.status, to: quarantine));
  return Success(animal.copyWith(status: quarantine));
}

Result<Animal> endQuarantine({required Animal animal, required User by, required DateTime now}) {
  if (!AccessPolicy.canEndQuarantine(by)) return const Failure(NotAllowed());
  final ready = ReadyForAdoption(since: now);
  if (animal.status is! InQuarantine) return Failure(InvalidTransition(from: animal.status, to: ready));
  return Success(animal.copyWith(status: ready));
}

Result<Animal> intakeAnimal({
  required AnimalId id,
  required User by,
  required String name,
  required Species species,
  required DateTime birthDate,
  required String description,
  required EnclosureId enclosureId,
  required DateTime now,
}) {
  if (!AccessPolicy.canIntake(by)) return const Failure(NotAllowed());

  final parsed = AnimalName.parse(name);
  final animalName = parsed.valueOrNull;
  if (animalName == null) return Failure(parsed.errorOrNull!);

  return Success(
    Animal(
      id: id,
      name: animalName,
      species: species,
      birthDate: birthDate,
      description: description,
      enclosureId: enclosureId,
      status: Received(receivedBy: by.id, at: now),
      receivedAt: now,
    ),
  );
}
