import 'package:domain/domain.dart';

abstract interface class AdoptionRequestRepository {
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal});

  Future<AdoptionRequest?> find(AdoptionRequestId id);

  Future<Result<AdoptionRequest>> submit(AdoptionRequest request);

  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from});

  Future<Result<ApprovalOutcome>> approve(ApprovalOutcome outcome);
}
