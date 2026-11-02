part of 'animals_bloc.dart';

sealed class AnimalsEvent {
  const AnimalsEvent();
}

final class AnimalsRequested extends AnimalsEvent {
  const AnimalsRequested();
}

final class AnimalsRetried extends AnimalsEvent {
  const AnimalsRetried();
}

/// Reloads the animals in the background after another bloc changed them (e.g. an approved request reserved one).
///
/// Unlike [AnimalsRequested] it keeps the current list on screen instead of showing [AnimalsLoading].
final class AnimalsRefreshed extends AnimalsEvent {
  const AnimalsRefreshed();
}

final class AnimalsFilterChanged extends AnimalsEvent {
  const AnimalsFilterChanged(this.filter);

  final AnimalsFilter filter;
}

final class AnimalSelected extends AnimalsEvent {
  const AnimalSelected(this.id);

  final AnimalId? id;
}

/// The intake form was submitted: [intakeAnimal] checks the rules (P1 and who may do it), then the animal is saved.
final class AnimalIntakeSubmitted extends AnimalsEvent {
  const AnimalIntakeSubmitted({
    required this.id,
    required this.by,
    required this.name,
    required this.species,
    required this.birthDate,
    required this.description,
    required this.enclosureId,
    required this.now,
  });

  final AnimalId id;
  final User by;
  final String name;
  final Species species;
  final DateTime birthDate;
  final String description;
  final EnclosureId enclosureId;
  final DateTime now;
}

/// Received (or Returned) → InQuarantine until [until]. Only the coordinator may start it.
final class QuarantineStarted extends AnimalsEvent {
  const QuarantineStarted({required this.animalId, required this.by, required this.now, required this.until});

  final AnimalId animalId;
  final User by;
  final DateTime now;
  final DateTime until;
}

/// InQuarantine → ReadyForAdoption. The coordinator or the veterinarian may end it.
final class QuarantineEnded extends AnimalsEvent {
  const QuarantineEnded({required this.animalId, required this.by, required this.now});

  final AnimalId animalId;
  final User by;
  final DateTime now;
}

/// The screen has shown the [AnimalsLoaded.notice]; clear it so the same message can appear again later.
final class AnimalsNoticeAcknowledged extends AnimalsEvent {
  const AnimalsNoticeAcknowledged();
}
