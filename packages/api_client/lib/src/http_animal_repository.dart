import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpAnimalRepository implements AnimalRepository {
  const HttpAnimalRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Animal>> animals() async =>
      valueOf(await _api.get(ApiPaths.animals), (json) => [for (final item in jsonList(json)) _animal(item)]);

  @override
  Future<Animal?> find(AnimalId id) async {
    final answer = await _api.get(ApiPaths.animal(id.value));
    if (answer case ApiRejected(error: NotFound())) return null;
    return valueOf(answer, _animal);
  }

  @override
  Future<Result<Animal>> create(Animal animal) async {
    final body = IntakeDto(
      name: animal.name.text,
      species: animal.species.toDto(),
      birthDate: animal.birthDate,
      description: animal.description,
      enclosureId: animal.enclosureId.value,
    );
    return resultOf(await _api.post(ApiPaths.animals, body: body.toJson()), _animal);
  }

  @override
  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from}) async {
    final id = animal.id.value;
    final answer = await switch ((from, animal.status)) {
      (_, InQuarantine(:final until)) => _api.post(ApiPaths.quarantine(id), body: QuarantineDto(until: until).toJson()),
      (InQuarantine(), ReadyForAdoption()) => _api.delete(ApiPaths.quarantine(id)),
      _ => throw ArgumentError.value(animal.status, 'status', 'The server has no action for this change'),
    };
    return resultOf(answer, _animal);
  }

  Animal _animal(Object? json) => AnimalDto.fromJson(jsonObject(json)).toDomain();
}
