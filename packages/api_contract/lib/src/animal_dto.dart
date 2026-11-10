import 'json.dart';

final class AnimalStatusDto {
  const AnimalStatusDto({
    required this.kind,
    this.at,
    this.since,
    this.until,
    this.receivedBy,
    this.approvedBy,
    this.adopterId,
    this.requestId,
    this.reason,
  });

  static const received = 'received';
  static const inQuarantine = 'in-quarantine';
  static const readyForAdoption = 'ready-for-adoption';
  static const reserved = 'reserved';
  static const adopted = 'adopted';
  static const permanentResident = 'permanent-resident';
  static const returned = 'returned';

  final String kind;
  final DateTime? at;
  final DateTime? since;
  final DateTime? until;
  final String? receivedBy;
  final String? approvedBy;
  final String? adopterId;
  final String? requestId;
  final String? reason;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (at case final at?) 'at': instantToJson(at),
    if (since case final since?) 'since': instantToJson(since),
    if (until case final until?) 'until': instantToJson(until),
    'receivedBy': ?receivedBy,
    'approvedBy': ?approvedBy,
    'adopterId': ?adopterId,
    'requestId': ?requestId,
    'reason': ?reason,
  };

  factory AnimalStatusDto.fromJson(Map<String, Object?> json) => AnimalStatusDto(
    kind: jsonString(json, 'kind'),
    at: jsonOptionalInstant(json, 'at'),
    since: jsonOptionalInstant(json, 'since'),
    until: jsonOptionalInstant(json, 'until'),
    receivedBy: jsonOptionalString(json, 'receivedBy'),
    approvedBy: jsonOptionalString(json, 'approvedBy'),
    adopterId: jsonOptionalString(json, 'adopterId'),
    requestId: jsonOptionalString(json, 'requestId'),
    reason: jsonOptionalString(json, 'reason'),
  );
}

final class AnimalDto {
  const AnimalDto({
    required this.id,
    required this.name,
    required this.species,
    required this.birthDate,
    required this.description,
    required this.enclosureId,
    required this.receivedAt,
    required this.status,
    this.photo,
  });

  static const dog = 'dog';
  static const cow = 'cow';
  static const goat = 'goat';
  static const horse = 'horse';

  final String id;
  final String name;
  final String species;
  final DateTime birthDate;
  final String description;
  final String enclosureId;
  final DateTime receivedAt;
  final AnimalStatusDto status;
  final String? photo;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'birthDate': dateToJson(birthDate),
    'description': description,
    'enclosureId': enclosureId,
    'receivedAt': instantToJson(receivedAt),
    'status': status.toJson(),
    'photo': ?photo,
  };

  factory AnimalDto.fromJson(Map<String, Object?> json) => AnimalDto(
    id: jsonString(json, 'id'),
    name: jsonString(json, 'name'),
    species: jsonString(json, 'species'),
    birthDate: jsonDate(json, 'birthDate'),
    description: jsonString(json, 'description'),
    enclosureId: jsonString(json, 'enclosureId'),
    receivedAt: jsonInstant(json, 'receivedAt'),
    status: AnimalStatusDto.fromJson(jsonObject(json['status'])),
    photo: jsonOptionalString(json, 'photo'),
  );
}

final class IntakeDto {
  const IntakeDto({
    required this.name,
    required this.species,
    required this.birthDate,
    required this.description,
    required this.enclosureId,
  });

  final String name;
  final String species;
  final DateTime birthDate;
  final String description;
  final String enclosureId;

  Map<String, Object?> toJson() => {
    'name': name,
    'species': species,
    'birthDate': dateToJson(birthDate),
    'description': description,
    'enclosureId': enclosureId,
  };

  factory IntakeDto.fromJson(Map<String, Object?> json) => IntakeDto(
    name: jsonString(json, 'name'),
    species: jsonString(json, 'species'),
    birthDate: jsonDate(json, 'birthDate'),
    description: jsonString(json, 'description'),
    enclosureId: jsonString(json, 'enclosureId'),
  );
}

final class QuarantineDto {
  const QuarantineDto({required this.until});

  final DateTime until;

  Map<String, Object?> toJson() => {'until': instantToJson(until)};

  factory QuarantineDto.fromJson(Map<String, Object?> json) => QuarantineDto(until: jsonInstant(json, 'until'));
}
