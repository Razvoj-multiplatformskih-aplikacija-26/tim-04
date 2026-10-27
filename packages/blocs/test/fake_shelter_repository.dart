import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';

final class FakeShelterRepository implements ShelterRepository {
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
    throw Exception('Simulated repository failure');
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
}
