import 'animal_dto.dart';
import 'json.dart';

final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    required this.title,
    this.value,
    this.min,
    this.max,
    this.from,
    this.to,
  });

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:utociste/problem/$code';

  final int status;
  final String code;
  final String title;
  final int? value;
  final int? min;
  final int? max;
  final AnimalStatusDto? from;
  final AnimalStatusDto? to;

  Map<String, Object?> toJson() => {
    'type': typeOf(code),
    'title': title,
    'status': status,
    'code': code,
    'value': ?value,
    'min': ?min,
    'max': ?max,
    if (from case final from?) 'from': from.toJson(),
    if (to case final to?) 'to': to.toJson(),
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
    value: jsonOptionalInt(json, 'value'),
    min: jsonOptionalInt(json, 'min'),
    max: jsonOptionalInt(json, 'max'),
    from: json['from'] == null ? null : AnimalStatusDto.fromJson(jsonObject(json['from'])),
    to: json['to'] == null ? null : AnimalStatusDto.fromJson(jsonObject(json['to'])),
  );
}
