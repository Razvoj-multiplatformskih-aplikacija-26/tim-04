import 'package:domain/domain.dart';

import 'ports/adoption_request_repository.dart';

final class GetRequests {
  const GetRequests({required this.requests});

  final AdoptionRequestRepository requests;

  Future<List<AdoptionRequest>> call(User by) => requests.requests(applicant: by.role.isStaff ? null : by.id);
}
