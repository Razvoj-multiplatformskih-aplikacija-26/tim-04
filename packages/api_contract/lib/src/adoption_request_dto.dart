import 'json.dart';

final class AdoptionRequestDto {
  const AdoptionRequestDto({
    required this.id,
    required this.animalId,
    required this.applicantId,
    required this.motivation,
    required this.createdAt,
    required this.status,
  });

  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const withdrawn = 'withdrawn';

  final String id;
  final String animalId;
  final String applicantId;
  final String motivation;
  final DateTime createdAt;
  final String status;

  Map<String, Object?> toJson() => {
    'id': id,
    'animalId': animalId,
    'applicantId': applicantId,
    'motivation': motivation,
    'createdAt': instantToJson(createdAt),
    'status': status,
  };

  factory AdoptionRequestDto.fromJson(Map<String, Object?> json) => AdoptionRequestDto(
    id: jsonString(json, 'id'),
    animalId: jsonString(json, 'animalId'),
    applicantId: jsonString(json, 'applicantId'),
    motivation: jsonString(json, 'motivation'),
    createdAt: jsonInstant(json, 'createdAt'),
    status: jsonString(json, 'status'),
  );
}

final class NewAdoptionRequestDto {
  const NewAdoptionRequestDto({required this.animalId, required this.motivation});

  final String animalId;
  final String motivation;

  Map<String, Object?> toJson() => {'animalId': animalId, 'motivation': motivation};

  factory NewAdoptionRequestDto.fromJson(Map<String, Object?> json) =>
      NewAdoptionRequestDto(animalId: jsonString(json, 'animalId'), motivation: jsonString(json, 'motivation'));
}
