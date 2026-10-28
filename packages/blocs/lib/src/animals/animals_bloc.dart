import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../shelter_repository.dart';
import 'animals_filter.dart';

part 'animals_event.dart';
part 'animals_state.dart';

final class AnimalsBloc extends Bloc<AnimalsEvent, AnimalsState> {
  AnimalsBloc({required this.repository, AnimalsFilter initialFilter = AnimalsFilter.all})
    : _filter = initialFilter,
      super(const AnimalsLoading()) {
    on<AnimalsRequested>((event, emit) => _load(emit));
    on<AnimalsRetried>((event, emit) => _load(emit));
    on<AnimalsFilterChanged>((event, emit) {
      _filter = event.filter;
      if (state is AnimalsLoaded || state is AnimalsEmpty) _show(emit);
    });
    on<AnimalSelected>((event, emit) {
      _selectedId = event.id;
      if (state is AnimalsLoaded) _show(emit);
    });
  }

  final ShelterRepository repository;

  List<Animal> _all = const [];
  AnimalsFilter _filter;
  AnimalId? _selectedId;

  Future<void> _load(Emitter<AnimalsState> emit) async {
    emit(const AnimalsLoading());
    try {
      _all = await repository.animals();
      _show(emit);
    } catch (error) {
      emit(AnimalsFailure(error));
    }
  }

  void _show(Emitter<AnimalsState> emit) {
    final visible = [
      for (final animal in _all)
        if (_filter.matches(animal)) animal,
    ];
    if (visible.isEmpty) {
      emit(AnimalsEmpty(_filter));
    } else {
      emit(AnimalsLoaded(animals: visible, filter: _filter, selectedId: _selectedId));
    }
  }
}
