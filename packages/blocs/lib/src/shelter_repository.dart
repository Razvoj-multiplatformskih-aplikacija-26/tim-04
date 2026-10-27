import 'package:domain/domain.dart';

abstract interface class ShelterRepository {
  Future<List<Animal>> animals();

  Future<Animal> animal(AnimalId id);

  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal});

  Future<void> saveRequest(AdoptionRequest request);

  Future<void> saveAnimal(Animal animal);
}
