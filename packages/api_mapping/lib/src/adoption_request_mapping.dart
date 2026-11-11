import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'accepted.dart';

extension AdoptionRequestStatusMapping on AdoptionRequestStatus {
  String toDto() => switch (this) {
    AdoptionRequestStatus.pending => AdoptionRequestDto.pending,
    AdoptionRequestStatus.approved => AdoptionRequestDto.approved,
    AdoptionRequestStatus.rejected => AdoptionRequestDto.rejected,
    AdoptionRequestStatus.withdrawn => AdoptionRequestDto.withdrawn,
  };
}

AdoptionRequestStatus requestStatusFromDto(String value) => switch (value) {
  AdoptionRequestDto.pending => AdoptionRequestStatus.pending,
  AdoptionRequestDto.approved => AdoptionRequestStatus.approved,
  AdoptionRequestDto.rejected => AdoptionRequestStatus.rejected,
  AdoptionRequestDto.withdrawn => AdoptionRequestStatus.withdrawn,
  _ => throw FormatException('Unknown adoption request status', value),
};

extension AdoptionRequestMapping on AdoptionRequest {
  AdoptionRequestDto toDto() => AdoptionRequestDto(
    id: id.value,
    animalId: animalId.value,
    applicantId: applicantId.value,
    motivation: motivation.text,
    createdAt: createdAt,
    status: status.toDto(),
  );
}

extension AdoptionRequestDtoMapping on AdoptionRequestDto {
  AdoptionRequest toDomain() => AdoptionRequest(
    id: AdoptionRequestId(id),
    animalId: AnimalId(animalId),
    applicantId: UserId(applicantId),
    motivation: accepted(RequestMotivation.parse(motivation)),
    createdAt: createdAt,
    status: requestStatusFromDto(status),
  );
}
