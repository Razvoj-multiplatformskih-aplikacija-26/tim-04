import 'package:domain/domain.dart';

import 'ports/adoption_request_repository.dart';

const _attempts = 3;

Future<Result<AdoptionRequest>> changeRequest(
  AdoptionRequestRepository requests,
  AdoptionRequestId id, {
  required User by,
  required Result<AdoptionRequest> Function(AdoptionRequest current) change,
}) async {
  Result<AdoptionRequest> outcome = const Failure(NotFound());
  for (var attempt = 0; attempt < _attempts; attempt++) {
    final request = await requests.find(id);
    if (request == null || !AccessPolicy.canViewRequest(by, request)) return const Failure(NotFound());
    switch (change(request)) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        outcome = await requests.save(value, from: request.status);
        if (outcome is Failure) continue;
        return outcome;
    }
  }
  return outcome;
}
