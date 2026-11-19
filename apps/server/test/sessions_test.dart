import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart' hide Result;
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/test_database.dart';

late Pool<void> database;
late RelicServer server;
late Uri base;
late Map<String, String> tokens;

Uri at(String path) => base.replace(path: path);

String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

Future<http.Response> logIn(String login, String password, {bool cookie = false}) => http.post(
  at(ApiPaths.sessions),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(LoginDto(username: login, password: password, cookie: cookie).toJson()),
);

void main() {
  setUpAll(() async {
    database = await freshTestDatabase('utociste_test_sessions');
    await seedDemoData(database, demoPassword: 'test-password');
    const clock = SystemClock();
    final animals = PostgresAnimalRepository(database);
    final sessions = SessionHandlers(
      accounts: AccountStore(database),
      secret: testSecret,
      ttl: const Duration(hours: 1),
    );
    tokens = await tokensFor(database, sessions);
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        animals: AnimalHandlers(animals: animals, clock: clock, newId: newUuid),
        requests: RequestHandlers(
          requests: PostgresAdoptionRequestRepository(database),
          animals: animals,
          clock: clock,
          newId: newUuid,
          notifier: const NoopNotifier(),
        ),
        sessions: sessions,
        corsOrigins: const [],
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  test('the right password gives a token that opens the current session', () async {
    final answer = await logIn('udomitelj1', 'test-password');
    expect(answer.statusCode, 201);
    final session = SessionDto.fromJson(jsonDecode(answer.body) as Map<String, Object?>);
    expect(session.user.id, 'u-ana');
    expect(session.user.role, UserDto.adopter);
    expect(session.token, isNotNull);

    final current = await http.get(at(ApiPaths.currentSession), headers: {'Authorization': 'Bearer ${session.token}'});
    expect(current.statusCode, 200);
    expect(SessionDto.fromJson(jsonDecode(current.body) as Map<String, Object?>).user.id, 'u-ana');
  });

  test('the browser gets the token only in an HttpOnly cookie', () async {
    final answer = await logIn('koordinator1', 'test-password', cookie: true);
    expect(answer.statusCode, 201);
    expect(SessionDto.fromJson(jsonDecode(answer.body) as Map<String, Object?>).token, isNull);
    final cookie = answer.headers['set-cookie']!;
    expect(cookie, startsWith('${ApiCookies.session}='));
    expect(cookie.toLowerCase(), contains('httponly'));
  });

  test('a wrong password and an unknown login look the same', () async {
    for (final answer in [await logIn('udomitelj1', 'pogresna'), await logIn('nepoznat', 'test-password')]) {
      expect(answer.statusCode, 401);
      expect(codeOf(answer), ErrorCodes.invalidCredentials);
    }
  });

  test('a changed or expired token is an expired session', () async {
    final expired = SessionHandlers(
      accounts: AccountStore(database),
      secret: testSecret,
      ttl: const Duration(seconds: -1),
    ).tokenFor(const User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.adopter));
    final changed = '${tokens['u-ana']}x';

    for (final token in [expired, changed]) {
      final answer = await http.get(at(ApiPaths.adoptionRequests), headers: {'Authorization': 'Bearer $token'});
      expect(answer.statusCode, 401);
      expect(codeOf(answer), ErrorCodes.sessionExpired);
    }
  });

  test('a token signed with another secret is an expired session', () async {
    final forged = SessionHandlers(
      accounts: AccountStore(database),
      secret: 'someone-elses-secret-0123456789abcdef',
      ttl: const Duration(hours: 1),
    ).tokenFor(const User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.coordinator));

    final answer = await http.post(at(ApiPaths.animals), headers: {'Authorization': 'Bearer $forged'});
    expect(answer.statusCode, 401);
    expect(codeOf(answer), ErrorCodes.sessionExpired);
  });
}
