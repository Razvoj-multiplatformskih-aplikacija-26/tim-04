import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class FakeShelterRepository implements ShelterRepository, AnimalRepository {
  FakeShelterRepository({List<Animal> animals = const [], List<AdoptionRequest> requests = const []})
    : _animals = [...animals],
      _requests = [...requests];

  final List<Animal> _animals;
  final List<AdoptionRequest> _requests;
  bool _failNext = false;

  void failNextRequest() => _failNext = true;

  void _throwIfFailing() {
    if (!_failNext) return;
    _failNext = false;
    throw const RepositoryException('Simulated repository failure', failure: RepositoryFailure.unreachable);
  }

  @override
  Future<List<Animal>> animals() async {
    _throwIfFailing();
    return [..._animals];
  }

  @override
  Future<Animal> animal(AnimalId id) async {
    _throwIfFailing();
    return _animals.firstWhere((a) => a.id == id);
  }

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async {
    _throwIfFailing();
    return [
      for (final r in _requests)
        if ((applicant == null || r.applicantId == applicant) && (animal == null || r.animalId == animal)) r,
    ];
  }

  @override
  Future<void> saveRequest(AdoptionRequest request) async {
    _throwIfFailing();
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index == -1) {
      _requests.add(request);
    } else {
      _requests[index] = request;
    }
  }

  @override
  Future<void> saveAnimal(Animal animal) async {
    _throwIfFailing();
    final index = _animals.indexWhere((a) => a.id == animal.id);
    if (index == -1) {
      _animals.add(animal);
    } else {
      _animals[index] = animal;
    }
  }

  @override
  Future<Animal?> find(AnimalId id) async {
    _throwIfFailing();
    return _animals.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<Result<Animal>> create(Animal animal) async {
    _throwIfFailing();
    _animals.add(animal);
    return Success(animal);
  }

  @override
  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from}) async {
    _throwIfFailing();
    final index = _animals.indexWhere((a) => a.id == animal.id);
    if (index == -1) return const Failure(NotFound());
    final current = _animals[index];
    if (current.status != from) return Failure(InvalidTransition(from: current.status, to: animal.status));
    _animals[index] = animal;
    return Success(animal);
  }
}
