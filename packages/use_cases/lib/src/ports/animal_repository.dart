import 'package:domain/domain.dart';

abstract interface class AnimalRepository {
  Future<List<Animal>> animals();

  Future<Animal?> find(AnimalId id);

  Future<Result<Animal>> create(Animal animal);

  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from});
}
