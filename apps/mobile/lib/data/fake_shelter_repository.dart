import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

import 'seed.dart';

final class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => 'RepositoryException: $message';
}

final class FakeShelterRepository implements ShelterRepository {
  FakeShelterRepository({
    this.latency = const Duration(milliseconds: 600),
    List<Animal>? animals,
    List<AdoptionRequest>? requests,
  }) : _animals = [...(animals ?? seedAnimals)],
       _requests = [...(requests ?? seedRequests)];

  final Duration latency;
  final List<Animal> _animals;
  final List<AdoptionRequest> _requests;

  int failingRequests = 0;
  bool _emptyNext = false;

  void failNextRequest() => failingRequests = 1;

  void emptyNextRequest() => _emptyNext = true;

  Future<void> _roundTrip() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
  }

  @override
  Future<List<Animal>> animals() async {
    await _roundTrip();
    if (_emptyNext) {
      _emptyNext = false;
      return const [];
    }
    return List.of(_animals);
  }

  @override
  Future<Animal> animal(AnimalId id) async {
    await _roundTrip();
    return _animals.firstWhere((a) => a.id == id, orElse: () => throw RepositoryException('No animal $id'));
  }

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async {
    await _roundTrip();
    return [
      for (final r in _requests)
        if ((applicant == null || r.applicantId == applicant) && (animal == null || r.animalId == animal)) r,
    ];
  }

  @override
  Future<void> saveRequest(AdoptionRequest request) async {
    await _roundTrip();
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index == -1) {
      _requests.add(request);
    } else {
      _requests[index] = request;
    }
  }

  @override
  Future<void> saveAnimal(Animal animal) async {
    await _roundTrip();
    final index = _animals.indexWhere((a) => a.id == animal.id);
    if (index == -1) {
      _animals.add(animal);
    } else {
      _animals[index] = animal;
    }
  }
}
