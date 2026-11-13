import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

HttpAdoptionRequestRepository requestsOver(MockClient server) => HttpAdoptionRequestRepository(
  ApiClient(baseUri: Uri.parse('http://localhost:8080'), devUser: 'u-ana', httpClient: server),
);

http.Response problemAnswer(ProblemDto problem) =>
    http.Response(jsonEncode(problem.toJson()), problem.status, headers: {'content-type': ProblemDto.mediaType});

final request = AdoptionRequest(
  id: const AdoptionRequestId('00000000-0000-4000-8000-000000000004'),
  animalId: const AnimalId('a-02'),
  applicantId: const UserId('u-ana'),
  motivation: RequestMotivation.parse('Imamo veliko dvorište i mnogo slobodnog vremena.').valueOrNull!,
  createdAt: DateTime.utc(2026, 11, 14),
);

Matcher failsWith(RepositoryFailure failure) =>
    throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', failure));

void main() {
  test('a rule broken on the server reaches the client as the same domain error', () async {
    final server = MockClient((sent) async {
      expect(sent.url.path, ApiPaths.adoptionRequests);
      expect(sent.headers[ApiHeaders.devUser], 'u-ana');
      return problemAnswer(const TooManyActiveRequests(max: 2).toProblem());
    });

    final result = await requestsOver(server).submit(request);

    expect(result, const Failure<AdoptionRequest>(TooManyActiveRequests(max: 2)));
  });

  test('withdrawing sends the action, not the whole request', () async {
    final server = MockClient((sent) async {
      expect(sent.method, 'POST');
      expect(sent.url.path, ApiPaths.withdrawal(request.id.value));
      expect(sent.body, isEmpty);
      final withdrawn = request.copyWith(status: AdoptionRequestStatus.withdrawn);
      return http.Response(
        jsonEncode(withdrawn.toDto().toJson()),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await requestsOver(server)
        .save(request.copyWith(status: AdoptionRequestStatus.withdrawn), from: AdoptionRequestStatus.pending);

    expect(result.valueOrNull?.status, AdoptionRequestStatus.withdrawn);
  });

  test('a server that cannot be reached is unreachable', () async {
    final server = MockClient((sent) async => throw http.ClientException('Connection refused', sent.url));

    expect(requestsOver(server).submit(request), failsWith(RepositoryFailure.unreachable));
  });

  test('a server error is a server error', () async {
    final server = MockClient((sent) async => http.Response('oops', 500));

    expect(requestsOver(server).submit(request), failsWith(RepositoryFailure.serverError));
  });

  test('a code the client does not know is refused', () async {
    final server = MockClient(
      (sent) async => problemAnswer(const ProblemDto(status: 409, code: 'nesto-novo', title: '')),
    );

    expect(requestsOver(server).submit(request), failsWith(RepositoryFailure.refused));
  });
}
