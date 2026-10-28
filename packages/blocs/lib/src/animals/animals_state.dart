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
  const AnimalsLoaded({required this.animals, required this.filter, this.selectedId});

  final List<Animal> animals;
  final AnimalsFilter filter;
  final AnimalId? selectedId;

  Animal? get selected => animals.where((a) => a.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [animals, filter, selectedId];
}
