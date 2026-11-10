import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class InMemoryAnimals implements AnimalRepository {
  InMemoryAnimals([List<Animal> animals = const []]) : _animals = List.of(animals);

  final List<Animal> _animals;

  void Function()? afterFind;

  List<Animal> get stored => List.unmodifiable(_animals);

  void replace(Animal animal) => _animals[_indexOf(animal.id)] = animal;

  @override
  Future<List<Animal>> animals() async => List.of(_animals);

  @override
  Future<Animal?> find(AnimalId id) async {
    final index = _indexOf(id);
    final found = index == -1 ? null : _animals[index];
    afterFind?.call();
    return found;
  }

  @override
  Future<Result<Animal>> create(Animal animal) async {
    _animals.add(animal);
    return Success(animal);
  }

  @override
  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from}) async {
    final index = _indexOf(animal.id);
    if (index == -1) return const Failure(NotFound());
    final current = _animals[index];
    if (current.status != from) return Failure(InvalidTransition(from: current.status, to: animal.status));
    _animals[index] = animal;
    return Success(animal);
  }

  int _indexOf(AnimalId id) => _animals.indexWhere((animal) => animal.id == id);
}
