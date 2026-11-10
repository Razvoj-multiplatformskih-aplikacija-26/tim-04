import 'package:domain/domain.dart';

import 'change_request.dart';
import 'clock.dart';
import 'ports/adoption_request_repository.dart';

final class WithdrawRequest {
  const WithdrawRequest({required this.requests, required this.clock});

  final AdoptionRequestRepository requests;
  final Clock clock;

  Future<Result<AdoptionRequest>> call({required AdoptionRequestId id, required User by}) => changeRequest(
    requests,
    id,
    by: by,
    change: (request) => withdrawRequest(request: request, by: by, now: clock.now()),
  );
}
