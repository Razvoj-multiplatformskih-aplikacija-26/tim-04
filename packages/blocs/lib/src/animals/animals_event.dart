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

final class AnimalsFilterChanged extends AnimalsEvent {
  const AnimalsFilterChanged(this.filter);

  final AnimalsFilter filter;
}

final class AnimalSelected extends AnimalsEvent {
  const AnimalSelected(this.id);

  final AnimalId? id;
}
