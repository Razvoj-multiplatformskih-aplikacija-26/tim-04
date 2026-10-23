import '../animal/animal.dart';
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
