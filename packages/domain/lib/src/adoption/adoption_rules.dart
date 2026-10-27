import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../animal/animal.dart';
import '../animal/animal_status.dart';
import '../errors.dart';
import '../identifiers.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'adoption_request.dart';
import 'request_motivation.dart';

const maxActiveRequests = 2;

Result<AdoptionRequest> submitRequest({
  required AdoptionRequestId id,
  required User user,
  required Animal animal,
  required List<AdoptionRequest> myRequests,
  required RequestMotivation motivation,
  required DateTime now,
}) {
  if (!AccessPolicy.canSubmitRequest(user)) return const Failure(NotAllowed());
  if (!animal.isAdoptable) return const Failure(AnimalNotAdoptable());
  if (myRequests.any((r) => r.animalId == animal.id && r.isActive)) return const Failure(DuplicateRequest());
  if (myRequests.where((r) => r.isActive).length >= maxActiveRequests) return const Failure(TooManyActiveRequests());
  return Success(
    AdoptionRequest(id: id, animalId: animal.id, applicantId: user.id, motivation: motivation, createdAt: now),
  );
}

Result<AdoptionRequest> withdrawRequest({required AdoptionRequest request, required User by, required DateTime now}) {
  if (!AccessPolicy.canWithdraw(by, request)) return const Failure(NotAllowed());
  if (request.status != AdoptionRequestStatus.pending) return const Failure(WithdrawNotAllowed());
  return Success(request.copyWith(status: AdoptionRequestStatus.withdrawn));
}

Result<AdoptionRequest> rejectRequest({required AdoptionRequest request, required User by}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  if (request.status != AdoptionRequestStatus.pending) return const Failure(InvalidRequestTransition());
  return Success(request.copyWith(status: AdoptionRequestStatus.rejected));
}

List<AdoptionRequest> competingRequests(AnimalId animalId, List<AdoptionRequest> allRequests) {
  final competing = [
    for (final request in allRequests)
      if (request.animalId == animalId && request.isActive) request,
  ];
  competing.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return competing;
}

@immutable
final class ApprovalOutcome {
  const ApprovalOutcome({required this.animal, required this.approved, required this.rejected});

  final Animal animal;
  final AdoptionRequest approved;
  final List<AdoptionRequest> rejected;

  @override
  bool operator ==(Object other) =>
      other is ApprovalOutcome &&
      other.animal == animal &&
      other.approved == approved &&
      const ListEquality<AdoptionRequest>().equals(other.rejected, rejected);

  @override
  int get hashCode => Object.hash(animal, approved, const ListEquality<AdoptionRequest>().hash(rejected));

  @override
  String toString() => 'ApprovalOutcome(${animal.id} reserved for ${approved.id}, ${rejected.length} rejected)';
}

Result<ApprovalOutcome> approveRequest({
  required Animal animal,
  required AdoptionRequest request,
  required List<AdoptionRequest> allRequestsForAnimal,
  required User by,
  required DateTime now,
}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  if (request.status != AdoptionRequestStatus.pending) return const Failure(InvalidRequestTransition());
  if (!animal.isAdoptable) return const Failure(AnimalNotAdoptable());

  final rejected = [
    for (final other in allRequestsForAnimal)
      if (other.id != request.id && other.status == AdoptionRequestStatus.pending)
        other.copyWith(status: AdoptionRequestStatus.rejected),
  ];

  return Success(
    ApprovalOutcome(
      animal: animal.copyWith(
        status: Reserved(requestId: request.id, approvedBy: by.id, at: now),
      ),
      approved: request.copyWith(status: AdoptionRequestStatus.approved),
      rejected: rejected,
    ),
  );
}
