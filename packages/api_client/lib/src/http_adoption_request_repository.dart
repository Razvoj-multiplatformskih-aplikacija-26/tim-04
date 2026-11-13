import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_client.dart';

final class HttpAdoptionRequestRepository implements AdoptionRequestRepository {
  const HttpAdoptionRequestRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async {
    final visible = valueOf(
      await _api.get(ApiPaths.adoptionRequests),
      (json) => [for (final item in jsonList(json)) _request(item)],
    );
    return [
      for (final request in visible)
        if ((applicant == null || request.applicantId == applicant) && (animal == null || request.animalId == animal))
          request,
    ];
  }

  @override
  Future<AdoptionRequest?> find(AdoptionRequestId id) async {
    for (final request in await requests()) {
      if (request.id == id) return request;
    }
    return null;
  }

  @override
  Future<Result<AdoptionRequest>> submit(AdoptionRequest request) async {
    final body = NewAdoptionRequestDto(animalId: request.animalId.value, motivation: request.motivation.text);
    return resultOf(await _api.post(ApiPaths.adoptionRequests, body: body.toJson()), _request);
  }

  @override
  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from}) async {
    final id = request.id.value;
    final answer = await switch (request.status) {
      AdoptionRequestStatus.withdrawn => _api.post(ApiPaths.withdrawal(id)),
      AdoptionRequestStatus.rejected => _api.post(ApiPaths.rejection(id)),
      AdoptionRequestStatus.pending || AdoptionRequestStatus.approved => throw ArgumentError.value(
        request.status,
        'status',
        'The server has no action for this change',
      ),
    };
    return resultOf(answer, _request);
  }

  @override
  Future<Result<ApprovalOutcome>> approve(ApprovalOutcome outcome) async {
    final answer = await _api.post(ApiPaths.approval(outcome.approved.id.value));
    return resultOf(
      answer,
      (json) => ApprovalOutcome(animal: outcome.animal, approved: _request(json), rejected: outcome.rejected),
    );
  }

  AdoptionRequest _request(Object? json) => AdoptionRequestDto.fromJson(jsonObject(json)).toDomain();
}
