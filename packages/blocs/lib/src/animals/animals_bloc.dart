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
    on<AnimalsRefreshed>((event, emit) => _refresh(emit));
    on<AnimalsFilterChanged>((event, emit) {
      _filter = event.filter;
      if (state is AnimalsLoaded || state is AnimalsEmpty) _show(emit);
    });
    on<AnimalSelected>((event, emit) {
      _selectedId = event.id;
      if (state is AnimalsLoaded) _show(emit);
    });
    on<AnimalIntakeSubmitted>((event, emit) => _intake(event, emit));
    on<QuarantineStarted>(
      (event, emit) => _change(event.animalId, emit, (animal) {
        return startQuarantine(animal: animal, by: event.by, now: event.now, until: event.until);
      }),
    );
    on<QuarantineEnded>(
      (event, emit) => _change(event.animalId, emit, (animal) {
        return endQuarantine(animal: animal, by: event.by, now: event.now);
      }),
    );
    on<AnimalsNoticeAcknowledged>((event, emit) {
      if (state case AnimalsLoaded(notice: _?)) _show(emit);
    });
  }

  final ShelterRepository repository;

  List<Animal> _all = const [];
  AnimalsFilter _filter;
  AnimalId? _selectedId;

  Animal? animalById(AnimalId id) {
    for (final animal in _all) {
      if (animal.id == id) return animal;
    }
    return null;
  }

  /// Every enclosure in use, sorted, for the intake form.
  List<EnclosureId> get enclosures {
    final ids = {for (final animal in _all) animal.enclosureId.value}.toList()..sort();
    return [for (final id in ids) EnclosureId(id)];
  }

  Future<void> _load(Emitter<AnimalsState> emit) async {
    emit(const AnimalsLoading());
    try {
      _all = await repository.animals();
      _show(emit);
    } catch (error) {
      emit(AnimalsFailure(error));
    }
  }

  Future<void> _refresh(Emitter<AnimalsState> emit) async {
    try {
      _all = await repository.animals();
      _show(emit);
    } catch (_) {
      // Keep showing the list we already have; the next load will try again.
    }
  }

  Future<void> _intake(AnimalIntakeSubmitted event, Emitter<AnimalsState> emit) async {
    final result = intakeAnimal(
      id: event.id,
      by: event.by,
      name: event.name,
      species: event.species,
      birthDate: event.birthDate,
      description: event.description,
      enclosureId: event.enclosureId,
      now: event.now,
    );
    // Show every animal so the new one (Received) is not hidden by the current filter.
    if (result is Success) _filter = AnimalsFilter.all;
    await _save(result, emit);
  }

  /// Applies a domain transition (e.g. [startQuarantine]) to the animal with [id] and saves the result.
  Future<void> _change(
    AnimalId id,
    Emitter<AnimalsState> emit,
    Result<Animal> Function(Animal animal) transition,
  ) async {
    final animal = animalById(id);
    if (animal == null) return;
    await _save(transition(animal), emit);
  }

  /// A refused rule becomes [AnimalRefused]; otherwise the animal is saved, the list reloaded, and [AnimalSaved] shown.
  Future<void> _save(Result<Animal> result, Emitter<AnimalsState> emit) async {
    switch (result) {
      case Failure(:final error):
        _show(emit, notice: AnimalRefused(error));
      case Success(value: final animal):
        try {
          await repository.saveAnimal(animal);
          _all = await repository.animals();
          _show(emit, notice: AnimalSaved(animal));
        } catch (error) {
          _show(emit, notice: AnimalSaveFailed(error));
        }
    }
  }

  void _show(Emitter<AnimalsState> emit, {AnimalsNotice? notice}) {
    final visible = [
      for (final animal in _all)
        if (_filter.matches(animal)) animal,
    ];
    if (visible.isEmpty) {
      emit(AnimalsEmpty(_filter));
    } else {
      emit(AnimalsLoaded(animals: visible, filter: _filter, selectedId: _selectedId, notice: notice));
    }
  }
}
