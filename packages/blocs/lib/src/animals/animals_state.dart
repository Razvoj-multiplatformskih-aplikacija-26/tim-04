part of 'animals_bloc.dart';

sealed class AnimalsState extends Equatable {
  const AnimalsState();

  @override
  List<Object?> get props => [];
}

final class AnimalsLoading extends AnimalsState {
  const AnimalsLoading();
}

final class AnimalsFailure extends AnimalsState {
  const AnimalsFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}

final class AnimalsEmpty extends AnimalsState {
  const AnimalsEmpty(this.filter);

  final AnimalsFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class AnimalsLoaded extends AnimalsState {
  const AnimalsLoaded({required this.animals, required this.filter, this.selectedId, this.notice});

  final List<Animal> animals;
  final AnimalsFilter filter;
  final AnimalId? selectedId;

  /// The outcome of the last action (e.g. intake), shown once by the screen.
  final AnimalsNotice? notice;

  Animal? get selected => animals.where((a) => a.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [animals, filter, selectedId, notice];
}

sealed class AnimalsNotice extends Equatable {
  const AnimalsNotice();

  @override
  List<Object?> get props => [];
}

/// The animal was saved.
final class AnimalSaved extends AnimalsNotice {
  const AnimalSaved(this.animal);

  final Animal animal;

  @override
  List<Object?> get props => [animal];
}

/// A domain rule refused the action, e.g. [NotAllowed] or [NameTooShort].
final class AnimalRefused extends AnimalsNotice {
  const AnimalRefused(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

/// Saving failed (no connection, server error); the list stays as it was.
final class AnimalSaveFailed extends AnimalsNotice {
  const AnimalSaveFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
