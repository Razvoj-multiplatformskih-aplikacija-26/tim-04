import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/test_database.dart';

late Pool<void> database;
late RelicServer server;
late Uri base;

Map<String, String> as(String userId) => {'Content-Type': 'application/json', devUserHeader: userId};

Uri at(String path) => base.replace(path: path);

String codeOf(http.Response response) => (jsonDecode(response.body) as Map<String, Object?>)['code']! as String;

String seededRequest(int number) => '00000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';

Future<http.Response> intake(String userId, {String name = 'Novi'}) => http.post(
  at(ApiPaths.animals),
  headers: as(userId),
  body: jsonEncode(
    IntakeDto(
      name: name,
      species: AnimalDto.dog,
      birthDate: DateTime.utc(2024, 1, 1),
      description: 'Pronađen pored puta.',
      enclosureId: 'P-2',
    ).toJson(),
  ),
);

Future<http.Response> submit(
  String userId,
  String animalId, {
  String motivation = 'Imamo veliko dvorište i mnogo slobodnog vremena.',
}) => http.post(
  at(ApiPaths.adoptionRequests),
  headers: as(userId),
  body: jsonEncode(NewAdoptionRequestDto(animalId: animalId, motivation: motivation).toJson()),
);

void main() {
  setUpAll(() async {
    database = await freshTestDatabase('utociste_test_rights');
    await seedDemoData(database);
    const clock = SystemClock();
    final animals = PostgresAnimalRepository(database);
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
        signIn: DevSignIn(UserStore(database)),
        corsOrigins: const [],
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await database.close();
  });

  group('rights', () {
    test('without a user the server asks to sign in', () async {
      final response = await http.get(at(ApiPaths.animals));
      expect(response.statusCode, 401);
      expect(codeOf(response), ErrorCodes.signInRequired);
    });

    test('an adopter cannot take in an animal', () async {
      final response = await intake('u-ana');
      expect(response.statusCode, 403);
      expect(codeOf(response), ErrorCodes.notAllowed);
    });

    test('an adopter cannot start a quarantine', () async {
      final response = await http.post(
        at(ApiPaths.quarantine('a-05')),
        headers: as('u-ana'),
        body: jsonEncode(QuarantineDto(until: DateTime.utc(2026, 12, 1)).toJson()),
      );
      expect(response.statusCode, 403);
      expect(codeOf(response), ErrorCodes.notAllowed);
    });

    test('an adopter cannot approve or reject, not even her own request', () async {
      for (final path in [ApiPaths.approval(seededRequest(4)), ApiPaths.rejection(seededRequest(4))]) {
        final response = await http.post(at(path), headers: as('u-ana'));
        expect(response.statusCode, 403, reason: path);
        expect(codeOf(response), ErrorCodes.notAllowed, reason: path);
      }
    });

    test('someone else\'s request looks as if it does not exist', () async {
      final response = await http.post(at(ApiPaths.withdrawal(seededRequest(1))), headers: as('u-ana'));
      expect(response.statusCode, 404);
      expect(codeOf(response), ErrorCodes.notFound);
    });
  });

  group('rules called around the app give the same code as in the app', () {
    test('a name that is too short', () async {
      final response = await intake('u-coordinator', name: 'R');
      expect(response.statusCode, 422);
      expect(codeOf(response), ErrorCodes.nameTooShort);
    });

    test('a motivation that is too short', () async {
      final response = await submit('u-ana', 'a-03', motivation: 'Kratko.');
      expect(response.statusCode, 422);
      expect(codeOf(response), ErrorCodes.motivationTooShort);
    });

    test('a third active request', () async {
      expect((await submit('u-jelena', 'a-03')).statusCode, 201);
      final third = await submit('u-jelena', 'a-04');
      expect(third.statusCode, 409);
      expect(codeOf(third), ErrorCodes.tooManyActiveRequests);
    });
  });
}
