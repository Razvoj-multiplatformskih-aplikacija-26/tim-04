import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'accepted.dart';

const _photoFolder = 'assets/animals/';

extension SpeciesMapping on Species {
  String toDto() => switch (this) {
    Species.dog => AnimalDto.dog,
    Species.cow => AnimalDto.cow,
    Species.goat => AnimalDto.goat,
    Species.horse => AnimalDto.horse,
  };
}

Species speciesFromDto(String value) => switch (value) {
  AnimalDto.dog => Species.dog,
  AnimalDto.cow => Species.cow,
  AnimalDto.goat => Species.goat,
  AnimalDto.horse => Species.horse,
  _ => throw FormatException('Unknown species', value),
};

extension AnimalStatusMapping on AnimalStatus {
  AnimalStatusDto toDto() => switch (this) {
    Received(:final receivedBy, :final at) => AnimalStatusDto(
      kind: AnimalStatusDto.received,
      receivedBy: receivedBy.value,
      at: at,
    ),
    InQuarantine(:final since, :final until) => AnimalStatusDto(
      kind: AnimalStatusDto.inQuarantine,
      since: since,
      until: until,
    ),
    ReadyForAdoption(:final since) => AnimalStatusDto(kind: AnimalStatusDto.readyForAdoption, since: since),
    Reserved(:final requestId, :final approvedBy, :final at) => AnimalStatusDto(
      kind: AnimalStatusDto.reserved,
      requestId: requestId.value,
      approvedBy: approvedBy.value,
      at: at,
    ),
    Adopted(:final adopterId, :final at) => AnimalStatusDto(
      kind: AnimalStatusDto.adopted,
      adopterId: adopterId.value,
      at: at,
    ),
    PermanentResident(:final reason) => AnimalStatusDto(kind: AnimalStatusDto.permanentResident, reason: reason),
    Returned(:final reason, :final at) => AnimalStatusDto(kind: AnimalStatusDto.returned, reason: reason, at: at),
  };
}

extension AnimalStatusDtoMapping on AnimalStatusDto {
  AnimalStatus toDomain() => switch (this) {
    AnimalStatusDto(kind: AnimalStatusDto.received, :final receivedBy?, :final at?) => Received(
      receivedBy: UserId(receivedBy),
      at: at,
    ),
    AnimalStatusDto(kind: AnimalStatusDto.inQuarantine, :final since?, :final until?) => InQuarantine(
      since: since,
      until: until,
    ),
    AnimalStatusDto(kind: AnimalStatusDto.readyForAdoption, :final since?) => ReadyForAdoption(since: since),
    AnimalStatusDto(kind: AnimalStatusDto.reserved, :final requestId?, :final approvedBy?, :final at?) => Reserved(
      requestId: AdoptionRequestId(requestId),
      approvedBy: UserId(approvedBy),
      at: at,
    ),
    AnimalStatusDto(kind: AnimalStatusDto.adopted, :final adopterId?, :final at?) => Adopted(
      adopterId: UserId(adopterId),
      at: at,
    ),
    AnimalStatusDto(kind: AnimalStatusDto.permanentResident, :final reason?) => PermanentResident(reason: reason),
    AnimalStatusDto(kind: AnimalStatusDto.returned, :final reason?, :final at?) => Returned(reason: reason, at: at),
    _ => throw FormatException('Unknown animal status', kind),
  };
}

extension AnimalMapping on Animal {
  AnimalDto toDto() => AnimalDto(
    id: id.value,
    name: name.text,
    species: species.toDto(),
    birthDate: birthDate,
    description: description,
    enclosureId: enclosureId.value,
    receivedAt: receivedAt,
    status: status.toDto(),
    photo: photoUrl?.split('/').last,
  );
}

extension AnimalDtoMapping on AnimalDto {
  Animal toDomain() => Animal(
    id: AnimalId(id),
    name: accepted(AnimalName.parse(name)),
    species: speciesFromDto(species),
    birthDate: DateTime(birthDate.year, birthDate.month, birthDate.day),
    description: description,
    enclosureId: EnclosureId(enclosureId),
    status: status.toDomain(),
    receivedAt: receivedAt,
    photoUrl: photo == null ? null : '$_photoFolder$photo',
  );
}
