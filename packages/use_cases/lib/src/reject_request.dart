import 'package:domain/domain.dart';

import 'change_request.dart';
import 'ports/adoption_request_repository.dart';

final class RejectRequest {
  const RejectRequest({required this.requests});

  final AdoptionRequestRepository requests;

  Future<Result<AdoptionRequest>> call({required AdoptionRequestId id, required User by}) => changeRequest(
    requests,
    id,
    by: by,
    change: (request) => rejectRequest(request: request, by: by),
  );
}
