import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

HttpAdoptionRequestRepository requestsOver(MockClient server) {
  final tokens = MemoryTokenStore()..write('token-of-ana');
  return HttpAdoptionRequestRepository(
    ApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      tokens: tokens,
      httpClient: server,
      keepsSessionInCookie: false,
    ),
  );
}

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
      expect(sent.headers['Authorization'], 'Bearer token-of-ana');
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

  group('session', () {
    final user = const UserDto(id: 'u-ana', name: 'Ana Petrović', role: UserDto.adopter);

    ApiClient clientOver(MockClient server, TokenStore tokens, {bool cookie = false}) => ApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      tokens: tokens,
      httpClient: server,
      keepsSessionInCookie: cookie,
    );

    test('logging in keeps the token and later calls send it', () async {
      final tokens = MemoryTokenStore();
      final server = MockClient((sent) async {
        if (sent.url.path == ApiPaths.sessions) {
          final session = SessionDto(user: user, expiresAt: DateTime.utc(2026, 11, 21), token: 'fresh');
          return http.Response(jsonEncode(session.toJson()), 201, headers: {'content-type': 'application/json'});
        }
        expect(sent.headers['Authorization'], 'Bearer fresh');
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });
      final api = clientOver(server, tokens);

      final signedIn = await HttpSessionRepository(api).logIn(username: 'udomitelj1', password: 'tajna');
      await HttpAdoptionRequestRepository(api).requests();

      expect(signedIn, const User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.adopter));
      expect(await tokens.read(), 'fresh');
    });

    test('a wrong password is no user, not an error', () async {
      final server = MockClient(
        (sent) async => problemAnswer(const ProblemDto(status: 401, code: ErrorCodes.invalidCredentials, title: '')),
      );

      expect(
        await HttpSessionRepository(clientOver(server, MemoryTokenStore())).logIn(username: 'x', password: 'y'),
        isNull,
      );
    });

    test('an expired session is announced and the call fails as expired', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('old');
      final server = MockClient(
        (sent) async => problemAnswer(const ProblemDto(status: 401, code: ErrorCodes.sessionExpired, title: '')),
      );
      final api = clientOver(server, tokens);
      final announced = expectLater(api.expirations, emits(null));

      await expectLater(HttpAdoptionRequestRepository(api).requests(), failsWith(RepositoryFailure.sessionExpired));
      await announced;
    });

    test('in the browser the token stays in the cookie and is never sent by hand', () async {
      final tokens = MemoryTokenStore();
      await tokens.write('should-not-be-sent');
      final server = MockClient((sent) async {
        expect(sent.headers.containsKey('Authorization'), isFalse);
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });

      await HttpAdoptionRequestRepository(clientOver(server, tokens, cookie: true)).requests();
    });
  });
}
