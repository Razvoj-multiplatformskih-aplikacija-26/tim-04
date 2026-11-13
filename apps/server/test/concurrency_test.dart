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

const _name = 'utociste_test_concurrency';

late Pool<void> database;
late Pool<void> serverDatabase;
late RelicServer server;
late Uri base;

Map<String, String> as(String userId) => {'Content-Type': 'application/json', devUserHeader: userId};

Uri at(String path) => base.replace(path: path);

String seededRequest(int number) => '00000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';

Map<String, Object?> bodyOf(http.Response response) => jsonDecode(response.body) as Map<String, Object?>;

Future<http.Response> submit(String userId, String animalId) => http.post(
  at(ApiPaths.adoptionRequests),
  headers: as(userId),
  body: jsonEncode(
    NewAdoptionRequestDto(animalId: animalId, motivation: 'Imamo veliko dvorište i mnogo slobodnog vremena.').toJson(),
  ),
);

Future<http.Response> approve(String userId, String requestId) =>
    http.post(at(ApiPaths.approval(requestId)), headers: as(userId));

Future<List<String>> requestStatuses(String animalId) async {
  final rows = await database.execute(
    Sql.named('SELECT status FROM adoption_requests WHERE animal_id = @animal'),
    parameters: {'animal': animalId},
  );
  return [for (final row in rows) row.single! as String];
}

Future<(String, String?)> animalState(String animalId) async {
  final rows = await database.execute(
    Sql.named('SELECT status, reserved_request FROM animals WHERE id = @animal'),
    parameters: {'animal': animalId},
  );
  final [status, reservedRequest] = rows.single;
  return (status! as String, reservedRequest as String?);
}

Uri _manyConnections() {
  final url = Uri.parse(serverEnvironment()['DATABASE_URL']!);
  return url.replace(path: '/$_name', queryParameters: {...url.queryParameters, 'max_connection_count': '8'});
}

void main() {
  setUp(() async {
    database = await freshTestDatabase(_name);
    await seedDemoData(database);
    serverDatabase = Pool<void>.withUrl(_manyConnections().toString());
    const clock = SystemClock();
    final animals = PostgresAnimalRepository(serverDatabase);
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(
      buildHandler(
        animals: AnimalHandlers(animals: animals, clock: clock, newId: newUuid),
        requests: RequestHandlers(
          requests: PostgresAdoptionRequestRepository(serverDatabase),
          animals: animals,
          clock: clock,
          newId: newUuid,
          notifier: const NoopNotifier(),
        ),
        signIn: DevSignIn(UserStore(serverDatabase)),
        corsOrigins: const [],
      ),
    );
    base = Uri.parse('http://localhost:${server.port}');
  });

  tearDown(() async {
    await server.close();
    await serverDatabase.close();
    await database.close();
  });

  test('five coordinators approving five different requests for one animal at once reserve it only once', () async {
    final applicants = ['u-ana', 'u-marko', 'u-jelena', 'u-nikola', 'u-stefan'];
    final requestIds = [for (final applicant in applicants) bodyOf(await submit(applicant, 'a-04'))['id']! as String];

    final responses = await Future.wait([
      for (final (index, id) in requestIds.indexed) approve(index.isEven ? 'u-coordinator' : 'u-senior', id),
    ]);

    final winners = [
      for (final (index, response) in responses.indexed)
        if (response.statusCode == 200) requestIds[index],
    ];
    expect(winners, hasLength(1));
    for (final response in responses.where((response) => response.statusCode != 200)) {
      expect(response.statusCode, 409);
      expect(bodyOf(response)['code'], anyOf(ErrorCodes.animalNotAdoptable, ErrorCodes.invalidRequestTransition));
    }
    expect(await animalState('a-04'), ('reserved', winners.single));
    final statuses = await requestStatuses('a-04');
    expect(statuses.where((status) => status == 'approved'), hasLength(1));
    expect(statuses.where((status) => status == 'pending'), isEmpty);
  });

  test('the same request approved five times at once is approved only once', () async {
    final responses = await Future.wait([for (var i = 0; i < 5; i++) approve('u-coordinator', seededRequest(4))]);

    expect(responses.where((response) => response.statusCode == 200), hasLength(1));
    expect(responses.where((response) => response.statusCode == 409), hasLength(4));
    expect(await animalState('a-02'), ('reserved', seededRequest(4)));
    expect(await requestStatuses('a-02'), ['approved']);
  });

  test('an adopter sending several requests at once cannot go over the limit of active requests', () async {
    final responses = await Future.wait([
      for (final animal in ['a-02', 'a-03', 'a-04']) submit('u-nikola', animal),
    ]);

    expect(responses.where((response) => response.statusCode == 201), hasLength(1));
    for (final response in responses.where((response) => response.statusCode != 201)) {
      expect(response.statusCode, 409);
      expect(bodyOf(response)['code'], ErrorCodes.tooManyActiveRequests);
    }
    final active = await database.execute(
      "SELECT count(*) FROM adoption_requests WHERE applicant_id = 'u-nikola' AND status IN ('pending', 'approved')",
    );
    expect(active.single.single, 2);
  });

  test('the same request sent twice at once is stored only once', () async {
    final responses = await Future.wait([submit('u-stefan', 'a-03'), submit('u-stefan', 'a-03')]);

    expect(responses.map((response) => response.statusCode), unorderedEquals([201, 409]));
    final duplicate = responses.firstWhere((response) => response.statusCode == 409);
    expect(bodyOf(duplicate)['code'], ErrorCodes.duplicateRequest);
    final rows = await database.execute(
      "SELECT count(*) FROM adoption_requests WHERE applicant_id = 'u-stefan' AND animal_id = 'a-03'",
    );
    expect(rows.single.single, 1);
  });
}
