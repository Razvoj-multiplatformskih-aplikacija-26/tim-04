import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class FakeShelterRepository implements AnimalRepository {
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

  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async {
    _throwIfFailing();
    return [
      for (final r in _requests)
        if ((applicant == null || r.applicantId == applicant) && (animal == null || r.animalId == animal)) r,
    ];
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

final class FakeAdoptionRequestRepository implements AdoptionRequestRepository {
  FakeAdoptionRequestRepository(this._store);

  final FakeShelterRepository _store;

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) =>
      _store.requests(applicant: applicant, animal: animal);

  @override
  Future<AdoptionRequest?> find(AdoptionRequestId id) async {
    _store._throwIfFailing();
    return _store._requests.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<Result<AdoptionRequest>> submit(AdoptionRequest request) async {
    _store._throwIfFailing();
    _store._requests.add(request);
    return Success(request);
  }

  @override
  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from}) async {
    _store._throwIfFailing();
    final requests = _store._requests;
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return const Failure(NotFound());
    if (requests[index].status != from) return const Failure(InvalidRequestTransition());
    requests[index] = request;
    return Success(request);
  }

  @override
  Future<Result<ApprovalOutcome>> approve(ApprovalOutcome outcome) async {
    _store._throwIfFailing();
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
