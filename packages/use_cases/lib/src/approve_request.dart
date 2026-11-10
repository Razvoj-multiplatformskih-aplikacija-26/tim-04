import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/adoption_request_repository.dart';
import 'ports/animal_repository.dart';

final class ApproveRequest {
  const ApproveRequest({required this.requests, required this.animals, required this.clock});

  final AdoptionRequestRepository requests;
  final AnimalRepository animals;
  final Clock clock;

  Future<Result<ApprovalOutcome>> call({required AdoptionRequestId id, required User by}) async {
    final request = await requests.find(id);
    if (request == null || !AccessPolicy.canViewRequest(by, request)) return const Failure(NotFound());
    final animal = await animals.find(request.animalId);
    if (animal == null) return const Failure(NotFound());
    final all = await requests.requests(animal: animal.id);
    final result = approveRequest(
      animal: animal,
      request: request,
      allRequestsForAnimal: all,
      by: by,
      now: clock.now(),
    );
    return switch (result) {
      Failure(:final error) => Failure(error),
      Success(:final value) => requests.approve(value),
    };
  }
}
