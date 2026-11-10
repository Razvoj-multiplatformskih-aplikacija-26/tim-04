import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

class InMemoryAnimals implements AnimalRepository {
  InMemoryAnimals(List<Animal> animals) : _animals = [...animals];

  final List<Animal> _animals;

  @override
  Future<List<Animal>> animals() async => List.of(_animals);

  @override
  Future<Animal?> find(AnimalId id) async => _animals.where((a) => a.id == id).firstOrNull;

  @override
  Future<Result<Animal>> create(Animal animal) async {
    _animals.add(animal);
    return Success(animal);
  }

  @override
  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from}) async {
    final index = _animals.indexWhere((a) => a.id == animal.id);
    if (index == -1) return const Failure(NotFound());
    final current = _animals[index].status;
    if (current != from) return Failure(InvalidTransition(from: current, to: animal.status));
    _animals[index] = animal;
    return Success(animal);
  }
}
