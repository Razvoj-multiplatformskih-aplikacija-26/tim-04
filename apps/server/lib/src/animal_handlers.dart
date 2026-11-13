import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'dev_sign_in.dart';
import 'http.dart';

final class AnimalHandlers {
  AnimalHandlers({required AnimalRepository animals, required Clock clock, required String Function() newId})
    : _animals = animals,
      _getAnimals = GetAnimals(animals: animals),
      _intakeAnimal = IntakeAnimal(animals: animals, clock: clock, newId: newId),
      _startQuarantine = StartQuarantine(animals: animals, clock: clock),
      _endQuarantine = EndQuarantine(animals: animals, clock: clock);

  final AnimalRepository _animals;
  final GetAnimals _getAnimals;
  final IntakeAnimal _intakeAnimal;
  final StartQuarantine _startQuarantine;
  final EndQuarantine _endQuarantine;

  Future<Response> animals(Request request) async {
    final status = request.queryParameters.raw[ApiQuery.status];
    final species = request.queryParameters.raw[ApiQuery.species];
    final animals = [for (final animal in await _getAnimals()) animal.toDto()];
    return json(200, [
      for (final animal in animals)
        if ((status == null || animal.status.kind == status) && (species == null || animal.species == species))
          animal.toJson(),
    ]);
  }

  Future<Response> find(Request request) async {
    final animal = await _animals.find(_id(request));
    if (animal == null) return problem(const NotFound());
    return json(200, animal.toDto().toJson());
  }

  Future<Response> intake(Request request) async {
    final body = IntakeDto.fromJson(await readObject(request));
    final result = await _intakeAnimal(
      by: _actor(request),
      name: body.name,
      species: speciesFromDto(body.species),
      birthDate: DateTime(body.birthDate.year, body.birthDate.month, body.birthDate.day),
      description: body.description,
      enclosureId: EnclosureId(body.enclosureId),
    );
    return respond(result, _toJson, status: 201);
  }

  Future<Response> startQuarantine(Request request) async {
    final body = QuarantineDto.fromJson(await readObject(request));
    return respond(await _startQuarantine(id: _id(request), by: _actor(request), until: body.until), _toJson);
  }

  Future<Response> endQuarantine(Request request) async =>
      respond(await _endQuarantine(id: _id(request), by: _actor(request)), _toJson);

  AnimalId _id(Request request) => AnimalId(request.rawPathParameters[#id]!);

  User _actor(Request request) => currentUser.get(request);
}

Map<String, Object?> _toJson(Animal animal) => animal.toDto().toJson();
