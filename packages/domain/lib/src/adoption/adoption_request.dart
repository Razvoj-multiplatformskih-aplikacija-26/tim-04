import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'request_motivation.dart';

enum AdoptionRequestStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  bool get isActive => this == pending || this == approved;
}

@immutable
final class AdoptionRequest {
  const AdoptionRequest({
    required this.id,
    required this.animalId,
    required this.applicantId,
    required this.motivation,
    required this.createdAt,
    this.status = AdoptionRequestStatus.pending,
  });

  final AdoptionRequestId id;
  final AnimalId animalId;
  final UserId applicantId;
  final RequestMotivation motivation;
  final DateTime createdAt;
  final AdoptionRequestStatus status;

  bool get isActive => status.isActive;

  AdoptionRequest copyWith({AdoptionRequestStatus? status}) {
    return AdoptionRequest(
      id: id,
      animalId: animalId,
      applicantId: applicantId,
      motivation: motivation,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdoptionRequest &&
      other.id == id &&
      other.animalId == animalId &&
      other.applicantId == applicantId &&
      other.motivation == motivation &&
      other.createdAt == createdAt &&
      other.status == status;

  @override
  int get hashCode => Object.hash(id, animalId, applicantId, motivation, createdAt, status);

  @override
  String toString() => 'AdoptionRequest($id, animal $animalId, by $applicantId, ${status.name})';
}
