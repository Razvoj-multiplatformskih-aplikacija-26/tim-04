import 'package:domain/domain.dart';

import 'clock.dart';
import 'notify.dart';
import 'ports/adoption_notifier.dart';
import 'ports/adoption_request_repository.dart';
import 'ports/animal_repository.dart';

final class ApproveRequest {
  const ApproveRequest({required this.requests, required this.animals, required this.clock, required this.notifier});

  final AdoptionRequestRepository requests;
  final AnimalRepository animals;
  final Clock clock;
  final AdoptionNotifier notifier;

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
    if (result case Failure(:final error)) return Failure(error);
    final saved = await requests.approve(result.valueOrNull!);
    if (saved case Success(:final value)) {
      await notifySafely(() => notifier.requestApproved(value.approved));
      for (final rejected in value.rejected) {
        await notifySafely(() => notifier.requestRejected(rejected));
      }
    }
    return saved;
  }
}
