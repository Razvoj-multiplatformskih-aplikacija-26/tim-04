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
