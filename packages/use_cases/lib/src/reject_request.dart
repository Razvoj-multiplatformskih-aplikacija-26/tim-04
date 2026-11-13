import 'package:domain/domain.dart';

import 'change_request.dart';
import 'notify.dart';
import 'ports/adoption_notifier.dart';
import 'ports/adoption_request_repository.dart';

final class RejectRequest {
  const RejectRequest({required this.requests, required this.notifier});

  final AdoptionRequestRepository requests;
  final AdoptionNotifier notifier;

  Future<Result<AdoptionRequest>> call({required AdoptionRequestId id, required User by}) async {
    final result = await changeRequest(
      requests,
      id,
      by: by,
      change: (request) => rejectRequest(request: request, by: by),
    );
    if (result case Success(:final value)) await notifySafely(() => notifier.requestRejected(value));
    return result;
  }
}
