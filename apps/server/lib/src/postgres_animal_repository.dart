import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;
import 'package:use_cases/use_cases.dart';

const _select = '''
  SELECT id, name, species, birth_date, description, enclosure_id, photo_url, received_at,
         status, status_since, status_until, status_by, adopter_id, reserved_request::text, status_reason
  FROM animals
''';

final class PostgresAnimalRepository implements AnimalRepository {
  const PostgresAnimalRepository(this._database);

  final Session _database;

  @override
  Future<List<Animal>> animals() async {
    final rows = await _database.execute('$_select ORDER BY received_at DESC');
    return [for (final row in rows) _animal(row)];
  }

  @override
  Future<Animal?> find(AnimalId id) async {
    final rows = await _database.execute(Sql.named('$_select WHERE id = @id'), parameters: {'id': id.value});
    return rows.isEmpty ? null : _animal(rows.single);
  }

  @override
  Future<Result<Animal>> create(Animal animal) async {
    await _database.execute(
      Sql.named('''
        INSERT INTO animals
          (id, name, species, birth_date, description, enclosure_id, photo_url, received_at,
           status, status_since, status_until, status_by, adopter_id, reserved_request, status_reason)
        VALUES
          (@id, @name, @species, @birthDate, @description, @enclosure, @photo, @receivedAt,
           @status, @since, @until, @by, @adopter, @request::uuid, @reason)
      '''),
      parameters: {
        'id': animal.id.value,
        'name': animal.name.text,
        'species': animal.species.toDto(),
        'birthDate': TypedValue(Type.date, _dateOnly(animal.birthDate)),
        'description': animal.description,
        'enclosure': animal.enclosureId.value,
        'photo': animal.photoUrl,
        'receivedAt': animal.receivedAt,
        ..._statusParameters(animal.status),
      },
    );
    return Success(animal);
  }

  @override
  Future<Result<Animal>> save(Animal animal, {required AnimalStatus from}) async {
    final result = await _database.execute(
      Sql.named('''
        UPDATE animals
        SET enclosure_id = @enclosure, status = @status, status_since = @since, status_until = @until,
            status_by = @by, adopter_id = @adopter, reserved_request = @request::uuid, status_reason = @reason
        WHERE id = @id AND status = @from
      '''),
      parameters: {
        'id': animal.id.value,
        'enclosure': animal.enclosureId.value,
        'from': from.toDto().kind,
        ..._statusParameters(animal.status),
      },
    );
    if (result.affectedRows == 0) return Failure(InvalidTransition(from: from, to: animal.status));
    return Success(animal);
  }
}

Map<String, Object?> _statusParameters(AnimalStatus status) {
  final dto = status.toDto();
  return {
    'status': dto.kind,
    'since': dto.since ?? dto.at,
    'until': dto.until,
    'by': dto.receivedBy ?? dto.approvedBy,
    'adopter': dto.adopterId,
    'request': dto.requestId,
    'reason': dto.reason,
  };
}

DateTime _dateOnly(DateTime date) => DateTime.utc(date.year, date.month, date.day);

Animal _animal(ResultRow row) {
  final [
    id,
    name,
    species,
    birthDate,
    description,
    enclosure,
    photo,
    receivedAt,
    status,
    since,
    until,
    by,
    adopter,
    request,
    reason,
  ] = row;
  final birth = birthDate! as DateTime;
  return Animal(
    id: AnimalId(id! as String),
    name: AnimalName.parse(name! as String).valueOrNull!,
    species: speciesFromDto(species! as String),
    birthDate: DateTime(birth.year, birth.month, birth.day),
    description: description! as String,
    enclosureId: EnclosureId(enclosure! as String),
    photoUrl: photo as String?,
    receivedAt: receivedAt! as DateTime,
    status: AnimalStatusDto(
      kind: status! as String,
      at: since as DateTime?,
      since: since,
      until: until as DateTime?,
      receivedBy: by as String?,
      approvedBy: by,
      adopterId: adopter as String?,
      requestId: request as String?,
      reason: reason as String?,
    ).toDomain(),
  );
}
