import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

final class FakeShelterRepository implements AnimalRepository {
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
      throw const RepositoryException('Simulated outage', failure: RepositoryFailure.unreachable);
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

  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async {
    await _roundTrip();
    return [
      for (final r in _requests)
        if ((applicant == null || r.applicantId == applicant) && (animal == null || r.animalId == animal)) r,
    ];
  }

  @override
  Future<Animal?> find(AnimalId id) async {
    await _roundTrip();
    return _animals.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<Result<Animal>> create(Animal animal) async {
    await _roundTrip();
    _animals.add(animal);
    return Success(animal);
  }

  /// Saves only while the animal is still in [from], like the server will; otherwise someone changed it first.
  @override
  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from}) async {
    await _roundTrip();
    final index = _animals.indexWhere((a) => a.id == animal.id);
    if (index == -1) return const Failure(NotFound());
    final current = _animals[index];
    if (current.status != from) return Failure(InvalidTransition(from: current.status, to: animal.status));
    _animals[index] = animal;
    return Success(animal);
  }
}

final class FakeAdoptionRequestRepository implements AdoptionRequestRepository {
  FakeAdoptionRequestRepository(this._store);

  final FakeShelterRepository _store;

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) =>
      _store.requests(applicant: applicant, animal: animal);

  @override
  Future<AdoptionRequest?> find(AdoptionRequestId id) async {
    await _store._roundTrip();
    return _store._requests.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<Result<AdoptionRequest>> submit(AdoptionRequest request) async {
    await _store._roundTrip();
    _store._requests.add(request);
    return Success(request);
  }

  @override
  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from}) async {
    await _store._roundTrip();
    final requests = _store._requests;
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return const Failure(NotFound());
    if (requests[index].status != from) return const Failure(InvalidRequestTransition());
    requests[index] = request;
    return Success(request);
  }

  @override
  Future<Result<ApprovalOutcome>> approve(ApprovalOutcome outcome) async {
    await _store._roundTrip();
    final animals = _store._animals;
    final requests = _store._requests;
    final animalIndex = animals.indexWhere((a) => a.id == outcome.animal.id);
    final requestIndex = requests.indexWhere((r) => r.id == outcome.approved.id);
    if (animalIndex == -1 ||
        requestIndex == -1 ||
        animals[animalIndex].status is! ReadyForAdoption ||
        requests[requestIndex].status != AdoptionRequestStatus.pending) {
      return const Failure(InvalidRequestTransition());
    }
    animals[animalIndex] = outcome.animal;
    for (final changed in [outcome.approved, ...outcome.rejected]) {
      requests[requests.indexWhere((r) => r.id == changed.id)] = changed;
    }
    return Success(outcome);
  }
}
