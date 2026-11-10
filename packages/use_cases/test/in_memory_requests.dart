import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

class InMemoryRequests implements AdoptionRequestRepository {
  InMemoryRequests(List<AdoptionRequest> requests) : _requests = [...requests];

  final List<AdoptionRequest> _requests;

  AdoptionRequest stored(AdoptionRequestId id) => _requests.firstWhere((r) => r.id == id);

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async => [
    for (final request in _requests)
      if ((applicant == null || request.applicantId == applicant) && (animal == null || request.animalId == animal))
        request,
  ];

  @override
  Future<AdoptionRequest?> find(AdoptionRequestId id) async => _requests.where((r) => r.id == id).firstOrNull;

  @override
  Future<Result<AdoptionRequest>> submit(AdoptionRequest request) async {
    _requests.add(request);
    return Success(request);
  }

  @override
  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from}) async {
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return const Failure(NotFound());
    if (_requests[index].status != from) return const Failure(InvalidRequestTransition());
    _requests[index] = request;
    return Success(request);
  }

  @override
  Future<Result<ApprovalOutcome>> approve(ApprovalOutcome outcome) async {
    final index = _requests.indexWhere((r) => r.id == outcome.approved.id);
    if (index == -1 || _requests[index].status != AdoptionRequestStatus.pending) {
      return const Failure(InvalidRequestTransition());
    }
    for (final changed in [outcome.approved, ...outcome.rejected]) {
      _requests[_requests.indexWhere((r) => r.id == changed.id)] = changed;
    }
    return Success(outcome);
  }
}

class RequestsChangedMeanwhile extends InMemoryRequests {
  RequestsChangedMeanwhile(super.requests, {required this.changeTo});

  final AdoptionRequestStatus changeTo;
  var _raced = false;

  @override
  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from}) async {
    if (!_raced) {
      _raced = true;
      _requests[_requests.indexWhere((r) => r.id == request.id)] = stored(request.id).copyWith(status: changeTo);
    }
    return super.save(request, from: from);
  }
}
