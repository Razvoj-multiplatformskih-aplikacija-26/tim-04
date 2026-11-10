import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

import 'animals_filter.dart';

part 'animals_event.dart';
part 'animals_state.dart';

final class AnimalsBloc extends Bloc<AnimalsEvent, AnimalsState> {
  AnimalsBloc({
    required this.getAnimals,
    required this.intakeAnimal,
    required this.startQuarantine,
    required this.endQuarantine,
    AnimalsFilter initialFilter = AnimalsFilter.all,
  }) : _filter = initialFilter,
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
    on<AnimalIntakeSubmitted>(
      (event, emit) => _save(
        emit,
        () => intakeAnimal(
          by: event.by,
          name: event.name,
          species: event.species,
          birthDate: event.birthDate,
          description: event.description,
          enclosureId: event.enclosureId,
        ),
        showAllWhenSaved: true,
      ),
    );
    on<QuarantineStarted>(
      (event, emit) => _save(emit, () => startQuarantine(id: event.animalId, by: event.by, until: event.until)),
    );
    on<QuarantineEnded>((event, emit) => _save(emit, () => endQuarantine(id: event.animalId, by: event.by)));
    on<AnimalsNoticeAcknowledged>((event, emit) {
      if (state case AnimalsLoaded(notice: _?)) _show(emit);
    });
  }

  final GetAnimals getAnimals;
  final IntakeAnimal intakeAnimal;
  final StartQuarantine startQuarantine;
  final EndQuarantine endQuarantine;

  List<Animal> _all = const [];
  AnimalsFilter _filter;
  AnimalId? _selectedId;

  Animal? animalById(AnimalId id) {
    for (final animal in _all) {
      if (animal.id == id) return animal;
    }
    return null;
  }

  List<EnclosureId> get enclosures {
    final ids = {for (final animal in _all) animal.enclosureId.value}.toList()..sort();
    return [for (final id in ids) EnclosureId(id)];
  }

  Future<void> _load(Emitter<AnimalsState> emit) async {
    emit(const AnimalsLoading());
    try {
      _all = await getAnimals();
      _show(emit);
    } catch (error) {
      emit(AnimalsFailure(error));
    }
  }

  Future<void> _refresh(Emitter<AnimalsState> emit) async {
    try {
      _all = await getAnimals();
      _show(emit);
    } catch (_) {}
  }

  Future<void> _save(
    Emitter<AnimalsState> emit,
    Future<Result<Animal>> Function() action, {
    bool showAllWhenSaved = false,
  }) async {
    try {
      switch (await action()) {
        case Failure(:final error):
          _show(emit, notice: AnimalRefused(error));
        case Success(value: final animal):
          if (showAllWhenSaved) _filter = AnimalsFilter.all;
          _all = await getAnimals();
          _show(emit, notice: AnimalSaved(animal));
      }
    } on RepositoryException catch (error) {
      _show(emit, notice: AnimalSaveFailed(error));
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
