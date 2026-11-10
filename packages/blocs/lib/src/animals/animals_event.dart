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

final class AnimalIntakeSubmitted extends AnimalsEvent {
  const AnimalIntakeSubmitted({
    required this.by,
    required this.name,
    required this.species,
    required this.birthDate,
    required this.description,
    required this.enclosureId,
  });

  final User by;
  final String name;
  final Species species;
  final DateTime birthDate;
  final String description;
  final EnclosureId enclosureId;
}

final class QuarantineStarted extends AnimalsEvent {
  const QuarantineStarted({required this.animalId, required this.by, required this.until});

  final AnimalId animalId;
  final User by;
  final DateTime until;
}

final class QuarantineEnded extends AnimalsEvent {
  const QuarantineEnded({required this.animalId, required this.by});

  final AnimalId animalId;
  final User by;
}

final class AnimalsNoticeAcknowledged extends AnimalsEvent {
  const AnimalsNoticeAcknowledged();
}
