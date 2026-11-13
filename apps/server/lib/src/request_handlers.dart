import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;
import 'package:use_cases/use_cases.dart';

import 'dev_sign_in.dart';
import 'http.dart';

final class RequestHandlers {
  RequestHandlers({
    required AdoptionRequestRepository requests,
    required AnimalRepository animals,
    required Clock clock,
    required String Function() newId,
  }) : _getRequests = GetRequests(requests: requests),
       _submitRequest = SubmitRequest(requests: requests, animals: animals, clock: clock, newId: newId),
       _withdrawRequest = WithdrawRequest(requests: requests, clock: clock),
       _approveRequest = ApproveRequest(requests: requests, animals: animals, clock: clock),
       _rejectRequest = RejectRequest(requests: requests);

  final GetRequests _getRequests;
  final SubmitRequest _submitRequest;
  final WithdrawRequest _withdrawRequest;
  final ApproveRequest _approveRequest;
  final RejectRequest _rejectRequest;

  Future<Response> requests(Request request) async =>
      json(200, [for (final adoptionRequest in await _getRequests(_actor(request))) _toJson(adoptionRequest)]);

  Future<Response> submit(Request request) async {
    final body = NewAdoptionRequestDto.fromJson(await readObject(request));
    final motivation = RequestMotivation.parse(body.motivation);
    if (motivation case Failure(:final error)) return problem(error);
    final result = await _submitRequest(
      animalId: AnimalId(body.animalId),
      motivation: motivation.valueOrNull!,
      by: _actor(request),
    );
    return respond(result, _toJson, status: 201);
  }

  Future<Response> withdraw(Request request) async =>
      respond(await _withdrawRequest(id: _id(request), by: _actor(request)), _toJson);

  Future<Response> approve(Request request) async => respond(
    await _approveRequest(id: _id(request), by: _actor(request)),
    (ApprovalOutcome outcome) => _toJson(outcome.approved),
  );

  Future<Response> reject(Request request) async =>
      respond(await _rejectRequest(id: _id(request), by: _actor(request)), _toJson);

  AdoptionRequestId _id(Request request) => AdoptionRequestId(request.rawPathParameters[#id]!);

  User _actor(Request request) => currentUser.get(request);
}

Map<String, Object?> _toJson(AdoptionRequest request) => request.toDto().toJson();
